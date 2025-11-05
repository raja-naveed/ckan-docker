# 🔧 Complete CKAN SAML2 Implementation Guide

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Initial Setup & Prerequisites](#initial-setup--prerequisites)
3. [SAML2 SSO Integration](#saml2-sso-integration)
4. [Fixes Applied](#fixes-applied)
5. [Custom Branding](#custom-branding)
6. [File Upload Configuration](#file-upload-configuration)
7. [Dynamic Homepage Features](#dynamic-homepage-features)
8. [System Administrator Setup](#system-administrator-setup)
9. [Complete File Structure](#complete-file-structure)
10. [Verification & Testing](#verification--testing)
11. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

This document provides a complete, step-by-step guide to implementing a fully functional CKAN data portal with:
- ✅ SAML2 SSO authentication via Keycloak
- ✅ Custom branding with organization logo
- ✅ Dynamic homepage with real-time data
- ✅ File upload functionality
- ✅ System administrator configuration
- ✅ Production-ready deployment

**Target Environment:** Ubuntu Server with Docker and Docker Compose  
**CKAN Version:** 2.11  
**Access URL:** `https://localhost:8443`

---

## 🚀 Initial Setup & Prerequisites

### System Requirements

```bash
# Operating System
Ubuntu Server (or compatible Linux distribution)

# Required Software
- Docker 20.10+
- Docker Compose 2.0+
- Git (for cloning repository)
- Text editor (nano/vim/vs-code)

# Network Requirements
- Access to existing PostgreSQL database (in s4idtcities network)
- Access to existing Redis instance (in s4idtcities network)
- Access to Keycloak server at https://auth.idtcities.com
- SSL certificates for HTTPS (port 8443)
```

### Verify Prerequisites

```bash
# Check Docker installation
docker --version
docker compose version

# Check network connectivity
ping -c 3 keycloak_postgres
ping -c 3 redis
curl -k https://auth.idtcities.com
```

---

## 📁 Project Structure

```
ckan-docker/
├── docker-compose.yml          # Main orchestration file
├── Dockerfile.custom           # Custom CKAN build
├── .env                        # Environment variables
├── fix_session.py              # Session persistence fix
├── fix_acs_endpoint.py         # ACS endpoint fix
├── fix_acs_csrf.py             # CSRF exemption (not needed - see notes)
├── ckan/
│   ├── setup/
│   │   └── prerun.py.override  # SAML2 initialization
│   └── docker-entrypoint.d/
├── nginx/
│   └── setup/
│       └── default.conf        # Reverse proxy configuration
└── src/
    └── ckanext-custom-theme/   # Custom theme with all features
        └── ckanext/
            └── custom_theme/
                ├── plugin.py
                └── templates/
                    ├── header.html
                    ├── footer.html
                    ├── base.html
                    └── home/
                        └── index.html
```

---

## 🔐 SAML2 SSO Integration

### Step 1: Docker Compose Configuration

**File:** `docker-compose.yml`

```yaml
services:
  ckan:
    build:
      context: .
      dockerfile: Dockerfile.custom
      args:
        - TZ=${TZ}
    networks:
      - s4idtcities
    env_file:
      - .env
    environment:
      # Database connections
      - CKAN_SQLALCHEMY_URL=postgresql://ckan-user:ckan-pass@keycloak_postgres:5432/ckandb
      - CKAN_DATASTORE_WRITE_URL=postgresql://ckan-user:ckan-pass@keycloak_postgres:5432/datastore
      - CKAN_DATASTORE_READ_URL=postgresql://readonlyuser:readonlypass@keycloak_postgres:5432/datastore
      - CKAN_REDIS_URL=redis://redis:6379/0

      # Plugins (saml2auth is critical)
      - CKAN__PLUGINS=image_view text_view datatables_view pdf_view geo_view geojson_view shp_view wmts_view video_view audio_view webpage_view resource_proxy datastore xloader envvars custom_theme saml2auth

      # SAML2 Configuration
      - CKANEXT__SAML2AUTH__IDP_METADATA__LOCATION=remote
      - CKANEXT__SAML2AUTH__IDP_METADATA__REMOTE_URL=https://auth.idtcities.com/realms/IdtCities/protocol/saml/descriptor
      - CKANEXT__SAML2AUTH__ENTITY_ID=https://localhost:8443/saml2/metadata
      - CKANEXT__SAML2AUTH__ACS_ENDPOINT=/saml2/acs
      - CKANEXT__SAML2AUTH__ENABLE_CKAN_INTERNAL_LOGIN=false
      - CKANEXT__SAML2AUTH__USER_EMAIL=urn:oid:1.2.840.113549.1.9.1
      - CKANEXT__SAML2AUTH__USER_FIRSTNAME=urn:oid:2.5.4.42
      - CKANEXT__SAML2AUTH__USER_LASTNAME=urn:oid:2.5.4.4
      - CKANEXT__SAML2AUTH__USER_FULLNAME=name
      - CKANEXT__SAML2AUTH__WANT_RESPONSE_SIGNED=false
      - CKANEXT__SAML2AUTH__WANT_ASSERTIONS_SIGNED=false
      - CKANEXT__SAML2AUTH__ASSERTION_CONSUMER_SERVICE_BINDING=urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST
      - CKANEXT__SAML2AUTH__SP__NAME_ID_FORMAT=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent

    volumes:
      - ckan_storage:/var/lib/ckan
      - pip_cache:/root/.cache/pip
      - site_packages:/usr/lib/python3.10/site-packages

    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-qO", "/dev/null", "http://localhost:5000/api/action/status_show"]
      interval: 60s
      timeout: 10s
      retries: 3

  nginx:
    build:
      context: nginx/
    networks:
      - s4idtcities
    ports:
      - "8443:443"
    depends_on:
      - ckan
    restart: unless-stopped

networks:
  s4idtcities:
    external: true

volumes:
  ckan_storage:
  solr_data:
  pip_cache:
  site_packages:
```

**Key Points:**
- CKAN runs on internal port 5000 (not exposed to host)
- Nginx exposes port 8443 (HTTPS) to host
- All services use external network `s4idtcities`
- SAML2 plugin is in the plugins list

### Step 2: Build and Start Services

```bash
# Navigate to project directory
cd /home/frontend/Snap4IdtCities/CKANDOCKER/ckan-docker

# Build and start all services
docker compose up -d --build

# Wait for services to be healthy
docker compose ps

# Check logs
docker compose logs -f ckan
```

**Expected Output:**
```
NAME                 STATUS
ckan-docker-ckan-1   Up (healthy)
ckan-docker-nginx-1  Up
ckan-docker-solr-1    Up (healthy)
```

---

## 🔧 Fixes Applied

### Fix 1: Session Persistence Issue

**Problem:** Users logged in but sessions didn't persist across page navigations due to NameID serialization issue.

**Solution:** Apply `fix_session.py`

**File:** `fix_session.py`

```python
#!/usr/bin/env python3
import os

print("[1/3] Fixing NameID serialization in cache.py...")
cache_file = "/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py"
with open(cache_file, 'r') as f:
    content = f.read()

old_func = """def set_saml_session_info(session, saml_session_info):
    session['_saml_session_info'] = saml_session_info"""

new_func = """def set_saml_session_info(session, saml_session_info):
    session_info_copy = dict(saml_session_info)
    if 'name_id' in session_info_copy:
        session_info_copy['name_id'] = str(session_info_copy['name_id'])
    session['_saml_session_info'] = session_info_copy"""

if old_func in content:
    content = content.replace(old_func, new_func)
    with open(cache_file, 'w') as f:
        f.write(content)
    print("[OK] NameID serialization fixed")
else:
    print("[SKIP] Already fixed or not found")

print("[2/3] Disabling set_subject_id in views...")
saml_file = "/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py"
with open(saml_file, 'r') as f:
    lines = f.readlines()

for i in range(len(lines)):
    if 'set_subject_id(session, session_info[' in lines[i] and not lines[i].strip().startswith('#'):
        lines[i] = '        # ' + lines[i].lstrip()
        print(f"[OK] Disabled set_subject_id on line {i+1}")
        break

with open(saml_file, 'w') as f:
    f.writelines(lines)

print("[3/3] Clearing Python cache...")
os.system('rm -rf /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/__pycache__')
os.system('rm -rf /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/__pycache__')

print("[DONE] Session persistence fixes applied!")
```

**Apply the Fix:**

```bash
# Copy fix script to container
docker cp fix_session.py ckan-docker-ckan-1:/tmp/

# Run the fix as root
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py

# Restart CKAN
docker compose restart ckan

# Verify fix
docker exec ckan-docker-ckan-1 grep -c "session_info_copy" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py
# Should output: 1
```

### Fix 2: ACS Endpoint Path

**Problem:** ACS endpoint path needed to be hardcoded to `/saml2/acs`.

**Solution:** Apply `fix_acs_endpoint.py`

**File:** `fix_acs_endpoint.py`

```python
lines = open('/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py').readlines()
for i, line in enumerate(lines):
    if "acs_endpoint = config.get" in line:
        lines[i] = "acs_endpoint = '/saml2/acs'  # Hardcoded for correct CKAN integration\n"
        print(f'Fixed line {i+1}')
        break
open('/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py', 'w').writelines(lines)
```

**Apply the Fix:**

```bash
# Copy fix script to container
docker cp fix_acs_endpoint.py ckan-docker-ckan-1:/tmp/

# Run the fix as root
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_acs_endpoint.py

# Restart CKAN
docker compose restart ckan

# Verify fix
docker exec ckan-docker-ckan-1 grep "acs_endpoint = " /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py
# Should show: acs_endpoint = '/saml2/acs'  # Hardcoded for correct CKAN integration
```

### Fix 3: Template URL Issues

**Problem:** `url_for('user.saml2login')` caused BuildError in templates.

**Solution:** Use direct URL paths instead.

**File:** `src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html`

**Change:**
```html
<!-- Before -->
<a href="{{ h.url_for('user.saml2login') }}">Login</a>

<!-- After -->
<a href="/user/saml2login">Login</a>
```

**File:** `src/ckanext-custom-theme/ckanext/custom_theme/plugins/saml2_redirect.py`

**Change:**
```python
# Before
return redirect(url_for('user.saml2login'))

# After
return redirect('/user/saml2login')
```

**Apply Changes:**

```bash
# Copy updated templates to container
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html

docker cp src/ckanext-custom-theme/ckanext/custom_theme/plugins/saml2_redirect.py ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/plugins/saml2_redirect.py

# Set permissions
docker exec -u root ckan-docker-ckan-1 chown -R ckan:ckan-sys /srv/app/src/ckanext-custom-theme/

# Restart CKAN
docker compose restart ckan
```

---

## 🎨 Custom Branding

### Adding Logo to Header

**File:** `src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html`

**Location:** Around line 7-14

**Change:**
```html
<!-- Replace this: -->
<div class="government-emblem"></div>

<!-- With this: -->
<a href="{{ h.url_for('home.index') }}" class="logo-link">
  <img src="https://home.idtcities.com/assets/IdtCitiesLogoWhite.png" alt="IdtCities Logo" class="header-logo">
</a>
```

**Add CSS (around line 197):**
```css
/* Header Logo Styling */
.header-branding {
  display: flex;
  align-items: center;
  gap: 15px;
}

.logo-link {
  display: flex;
  align-items: center;
  text-decoration: none;
  transition: opacity 0.3s ease;
}

.logo-link:hover {
  opacity: 0.8;
}

.header-logo {
  height: 50px;
  width: auto;
  max-width: 200px;
  object-fit: contain;
  display: block;
}

/* Responsive */
@media (max-width: 768px) {
  .header-logo {
    height: 40px;
    max-width: 150px;
  }
}
```

### Adding Logo to Footer

**File:** `src/ckanext-custom-theme/ckanext/custom_theme/templates/footer.html`

**Location:** Around line 97

**Change:**
```html
<!-- Replace this: -->
<div class="government-emblem-footer"></div>

<!-- With this: -->
<a href="{{ h.url_for('home.index') }}" class="footer-logo-link">
  <img src="https://home.idtcities.com/assets/IdtCitiesLogoWhite.png" alt="IdtCities Logo" class="footer-logo-img">
</a>
```

**Add CSS (around line 89):**
```css
/* Footer Logo Styling */
.footer-logo-link {
  display: flex;
  align-items: center;
  text-decoration: none;
  transition: opacity 0.3s ease;
  margin-right: 15px;
}

.footer-logo-link:hover {
  opacity: 0.8;
}

.footer-logo-img {
  height: 60px;
  width: auto;
  max-width: 200px;
  object-fit: contain;
  display: block;
}

/* Responsive */
@media (max-width: 768px) {
  .footer-logo-img {
    height: 45px;
    max-width: 150px;
  }
}
```

**Apply Changes:**

```bash
# Copy updated files
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/footer.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/footer.html

# Set permissions
docker exec -u root ckan-docker-ckan-1 chown -R ckan:ckan-sys /srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/

# Restart CKAN
docker compose restart ckan
```

---

## 📤 File Upload Configuration

### Enable File Uploads

**Problem:** Only "Link" button visible, no "Upload" option for resources.

**Solution:** Enable uploads in CKAN configuration.

**Commands:**

```bash
# Enable file uploads
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "ckan.uploads_enabled = true"

# Verify storage path is set
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "ckan.storage_path = /var/lib/ckan/default"

# Create storage directory with proper permissions
docker exec -u root ckan-docker-ckan-1 mkdir -p /var/lib/ckan/default/storage/uploads
docker exec -u root ckan-docker-ckan-1 chown -R 503:502 /var/lib/ckan/default

# Verify configuration
docker exec ckan-docker-ckan-1 grep "uploads_enabled\|storage_path" /srv/app/ckan.ini
# Should show:
# ckan.uploads_enabled = true
# ckan.storage_path = /var/lib/ckan/default

# Restart CKAN
docker compose restart ckan
```

**Verification:**

```bash
# Check via Python
docker exec ckan-docker-ckan-1 python3 << 'EOF'
import sys
sys.path.insert(0, '/srv/app/src/ckan')
from ckan.config.environment import load_environment
from ckan import config
load_environment(config.update_config())
print("Uploads enabled:", config.get('ckan.uploads_enabled'))
print("Storage path:", config.get('ckan.storage_path'))
EOF
```

**Expected Output:**
```
Uploads enabled: True
Storage path: /var/lib/ckan/default
```

---

## 🏠 Dynamic Homepage Features

### Step 1: Update Plugin Helper Functions

**File:** `src/ckanext-custom-theme/ckanext/custom_theme/plugin.py`

**Add these methods to the `CustomThemePlugin` class:**

```python
def get_helpers(self):
    return {
        'custom_get_total_datasets': self._get_total_datasets,
        'custom_get_featured_datasets': self._get_featured_datasets,
        'custom_get_recent_datasets': self._get_recent_datasets,
        'custom_get_organization_count': self._get_organization_count,
        'custom_get_group_count': self._get_group_count,
        'custom_get_groups_with_counts': self._get_groups_with_counts,
        'custom_get_popular_datasets': self._get_popular_datasets,
        'custom_get_total_resources': self._get_total_resources,
        'get_current_year': self._get_current_year,
    }

def _get_groups_with_counts(self, limit=9):
    """Get groups with their dataset counts for homepage"""
    try:
        groups = toolkit.get_action('group_list')({}, {
            'all_fields': True,
            'sort': 'package_count desc',
            'limit': limit
        })
        
        result = []
        for group in groups:
            try:
                group_detail = toolkit.get_action('group_show')({}, {
                    'id': group['id'],
                    'include_datasets': False
                })
                result.append({
                    'id': group['id'],
                    'name': group['name'],
                    'title': group.get('title', group['name']),
                    'description': group.get('description', ''),
                    'package_count': group_detail.get('package_count', 0),
                    'image_url': group_detail.get('image_url', '')
                })
            except Exception:
                result.append({
                    'id': group['id'],
                    'name': group['name'],
                    'title': group.get('title', group['name']),
                    'description': group.get('description', ''),
                    'package_count': 0,
                    'image_url': ''
                })
        
        return result
    except Exception:
        return []

def _get_popular_datasets(self, limit=6):
    """Get popular datasets based on views/downloads"""
    try:
        result = toolkit.get_action('package_search')({}, {
            'rows': limit,
            'sort': 'views_recent desc, metadata_modified desc'
        })
        return result.get('results', [])
    except Exception:
        return self._get_recent_datasets(limit)

def _get_total_resources(self):
    """Get total number of resources"""
    try:
        result = toolkit.get_action('package_search')({}, {
            'include_private': False
        })
        total = 0
        for dataset in result.get('results', []):
            total += dataset.get('num_resources', 0)
        return total
    except Exception:
        return 0
```

### Step 2: Update Homepage Template

**File:** `src/ckanext-custom-theme/ckanext/custom_theme/templates/home/index.html`

**Replace the Categories Section (lines 39-90):**

```html
<!-- Categories Section - Dynamic -->
<div class="categories-section">
  <div class="container">
    <h2>Explore by Category</h2>
    <p>Browse datasets organized by topic</p>
    <div class="categories-grid">
      {% set groups = h.custom_get_groups_with_counts(9) %}
      {% if groups %}
        {% for group in groups %}
          <a href="{{ h.url_for('group.read', id=group.id) }}" class="category-card">
            {% if group.image_url %}
              <img src="{{ group.image_url }}" alt="{{ group.title }}" class="category-image">
            {% else %}
              <div class="category-icon icon-default"></div>
            {% endif %}
            <h3>{{ group.title }}</h3>
            <p>{{ group.package_count }} dataset{{ 's' if group.package_count != 1 else '' }}</p>
          </a>
        {% endfor %}
      {% else %}
        <a href="{{ h.url_for('group.index') }}" class="category-card">
          <div class="category-icon icon-default"></div>
          <h3>Create Categories</h3>
          <p>Start organizing your data</p>
        </a>
      {% endif %}
    </div>
    <div class="view-all-categories">
      <a href="{{ h.url_for('group.index') }}" class="btn btn-primary">View All Categories</a>
    </div>
  </div>
</div>

<!-- Featured Datasets Section -->
{% set featured_datasets = h.custom_get_featured_datasets(6) %}
{% if featured_datasets %}
<div class="featured-datasets-section">
  <div class="container">
    <h2>Featured Datasets</h2>
    <p>Discover our most popular and important datasets</p>
    <div class="datasets-grid">
      {% for dataset in featured_datasets %}
        <div class="dataset-card">
          <div class="dataset-header">
            <h3><a href="{{ h.url_for('dataset.read', id=dataset.name) }}">{{ dataset.title }}</a></h3>
            {% if dataset.organization %}
              <span class="dataset-org">{{ dataset.organization.title }}</span>
            {% endif %}
          </div>
          <p class="dataset-description">{{ dataset.notes | truncate(120) }}</p>
          <div class="dataset-footer">
            <span class="dataset-resources">{{ dataset.num_resources }} resource{{ 's' if dataset.num_resources != 1 else '' }}</span>
            <a href="{{ h.url_for('dataset.read', id=dataset.name) }}" class="dataset-link">View →</a>
          </div>
        </div>
      {% endfor %}
    </div>
    <div class="view-all-datasets">
      <a href="{{ h.url_for('dataset.search') }}" class="btn btn-outline">View All Datasets</a>
    </div>
  </div>
</div>
{% endif %}

<!-- Recent Datasets Section -->
{% set recent_datasets = h.custom_get_recent_datasets(6) %}
{% if recent_datasets %}
<div class="recent-datasets-section">
  <div class="container">
    <h2>Recently Updated</h2>
    <p>Latest datasets added to the portal</p>
    <div class="datasets-grid">
      {% for dataset in recent_datasets %}
        <div class="dataset-card">
          <div class="dataset-header">
            <h3><a href="{{ h.url_for('dataset.read', id=dataset.name) }}">{{ dataset.title }}</a></h3>
            <span class="dataset-date">{{ h.render_datetime(dataset.metadata_modified, date_format='%b %d, %Y') }}</span>
          </div>
          <p class="dataset-description">{{ dataset.notes | truncate(120) }}</p>
          <div class="dataset-footer">
            <span class="dataset-resources">{{ dataset.num_resources }} resource{{ 's' if dataset.num_resources != 1 else '' }}</span>
            <a href="{{ h.url_for('dataset.read', id=dataset.name) }}" class="dataset-link">View →</a>
          </div>
        </div>
      {% endfor %}
    </div>
  </div>
</div>
{% endif %}
```

**Update Statistics Section (line 101):**

```html
<!-- Change this: -->
<div class="stat-number">{{ h.custom_get_total_datasets() * 2 }}</div>

<!-- To this: -->
<div class="stat-number">{{ h.custom_get_total_resources() }}</div>
```

**Add CSS for New Sections (around line 839):**

```css
/* Category Image Styling */
.category-image {
  width: 60px;
  height: 60px;
  object-fit: cover;
  border-radius: 50%;
  margin: 0 auto 15px;
  border: 2px solid #e9ecef;
  transition: all 0.3s ease;
}

.category-card:hover .category-image {
  border-color: #1e3a5f;
  transform: scale(1.1);
}

/* Featured & Recent Datasets Sections */
.featured-datasets-section,
.recent-datasets-section {
  padding: 80px 0;
  background: white;
}

.featured-datasets-section {
  background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
}

.featured-datasets-section h2,
.recent-datasets-section h2 {
  font-size: 36px;
  font-weight: 700;
  color: #1e3a5f;
  margin-bottom: 15px;
  text-align: center;
}

.featured-datasets-section p,
.recent-datasets-section p {
  font-size: 18px;
  color: #666;
  margin-bottom: 50px;
  text-align: center;
}

.datasets-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 30px;
  margin-bottom: 40px;
}

.dataset-card {
  background: white;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  border: 1px solid #e9ecef;
  display: flex;
  flex-direction: column;
}

.dataset-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
  border-color: #1e3a5f;
}

.dataset-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
  gap: 15px;
}

.dataset-header h3 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #1e3a5f;
  flex: 1;
}

.dataset-header h3 a {
  color: #1e3a5f;
  text-decoration: none;
  transition: color 0.3s ease;
}

.dataset-header h3 a:hover {
  color: #2c5aa0;
  text-decoration: underline;
}

.dataset-org {
  font-size: 12px;
  color: #666;
  background: #f8f9fa;
  padding: 4px 8px;
  border-radius: 4px;
  white-space: nowrap;
}

.dataset-date {
  font-size: 12px;
  color: #999;
  white-space: nowrap;
}

.dataset-description {
  color: #666;
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: 20px;
  flex: 1;
}

.dataset-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 15px;
  border-top: 1px solid #e9ecef;
}

.dataset-resources {
  font-size: 14px;
  color: #666;
  font-weight: 500;
}

.dataset-link {
  color: #2c5aa0;
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
  transition: all 0.3s ease;
}

.dataset-link:hover {
  color: #1e3a5f;
  text-decoration: none;
  transform: translateX(5px);
}

.view-all-datasets {
  text-align: center;
  margin-top: 40px;
}

.btn-outline {
  display: inline-block;
  background: transparent;
  color: #1e3a5f;
  padding: 15px 40px;
  border-radius: 50px;
  text-decoration: none;
  font-weight: 700;
  font-size: 16px;
  border: 2px solid #1e3a5f;
  transition: all 0.3s ease;
}

.btn-outline:hover {
  background: #1e3a5f;
  color: white;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(30, 58, 95, 0.3);
  text-decoration: none;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .datasets-grid {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .featured-datasets-section h2,
  .recent-datasets-section h2 {
    font-size: 28px;
  }

  .dataset-card {
    padding: 20px;
  }
}
```

**Apply Changes:**

```bash
# Copy updated files
docker cp src/ckanext-custom-theme/ckanext/custom_theme/plugin.py ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/plugin.py
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/home/index.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/home/index.html

# Set permissions
docker exec -u root ckan-docker-ckan-1 chown -R ckan:ckan-sys /srv/app/src/ckanext-custom-theme/

# Restart CKAN
docker compose restart ckan
```

---

## 👑 System Administrator Setup

### Grant Sysadmin Privileges

```bash
# List current sysadmins
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini sysadmin list

# Add user as sysadmin (replace 'superadmin' with actual username)
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini sysadmin add superadmin

# Verify the user is now a sysadmin
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini sysadmin list

# Check user details
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini user show superadmin
```

**Expected Output:**
```
Sysadmins:
count = 3
User name=superadmin email=superadmin@gmail.com id=e5abeb04-7d9e-43cb-9755-53af2cfc9cc8
```

---

## 📂 Complete File Structure

### Files Created/Modified

1. **fix_session.py** - Session persistence fix
2. **fix_acs_endpoint.py** - ACS endpoint fix
3. **src/ckanext-custom-theme/ckanext/custom_theme/plugin.py** - Helper functions
4. **src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html** - Header with logo
5. **src/ckanext-custom-theme/ckanext/custom_theme/templates/footer.html** - Footer with logo
6. **src/ckanext-custom-theme/ckanext/custom_theme/templates/home/index.html** - Dynamic homepage
7. **src/ckanext-custom-theme/ckanext/custom_theme/plugins/saml2_redirect.py** - Login redirect

### Runtime Files Modified (Inside Container)

1. `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py` - Session fix applied
2. `/usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py` - ACS endpoint fix applied
3. `/srv/app/ckan.ini` - Uploads enabled, storage path configured

---

## ✅ Verification & Testing

### 1. Check All Services Are Running

```bash
docker compose ps
```

**Expected:** All services show "Up (healthy)" status

### 2. Test SAML2 Login

```bash
# Test login endpoint
curl -k https://localhost:8443/user/saml2login

# Should redirect to Keycloak
```

**Manual Test:**
1. Open browser: `https://localhost:8443/`
2. Click "Login"
3. Should redirect to Keycloak login page
4. Enter credentials
5. Should redirect back and show logged in

### 3. Test ACS Endpoint

```bash
# Test POST to ACS endpoint
curl -k -X POST https://localhost:8443/saml2/acs -d "SAMLResponse=test"

# Should return HTML (not 405 error)
```

### 4. Verify Session Persistence

```bash
# Check if session fix is applied
docker exec ckan-docker-ckan-1 grep -c "session_info_copy" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py
# Should output: 1
```

### 5. Verify ACS Endpoint Configuration

```bash
# Check ACS endpoint is hardcoded
docker exec ckan-docker-ckan-1 grep "acs_endpoint = " /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py
# Should show: acs_endpoint = '/saml2/acs'  # Hardcoded for correct CKAN integration
```

### 6. Verify File Uploads Enabled

```bash
# Check configuration
docker exec ckan-docker-ckan-1 grep "uploads_enabled\|storage_path" /srv/app/ckan.ini
# Should show:
# ckan.uploads_enabled = true
# ckan.storage_path = /var/lib/ckan/default
```

### 7. Test Logo Display

```bash
# Check logo in header
curl -k https://localhost:8443/ | grep -i "IdtCitiesLogoWhite"
# Should find the logo image tag
```

### 8. Test Dynamic Homepage

```bash
# Check if groups are being fetched
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini group list
```

### 9. Verify Sysadmin Privileges

```bash
# List sysadmins
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini sysadmin list
# Should include your user
```

---

## 🔍 Troubleshooting

### Issue: CKAN Won't Start

**Check logs:**
```bash
docker compose logs ckan | tail -50
```

**Common causes:**
- Syntax errors in Python files
- Import errors
- Database connection issues
- Missing dependencies

**Solution:**
```bash
# Check for syntax errors
docker exec ckan-docker-ckan-1 python3 -m py_compile /srv/app/src/ckanext-custom-theme/ckanext/custom_theme/plugin.py

# Check database connection
docker exec ckan-docker-ckan-1 ping -c 3 keycloak_postgres
```

### Issue: 405 Method Not Allowed on ACS

**Verify route registration:**
```bash
docker exec ckan-docker-ckan-1 grep "add_url_rule.*acs" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/views/saml2auth.py
# Should show: methods=['GET', 'POST']
```

**If not found, reapply fixes:**
```bash
docker cp fix_acs_endpoint.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_acs_endpoint.py
docker compose restart ckan
```

### Issue: Session Not Persisting

**Reapply session fix:**
```bash
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker compose restart ckan
```

### Issue: Upload Button Not Showing

**Check uploads enabled:**
```bash
docker exec ckan-docker-ckan-1 grep "uploads_enabled" /srv/app/ckan.ini
# Should show: ckan.uploads_enabled = true
```

**If not enabled:**
```bash
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "ckan.uploads_enabled = true"
docker compose restart ckan
```

### Issue: Logo Not Displaying

**Check file permissions:**
```bash
docker exec ckan-docker-ckan-1 ls -la /srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html
```

**Verify logo URL:**
```bash
curl -I https://home.idtcities.com/assets/IdtCitiesLogoWhite.png
# Should return 200 OK
```

### Issue: Dynamic Categories Not Showing

**Check if groups exist:**
```bash
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini group list
```

**Check plugin helper:**
```bash
docker exec ckan-docker-ckan-1 python3 << 'EOF'
import sys
sys.path.insert(0, '/srv/app/src/ckan')
from ckanext.custom_theme.plugin import CustomThemePlugin
plugin = CustomThemePlugin()
groups = plugin._get_groups_with_counts(9)
print(f"Found {len(groups)} groups")
EOF
```

---

## 🚀 Complete Setup Script

For a fresh installation, run these commands in order:

```bash
#!/bin/bash

# Navigate to project directory
cd /home/frontend/Snap4IdtCities/CKANDOCKER/ckan-docker

# 1. Build and start services
echo "Building and starting services..."
docker compose up -d --build

# 2. Wait for services to be healthy
echo "Waiting for services to be healthy..."
sleep 30
docker compose ps

# 3. Apply session persistence fix
echo "Applying session persistence fix..."
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py

# 4. Apply ACS endpoint fix
echo "Applying ACS endpoint fix..."
docker cp fix_acs_endpoint.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_acs_endpoint.py

# 5. Enable file uploads
echo "Enabling file uploads..."
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "ckan.uploads_enabled = true"
docker exec -u root ckan-docker-ckan-1 mkdir -p /var/lib/ckan/default/storage/uploads
docker exec -u root ckan-docker-ckan-1 chown -R 503:502 /var/lib/ckan/default

# 6. Copy updated theme files
echo "Copying theme files..."
docker cp src/ckanext-custom-theme/ckanext/custom_theme/plugin.py ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/plugin.py
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/header.html
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/footer.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/footer.html
docker cp src/ckanext-custom-theme/ckanext/custom_theme/templates/home/index.html ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/ckanext/custom_theme/templates/home/index.html

# 7. Set permissions
echo "Setting permissions..."
docker exec -u root ckan-docker-ckan-1 chown -R ckan:ckan-sys /srv/app/src/ckanext-custom-theme/

# 8. Restart CKAN
echo "Restarting CKAN..."
docker compose restart ckan

# 9. Wait for restart
echo "Waiting for CKAN to restart..."
sleep 20

# 10. Verify installation
echo "Verifying installation..."
docker compose ps
docker compose logs ckan --tail 10

echo "Setup complete! Access CKAN at https://localhost:8443"
```

**Save as:** `setup_complete.sh`  
**Make executable:** `chmod +x setup_complete.sh`  
**Run:** `./setup_complete.sh`

---

## 📝 Quick Reference Commands

### Service Management
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart CKAN only
docker compose restart ckan

# View logs
docker compose logs -f ckan

# Check status
docker compose ps
```

### Configuration
```bash
# View CKAN config
docker exec ckan-docker-ckan-1 cat /srv/app/ckan.ini

# Update config
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini config-tool /srv/app/ckan.ini "key = value"

# List sysadmins
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini sysadmin list

# Add sysadmin
docker exec ckan-docker-ckan-1 ckan -c /srv/app/ckan.ini sysadmin add username
```

### File Management
```bash
# Copy file to container
docker cp local_file.txt ckan-docker-ckan-1:/path/in/container/

# Copy file from container
docker cp ckan-docker-ckan-1:/path/in/container/file.txt ./

# Set permissions
docker exec -u root ckan-docker-ckan-1 chown -R ckan:ckan-sys /path/
```

---

## 🎯 Summary of All Changes

### 1. SAML2 SSO Integration
- ✅ Configured Keycloak integration
- ✅ Fixed session persistence
- ✅ Fixed ACS endpoint routing
- ✅ Fixed template URL issues

### 2. Custom Branding
- ✅ Added logo to header
- ✅ Added logo to footer
- ✅ Responsive logo sizing

### 3. File Uploads
- ✅ Enabled uploads in configuration
- ✅ Created storage directory
- ✅ Set proper permissions

### 4. Dynamic Homepage
- ✅ Dynamic categories from CKAN groups
- ✅ Featured datasets section
- ✅ Recent datasets section
- ✅ Accurate statistics

### 5. System Administration
- ✅ Configured superadmin user
- ✅ Verified sysadmin privileges

---

## 📚 Additional Resources

- **SAML2 Setup Guide:** `SAML2_COMPLETE_SETUP_GUIDE.md`
- **Server Deployment:** `SERVER_DEPLOYMENT_GUIDE.md`
- **CKAN Documentation:** https://docs.ckan.org/
- **Keycloak Admin:** https://auth.idtcities.com/admin/

---

## ✅ Final Checklist

Before considering the setup complete, verify:

- [ ] All Docker services are running and healthy
- [ ] SAML2 login redirects to Keycloak
- [ ] Users can log in and stay logged in
- [ ] Logo displays in header and footer
- [ ] File upload button appears in resource form
- [ ] Dynamic categories show on homepage
- [ ] Featured and recent datasets display
- [ ] Statistics are accurate
- [ ] Sysadmin user has full privileges
- [ ] No errors in logs

---

**Date Created:** November 2025  
**Last Updated:** November 2025  
**Status:** ✅ Production Ready  
**Version:** 1.0

---

## 🔄 Maintenance

### Regular Tasks

```bash
# Check service health weekly
docker compose ps

# Review logs monthly
docker compose logs ckan --since 30d > ckan_logs_monthly.txt

# Backup configuration
docker exec ckan-docker-ckan-1 cat /srv/app/ckan.ini > ckan.ini.backup

# Update theme files (if modified externally)
docker cp src/ckanext-custom-theme/ ckan-docker-ckan-1:/srv/app/src/ckanext-custom-theme/
docker compose restart ckan
```

---

**This guide provides complete instructions for setting up and maintaining the CKAN SAML2 portal. Follow each section sequentially for a successful deployment.**

