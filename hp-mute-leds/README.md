# Luces de mute — HP OmniBook 5 Flip 14-fp0xxx

Hardware: Realtek ALC245, codec SSID `103c:8e03`, kernel `7.2.5-3-omarchy`.

La prueba directa confirmó visualmente que ambas luces funcionan: mute usa el coeficiente 0x0b, máscara 0x0c, valor encendido 0x08; micmute usa GPIO 0x04 con polaridad invertida.

Se instaló el ajuste nativo equivalente a `103c:8756` mediante un parche temprano del módulo SOF `snd_soc_hdac_hda`. No cambia la configuración de los pines de audio. Archivos:

- `/usr/lib/firmware/hp-omnibook-14-fp-leds.fw`
- `/etc/modprobe.d/hp-omnibook-mute-leds.conf`
- `/etc/mkinitcpio.conf.d/hp-omnibook-mute-leds.conf`

La reconfiguración en caliente quedó bloqueada en `snd_card_free`, dentro del controlador ASoC. Los servicios PipeWire y WirePlumber se restablecieron, pero el audio interno necesita reiniciar. No repetir la escritura de `reconfig` en este equipo.

Tras reiniciar, comprobar el sonido, el micrófono y ambas teclas de mute. Deben existir `hda::mute` y `hda::micmute` en `/sys/class/leds`; la confirmación visual sigue pendiente.

Para deshacer el ajuste desde una terminal:

```bash
sudo rm /etc/modprobe.d/hp-omnibook-mute-leds.conf /etc/mkinitcpio.conf.d/hp-omnibook-mute-leds.conf /usr/lib/firmware/hp-omnibook-14-fp-leds.fw
sudo limine-mkinitcpio
```

Luego reiniciar.
