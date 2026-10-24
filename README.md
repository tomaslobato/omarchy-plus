# omarchy-plus

Configuración de este OmniBook sobre Omarchy: atajos, teclado táctil, rotación de la pantalla, tema Alpenglow, luces de mute y límite de batería al 80%.

El código del módulo de batería y el parche de las luces están copiados tal cual. `apply.sh` no los vuelve a escribir.

```bash
./apply.sh
```

Se puede correr otra vez. Si un archivo de configuración ya existe y es distinto, la primera vez deja una copia `*.bak.omarchy-plus`.

- Horizontal queda en escala 1.25 y vertical en 1.6. `Super+Q` y el botón de la barra giran la pantalla y el táctil.
- `Super+Shift+J`, el botón de la barra y el menú abren el teclado táctil.
- El tema por defecto es Alpenglow, Se instala desde `https://github.com/peteonrails/omarchy-alpenglow-theme` y `apply.sh` lo deja activo con `omarchy theme set alpenglow`.
- La tecla de mute llama a `~/.local/bin/mic-mute-toggle`.
- El límite de batería instala el comando universal con `salva-baterias/install-system.sh`. En esta OmniBook sigue usando el módulo de BIOS que ya está. En otras laptops escribe `charge_control_end_threshold`. Si el módulo ya está en `/usr/src/hp-battery-health-0.1.0`, no se recompila.
- Las luces copian el firmware y las dos configuraciones que ya funcionan. Solo regeneran el initramfs si alguno de esos archivos cambió, y piden reiniciar. No tocan el nodo `reconfig`.
