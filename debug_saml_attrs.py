# Patch the ACS view to log all SAML attributes
import sys

with open('/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py', 'r') as f:
    lines = f.readlines()

# Find the line with email = auth_response.ava
for i, line in enumerate(lines):
    if 'email = auth_response.ava[saml_user_email][0]' in line:
        # Insert debug logging before this line
        indent = '    '
        debug_lines = [
            f'{indent}# DEBUG: Log all available SAML attributes\n',
            f'{indent}import logging as log_mod\n',
            f'{indent}log_mod.error(f"DEBUG: All SAML attributes received: {{auth_response.ava}}")\n',
            f'{indent}log_mod.error(f"DEBUG: Looking for email attribute: {{saml_user_email}}")\n',
            f'{indent}\n'
        ]
        lines = lines[:i] + debug_lines + lines[i:]
        print(f'✓ Added debug logging before line {i+1}')
        break

with open('/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py', 'w') as f:
    f.writelines(lines)

print('✓ Debug logging added to SAML2 ACS handler')


