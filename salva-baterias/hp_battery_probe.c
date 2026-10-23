// SPDX-License-Identifier: GPL-2.0
/* Read-only diagnostic: request BIOS enumeration records, then read the raw
 * firmware response when this HP's AML fails on zero-length CreateField. */
#include <linux/module.h>
#include <linux/acpi.h>
#include <linux/wmi.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#define GUID "2D114B49-2DFB-4130-B8FE-4A3C09E75133"
static unsigned char records[128][1024];
static int lengths[128], count;
static acpi_status statuses[128];
static int types[128];
static struct proc_dir_entry *entry;
static int show(struct seq_file *s, void *unused)
{
 int i, j;
 for (i=0; i<count; i++) {
  seq_printf(s, "%d/%x/%d:", i, statuses[i], types[i]);
  for (j=0; j<lengths[i]; j++) seq_printf(s, "%02x", records[i][j]);
  seq_putc(s, '\n');
 }
 return 0;
}
static int open_probe(struct inode *inode, struct file *file) { return single_open(file, show, NULL); }
static const struct proc_ops ops = { .proc_open=open_probe, .proc_read=seq_read, .proc_lseek=seq_lseek, .proc_release=single_release };
static int __init start(void)
{
 int i;
 if (!wmi_has_guid(GUID)) return -ENODEV;
 count=wmi_instance_count(GUID);
 if (count<1 || count>128) return -EINVAL;
 for (i=0; i<count; i++) {
  struct acpi_buffer out={ACPI_ALLOCATE_BUFFER, NULL};
  union acpi_object *obj;
  wmi_query_block(GUID, i, &out);
  kfree(out.pointer);
  out.pointer=NULL;
  out.length=ACPI_ALLOCATE_BUFFER;
  statuses[i]=acpi_evaluate_object(NULL, "\\_SB.WMID.EHWB", NULL, &out);
  if (ACPI_FAILURE(statuses[i])) continue;
  obj=out.pointer;
  if (obj) types[i]=obj->type;
  if (obj && obj->type==ACPI_TYPE_BUFFER) {
   lengths[i]=min_t(int, obj->buffer.length, 1024);
   memcpy(records[i], obj->buffer.pointer, lengths[i]);
  }
  kfree(out.pointer);
 }
 entry=proc_create("hp_battery_probe", 0400, NULL, &ops);
 return entry ? 0 : -ENOMEM;
}
static void __exit stop(void) { proc_remove(entry); }
module_init(start); module_exit(stop);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Read-only HP BIOS enumeration diagnostic");
