# ✅ Domain Migration Complete: localhost:8443 → datagate.snap4idtcity.com

## 🎯 Summary

All configurations have been updated to use `https://datagate.snap4idtcity.com` instead of `https://localhost:8443`.

---

## ✅ Changes Applied

### 1. **CKAN Configuration** ✅
- **File:** `/srv/app/ckan.ini` (inside container)
- **Changed:** `ckan.site_url = https://datagate.snap4idtcity.com`
- **Changed:** `ckanext.saml2auth.entity_id = https://datagate.snap4idtcity.com/saml2/metadata`

### 2. **Environment Variables** ✅
- **File:** `docker-compose.yml`
- **Changed:** `CKAN__SITE__URL=https://datagate.snap4idtcity.com`
- **Changed:** `CKANEXT__SAML2AUTH__ENTITY_ID=https://datagate.snap4idtcity.com/saml2/metadata`

### 3. **.env File** ✅
- **File:** `.env`
- **Changed:** `CKAN_SITE_URL=https://datagate.snap4idtcity.com`

### 4. **Nginx Configuration** ✅
- **File:** `nginx/setup/default.conf`
- **Changed:** `server_name datagate.snap4idtcity.com;`
- **Added:** Proper proxy headers for domain forwarding

### 5. **Keycloak SAML2 Client** ✅ (You updated this)
- **Client ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
- **Valid Redirect URIs:** `https://datagate.snap4idtcity.com/saml2/acs`
- **Valid Post Logout Redirect URIs:** `https://datagate.snap4idtcity.com/*`
- **Web Origins:** `https://datagate.snap4idtcity.com`

---

## 🧪 Testing Checklist

Please test these to verify everything works:

### ✅ Test 1: Access CKAN Homepage
- [ ] Open: `https://datagate.snap4idtcity.com`
- [ ] Should load without redirecting to localhost:8443
- [ ] Logo and homepage should display correctly

### ✅ Test 2: SAML2 Login Flow
- [ ] Click "Login" button
- [ ] Should redirect to Keycloak: `https://auth.idtcities.com`
- [ ] After login, should redirect back to: `https://datagate.snap4idtcity.com`
- [ ] Should NOT redirect to `localhost:8443`
- [ ] User should be logged in and see their username

### ✅ Test 3: File Upload URLs
- [ ] Go to any dataset → "Add Resource"
- [ ] Check "Upload" button - should show correct domain
- [ ] Upload a file
- [ ] File URL should be: `https://datagate.snap4idtcity.com/storage/...`
- [ ] Should NOT contain `localhost:8443`

### ✅ Test 4: Resource URLs
- [ ] View any resource/download file
- [ ] URLs should use: `https://datagate.snap4idtcity.com/...`
- [ ] Should NOT contain `localhost:8443`

### ✅ Test 5: SAML2 Metadata
- [ ] Open: `https://datagate.snap4idtcity.com/saml2/metadata`
- [ ] Should show XML with `entityID="https://datagate.snap4idtcity.com/saml2/metadata"`
- [ ] Should show ACS URL: `https://datagate.snap4idtcity.com/saml2/acs`

---

## 🔍 Verification Commands

If you need to verify the configuration:

```bash
# Check CKAN config
docker exec ckan-docker-ckan-1 grep -E "site_url|entity_id" /srv/app/ckan.ini

# Check environment variables
docker exec ckan-docker-ckan-1 env | grep -E "CKAN.*SITE|SAML.*ENTITY"

# Check Nginx config
docker exec ckan-docker-nginx-1 grep "server_name" /etc/nginx/conf.d/default.conf

# Check services are running
docker compose ps
```

---

## ⚠️ If Issues Persist

### Issue: Still redirecting to localhost:8443

**Solution:**
1. Clear browser cache and cookies
2. Restart CKAN: `docker compose restart ckan`
3. Check logs: `docker compose logs ckan | tail -50`

### Issue: "Invalid Redirect URI" in Keycloak

**Solution:**
1. Double-check Keycloak client settings:
   - Valid Redirect URIs must include: `https://datagate.snap4idtcity.com/saml2/acs`
   - Web Origins must include: `https://datagate.snap4idtcity.com`
2. Verify no typos in URLs

### Issue: File upload URLs still show localhost

**Solution:**
1. Verify CKAN site_url: `docker exec ckan-docker-ckan-1 grep "site_url" /srv/app/ckan.ini`
2. Restart CKAN: `docker compose restart ckan`
3. Clear CKAN cache if needed

---

## 📝 Files Modified

1. ✅ `docker-compose.yml` - Environment variables
2. ✅ `.env` - Site URL
3. ✅ `nginx/setup/default.conf` - Server name and headers
4. ✅ `/srv/app/ckan.ini` (container) - CKAN configuration
5. ✅ Keycloak Admin Console - SAML2 client settings

---

## 🎉 Status

**All domain configurations have been updated!**

- ✅ CKAN site URL: `https://datagate.snap4idtcity.com`
- ✅ SAML2 Entity ID: `https://datagate.snap4idtcity.com/saml2/metadata`
- ✅ Nginx server name: `datagate.snap4idtcity.com`
- ✅ Keycloak client: Updated with new domain

**Next Steps:**
1. Test the login flow
2. Test file uploads
3. Verify all URLs use the correct domain

---

**Date Completed:** November 2025  
**Status:** ✅ Ready for Testing

