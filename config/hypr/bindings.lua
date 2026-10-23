-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
-- omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Toggle the keyboard visibility using a custom keybind

-- (Replace "SUPER_ALT, K" with your preferred physical binding structure if Omarchy uses a strict table format)

o.bind("SUPER + E", nil, "nautilus")

-- Desactivar los atajos predeterminados de Hey.com.
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + ALT + E")

-- Teclado táctil en Super + Shift + J.
hl.unbind("SUPER + SHIFT + J")
o.bind("SUPER + SHIFT + J", "Alternar Teclado Táctil", "pkill wvkbd-mobintl || wvkbd-mobintl -L 250")

-- Captura de pantalla: sustituir Google Maps y habilitar Impr Pant.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Captura de pantalla", "omarchy capture screenshot")
hl.unbind("Print")
o.bind("Print", "Captura de pantalla", "omarchy capture screenshot")

-- Alternar la pantalla enfocada entre Full HD y su resolución nativa.
o.bind("SUPER + SHIFT + R", "Alternar resolución 1080p / completa", [[
    monitor=$(hyprctl monitors -j | jq -ec '.[] | select(.focused == true)') || exit 1
    output=$(printf '%s' "$monitor" | jq -r '.name')
    case "$output" in *[!a-zA-Z0-9._-]*|"") exit 1 ;; esac
    scale=$(printf '%s' "$monitor" | jq -r '.scale')
    position=$(printf '%s' "$monitor" | jq -r '"\(.x)x\(.y)"')
    if printf '%s' "$monitor" | jq -e '.width == 1920 and .height == 1080' >/dev/null; then
        mode=preferred
    else
        mode=1920x1080@60
    fi
    hyprctl eval "hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"$position\", scale = $scale })"
]])

-- Abrir WhatsApp en lugar de Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })

-- Abrir Notion en lugar del editor.
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Notion", { webapp = "https://app.notion.com", focus = true })


-- Keep the HP mic LED in sync with the selected microphone mute state.
hl.unbind("XF86AudioMicMute")
o.bind("XF86AudioMicMute", "Mute microphone", os.getenv("HOME") .. "/.local/bin/mic-mute-toggle", { locked = true })

-- Open Omarchy menu when either Super key is tapped alone.
hl.unbind("SUPER + SPACE")
o.bind("SUPER + SUPER_L", "Omarchy menu", "omarchy-menu toggle", { release = true })
o.bind("SUPER + SUPER_R", "Omarchy menu", "omarchy-menu toggle", { release = true })

o.bind("SUPER + SPACE", "Cambiar Idioma", [[
    for device in $(hyprctl devices -j | jq -r ' .keyboards[].name'); do
        hyprctl switchxkblayout "$device" next
    done
]])

-- Alternar la pantalla integrada entre la orientación normal y 90°.
o.bind("SUPER + Q", "Rotar pantalla", [[
    /home/lobato/.local/bin/omarchy-rotate-display
]])
