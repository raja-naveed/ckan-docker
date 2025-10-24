#!/usr/bin/env python3
import os

print("[1/3] Fixing NameID serialization in cache.py...")
cache_file = "/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py"
with open(cache_file, 'r') as f:
    content = f.read()

old_func = """def set_saml_session_info(session, saml_session_info):
    session['_saml_session_info'] = saml_session_info"""

new_func = """def set_saml_session_info(session, saml_session_info):
    session_info_copy = dict(saml_session_info)
    if 'name_id' in session_info_copy:
        session_info_copy['name_id'] = str(session_info_copy['name_id'])
    session['_saml_session_info'] = session_info_copy"""

if old_func in content:
    content = content.replace(old_func, new_func)
    with open(cache_file, 'w') as f:
        f.write(content)
    print("[OK] NameID serialization fixed")
else:
    print("[SKIP] Already fixed or not found")

print("[2/3] Disabling set_subject_id in views...")
saml_file = "/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py"
with open(saml_file, 'r') as f:
    lines = f.readlines()

for i in range(len(lines)):
    if 'set_subject_id(session, session_info[' in lines[i] and not lines[i].strip().startswith('#'):
        lines[i] = '        # ' + lines[i].lstrip()
        print(f"[OK] Disabled set_subject_id on line {i+1}")
        break

with open(saml_file, 'w') as f:
    f.writelines(lines)

print("[3/3] Clearing Python cache...")
os.system('rm -rf /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/__pycache__')
os.system('rm -rf /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/__pycache__')

print("[DONE] Session persistence fixes applied!")
