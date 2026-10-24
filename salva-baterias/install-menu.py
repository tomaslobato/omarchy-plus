#!/usr/bin/env python3
"""Add or refresh the battery entry, preserving existing Omarchy JSONC and a backup."""
import json
import os
import re
import shutil
from datetime import datetime
from pathlib import Path

if os.geteuid() == 0:
    raise SystemExit('Ejecutarlo como el usuario, no como root.')

path = Path.home() / '.config/omarchy/extensions/omarchy-menu.jsonc'
entry = json.loads(Path(__file__).with_name('omarchy-menu.jsonc').read_text())
text = path.read_text() if path.exists() else '{}\n'
# Strip comments without touching quoted strings, for validation only.
def uncomment(match):
    return match.group() if match.group().startswith('"') else ''
clean = re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', uncomment, text)
# JSONC trailing commas, again without touching string contents.
clean = re.sub(r'"(?:\\.|[^"\\])*"|,(?=\s*[}\]])', uncomment, clean)
def parsed(raw):
    def uncomment(match):
        return match.group() if match.group().startswith('"') else ''
    body = re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', uncomment, raw)
    body = re.sub(r'"(?:\\.|[^"\\])*"|,(?=\s*[}\]])', uncomment, body)
    return json.loads(body)

def object_span(raw, key):
    token = f'"{key}"'
    start = 0
    while True:
        i = raw.find(token, start)
        if i < 0:
            raise SystemExit(f'No encontré {key} para actualizarlo.')
        j = raw.find('{', i + len(token))
        if j < 0:
            raise SystemExit('Menú inválido.')
        if not re.fullmatch(r'\s*:\s*', raw[i + len(token):j]):
            start = i + len(token)
            continue
        depth = 0
        in_str = False
        esc = False
        k = j
        while k < len(raw):
            c = raw[k]
            if in_str:
                if esc:
                    esc = False
                elif c == '\\':
                    esc = True
                elif c == '"':
                    in_str = False
            else:
                if c == '"':
                    in_str = True
                elif c == '{':
                    depth += 1
                elif c == '}':
                    depth -= 1
                    if depth == 0:
                        return i, k + 1
            k += 1
        raise SystemExit('Menú inválido.')

items = parsed(clean)
replacement = json.dumps(entry, ensure_ascii=False, indent=2)[1:-1].strip()
if 'setup.battery-health' in items:
    if items['setup.battery-health'] == entry['setup.battery-health']:
        print('La opción ya está instalada.')
    else:
        span = object_span(text, 'setup.battery-health')
        updated = text[:span[0]] + replacement + text[span[1]:]
        parsed(re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', uncomment, updated))
        if path.exists():
            shutil.copy2(path, path.with_name(path.name + '.bak.' + datetime.now().strftime('%Y%m%d-%H%M%S')))
        path.write_text(updated)
        print(f'Opción actualizada en {path}')
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
