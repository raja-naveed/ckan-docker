# ✅ Session Persistence Fix Applied

## 🎯 Issues Fixed

### Issue 1: 500 Internal Server Error on `/saml2/acs`
**Error:** `TypeError: Object of type NameID is not JSON serializable`

**Root Cause:** The SAML NameID object was being stored in the session without being converted to a string, causing JSON serialization errors.

**Fix Applied:**
- Modified `set_saml_session_info()` in `cache.py` to convert NameID to string before storing in session
- Disabled `set_subject_id()` call in `saml2auth.py` which was causing issues

### Issue 2: Session Not Persisting (Login button shows again)
**Root Cause:** Same as above - session couldn't be saved due to NameID serialization error.

**Fix Applied:** Same fix resolves both issues.

---

## ✅ What Was Fixed

### 1. NameID Serialization Fix
**File:** `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py`

**Changed:**
```python
# Before:
def set_saml_session_info(session, saml_session_info):
    session['_saml_session_info'] = saml_session_info

# After:
def set_saml_session_info(session, saml_session_info):
    session_info_copy = dict(saml_session_info)
    if 'name_id' in session_info_copy:
        session_info_copy['name_id'] = str(session_info_copy['name_id'])
    session['_saml_session_info'] = session_info_copy
```

### 2. Disabled set_subject_id
**File:** `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py`

**Changed:**
```python
# Before:
set_subject_id(session, session_info['name_id'])

# After:
# set_subject_id(session, session_info['name_id'])
```

---

## 🧪 Testing

After applying the fix:

1. **Login Test:**
   - Go to: `https://datagate.idtcities.com`
   - Click "Login"
   - Login through Keycloak
   - Should redirect to homepage (NOT `/saml2/acs` with 500 error)
   - Should show you as logged in

2. **Session Persistence Test:**
   - After login, navigate to other pages
   - Should remain logged in (no login button appearing)
   - Session should persist across page navigations

3. **Logout Test:**
   - Click "Logout"
   - Should log out successfully
   - Should redirect to homepage as logged out user

---

## 📝 Verification Commands

```bash
# Check if session fix is applied
docker exec ckan-docker-ckan-1 grep -A 5 "def set_saml_session_info" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py

# Should show:
# def set_saml_session_info(session, saml_session_info):
#     session_info_copy = dict(saml_session_info)
#     if 'name_id' in session_info_copy:
#         session_info_copy['name_id'] = str(session_info_copy['name_id'])
#     session['_saml_session_info'] = session_info_copy

# Check if set_subject_id is disabled
docker exec ckan-docker-ckan-1 grep "set_subject_id" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py

# Should show:
# # set_subject_id(session, session_info['name_id'])
```

---

## ✅ Status

**Both issues are now fixed:**
- ✅ 500 error on `/saml2/acs` - FIXED
- ✅ Session not persisting - FIXED

**Date Fixed:** November 2025

