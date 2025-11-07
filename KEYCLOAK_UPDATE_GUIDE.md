# 🔐 Keycloak SAML2 Client Update Guide

## 🎯 Overview

After changing the CKAN domain from `localhost:8443` to `datagate.snap4idtcity.com`, you **MUST** update the SAML2 client configuration in Keycloak to match the new domain.

---

## 📋 Prerequisites

- Access to Keycloak Admin Console: `https://auth.idtcities.com/admin`
- Admin credentials for the `IdtCities` realm
- The CKAN SAML2 client should already exist in Keycloak

---

## 🔧 Step-by-Step Keycloak Update Instructions

### Step 1: Access Keycloak Admin Console

1. Open your browser and navigate to:
   ```
   https://auth.idtcities.com/admin
   ```

2. Log in with your Keycloak administrator credentials

3. Select the **`IdtCities`** realm from the dropdown (top left)

---

### Step 2: Navigate to the CKAN SAML2 Client

1. In the left sidebar, click **`Clients`**
2. Find and click on the **CKAN client** (usually named `ckan` or `datagate-ckan`)
   - If you don't see it, search for it in the search box
   - If it doesn't exist, you'll need to create it (see **Creating New Client** section below)

---

### Step 3: Update Client Settings

Click on the CKAN client name to open its settings. You need to update the following fields:

#### **3.1. Client ID**
- **Current:** `https://localhost:8443/saml2/metadata` (or similar)
- **New:** `https://datagate.snap4idtcity.com/saml2/metadata`
- **Location:** This is typically the **Client ID** field at the top of the settings page

#### **3.2. Valid Redirect URIs**
- **Current:** `https://localhost:8443/saml2/acs` (or similar)
- **New:** `https://datagate.snap4idtcity.com/saml2/acs`
- **Location:** Under the **`Settings`** tab → **`Valid Redirect URIs`** field

**Important:** You can add multiple URIs separated by commas:
```
https://datagate.snap4idtcity.com/saml2/acs,https://localhost:8443/saml2/acs
```
(Keeping localhost temporarily for testing is optional)

#### **3.3. Valid Post Logout Redirect URIs**
- **Current:** `https://localhost:8443/*` (or similar)
- **New:** `https://datagate.snap4idtcity.com/*`
- **Location:** Under the **`Settings`** tab → **`Valid Post Logout Redirect URIs`** field

**Example:**
```
https://datagate.snap4idtcity.com/*,https://datagate.snap4idtcity.com/
```

#### **3.4. Web Origins**
- **Current:** `https://localhost:8443` (or similar)
- **New:** `https://datagate.snap4idtcity.com`
- **Location:** Under the **`Settings`** tab → **`Web Origins`** field

**Example:**
```
https://datagate.snap4idtcity.com,https://localhost:8443
```

---

### Step 4: Update SAML2 Specific Settings

Scroll down to the **`SAML2`** section (if visible) or check the **`Advanced Settings`** tab:

#### **4.1. Assertion Consumer Service POST Binding URL**
- **Current:** `https://localhost:8443/saml2/acs`
- **New:** `https://datagate.snap4idtcity.com/saml2/acs`

#### **4.2. Service Provider Entity ID**
- **Current:** `https://localhost:8443/saml2/metadata`
- **New:** `https://datagate.snap4idtcity.com/saml2/metadata`

#### **4.3. Single Logout Service URL**
- **Current:** `https://localhost:8443/saml2/sls` (if configured)
- **New:** `https://datagate.snap4idtcity.com/saml2/sls`

---

### Step 5: Save Changes

1. Click the **`Save`** button at the bottom of the page
2. Wait for the confirmation message: **"Client updated successfully"**

---

### Step 6: Verify Configuration

After saving, verify these URLs are correct:

✅ **Client ID:** `https://datagate.snap4idtcity.com/saml2/metadata`  
✅ **Valid Redirect URIs:** Contains `https://datagate.snap4idtcity.com/saml2/acs`  
✅ **Valid Post Logout Redirect URIs:** Contains `https://datagate.snap4idtcity.com/*`  
✅ **Web Origins:** Contains `https://datagate.snap4idtcity.com`  

---

## 🆕 Creating a New Client (If Needed)

If the CKAN client doesn't exist in Keycloak, create it:

### Step 1: Create New Client

1. In Keycloak Admin Console → **`Clients`** → Click **`Create client`**
2. Fill in:
   - **Client type:** `OpenID Connect`
   - **Client ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
   - Click **`Next`**

### Step 2: Configure Capabilities

1. Enable **`SAML 2.0`** capability
2. Click **`Next`**

### Step 3: Configure Client Settings

Fill in the same settings as described in **Step 3** above:
- **Valid Redirect URIs:** `https://datagate.snap4idtcity.com/saml2/acs`
- **Valid Post Logout Redirect URIs:** `https://datagate.snap4idtcity.com/*`
- **Web Origins:** `https://datagate.snap4idtcity.com`

### Step 4: Configure SAML2 Details

1. Go to **`SAML2`** tab
2. Set:
   - **Assertion Consumer Service POST Binding URL:** `https://datagate.snap4idtcity.com/saml2/acs`
   - **Service Provider Entity ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
   - **Name ID Format:** `persistent` (or `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent`)

### Step 5: Save

Click **`Save`** to create the client.

---

## 🔍 Verify SAML2 Metadata

After updating, verify the SAML2 metadata is accessible:

```bash
# Test CKAN metadata endpoint
curl -k https://datagate.snap4idtcity.com/saml2/metadata

# Should return XML with entityID="https://datagate.snap4idtcity.com/saml2/metadata"
```

The metadata should show:
- **Entity ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
- **ACS URL:** `https://datagate.snap4idtcity.com/saml2/acs`

---

## 🧪 Testing the Login Flow

1. **Open CKAN:** `https://datagate.snap4idtcity.com`
2. **Click "Login"**
3. **Expected:** Redirects to Keycloak login page
4. **After login:** Should redirect back to `https://datagate.snap4idtcity.com` (NOT localhost:8443)
5. **Verify:** You should be logged in and see your username

---

## ⚠️ Common Issues & Troubleshooting

### Issue 1: "Invalid Redirect URI" Error

**Symptom:** After login, Keycloak shows "Invalid Redirect URI" error

**Solution:**
- Double-check **Valid Redirect URIs** in Keycloak includes: `https://datagate.snap4idtcity.com/saml2/acs`
- Make sure there are no trailing slashes or typos
- Clear browser cache and cookies

### Issue 2: Redirects to localhost:8443

**Symptom:** After login, browser redirects to `localhost:8443` instead of `datagate.snap4idtcity.com`

**Solution:**
- Verify CKAN `site_url` is set correctly (see CKAN configuration)
- Check Nginx configuration has correct `server_name`
- Verify Keycloak **Valid Redirect URIs** doesn't include old localhost URLs (or remove them)

### Issue 3: "Entity ID Mismatch" Error

**Symptom:** SAML2 authentication fails with entity ID mismatch

**Solution:**
- Verify **Client ID** in Keycloak matches: `https://datagate.snap4idtcity.com/saml2/metadata`
- Verify CKAN `ckanext.saml2auth.entity_id` is set to: `https://datagate.snap4idtcity.com/saml2/metadata`
- Check SAML2 metadata endpoint: `https://datagate.snap4idtcity.com/saml2/metadata`

### Issue 4: CORS Errors

**Symptom:** Browser console shows CORS errors

**Solution:**
- Verify **Web Origins** in Keycloak includes: `https://datagate.snap4idtcity.com`
- Check Nginx `Access-Control-Allow-Origin` headers (if configured)

---

## 📝 Quick Reference: Keycloak Settings Checklist

Before saving, verify these settings:

- [ ] **Client ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
- [ ] **Valid Redirect URIs:** `https://datagate.snap4idtcity.com/saml2/acs`
- [ ] **Valid Post Logout Redirect URIs:** `https://datagate.snap4idtcity.com/*`
- [ ] **Web Origins:** `https://datagate.snap4idtcity.com`
- [ ] **Assertion Consumer Service POST Binding URL:** `https://datagate.snap4idtcity.com/saml2/acs`
- [ ] **Service Provider Entity ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
- [ ] **Name ID Format:** `persistent` or `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent`

---

## 🔄 Summary of Changes

### What Changed:
- **Old Domain:** `https://localhost:8443`
- **New Domain:** `https://datagate.snap4idtcity.com`

### What Needs Updating in Keycloak:
1. Client ID / Entity ID
2. Valid Redirect URIs
3. Valid Post Logout Redirect URIs
4. Web Origins
5. SAML2 ACS URL
6. SAML2 Service Provider Entity ID

### What Changed in CKAN (Already Done):
- ✅ `CKAN__SITE__URL` → `https://datagate.snap4idtcity.com`
- ✅ `CKANEXT__SAML2AUTH__ENTITY_ID` → `https://datagate.snap4idtcity.com/saml2/metadata`
- ✅ Nginx `server_name` → `datagate.snap4idtcity.com`
- ✅ Nginx proxy headers updated

---

## 📞 Support

If you encounter issues:
1. Check Keycloak logs: **Realm → Events** tab
2. Check CKAN logs: `docker compose logs ckan`
3. Check browser console for JavaScript errors
4. Verify all URLs are HTTPS (not HTTP)
5. Ensure SSL certificates are valid for `datagate.snap4idtcity.com`

---

**Last Updated:** November 2025  
**Status:** ✅ Ready for Production

