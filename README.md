# omarchy-plus

Configuración de este HP OmniBook 5 Flip sobre Omarchy: atajos, teclado táctil, rotación de la pantalla, tema Alpenglow, luces de mute y límite de batería al 80%.

`apply.sh` copia esos archivos y, la primera vez que uno ya existe y es distinto, deja `*.bak.omarchy-plus` al lado. Se puede correr de nuevo. No reescribe el módulo de batería ni el parche de las luces: usa las copias que están en el repo.

## Instalar

Hace falta Omarchy, `git`, `jq` y `sudo`. En esta OmniBook, si el módulo de batería todavía no está instalado, también hacen falta DKMS y los headers del kernel (`omarchy pkg add dkms`).

```bash
cd omarchy-plus
./apply.sh
```

El script pide la contraseña para el límite de batería y para las luces. Al terminar:

- Recargá Hyprland para tomar atajos, pantalla y entrada: `hyprctl reload`
- Si la barra no cambia, `omarchy restart shell`
- Si las luces eran nuevas o distintas, reiniciá. El sonido interno vuelve después de ese reinicio. No escribas el nodo `reconfig`.

## Qué cambia

### Pantalla

- La pantalla interna `eDP-1` y el HDMI quedan en escala 1.25. El HDMI se coloca arriba del panel (`0x-864`).
- `Super+Q` y el botón de rotar de la barra alternan el panel entre horizontal (escala 1.25) y vertical (escala 1.6, giro de 90°).
- El táctil y el lápiz (`elan2514:00-04f3:445a` y su stylus) siguen al panel. Hyprland no gira el toque solo.

El atajo y el botón llaman a `/home/lobato/.local/bin/omarchy-rotate-display`, que es donde `apply.sh` instala el script para este usuario.

### Teclado, ratón y panel táctil

- Distribuciones `us` y `latam`.
- Repetición a 40, espera de 250, bloqueo numérico encendido.
- Ratón con sensibilidad 0.25 y sin aceleración.
- Panel táctil con desplazamiento natural, clic con dos dedos, desplazamiento a 0.4, arrastre con tres dedos, y sigue activo mientras se escribe.

### Atajos

| Atajo | Qué hace |
| --- | --- |
| `Super` (tocar y soltar) | Abre el menú de Omarchy |
| `Super+Espacio` | Pasa a la distribución de teclado siguiente |
| `Super+E` | Archivos |
| `Super+Q` | Rota la pantalla interna |
| `Super+Shift+J` | Muestra u oculta el teclado táctil |
| `Super+Shift+S` y `Impr Pant` | Captura de pantalla |
| `Super+Shift+R` | La pantalla enfocada alterna 1920×1080 y su resolución nativa |
| `Super+Shift+W` | WhatsApp Web |
| `Super+Shift+N` | Notion |
| Mute del micrófono | Sincroniza la luz de mute con `mic-mute-toggle` |

Se quitan los atajos de Hey.com (`Super+Shift+C`, `Super+Shift+E` y `Super+Shift+Alt+E`).

### Barra

Queda arriba, opaca y centrada en el reloj. La fuente base es 12. En el centro hay un botón de teclado táctil y otro para rotar la pantalla. El protector espera 150 segundos y el bloqueo, 300. En los agentes quedan activos Claude, Fireworks y Grok.

El teclado de la barra, del atajo y del menú es `wvkbd-mobintl -L 250`. Si no está instalado, `apply.sh` agrega el paquete `wvkbd`.

### Menú

`apply.sh` reemplaza `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Quedan dos entradas:

- **Limitar batería al 80%**, en Setup. La marca indica que el tope está activo. Solo se ve si la laptop publica un control de carga.
- **Teclado táctil**, que muestra u oculta el teclado en pantalla.

### Tema

El tema queda en Alpenglow, commit `cc31fb4cd677647085a788f1102373c8751398a8`, clonado en `~/.config/omarchy/themes/alpenglow`. `apply.sh` lo activa con `omarchy theme set alpenglow`. Si esa carpeta ya existe y no es un clon git, el script se detiene y no la pisa.

### Batería

Instala `salva-baterias`. Activar deja el tope en 80%. Desactivar vuelve a la carga completa.

- En esta OmniBook escribe el ajuste de BIOS que ya usa el módulo `hp-battery-health`. Si `/usr/src/hp-battery-health-0.1.0` existe, no lo recompila ni lo recarga.
- Ese módulo solo se compila en la OmniBook 5 Flip 14-fp0xxx, y solo si todavía no está. En otra marca no se instala.
- En otras laptops escribe `charge_control_end_threshold` (o el nombre viejo `charge_stop_threshold`) de la batería del equipo. Si no existe, prueba Huawei, LG antiguo, Sony o Samsung. Ratones y lápices no entran.
- No usa el `conservation_mode` de Lenovo IdeaPad, porque ese tope es 60% u 80% según el modelo y Linux no dice cuál es.

El BIOS de esta HP recuerda el valor. En las demás, el primer cambio deja `/etc/salva-baterias.conf` y un servicio que lo vuelve a aplicar al arrancar.

```bash
salva-baterias status
salva-baterias on
salva-baterias off
salva-baterias toggle
```

Desde el menú pide autorización con `pkexec`. Más detalle en [salva-baterias/README.md](salva-baterias/README.md).

### Luces de mute

En esta OmniBook copia tres archivos, y solo regenera el initramfs si alguno cambió:

- `/usr/lib/firmware/hp-omnibook-14-fp-leds.fw`
- `/etc/modprobe.d/hp-omnibook-mute-leds.conf`
- `/etc/mkinitcpio.conf.d/hp-omnibook-mute-leds.conf`

La tecla de mute del micrófono llama a `~/.local/bin/mic-mute-toggle`. No se toca el nodo `reconfig`. El detalle está en [hp-mute-leds/README.md](hp-mute-leds/README.md).

## Qué no cambia

No modifica `hyprland.lua`, no recompila un módulo de batería que ya esté instalado y no escribe el nodo `reconfig` del audio. Las luces y el módulo de BIOS son de esta OmniBook. El comando de batería, en cambio, también sirve en laptops que publican el umbral del kernel.

## Volver atrás

Los archivos de usuario reemplazados tienen una copia `*.bak.omarchy-plus` de la primera corrida. Para quitar las luces o el módulo de batería, los pasos están en los README de `hp-mute-leds` y `salva-baterias`. Quitar el módulo no cambia el valor que ya quedó en el BIOS.
