# 🔧 Fix: Invalid Redirect URI in Keycloak

## 🎯 Problem

When logging in through Keycloak, you get an error: **"Invalid redirect uri"**

This happens because the redirect URI that CKAN sends to Keycloak doesn't match what's configured in Keycloak's **Valid Redirect URIs**.

---

## ✅ Solution: Update Keycloak Valid Redirect URIs

### Step 1: Access Keycloak Admin Console

1. Go to: `https://auth.idtcities.com/admin`
2. Log in with admin credentials
3. Select the **`IdtCities`** realm

### Step 2: Find Your CKAN Client

1. Click **`Clients`** in the left sidebar
2. Find and click on your **CKAN client** (usually named `ckan` or similar)

### Step 3: Update Valid Redirect URIs

1. Click on the **`Settings`** tab
2. Find the **`Valid Redirect URIs`** field
3. **Add these exact URIs** (one per line or comma-separated):

```
https://datagate.snap4idtcity.com/saml2/acs
https://datagate.snap4idtcity.com/saml2/acs*
https://datagate.snap4idtcity.com/*
```

**Important Notes:**
- The **exact URI** that CKAN uses is: `https://datagate.snap4idtcity.com/saml2/acs`
- You can add wildcards like `https://datagate.snap4idtcity.com/*` to allow all paths
- Make sure there are **no trailing slashes** unless intentional

### Step 4: Also Check Root URL

1. In the same **Settings** tab, find **`Root URL`** field
2. Set it to: `https://datagate.snap4idtcity.com`

### Step 5: Save Changes

1. Click **`Save`** at the bottom
2. Wait for confirmation: "Client updated successfully"

---

## 🔍 Verify the Redirect URI CKAN is Using

You can verify what redirect URI CKAN is sending by checking the SAML2 metadata:

```bash
curl -k "https://datagate.snap4idtcity.com/saml2/metadata" | grep AssertionConsumerService
```

This should show:
```xml
<AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://datagate.snap4idtcity.com/saml2/acs"/>
```

**The `Location` value is the redirect URI that must be in Keycloak's Valid Redirect URIs.**

---

## 📋 Complete Keycloak Client Settings Checklist

Make sure ALL these settings are correct:

- [ ] **Client ID:** `https://datagate.snap4idtcity.com/saml2/metadata`
- [ ] **Valid Redirect URIs:** Includes `https://datagate.snap4idtcity.com/saml2/acs`
- [ ] **Valid Post Logout Redirect URIs:** Includes `https://datagate.snap4idtcity.com/*`
- [ ] **Web Origins:** Includes `https://datagate.snap4idtcity.com`
- [ ] **Root URL:** `https://datagate.snap4idtcity.com`

---

## 🧪 Test After Fix

1. **Clear browser cache and cookies**
2. Go to: `https://datagate.snap4idtcity.com`
3. Click **"Login"**
4. Should redirect to Keycloak **without** "Invalid redirect uri" error
5. After login, should redirect back to CKAN successfully

---

## ⚠️ Common Mistakes

### ❌ Wrong:
- `https://datagate.snap4idtcity.com/saml2/acs/` (trailing slash)
- `http://datagate.snap4idtcity.com/saml2/acs` (HTTP instead of HTTPS)
- `https://localhost:8443/saml2/acs` (old domain)

### ✅ Correct:
- `https://datagate.snap4idtcity.com/saml2/acs` (exact match)
- `https://datagate.snap4idtcity.com/*` (wildcard for all paths)

---

## 🔄 Alternative: Use Wildcard (Recommended)

If you want to be more flexible, you can use wildcards:

**Valid Redirect URIs:**
```
https://datagate.snap4idtcity.com/*
```

This will accept any redirect URI starting with `https://datagate.snap4idtcity.com/`

**Note:** Some Keycloak versions require exact matches, so it's safer to include both the exact URI and the wildcard.

---

## 📞 Still Having Issues?

If you still get "Invalid redirect uri" after updating:

1. **Double-check for typos** in the URL
2. **Verify HTTPS** (not HTTP)
3. **Check for trailing slashes** - remove them if present
4. **Clear browser cache** completely
5. **Check Keycloak logs:** Realm → Events tab
6. **Verify CKAN metadata:** `curl -k "https://datagate.snap4idtcity.com/saml2/metadata"`

---

**Last Updated:** November 2025

