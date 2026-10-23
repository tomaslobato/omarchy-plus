#!/usr/bin/env python3
"""Add the battery entry, preserving existing Omarchy JSONC and a backup."""
import json
import re
import shutil
from datetime import datetime
from pathlib import Path

path = Path.home() / '.config/omarchy/extensions/omarchy-menu.jsonc'
entry = json.loads(Path(__file__).with_name('omarchy-menu.jsonc').read_text())
text = path.read_text() if path.exists() else '{}\n'
# Strip comments without touching quoted strings, for validation only.
def uncomment(match):
    return match.group() if match.group().startswith('"') else ''
clean = re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', uncomment, text)
# JSONC trailing commas, again without touching string contents.
clean = re.sub(r'"(?:\\.|[^"\\])*"|,(?=\s*[}\]])', uncomment, clean)
items = json.loads(clean)
if 'setup.battery-health' in items:
    if items['setup.battery-health'] != entry['setup.battery-health']:
        raise SystemExit('Ya existe setup.battery-health con otra configuración; no se reemplazó.')
    print('La opción ya está instalada.')
else:
    if not isinstance(items, dict):
        raise SystemExit('El menú debe ser un objeto JSONC.')
    pos = text.rfind('}')
    if pos < 0:
        raise SystemExit('Menú inválido.')
    # Existing nonempty objects may or may not have a trailing comma.
    body = re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', uncomment, text[:pos]).rstrip()
    separator = ',' if items and not body.endswith(',') else ''
    addition = json.dumps(entry, ensure_ascii=False, indent=2)[1:-1].strip()
    if path.exists():
        shutil.copy2(path, path.with_name(path.name + '.bak.' + datetime.now().strftime('%Y%m%d-%H%M%S')))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text[:pos] + separator + '\n  ' + addition + '\n' + text[pos:])
    print(f'Opción instalada en {path}')
