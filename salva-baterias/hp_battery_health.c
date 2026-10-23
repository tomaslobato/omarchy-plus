// SPDX-License-Identifier: GPL-2.0
/* HP OmniBook 14-fp0xxx workaround for zero-length fields in WQBC.
 * Adds a temporary read-only AML helper; writes use HP's SetBIOSSetting WMI.
 * Exposes only Battery Health Manager and supports BIOS without a password. */
#include <linux/module.h>
#include <linux/acpi.h>
#include <linux/wmi.h>
#include <linux/dmi.h>
#include <linux/kobject.h>
#include <linux/mutex.h>
#include <linux/unaligned.h>
#include "hp-battery-read.h"
#define ENUM_GUID "2D114B49-2DFB-4130-B8FE-4A3C09E75133"
#define SET_GUID "1F4C91EB-DC5C-460B-951D-C7CB9B4B8D5E"
#define SETTING "Battery Health Manager"
#define ON "Maximize my battery health On"
#define OFF "Maximize my battery health Off"
static DEFINE_MUTEX(lock);
static struct kobject *kobj;
static u32 table_index;
static int battery_index = -1;
static bool table_loaded;
/* Bounded decoder for HP's length-prefixed ASCII enumeration response. */
static int string(const u8 **p, const u8 *end, char *out, size_t size)
{
 unsigned int n;
 if (end-*p<2) return -EPROTO;
 n=get_unaligned_le16(*p); *p+=2;
 if (n >= size || n > end-*p) return -EPROTO;
 memcpy(out, *p, n); out[n]=0; *p+=n;
 return 0;
}
static int read_record(int index, char *name, char *value)
{
 union acpi_object arg={.integer={.type=ACPI_TYPE_INTEGER,.value=index}};
 struct acpi_object_list args={1,&arg};
 struct acpi_buffer out={ACPI_ALLOCATE_BUFFER,NULL};
 union acpi_object *obj, *raw;
 const u8 *p,*end;
 char desc[512], option[128];
 unsigned int n, i;
 int ret=-EPROTO;
 bool has_on=false, has_off=false;
 if (ACPI_FAILURE(acpi_evaluate_object(NULL,"\\_SB.WMID.HBRD",&args,&out))) return -EIO;
 obj=out.pointer;
 if (!obj || obj->type!=ACPI_TYPE_PACKAGE || obj->package.count!=2) goto done;
 if (obj->package.elements[0].type!=ACPI_TYPE_INTEGER || obj->package.elements[0].integer.value) { ret=-EIO; goto done; }
 raw=&obj->package.elements[1];
 if (raw->type!=ACPI_TYPE_BUFFER) goto done;
 p=raw->buffer.pointer; end=p+raw->buffer.length;
 if (string(&p,end,name,128)) goto done;
 if (strcmp(name,SETTING)) {ret=-ENOENT; goto done;}
 if (end-p<4 || get_unaligned_le16(p)) goto done; /* read-only flag */
 p+=4;
 if (string(&p,end,desc,sizeof(desc)) || string(&p,end,value,128)) goto done;
 if (end-p<2) goto done;
 n=get_unaligned_le16(p);p+=2;
 if (n>16) goto done;
 for(i=0;i<n;i++) {
  if(string(&p,end,option,sizeof(option))) goto done;
  has_on |= !strcmp(option,ON); has_off |= !strcmp(option,OFF);
 }
 if(!has_on || !has_off || (strcmp(value,ON) && strcmp(value,OFF))) goto done;
 ret=0;
done:
 kfree(out.pointer); return ret;
}
static ssize_t enabled_show(struct kobject *k, struct kobj_attribute *a, char *buf)
{
 char name[128],value[128];int ret;
 mutex_lock(&lock);ret=read_record(battery_index,name,value);mutex_unlock(&lock);
 return ret ? ret : sysfs_emit(buf,"%d\n",!strcmp(value,ON));
}
static u16 *encode(u16 *p,const char *s)
{
 size_t n=strlen(s),i;
 *p++=cpu_to_le16(n ? n*2 : 2);
 if(!n) {*p++=0; return p;}
 for(i=0;i<n;i++) *p++=cpu_to_le16((unsigned char)s[i]);
 return p;
}
static ssize_t enabled_store(struct kobject *k,struct kobj_attribute *a,const char *buf,size_t count)
{
 bool enabled; u16 data[128],*end;
 struct acpi_buffer in,out={ACPI_ALLOCATE_BUFFER,NULL};
 union acpi_object *obj;
 char name[128],value[128];int ret;
 if(kstrtobool(buf,&enabled)) return -EINVAL;
 mutex_lock(&lock);
 ret=read_record(battery_index,name,value);
 if(ret) goto done;
 if(enabled == !strcmp(value,ON)) {ret=0;goto done;}
 end=encode(data,SETTING);end=encode(end,enabled?ON:OFF);end=encode(end,"");
 in.length=(u8 *)end-(u8 *)data;in.pointer=data;
 if(ACPI_FAILURE(wmi_evaluate_method(SET_GUID,0,1,&in,&out))) {ret=-EIO;goto free;}
 obj=out.pointer;
 if(!obj || obj->type!=ACPI_TYPE_INTEGER) {ret=-EPROTO;goto free;}
 if(obj->integer.value) {
  pr_err("hp_battery_health: SetBIOSSetting returned %llu\n",obj->integer.value);
  ret=obj->integer.value==6 ? -EACCES : -EIO;goto free;
 }
 ret=read_record(battery_index,name,value);
 if(!ret && enabled != !strcmp(value,ON)) ret=-EIO;
free:
 kfree(out.pointer);
done:
 mutex_unlock(&lock);return ret?ret:count;
}
static struct kobj_attribute enabled_attr=__ATTR_RW(enabled);
static int __init start(void)
{
 char name[128],value[128];int i,n,ret;
 struct acpi_table_header *table;
 if(!dmi_match(DMI_SYS_VENDOR,"HP") || !dmi_match(DMI_PRODUCT_NAME,"HP OmniBook 5 Flip Laptop 14-fp0xxx")) return -ENODEV;
 if(!wmi_has_guid(ENUM_GUID) || !wmi_has_guid(SET_GUID)) return -ENODEV;
 /* ACPICA retains the table descriptor after unload, including its pointer.
  * Give it kernel-lifetime storage independent of this module. This tiny
  * allocation intentionally survives unload (218 bytes per load). */
 table=kmemdup(read_aml,sizeof(read_aml),GFP_KERNEL);
 if(!table) return -ENOMEM;
 if(ACPI_FAILURE(acpi_load_table(table,&table_index))) return -EIO;
 table_loaded=true;
 n=wmi_instance_count(ENUM_GUID);
 if(n<1 || n>128) {ret=-EINVAL;goto fail;}
 for(i=0;i<n;i++) if(!read_record(i,name,value)) {battery_index=i;break;}
 if(battery_index<0) {ret=-ENODEV;goto fail;}
 kobj=kobject_create_and_add("hp_battery_health",kernel_kobj);
 if(!kobj) {ret=-ENOMEM;goto fail;}
 ret=sysfs_create_file(kobj,&enabled_attr.attr);
 if(ret) {kobject_put(kobj);goto fail;}
 pr_info("hp_battery_health: Battery Health Manager available (record %d)\n",battery_index);
 return 0;
fail:
 acpi_unload_table(table_index);table_loaded=false;return ret;
}
static void __exit stop(void)
{
 sysfs_remove_file(kobj,&enabled_attr.attr);kobject_put(kobj);
 if(table_loaded) acpi_unload_table(table_index);
}
module_init(start);module_exit(stop);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("HP OmniBook Battery Health Manager firmware workaround");
