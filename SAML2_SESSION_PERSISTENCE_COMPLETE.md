# SAML2 SSO with Session Persistence - COMPLETE ✅

## Date: October 24, 2025
## Status: FULLY WORKING

---

## What Has Been Fixed

### 1. ✅ SAML2 Authentication Integration
- **Keycloak IdP**: Connected to `https://auth.idtcities.com/realms/IdtCities`
- **Entity ID**: `https://localhost:8443/saml2/metadata`
- **ACS Endpoint**: `/saml2/acs` (HTTP-POST binding)
- **Attribute Mapping**: Using OID format for email, firstname, lastname

### 2. ✅ Session Persistence Fixed
**Problem**: User would log in successfully but session would not persist across page navigation.

**Root Cause**: NameID object from SAML2 response was not JSON serializable, causing Flask session to fail silently.

**Solution Applied** (in `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py`):
```python
def set_saml_session_info(session, saml_session_info):
    session_info_copy = dict(saml_session_info)
    if 'name_id' in session_info_copy:
        session_info_copy['name_id'] = str(session_info_copy['name_id'])  # Convert NameID to string
    session['_saml_session_info'] = session_info_copy
```

### 3. ✅ Additional Fixes Applied
- Disabled problematic `set_subject_id()` call in views (line 269)
- Fixed ACS endpoint routing (hardcoded `/saml2/acs`)
- Cleared Python cache to ensure changes take effect
- Configured OID attribute mappings for Keycloak X500 mappers

---

## How to Test

### Step 1: Access the SAML2 Login
1. Open browser: `https://localhost:8443/user/saml2login`
2. Accept the self-signed certificate warning (click "Advanced" → "Proceed to localhost")
3. You will be redirected to Keycloak login page

### Step 2: Login with Keycloak
- **Username**: `superadmin`
- **Password**: `idtcities123`
- Click "Sign In"

### Step 3: Verify Session Persistence
After successful login, you should see:
- ✅ Username "Super Admin" in the header (top right)
- ✅ User remains logged in when navigating to other pages
- ✅ Can access user profile: `https://localhost:8443/user/superadmin`
- ✅ Can access datasets: `https://localhost:8443/dataset/`
- ✅ Can access organizations: `https://localhost:8443/organization/`

### Step 4: Test Session Across Pages
1. Click on "Data" menu → Should show username in header
2. Click on "Organizations" → Should show username in header
3. Click on username → Should show user profile page
4. Navigate to home page → Should still show username in header

**Expected Result**: Username stays visible in header across ALL pages!

---

## Technical Details

### Configuration Files Modified

#### 1. `docker-compose.yml`
```yaml
environment:
  - CKAN__PLUGINS=... saml2auth
  - CKANEXT__SAML2AUTH__IDP_METADATA__LOCATION=remote
  - CKANEXT__SAML2AUTH__IDP_METADATA__REMOTE_URL=https://auth.idtcities.com/realms/IdtCities/protocol/saml/descriptor
  - CKANEXT__SAML2AUTH__USER_FIRSTNAME=urn:oid:2.5.4.42
  - CKANEXT__SAML2AUTH__USER_LASTNAME=urn:oid:2.5.4.4
  - CKANEXT__SAML2AUTH__USER_EMAIL=urn:oid:1.2.840.113549.1.9.1
  - CKANEXT__SAML2AUTH__ENTITY_ID=https://localhost:8443/saml2/metadata
  - CKANEXT__SAML2AUTH__ACS_ENDPOINT=/saml2/acs
  - CKANEXT__SAML2AUTH__ENABLE_CKAN_INTERNAL_LOGIN=false
```

#### 2. `Dockerfile.custom`
- Added `xmlsec1` package (required for SAML2)
- Added `ckanext-saml2auth` plugin installation
- Added custom `prerun.py.override` for SAML2 configuration

#### 3. Runtime Patches Applied
- **File**: `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py`
  - Fixed NameID serialization for session persistence
  
- **File**: `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py`
  - Line 269: Disabled `set_subject_id()` call
  - Line 348: Hardcoded ACS endpoint to `/saml2/acs`

---

## Keycloak Configuration

### Client Settings
- **Client ID**: `https://localhost:8443/saml2/metadata`
- **Client Protocol**: `saml`
- **Valid Redirect URIs**: `https://localhost:8443/*`
- **Master SAML Processing URL**: `https://localhost:8443/saml2/acs`
- **Force POST Binding**: `ON`
- **Client Signature Required**: `OFF`

### Client Scopes & Mappers
Created dedicated scope with X500 mappers:
- **X500 email** → `urn:oid:1.2.840.113549.1.9.1`
- **X500 givenName** → `urn:oid:2.5.4.42`
- **X500 surname** → `urn:oid:2.5.4.4`

---

## Verification Commands

### Check if patches are applied:
```bash
# Check NameID fix
docker exec ckan-docker-ckan-1 grep -A 4 "def set_saml_session_info" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py

# Check set_subject_id is disabled
docker exec ckan-docker-ckan-1 sed -n '269p' /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py

# Check ACS endpoint
docker exec ckan-docker-ckan-1 grep -n "acs_endpoint = " /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py
```

### Check CKAN is running:
```bash
docker ps
docker logs ckan-docker-ckan-1 --tail 50
```

---

## Re-applying Fixes After Container Rebuild

If you rebuild the container, run this script to re-apply the session persistence fixes:

```bash
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan
```

---

## Success Criteria ✅

- [x] User can login via Keycloak SAML2
- [x] No 405 errors on ACS endpoint
- [x] No 500 errors after authentication
- [x] Username appears in header after login
- [x] Session persists across page navigation
- [x] User can access protected pages
- [x] User profile is accessible
- [x] Internal login is disabled (SAML2 only)

---

## What to Show Your Boss

1. **Open the site**: `https://localhost:8443/`
2. **Click "Login"** (it will show 403 - this is correct, SAML2 only)
3. **Navigate to**: `https://localhost:8443/user/saml2login`
4. **Login with Keycloak** credentials
5. **Show that username appears in header** after successful login
6. **Navigate to different pages** (Data, Organizations, etc.)
7. **Show that username STAYS in header** across all pages
8. **Click on username** to show user profile page

**This proves the session is persisting correctly!**

---

## Support

If you encounter any issues:
1. Check container logs: `docker logs ckan-docker-ckan-1 --tail 100`
2. Verify patches are applied (see verification commands above)
3. Re-apply fixes if needed (see re-applying section above)
4. Check Keycloak events log for authentication errors

---

## Summary

✅ **SAML2 SSO is fully working**  
✅ **Session persistence is fixed**  
✅ **User stays logged in across pages**  
✅ **Ready for production demonstration**

**Last Updated**: October 24, 2025  
**Status**: COMPLETE AND WORKING

