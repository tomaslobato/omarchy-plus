#!/usr/bin/env bash
# Apply the Omarchy customizations kept in this repo.
# Safe to run again. Does not rewrite the battery module or the mute-LED patch.
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
hypr_dir=$config_home/hypr
omarchy_dir=$config_home/omarchy
bin_dir=$HOME/.local/bin
theme_dir=$omarchy_dir/themes/lawson-night
theme_url=https://github.com/phuclh/omarchy-lawson-night-theme.git
theme_pin=28dfc00

install_user_file() {
  local src=$1 dest=$2 mode=$3
  mkdir -p -- "$(dirname -- "$dest")"
  if [[ -e $dest ]] && ! cmp -s "$src" "$dest"; then
    if [[ ! -e ${dest}.bak.omarchy-plus ]]; then
      cp -a -- "$dest" "${dest}.bak.omarchy-plus"
    fi
  fi
  install -m "$mode" -- "$src" "$dest"
}

echo "Configuración de Hyprland, barra y menú"
install_user_file "$root/config/hypr/bindings.lua" "$hypr_dir/bindings.lua" 644
install_user_file "$root/config/hypr/input.lua" "$hypr_dir/input.lua" 644
install_user_file "$root/config/hypr/monitors.lua" "$hypr_dir/monitors.lua" 644
install_user_file "$root/config/omarchy/shell.json" "$omarchy_dir/shell.json" 644
install_user_file "$root/config/omarchy/shell.toml" "$omarchy_dir/shell.toml" 644
install_user_file "$root/config/omarchy/extensions/omarchy-menu.jsonc" "$omarchy_dir/extensions/omarchy-menu.jsonc" 644
install_user_file "$root/config/omarchy/bar/modules/rotate-display.qml" "$omarchy_dir/bar/modules/rotate-display.qml" 644
install_user_file "$root/config/bin/omarchy-rotate-display" "$bin_dir/omarchy-rotate-display" 755
install_user_file "$root/hp-mute-leds/mic-mute-toggle" "$bin_dir/mic-mute-toggle" 755

if ! command -v wvkbd-mobintl >/dev/null 2>&1; then
  echo "Instalando wvkbd"
  omarchy pkg add wvkbd
fi

echo "Tema Lawson Night ($theme_pin)"
if [[ -d $theme_dir/.git ]]; then
  git -C "$theme_dir" fetch origin
  git -C "$theme_dir" checkout "$theme_pin"
elif [[ ! -e $theme_dir ]]; then
  git clone "$theme_url" "$theme_dir"
  git -C "$theme_dir" checkout "$theme_pin"
else
  echo "$theme_dir existe y no es un clon git. No lo reemplazo." >&2
  exit 1
fi
omarchy theme set lawson-night

if [[ -e /usr/src/hp-battery-health-0.1.0 ]]; then
  echo "El límite de batería ya está instalado. No se vuelve a instalar."
else
  echo "Instalando el límite de batería"
  sudo "$root/salva-baterias/install-system.sh"
fi

echo "Luces de mute"
leds_changed=0
install_root_file() {
  local src=$1 dest=$2 mode=$3
  if [[ ! -e $dest ]] || ! cmp -s "$src" "$dest"; then
    sudo install -D -m "$mode" -- "$src" "$dest"
    leds_changed=1
  fi
}
install_root_file "$root/hp-mute-leds/hp-omnibook-14-fp-leds.fw" /usr/lib/firmware/hp-omnibook-14-fp-leds.fw 644
install_root_file "$root/hp-mute-leds/hp-omnibook-mute-leds.conf" /etc/modprobe.d/hp-omnibook-mute-leds.conf 644
install_root_file "$root/hp-mute-leds/hp-omnibook-mute-leds.mkinitcpio.conf" /etc/mkinitcpio.conf.d/hp-omnibook-mute-leds.conf 644
if [[ $leds_changed == 1 ]]; then
  sudo limine-mkinitcpio
  echo "Las luces de mute quedan activas después de reiniciar. No escribas el nodo reconfig."
else
  echo "Las luces de mute ya estaban instaladas."
fi

echo "Listo."
