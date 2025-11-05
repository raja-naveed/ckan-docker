#!/usr/bin/env python3
"""
Fix ACS endpoint to exempt from CSRF protection and ensure POST method works
"""
import os

print("[1/3] Ensuring ACS endpoint path is correct...")
saml_file = "/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py"
with open(saml_file, 'r') as f:
    content = f.read()

# Fix ACS endpoint path if needed
if "acs_endpoint = config.get" in content:
    content = content.replace(
        "acs_endpoint = config.get",
        "acs_endpoint = '/saml2/acs'  # Hardcoded for correct CKAN integration\n# acs_endpoint = config.get"
    )
    print("[OK] ACS endpoint path fixed")

print("[2/3] Adding CSRF exemption to ACS function...")
# Find the acs function and add CSRF exemption decorator
if "def acs():" in content:
    # Check if already has csrf exemption
    if "csrf.exempt" in content or "@csrf.exempt" in content:
        print("[SKIP] CSRF exemption already present")
    else:
        # Find the def acs line and add decorator before it
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.strip() == "def acs():":
                # Add CSRF exemption import if not present
                if "from flask import" in content and "csrf" not in content:
                    # Find the flask import line
                    for j, import_line in enumerate(lines):
                        if "from flask import" in import_line and j < i:
                            lines[j] = import_line.replace("from flask import", "from flask import csrf, ")
                            break
                elif "from flask import" not in content:
                    # Add flask import at the top
                    for j, import_line in enumerate(lines):
                        if "import" in import_line and j < 10:
                            lines.insert(j+1, "from flask import csrf")
                            break
                
                # Add decorator before def acs
                lines.insert(i, "@csrf.exempt")
                lines.insert(i+1, "def acs():")
                content = '\n'.join(lines)
                print("[OK] CSRF exemption added to ACS function")
                break

print("[3/3] Ensuring POST method is registered...")
# Verify POST method is in the route registration
if "methods=[u'GET', u'POST']" in content or "methods=['GET', 'POST']" in content:
    print("[OK] POST method already registered")
else:
    # Fix the methods parameter
    content = content.replace(
        "saml2auth.add_url_rule(acs_endpoint, view_func=acs)",
        "saml2auth.add_url_rule(acs_endpoint, view_func=acs, methods=['GET', 'POST'])"
    )
    print("[OK] POST method added to route")

# Write the fixed content
with open(saml_file, 'w') as f:
    f.write(content)

print("[4/4] Clearing Python cache...")
os.system('rm -rf /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/__pycache__')
os.system('rm -rf /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/__pycache__')

print("[DONE] ACS endpoint CSRF exemption fix applied!")

