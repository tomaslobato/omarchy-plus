#!/bin/bash
# Instala el comando universal. El módulo de esta OmniBook solo se compila
# si todavía no está, y nunca en otra marca. No lo recompila ni lo recarga.
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Ejecutar con sudo o pkexec.' >&2; exit 1; }
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

install -d /usr/local/bin /usr/local/libexec
install -m 755 salva-baterias /usr/local/bin/salva-baterias
install -m 755 salva-baterias-root /usr/local/libexec/salva-baterias-root

install_hp_if_needed() {
  local vendor product source_dir state
  vendor=$(< /sys/class/dmi/id/sys_vendor)
  product=$(< /sys/class/dmi/id/product_name)
  source_dir=/usr/src/hp-battery-health-0.1.0
  if [[ $vendor != HP || $product != "HP OmniBook 5 Flip Laptop 14-fp0xxx" ]]; then
    echo "No instalo el módulo de HP en ${vendor} ${product}."
    return 0
  fi
  if [[ -e $source_dir ]]; then
    echo "El módulo HP ya está instalado. No se recompila."
  else
    command -v dkms >/dev/null || { echo 'Instalar dkms y los headers del kernel.' >&2; exit 1; }
    install -d "$source_dir"
    install -m 644 hp_battery_health.c hp-battery-read.h hp-battery-read.asl dkms.conf "$source_dir/"
    printf 'obj-m += hp_battery_health.o\nKDIR ?= /usr/lib/modules/$(shell uname -r)/build\nall:\n\t$(MAKE) -C $(KDIR) M=$(CURDIR) modules\nclean:\n\t$(MAKE) -C $(KDIR) M=$(CURDIR) clean\n' > "$source_dir/Makefile"
    dkms add -m hp-battery-health -v 0.1.0
    dkms build -m hp-battery-health -v 0.1.0
    dkms install -m hp-battery-health -v 0.1.0
    printf 'hp_battery_health\n' > /etc/modules-load.d/hp-battery-health.conf
  fi
  if [[ ! -e /etc/modules-load.d/hp-battery-health.conf ]]; then
    printf 'hp_battery_health\n' > /etc/modules-load.d/hp-battery-health.conf
  fi
  state=/sys/module/hp_battery_health/initstate
  if [[ ! -e $state ]]; then
    modprobe hp_battery_health
  elif [[ $(<"$state") != live ]]; then
    echo 'El módulo HP quedó bloqueado. Reiniciá antes de volver a cargarlo.' >&2
    exit 1
  fi
}

install_hp_if_needed
echo 'Comando de límite de batería instalado.'
