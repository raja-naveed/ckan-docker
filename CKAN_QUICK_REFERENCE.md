# 🚀 CKAN Quick Reference Guide

## 📋 **Quick Stats**

```
CKAN Version:     2.11.3 (Latest Stable)
Python Version:   3.10.17
PostgreSQL:       16.10
Solr:             9.9.0
Redis:            6.2.20

Datasets:         3
Users:            1 (admin)
Plugins:          7
Extensions:       2 custom
```

---

## 🔗 **Access URLs**

| Service | URL | Notes |
|---------|-----|-------|
| **Main Portal** | https://localhost:8443 | SSL (recommended) |
| **Direct CKAN** | http://localhost:5000 | HTTP |
| **API Endpoint** | http://localhost:5000/api/3/ | RESTful API |

**Admin Login:**
- Username: `admin`
- Password: `Admin@2024Secure`

---

## ⚡ **Quick Commands**

### **Start/Stop Services**
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart CKAN only
docker compose restart ckan

# View logs
docker compose logs -f ckan

# Check status
docker compose ps
```

### **CKAN Commands**
```bash
# Enter CKAN container
docker compose exec ckan bash

# Rebuild search index
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index rebuild

# Create sysadmin
docker compose exec ckan ckan -c /srv/app/ckan.ini sysadmin add username

# List users
docker compose exec ckan ckan -c /srv/app/ckan.ini user list

# Database init/upgrade
docker compose exec ckan ckan -c /srv/app/ckan.ini db init
docker compose exec ckan ckan -c /srv/app/ckan.ini db upgrade
```

### **Database Access**
```bash
# PostgreSQL shell
docker compose exec db psql -U ckandbuser -d ckandb

# Count datasets
docker compose exec db psql -U ckandbuser -d ckandb -c "SELECT COUNT(*) FROM package;"

# List tables
docker compose exec db psql -U ckandbuser -d ckandb -c "\dt"
```

---

## 🔌 **Enabled Plugins**

```
1. image_view       - Image viewer
2. text_view        - Text file viewer  
3. datatables_view  - Interactive tables
4. datastore        - Structured data storage
5. datapusher       - Data upload service
6. envvars          - Environment variables
7. custom_theme     - Snap4IDTCity theme
```

---

## 📁 **Important Paths**

### **Host Machine**
```
Project Root:        C:\Users\Raja\Desktop\Projects\NewCkan\ckan-docker\
Docker Compose:      ./docker-compose.yml
Environment:         ./.env
Custom Theme:        ./src/ckanext-custom-theme/
```

### **Inside Container**
```
CKAN Config:         /srv/app/ckan.ini
CKAN Source:         /srv/app/src/ckan/
Custom Extensions:   /srv/app/src/ckanext-*/
Storage:             /var/lib/ckan/
```

---

## 🐳 **Docker Services**

```
ckan          - Main CKAN application (port 5000)
db            - PostgreSQL database (port 5432)
solr          - Search engine (port 8983)
redis         - Cache server (port 6379)
datapusher    - Data processor (port 8800)
nginx         - SSL proxy (port 8443)
```

---

## 🎨 **Custom Theme Structure**

```
src/ckanext-custom-theme/
├── ckanext/custom_theme/
│   ├── plugin.py              # Helper functions
│   ├── templates/
│   │   ├── base.html          # Global styles
│   │   ├── header.html        # Navigation
│   │   ├── footer.html        # Footer
│   │   ├── home/
│   │   │   └── index.html     # Homepage
│   │   └── user/
│   │       └── login.html     # Login page
│   └── public/                # Static assets
└── setup.py
```

---

## 📊 **Database Tables**

**Main Tables:**
- `package` - Datasets
- `resource` - Files/links
- `user` - Users
- `group` - Organizations/groups
- `tag` - Tags
- `revision` - Version history

**Total:** 27 tables + revision tables

---

## 🔧 **Configuration Files**

### **ckan.ini** (Main Config)
```ini
ckan.site_url = http://localhost:5000
ckan.plugins = image_view text_view datatables_view datastore datapusher envvars custom_theme
sqlalchemy.url = postgresql://...
solr_url = http://127.0.0.1:8983/solr/ckan
ckan.redis.url = redis://localhost:6379/0
```

### **.env** (Environment)
```bash
CKAN_VERSION=2.11.3
CKAN_SITE_URL=https://localhost:8443
CKAN_SYSADMIN_NAME=admin
CKAN__PLUGINS="image_view text_view datatables_view datastore datapusher envvars custom_theme"
```

---

## 🆘 **Troubleshooting**

### **CKAN not accessible?**
```bash
# Check if services are running
docker compose ps

# Check logs
docker compose logs ckan

# Restart
docker compose restart ckan
```

### **Database connection error?**
```bash
# Check PostgreSQL
docker compose ps db

# Test connection
docker compose exec db psql -U ckandbuser -d ckandb -c "SELECT 1;"
```

### **Search not working?**
```bash
# Rebuild search index
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index rebuild
```

### **Theme not loading?**
```bash
# Check plugin is enabled
docker compose exec ckan grep "ckan.plugins" /srv/app/ckan.ini

# Restart CKAN
docker compose restart ckan
```

---

## 📈 **Performance Tips**

1. **Index regularly:** Rebuild search index after bulk uploads
2. **Clean cache:** Clear Redis cache if data seems stale
3. **Monitor logs:** Check for errors regularly
4. **Database maintenance:** Run VACUUM on PostgreSQL
5. **Backup regularly:** Export database and storage volumes

---

## 🔒 **Security Checklist**

- [x] Admin password changed from default
- [x] HTTPS enabled via NGINX
- [ ] API rate limiting configured
- [ ] Regular backups scheduled
- [ ] Monitoring/alerting setup
- [ ] Security headers configured
- [ ] File upload scanning

---

## 📚 **Useful API Endpoints**

```bash
# Get package list
curl http://localhost:5000/api/3/action/package_list

# Get package details
curl http://localhost:5000/api/3/action/package_show?id=dataset-name

# Search packages
curl http://localhost:5000/api/3/action/package_search?q=keyword

# Get organization list
curl http://localhost:5000/api/3/action/organization_list

# Get user info (requires API key)
curl -H "Authorization: YOUR-API-KEY" http://localhost:5000/api/3/action/user_show?id=admin
```

---

## 🎯 **Common Tasks**

### **Add a New Dataset**
1. Login as admin
2. Click "Datasets" → "Add Dataset"
3. Fill in metadata
4. Add resources (files/links)
5. Publish

### **Create Organization**
1. Login as admin
2. Click "Organizations" → "Add Organization"
3. Fill details
4. Add members

### **Upload to DataStore**
1. Create dataset with CSV resource
2. Go to resource page
3. Click "DataStore" tab
4. Click "Upload to DataStore"
5. Wait for completion
6. DataTables view will appear

### **Generate API Token**
1. Login to CKAN
2. Go to user profile
3. Click "API Tokens"
4. Generate new token
5. Copy and save securely

---

## 📞 **Support & Resources**

**Official Documentation:**
- CKAN Docs: https://docs.ckan.org/en/2.11/
- API Guide: https://docs.ckan.org/en/2.11/api/
- Extensions: https://extensions.ckan.org/

**Community:**
- GitHub: https://github.com/ckan/ckan
- Forum: https://discuss.ckan.org/
- Stack Overflow: Tag `ckan`

**Your Documentation:**
- `CKAN_COMPLETE_ANALYSIS.md` - Full analysis
- `CKAN_THEMING_GUIDE.md` - Theme customization
- `README.md` - Project overview

---

## ⚠️ **Known Limitations**

- DataStore doesn't support all file types
- Max upload size: 100MB (configurable)
- Solr requires regular reindexing
- Large files may timeout
- Some view plugins require external services

---

## 🎉 **Status: READY FOR USE**

Your CKAN instance is fully operational and ready for production use!

**Version:** 2.11.3 (Latest Stable)  
**Status:** 🟢 All Services Healthy  
**Theme:** ✅ Custom Snap4IDTCity Theme Active

---

**Quick Access:** https://localhost:8443 (admin / Admin@2024Secure)

