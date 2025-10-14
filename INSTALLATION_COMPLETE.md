# 🎉 CKAN Installation Complete!

**Installation Date**: October 13, 2025  
**CKAN Version**: 2.10.5  
**Installation Type**: Docker Compose

---

## ✅ Installation Summary

CKAN has been successfully installed and configured with all required components:

### Running Services (6 containers)
- ✅ **CKAN** - Main application (healthy)
- ✅ **PostgreSQL** - Database (healthy)
- ✅ **Solr** - Search engine (healthy)
- ✅ **Redis** - Caching layer (healthy)
- ✅ **DataPusher** - CSV/Excel data processor (healthy)
- ✅ **NGINX** - Reverse proxy with SSL (running)

---

## 🔐 Admin Credentials

**Username**: `admin`  
**Password**: `Admin@2024Secure`  
**Email**: your_email@example.com

> ⚠️ **Security Note**: Please change this password after your first login!

---

## 🌐 Access URLs

### Main Interface (HTTPS - Recommended)
```
https://localhost:8443
```

### Alternative (HTTP via CKAN directly)
```
http://localhost:5000
```

### API Endpoint
```
https://localhost:8443/api/3/action/status_show
```

---

## 📦 Database Configuration

### Main Database
- **Host**: db
- **Port**: 5432
- **Database**: ckandb
- **User**: ckandbuser
- **Password**: MyCkanDbPass2024!

### Datastore Database
- **Database**: datastore
- **Read-only User**: datastore_ro
- **Password**: MyDatastorePass2024!

---

## 🗂️ Docker Volumes

Persistent data is stored in the following Docker volumes:

1. **ckan-docker_ckan_storage** - Uploaded files and resources
2. **ckan-docker_pg_data** - PostgreSQL database files
3. **ckan-docker_solr_data** - Search index data
4. **ckan-docker_site_packages** - Python packages
5. **ckan-docker_pip_cache** - Pip cache for faster builds

To back up your data, backup these volumes:
```bash
docker volume inspect ckan-docker_ckan_storage
docker volume inspect ckan-docker_pg_data
```

---

## 🚀 Quick Start Guide

### Start CKAN
```bash
cd C:\Users\Raja\Desktop\Projects\NewCkan\ckan-docker
docker compose up -d
```

### Stop CKAN
```bash
docker compose down
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f ckan
docker compose logs -f db
```

### Restart a Service
```bash
docker compose restart ckan
```

### Access CKAN Shell
```bash
docker compose exec ckan bash
```

### CKAN Commands
```bash
# List users
docker compose exec ckan ckan user list

# List sysadmins
docker compose exec ckan ckan sysadmin list

# Create new user
docker compose exec ckan ckan user add username email=user@example.com

# Make user sysadmin
docker compose exec ckan ckan sysadmin add username

# Delete user
docker compose exec ckan ckan user remove username
```

---

## 📊 Enabled Extensions

The following CKAN extensions are enabled:

- **image_view** - Image file previews
- **text_view** - Text file previews  
- **datatables_view** - Interactive table viewer
- **datastore** - Data API for querying datasets
- **datapusher** - Automatic CSV/Excel import
- **envvars** - Environment variable configuration

---

## 🔧 Configuration Files

### Environment Variables
Location: `ckan-docker/.env`

This file contains all sensitive configuration including passwords, API keys, and service URLs.

### CKAN Configuration
Location: Inside ckan container at `/srv/app/ckan.ini`

To edit:
```bash
docker compose exec ckan vi /srv/app/ckan.ini
# Then restart
docker compose restart ckan
```

---

## 🛠️ Common Tasks

### Add Sample Data
```bash
# Create an organization
docker compose exec ckan ckan organization create my-org title="My Organization"

# Create a dataset
docker compose exec ckan ckan dataset create my-dataset owner_org=my-org
```

### Rebuild Search Index
```bash
docker compose exec ckan ckan search-index rebuild
```

### Database Backup
```bash
# Backup PostgreSQL data
docker compose exec db pg_dump -U ckandbuser ckandb > backup.sql

# Restore
docker compose exec -T db psql -U ckandbuser ckandb < backup.sql
```

### Update CKAN
```bash
# Pull latest images
docker compose pull

# Rebuild and restart
docker compose up -d --build
```

---

## 🐛 Troubleshooting

### CKAN Won't Start
```bash
# Check logs
docker compose logs ckan

# If database connection issues, restart in order:
docker compose restart db
sleep 10
docker compose restart ckan
```

### Database Permission Errors
```bash
# Reset datastore permissions
docker compose exec ckan ckan datastore set-permissions | docker compose exec -T db psql -U ckandbuser
```

### Clear Cache
```bash
docker compose restart redis
docker compose restart ckan
```

### SSL Certificate Issues
The NGINX container generates a self-signed SSL certificate on startup. Your browser will show a warning - this is normal for local development. Click "Advanced" and proceed.

---

## 📚 Next Steps

1. **Login**: Visit https://localhost:8443 and login with admin credentials
2. **Create Organization**: Organizations group related datasets
3. **Upload Datasets**: Start adding your data
4. **Customize**: Edit the CKAN theme and configuration
5. **Add Extensions**: Install additional CKAN extensions for more features

### Recommended Extensions to Explore
- **ckanext-scheming** - Custom metadata schemas
- **ckanext-harvest** - Harvest datasets from other portals
- **ckanext-spatial** - Geospatial data support
- **ckanext-geoview** - Interactive maps for geospatial data
- **ckanext-pages** - Add static pages to your portal

---

## 📖 Documentation

- **CKAN Documentation**: https://docs.ckan.org/
- **CKAN API Guide**: https://docs.ckan.org/en/latest/api/
- **Docker CKAN**: https://github.com/ckan/ckan-docker
- **Extensions**: https://extensions.ckan.org/

---

## 🎯 Your CKAN is Ready!

Your CKAN installation is complete and ready to use! 

Access it now at: **https://localhost:8443**

Happy data publishing! 🚀

---

*Installation completed automatically on October 13, 2025*


