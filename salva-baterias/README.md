# Salva baterías para Linux / Omarchy

Implementación para **HP OmniBook 5 Flip Laptop 14-fp0xxx**, probada con BIOS
F.06 y kernel Omarchy 7.2.5-3. El firmware publica `Battery Health Manager`
con `Maximize my battery health On` y `Maximize my battery health Off`.

## Uso

```bash
salva-baterias status
salva-baterias on
salva-baterias off
salva-baterias toggle
```

En Omarchy: **Setup → Limitar batería al 80%**. La marca ✓ indica activado.
Los cambios requieren autorización de administrador (sudo en terminal,
pkexec desde el menú). No se instala una excepción de permisos.

El ajuste se escribe en el BIOS, con lectura posterior para confirmar el
cambio; no hace falta un proceso que vigile el porcentaje. No se modifica
Adaptive Battery Extender ni otros ajustes. No soporta contraseña de BIOS.

## Instalación

Se necesitan DKMS y los headers del kernel instalado. En Omarchy:

```bash
omarchy pkg add dkms
# Instalar el paquete de headers correspondiente a tu kernel si falta.
cd linux
sudo ./install-system.sh
python3 ./install-menu.py
```

DKMS recompila el módulo para nuevos kernels cuando sus headers están
instalados. `/etc/modules-load.d/hp-battery-health.conf` lo carga al arrancar.
La entrada de menú se oculta si la interfaz no está disponible. El instalador
conserva una copia del menú previo. El soporte está limitado al modelo indicado;
no se presupone compatibilidad con otros HP.

## Cómo funciona

El script Windows usa `HP_BIOSSettingInterface.SetBIOSSetting`. Linux usa el
mismo GUID WMI de escritura y la codificación UTF-16 del controlador oficial
`hp-bioscfg`.

En este BIOS, `WQBC` crea campos ACPI de longitud cero para valores vacíos;
ACPICA aborta la consulta. Además, el registro cero no tiene nombre. La
implementación añade temporalmente un método ACPI `HBRD` que ejecuta la misma
consulta de lectura bajo el mutex original y devuelve el registro crudo,
sin crear esos campos. No reemplaza tablas ni métodos del BIOS, ni cambia
el arranque o el firmware. El módulo valida nombre, permisos y ambos valores
posibles antes de publicar `/sys/kernel/hp_battery_health/enabled`.

`hp-battery-read.h` es el AML generado desde `hp-battery-read.asl` con ACPICA
`iasl`. Se incluye para que DKMS no necesite un compilador ASL.

ACPICA conserva el descriptor y la dirección de una tabla después de
`acpi_unload_table`. El módulo usa una copia independiente del módulo que
permanece asignada hasta reiniciar (218 bytes por carga), para permitir la
recarga sin dejar una referencia a memoria liberada.

## Validación y estado de esta instalación (2026-10-12)

- Se leyó el ajuste real en el registro 79: activado.
- Se cambió a desactivado y se confirmó mediante lectura.
- Se restauró a activado y se confirmó mediante lectura.
- La primera versión tuvo un error de duración de memoria al descargar y
  recargar el módulo: provocó un Oops en `acpi_tb_verify_temp_table`.
- La corrección de almacenamiento independiente está compilada e instalada
  mediante DKMS; **requiere reiniciar y validar en un kernel limpio**. No se
  volvió a cargar en la sesión afectada.
- El menú se valida con el parser de Omarchy; la comprobación visual queda
  pendiente porque `omarchy-shell` no está en ejecución en esta sesión.

Después de reiniciar, comprobar `salva-baterias status`, el cambio off/on y el
menú. El BIOS quedó con el límite activado antes del error de recarga.

## Desinstalación

```bash
sudo rm /etc/modules-load.d/hp-battery-health.conf
sudo dkms remove -m hp-battery-health -v 0.1.0 --all
sudo rm -r /usr/src/hp-battery-health-0.1.0
sudo rm /usr/local/bin/salva-baterias /usr/local/libexec/salva-baterias-root
```

Eliminar la entrada `setup.battery-health` del menú personal de Omarchy y
reiniciar. Desinstalar no cambia el valor guardado en el BIOS. No intentar
descargar/recargar módulos en la sesión que sufrió el Oops.

El módulo `hp_battery_probe.c` fue una herramienta de diagnóstico de lectura,
retirada tras recuperar los registros; no se instala mediante DKMS.
