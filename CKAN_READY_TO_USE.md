# 🎉 Your CKAN Data Portal is Ready!

## ✅ All Systems Running

```
🟢 CKAN 2.11        HEALTHY
🟢 PostgreSQL       HEALTHY
🟢 Solr Search      HEALTHY
🟢 Redis Cache      HEALTHY
🟢 Datapusher       HEALTHY
🟢 Nginx (HTTPS)    RUNNING
```

**Access URL**: **https://localhost:8443**

---

## 🔐 Login Credentials

### Admin Account (Already Created)
- **Username**: `admin`
- **Email**: `admin@idtcities.com`
- **Password**: `admin123`

**⚠️ Change this password after first login!**

---

## 🚀 Quick Start Guide

### 1. Access CKAN
Open your browser and go to: **https://localhost:8443**

### 2. Login as Admin
- Click **"Log in"** in the top-right
- Username: `admin`
- Password: `admin123`

### 3. Change Your Password
- Click your name (top-right) → **"Manage"**
- Go to **"Settings"** tab
- Set a new secure password

### 4. Create Your First Organization
Organizations group related datasets together.

- Click **"Organizations"** → **"Add Organization"**
- Fill in:
  - **Name**: Your organization name
  - **URL**: Auto-generated from name
  - **Description**: Brief description
  - **Image**: Optional logo
- Click **"Create Organization"**

### 5. Create Your First Dataset
- Click **"Datasets"** → **"Add Dataset"**
- Fill in the metadata:
  - **Title**: Dataset name
  - **Description**: What the data is about
  - **Tags**: Keywords for searching
  - **License**: Data license
  - **Organization**: Select the one you created
- Click **"Next: Add Data"**

### 6. Upload Data
Supported formats:
- **CSV** - Comma-separated values
- **Excel** - XLS, XLSX
- **JSON** - Structured data
- **GeoJSON** - Geographic data (map preview!)
- **PDF** - Documents
- **Images** - PNG, JPG, GIF
- **Text** - TXT, MD
- **And more!**

**Upload methods:**
- **Upload file** - From your computer
- **Link to file** - From a URL
- **API** - Link to an API endpoint

---

## 👥 User Management

### Create Additional Users

**Method 1: Via Command Line**
```bash
# Create regular user
docker-compose exec ckan ckan user add username email=user@example.com name="Full Name"

# Create admin user
docker-compose exec ckan ckan sysadmin add username email=admin@example.com name="Admin Name"
```

**Method 2: Enable User Registration**
Users can self-register on the website:
1. Login as admin
2. Go to **"Admin"** → **"Config"**
3. Enable **"Allow users to register"**
4. Save

**Method 3: Via Web Interface (as admin)**
1. Go to **"Admin"** → **"Users"**
2. Click **"Add User"**
3. Fill in details
4. Choose permissions

### Promote User to Admin
```bash
docker-compose exec ckan ckan sysadmin add username
```

### Remove Admin Rights
```bash
docker-compose exec ckan ckan sysadmin remove username
```

---

## 📊 Available Data Viewers

Your CKAN includes these data preview tools:

### 1. **DataTables View** (CSV, Excel)
- Interactive tables
- Search, sort, filter
- Column reordering
- Export options

### 2. **PDF Viewer**
- In-browser PDF viewing
- Zoom, navigation
- Download option

### 3. **Image Viewer**
- Display images inline
- Supports: PNG, JPG, GIF, BMP

### 4. **GeoJSON/Map Viewer**
- Interactive maps
- GeoJSON visualization
- OpenStreetMap base layer
- Zoom, pan, click features

### 5. **Text Preview**
- Plain text files
- Markdown rendering
- Code highlighting

### 6. **Video/Audio Players**
- Embedded media playback
- Supports: MP4, WebM, MP3, OGG

---

## 🔧 Configuration

### Site Settings
1. Login as admin
2. Go to **"Admin"** → **"Config"**
3. Customize:
   - Site title
   - Site logo
   - About text
   - Social media links
   - Homepage layout

### Theme Customization
Your CKAN includes a custom theme. To modify:
- Edit files in: `src/ckanext-custom-theme/`
- Rebuild: `docker-compose restart ckan`

---

## 📦 Data Upload & Processing

### XLoader (Automatic Data Processing)
When you upload CSV/Excel files:
1. File is uploaded to CKAN
2. **XLoader** automatically:
   - Parses the data
   - Imports to PostgreSQL DataStore
   - Makes it available via API
   - Enables DataTables preview

### Check XLoader Status
```bash
docker-compose logs ckan | grep -i xloader
```

### DataStore API
Once data is loaded, access it via API:
```
https://localhost:8443/api/3/action/datastore_search?resource_id={RESOURCE_ID}
```

---

## 🔍 Search Configuration

### Solr Search Engine
Your CKAN uses Solr for powerful search capabilities:
- Full-text search across datasets
- Faceted search (filter by tags, orgs, etc.)
- Automatic indexing

### Rebuild Search Index (if needed)
```bash
docker-compose exec ckan ckan search-index rebuild
```

---

## 🛠️ Useful Commands

### Check CKAN Status
```bash
docker-compose ps
```

### View CKAN Logs
```bash
docker-compose logs ckan -f
```

### Restart CKAN
```bash
docker-compose restart ckan
```

### Access CKAN Shell
```bash
docker-compose exec ckan bash
```

### Backup Database
```bash
docker-compose exec db pg_dump -U ckandbuser ckandb > backup.sql
```

### List All Users
```bash
docker-compose exec ckan ckan user list
```

---

## 📱 API Access

### Get API Token
1. Login to CKAN
2. Click your name → **"API Tokens"**
3. Create a new token
4. Copy and save it securely

### Example API Calls

**List all datasets:**
```bash
curl https://localhost:8443/api/3/action/package_list
```

**Get dataset details:**
```bash
curl https://localhost:8443/api/3/action/package_show?id=dataset-name
```

**Search datasets:**
```bash
curl https://localhost:8443/api/3/action/package_search?q=keyword
```

**With authentication:**
```bash
curl -H "Authorization: YOUR_API_TOKEN" \
  https://localhost:8443/api/3/action/package_create \
  -d '{"name":"my-dataset", "title":"My Dataset"}'
```

---

## 🎨 Features Included

✅ **Data Viewers**
- CSV/Excel with DataTables
- PDF viewer
- Image viewer
- GeoJSON/Map viewer
- Text preview
- Video/Audio players

✅ **Data Processing**
- XLoader for automatic CSV import
- DataStore API
- Full-text search

✅ **User Management**
- Admin interface
- User roles & permissions
- API tokens

✅ **Organization Management**
- Create organizations
- Assign datasets to orgs
- Member management

✅ **Custom Theme**
- Modern, responsive design
- Customizable colors & layout

✅ **Security**
- HTTPS enabled
- CSRF protection
- API authentication

---

## 🔐 Security Best Practices

1. **Change default password** immediately
2. **Use strong passwords** for all users
3. **Enable HTTPS** in production (already enabled)
4. **Regular backups** of database
5. **Keep CKAN updated** (check for updates monthly)
6. **Limit admin users** to trusted personnel
7. **Use API tokens** instead of password for scripts

---

## 📚 Documentation & Resources

### Official CKAN Documentation
- User Guide: https://docs.ckan.org/en/2.11/user-guide.html
- API Guide: https://docs.ckan.org/en/2.11/api/index.html
- Extensions: https://extensions.ckan.org/

### Your Installation
- **CKAN Version**: 2.11
- **Python Version**: 3.10
- **Database**: PostgreSQL 14
- **Search**: Solr 9
- **Cache**: Redis 6

---

## 🆘 Troubleshooting

### CKAN won't start
```bash
docker-compose logs ckan
docker-compose restart ckan
```

### Can't login
- Verify credentials
- Check caps lock
- Reset password via CLI

### Data upload fails
- Check file size (default max: 50MB)
- Verify file format is supported
- Check XLoader logs

### Search not working
```bash
docker-compose exec ckan ckan search-index rebuild
```

### Reset admin password
```bash
docker-compose exec ckan ckan user setpass admin
```

---

## 📞 Support

### Container Status
```bash
docker-compose ps
```

### View Logs
```bash
# CKAN
docker-compose logs ckan

# Database
docker-compose logs db

# All services
docker-compose logs
```

### Restart Everything
```bash
docker-compose restart
```

### Complete Reset (⚠️ DELETES ALL DATA)
```bash
docker-compose down -v
docker-compose up -d
```

---

## 🎯 Next Steps

1. ✅ **Login** with admin/admin123
2. ✅ **Change password**
3. ✅ **Create organization**
4. ✅ **Upload first dataset**
5. ✅ **Create additional users**
6. ✅ **Customize site settings**
7. ✅ **Test data viewers**
8. ✅ **Try the API**

---

## 🎉 You're All Set!

Your CKAN data portal is **fully functional** and ready for production use!

**Access it now**: **https://localhost:8443**

**Login**: admin / admin123

Enjoy your data portal! 🚀

