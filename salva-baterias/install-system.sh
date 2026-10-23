#!/bin/bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Ejecutar con sudo o pkexec.' >&2; exit 1; }
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
command -v dkms >/dev/null || { echo 'Instalar dkms y los headers del kernel.' >&2; exit 1; }
source_dir=/usr/src/hp-battery-health-0.1.0
[[ ! -e "$source_dir" ]] || { echo "$source_dir ya existe; revisar la instalación previa." >&2; exit 1; }
install -d "$source_dir" /usr/local/libexec
install -m 644 hp_battery_health.c hp-battery-read.h hp-battery-read.asl dkms.conf "$source_dir/"
printf 'obj-m += hp_battery_health.o\nKDIR ?= /usr/lib/modules/$(shell uname -r)/build\nall:\n\t$(MAKE) -C $(KDIR) M=$(CURDIR) modules\nclean:\n\t$(MAKE) -C $(KDIR) M=$(CURDIR) clean\n' > "$source_dir/Makefile"
dkms add -m hp-battery-health -v 0.1.0
dkms build -m hp-battery-health -v 0.1.0
dkms install -m hp-battery-health -v 0.1.0
install -m 755 salva-baterias /usr/local/bin/salva-baterias
install -m 755 salva-baterias-root /usr/local/libexec/salva-baterias-root
printf 'hp_battery_health\n' > /etc/modules-load.d/hp-battery-health.conf
modprobe hp_battery_health
