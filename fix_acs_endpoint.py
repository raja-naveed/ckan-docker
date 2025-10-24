lines = open('/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py').readlines()
for i, line in enumerate(lines):
    if "acs_endpoint = config.get" in line:
        lines[i] = "acs_endpoint = '/saml2/acs'  # Hardcoded for correct CKAN integration\n"
        print(f'Fixed line {i+1}')
        break
open('/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py', 'w').writelines(lines)
