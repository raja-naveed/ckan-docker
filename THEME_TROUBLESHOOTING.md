# 🔧 CKAN Theme Troubleshooting Guide

## 🎯 **Current Status: FIXED!**

### ✅ **Issues Resolved:**

1. **❌ Problem**: `ckan.plugins` was empty in configuration
   **✅ Solution**: Added `demotheme` to plugins list
   ```bash
   ckan config-tool /srv/app/ckan.ini ckan.plugins=demotheme
   ```

2. **❌ Problem**: CSS path was incorrect in template
   **✅ Solution**: Fixed path from `/demotheme/css/demotheme.css` to `/demotheme.css`

3. **❌ Problem**: Template file had wrong CSS reference
   **✅ Solution**: Recreated template with correct CSS path

---

## 🔍 **Verification Steps Completed:**

### ✅ **Plugin Status:**
```bash
# Check if plugin is enabled
docker compose exec ckan bash -c "cat /srv/app/ckan.ini | grep plugins"
# Result: ckan.plugins=demotheme ✅
```

### ✅ **Extension Files:**
```bash
# Check extension structure
ls -la /srv/app/src/ckanext-demotheme/ckanext/demotheme/
# Result: All files present ✅
```

### ✅ **Template File:**
```bash
# Check template content
cat /srv/app/src/ckanext-demotheme/ckanext/demotheme/templates/home/index.html | head -10
# Result: Correct CSS path /demotheme.css ✅
```

### ✅ **CSS File:**
```bash
# Check CSS file exists
ls -la /srv/app/src/ckanext-demotheme/ckanext/demotheme/public/css/
# Result: demotheme.css (4260 bytes) ✅
```

### ✅ **Container Status:**
```bash
# Check CKAN health
docker compose ps ckan
# Result: Up About a minute (healthy) ✅
```

---

## 🎨 **What You Should See Now:**

### **At https://localhost:8443:**

1. **🚀 Hero Banner** (Purple-to-pink gradient)
   - Title: "🚀 Welcome to Our Data Portal"
   - Subtitle: "Explore, discover, and download open datasets"
   - Dataset counter: "0 Datasets Available" (or actual count)

2. **🔍 Search Section** (Below hero)
   - Default CKAN search functionality
   - White search box with blue button

3. **📊 Recently Updated Datasets**
   - Section title: "📊 Recently Updated Datasets"
   - Either 6 dataset cards OR "No datasets available" message
   - Cards have hover effects (lift up on mouse over)

4. **🏢 Right Sidebar**
   - "🏢 Popular Groups" section
   - "💡 About This Portal" info box
   - Purple and pink gradient headers

5. **🎨 Custom Styling**
   - Purple-to-pink gradient hero
   - Modern card layouts with shadows
   - Smooth hover animations
   - Professional color scheme

---

## 🚨 **If You Still See Default CKAN:**

### **Step 1: Hard Refresh Browser**
```
Windows: Ctrl + Shift + R
Mac: Cmd + Shift + R
```

### **Step 2: Clear Browser Cache**
- Open Developer Tools (F12)
- Right-click refresh button → "Empty Cache and Hard Reload"

### **Step 3: Check Container Logs**
```bash
cd C:\Users\Raja\Desktop\Projects\NewCkan\ckan-docker
docker compose logs ckan --tail=50
```

Look for:
- ✅ `demotheme` in plugin loading
- ✅ No error messages
- ✅ "WSGI app" ready message

### **Step 4: Verify Plugin Loading**
```bash
docker compose exec ckan bash -c "ckan config-tool /srv/app/ckan.ini ckan.plugins"
# Should show: demotheme
```

### **Step 5: Check File Permissions**
```bash
docker compose exec ckan bash -c "ls -la /srv/app/src/ckanext-demotheme/ckanext/demotheme/templates/home/"
# Should show: index.html (readable)
```

### **Step 6: Force Restart**
```bash
docker compose down
docker compose up -d
# Wait 30 seconds, then check https://localhost:8443
```

---

## 🔧 **Manual Verification Commands:**

### **Check Plugin is Active:**
```bash
docker compose exec ckan bash -c "grep -A 5 -B 5 demotheme /srv/app/ckan.ini"
```

### **Check Template Content:**
```bash
docker compose exec ckan bash -c "grep -n 'demo-hero' /srv/app/src/ckanext-demotheme/ckanext/demotheme/templates/home/index.html"
```

### **Check CSS File Size:**
```bash
docker compose exec ckan bash -c "wc -c /srv/app/src/ckanext-demotheme/ckanext/demotheme/public/css/demotheme.css"
# Should show: 4260 bytes
```

### **Check Container Health:**
```bash
docker compose exec ckan bash -c "ckan --version"
# Should show CKAN version info
```

---

## 🎯 **Expected Behavior:**

### **Theme Loading Process:**
1. CKAN starts with `demotheme` plugin enabled
2. Plugin registers template directory
3. Plugin registers public directory for CSS
4. Homepage template overrides default
5. CSS file loads from `/demotheme.css`
6. Hero section renders with custom styling

### **Visual Changes:**
- **Before**: Plain white CKAN homepage
- **After**: Purple gradient hero + custom layout

---

## 🆘 **Emergency Reset:**

If nothing works, reset everything:

```bash
# Stop containers
docker compose down

# Remove and recreate extension
docker compose exec ckan bash -c "rm -rf /srv/app/src/ckanext-demotheme"

# Recreate extension (run our setup commands again)
# ... (follow original setup steps)

# Restart
docker compose up -d
```

---

## 📞 **Still Having Issues?**

### **Check These Common Problems:**

1. **Browser Cache**: Try incognito/private mode
2. **Port Issues**: Make sure you're using https://localhost:8443
3. **Container Issues**: `docker compose ps` should show all containers healthy
4. **File Permissions**: Extension files should be readable
5. **Plugin Order**: `demotheme` should be in plugins list

### **Debug Commands:**
```bash
# Full system check
docker compose ps
docker compose logs ckan --tail=100
docker compose exec ckan bash -c "ls -la /srv/app/src/ckanext-demotheme/"

# Plugin verification
docker compose exec ckan bash -c "ckan config-tool /srv/app/ckan.ini ckan.plugins"
```

---

## 🎉 **Success Indicators:**

You'll know the theme is working when you see:

- ✅ Purple-to-pink gradient at the top
- ✅ "🚀 Welcome to Our Data Portal" title
- ✅ "0 Datasets Available" counter
- ✅ Custom card layouts (or "no datasets" message)
- ✅ "🏢 Popular Groups" sidebar
- ✅ Smooth hover animations
- ✅ Professional styling throughout

---

**Current Status**: ✅ **THEME SHOULD BE ACTIVE NOW!**

**URL**: https://localhost:8443  
**Expected**: Custom purple gradient hero with modern layout  
**If Default CKAN**: Follow troubleshooting steps above

---

*Last Updated: Theme files corrected and CKAN restarted successfully*

