# 🚀 CKAN 2.11 with SAML2 SSO - Server Installation Guide

[![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://www.docker.com/)
[![CKAN](https://img.shields.io/badge/CKAN-2.11-green.svg)](https://ckan.org/)
[![SAML2](https://img.shields.io/badge/SAML2-SSO-orange.svg)](https://en.wikipedia.org/wiki/SAML_2.0)
[![Keycloak](https://img.shields.io/badge/Keycloak-IdP-red.svg)](https://www.keycloak.org/)

## 📋 Overview

This repository contains a complete **CKAN 2.11** installation with **SAML2 Single Sign-On (SSO)** integration using **Keycloak** as the Identity Provider. The solution includes session persistence, custom theming, and enterprise-grade security.

### ✨ Features

- ✅ **SAML2 SSO** with Keycloak integration
- ✅ **Session Persistence** across all pages
- ✅ **Custom Theme** with modern UI
- ✅ **Data Visualization** (GeoJSON, CSV, PDF, etc.)
- ✅ **Data Loading** with XLoader
- ✅ **Security** (SAML2 only, internal login disabled)
- ✅ **Production Ready** with Docker containers

---

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Keycloak IdP  │◄──►│   CKAN Portal   │◄──►│   PostgreSQL    │
│  (SAML2 Auth)   │    │   (Port 8443)   │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Nginx Proxy   │
                       │   (SSL/TLS)     │
                       └─────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- **Docker** 20.10+ and **Docker Compose** 2.0+
- **4GB RAM** minimum (8GB recommended)
- **20GB disk space**
- **Domain name** with SSL certificate
- **Keycloak server** access

### 1. Clone Repository

```bash
git clone <repository-url>
cd ckan-docker
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

**Required Environment Variables:**
```bash
# Database Configuration
POSTGRES_USER=ckan
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=ckan
CKAN_DB_USER=ckan
CKAN_DB_PASSWORD=your_secure_password
CKAN_DB=ckan

# Datastore Configuration
DATASTORE_READONLY_USER=datastore_ro
DATASTORE_READONLY_PASSWORD=your_secure_password
DATASTORE_DB=datastore

# CKAN Configuration
CKAN_SITE_URL=https://your-domain.com
CKAN_SITE_ID=your-site-id
CKAN_SITE_TITLE="Your Data Portal"
CKAN_SITE_DESCRIPTION="Open data portal"

# SAML2 Configuration
SAML2_IDP_URL=https://auth.snap4idtcity.com/realms/IdtCities/protocol/saml/descriptor
SAML2_ENTITY_ID=https://your-domain.com/saml2/metadata
```

### 3. Update Domain Configuration

**Edit `docker-compose.yml`:**
```yaml
# Update Entity ID for your domain
- CKANEXT__SAML2AUTH__ENTITY_ID=https://your-domain.com/saml2/metadata
```

### 4. Deploy Application

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f ckan
```

### 5. Apply Session Persistence Fix

```bash
# Copy and apply session fix
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan
```

### 6. Verify Installation

```bash
# Check all containers are healthy
docker-compose ps

# Test SAML2 endpoint
curl -k https://your-domain.com/user/saml2login

# Verify session fix
docker exec ckan-docker-ckan-1 grep -c "session_info_copy" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py
```

---

## 🔧 Configuration

### Keycloak Setup

1. **Access Keycloak Admin Console:**
   - URL: `https://auth.snap4idtcity.com/admin/`
   - Realm: `IdtCities`

2. **Create/Update SAML Client:**
   ```
   Client ID: https://your-domain.com/saml2/metadata
   Client Protocol: saml
   Valid Redirect URIs: https://your-domain.com/*
   Master SAML Processing URL: https://your-domain.com/saml2/acs
   Force POST Binding: ON
   Client Signature Required: OFF
   ```

3. **Configure Client Scopes:**
   - Create dedicated scope with X500 mappers:
     - X500 email → `urn:oid:1.2.840.113549.1.9.1`
     - X500 givenName → `urn:oid:2.5.4.42`
     - X500 surname → `urn:oid:2.5.4.4`

### SSL Certificate Setup

**For Let's Encrypt:**
```bash
# Install certbot
sudo apt install certbot

# Generate certificate
sudo certbot certonly --standalone -d your-domain.com

# Update nginx configuration
# Edit nginx/setup/default.conf:
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

**For Custom Certificate:**
```bash
# Update nginx/setup/default.conf:
ssl_certificate /path/to/your/certificate.crt;
ssl_certificate_key /path/to/your/private.key;
```

---

## 📁 Project Structure

```
ckan-docker/
├── docker-compose.yml          # Main orchestration file
├── Dockerfile.custom           # Custom CKAN build
├── .env                       # Environment variables
├── fix_session.py             # Session persistence fix
├── ckan/
│   ├── setup/
│   │   └── prerun.py.override # SAML2 configuration
│   └── docker-entrypoint.d/   # Initialization scripts
├── nginx/
│   ├── Dockerfile
│   └── setup/
│       └── default.conf       # Nginx configuration
├── postgresql/
│   └── docker-entrypoint-initdb.d/ # Database initialization
├── datapusher/
│   └── Dockerfile             # Data processing service
├── src/
│   └── ckanext-custom-theme/  # Custom theme
└── ckanext-scheming/          # Schema extension
```

---

## 🔍 Services

| Service | Port | Description |
|---------|------|-------------|
| **nginx** | 8443 | HTTPS proxy and SSL termination |
| **ckan** | 5000 | Main CKAN application |
| **postgresql** | 5432 | Database (internal) |
| **solr** | 8983 | Search engine (internal) |
| **redis** | 6379 | Cache and sessions (internal) |
| **datapusher** | 8800 | Data processing (internal) |

---

## 🛠️ Management Commands

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### Restart Services
```bash
docker-compose restart
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ckan
```

### Update Application
```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build

# Re-apply session fix
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan
```

### Backup Database
```bash
# Create backup
docker exec ckan-docker-db-1 pg_dump -U ckan ckan > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker exec -i ckan-docker-db-1 psql -U ckan ckan < backup_file.sql
```

### Backup Volumes
```bash
# Backup CKAN storage
docker run --rm -v ckan-docker_ckan_storage:/data -v $(pwd):/backup alpine tar czf /backup/ckan-storage-$(date +%Y%m%d).tar.gz /data

# Backup database
docker run --rm -v ckan-docker_pg_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-$(date +%Y%m%d).tar.gz /data
```

---

## 🔒 Security

### Firewall Configuration
```bash
# Allow HTTPS traffic
sudo ufw allow 443
sudo ufw allow 8443

# Block direct access to internal ports
sudo ufw deny 5000
sudo ufw deny 5432
sudo ufw deny 8983
sudo ufw deny 6379
sudo ufw deny 8800
```

### SSL/TLS Security
- **TLS 1.2+** only
- **Strong cipher suites**
- **HSTS** headers
- **Certificate validation**

### Authentication Security
- **SAML2 only** (internal login disabled)
- **Session persistence** with secure cookies
- **CSRF protection** enabled
- **Secure headers** configured

### Optional: Re-enable SAML2 Single Sign-On

CKAN ships with SAML helpers, but our deployment now uses the native login by default.  
If you need to reconnect to Keycloak:

1. **Update `docker-compose.yml` (and `.env` if used)**
   - Add `saml2auth` back to the `CKAN__PLUGINS` list.
   - Reintroduce the SAML environment variables:
     ```yaml
     - CKANEXT__SAML2AUTH__IDP_METADATA__LOCATION=remote
     - CKANEXT__SAML2AUTH__IDP_METADATA__REMOTE_URL=https://auth.snap4idtcity.com/realms/IdtCities/protocol/saml/descriptor
     - CKANEXT__SAML2AUTH__USER_EMAIL=urn:oid:1.2.840.113549.1.9.1
     - CKANEXT__SAML2AUTH__USER_FIRSTNAME=urn:oid:2.5.4.42
     - CKANEXT__SAML2AUTH__USER_LASTNAME=urn:oid:2.5.4.4
     - CKANEXT__SAML2AUTH__USER_FULLNAME=name
     - CKANEXT__SAML2AUTH__ENTITY_ID=https://datagate.snap4idtcity.com/saml2/metadata
     - CKANEXT__SAML2AUTH__ACS_ENDPOINT=/saml2/acs
     - CKANEXT__SAML2AUTH__ENABLE_CKAN_INTERNAL_LOGIN=false
     - CKANEXT__SAML2AUTH__WANT_RESPONSE_SIGNED=false
     - CKANEXT__SAML2AUTH__WANT_ASSERTIONS_SIGNED=false
     - CKANEXT__SAML2AUTH__ASSERTION_CONSUMER_SERVICE_BINDING=urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST
     - CKANEXT__SAML2AUTH__SP__NAME_ID_FORMAT=urn:oasis:names:tc:SAML:2.0:nameid-format:persistent
     ```

2. **Write the same values into `ckan.ini`**
   ```bash
   docker compose exec ckan bash
   ckan config-tool /srv/app/ckan.ini \
     "ckan.plugins = … saml2auth" \
     "ckanext.saml2auth.idp_metadata.location = remote" \
     "ckanext.saml2auth.idp_metadata.remote_url = https://auth.snap4idtcity.com/realms/IdtCities/protocol/saml/descriptor" \
     "ckanext.saml2auth.entity_id = https://datagate.snap4idtcity.com/saml2/metadata" \
     "ckanext.saml2auth.acs_endpoint = /saml2/acs" \
     "ckanext.saml2auth.user_email = urn:oid:1.2.840.113549.1.9.1" \
     "ckanext.saml2auth.user_firstname = urn:oid:2.5.4.42" \
     "ckanext.saml2auth.user_lastname = urn:oid:2.5.4.4" \
     "ckanext.saml2auth.user_fullname = name" \
     "ckanext.saml2auth.enable_ckan_internal_login = false" \
     "ckanext.saml2auth.want_response_signed = false" \
     "ckanext.saml2auth.want_assertions_signed = false" \
     "ckanext.saml2auth.assertion_consumer_service_binding = urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" \
     "ckanext.saml2auth.sp.name_id_format = urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
   exit
   docker compose restart ckan
   ```

3. **Create/update the Keycloak SAML client (realm `IdtCities`)**
   | Setting | Value |
   | --- | --- |
   | Client ID / Entity ID | `https://datagate.snap4idtcity.com/saml2/metadata` |
   | Assertion Consumer Service (POST URL) | `https://datagate.snap4idtcity.com/saml2/acs` |
   | Valid Redirect URIs | `https://datagate.snap4idtcity.com/saml2/acs` |
   | Valid Post Logout Redirect URIs | `https://datagate.snap4idtcity.com/*` |
   | Web Origins | `https://datagate.snap4idtcity.com` |
   | NameID format | `urn:oasis:names:tc:SAML:2.0:nameid-format:persistent` |
   | Attribute mappers | Email `urn:oid:1.2.840.113549.1.9.1`, First name `urn:oid:2.5.4.42`, Last name `urn:oid:2.5.4.4`, Full name `name` |

After Keycloak is configured and CKAN is restarted, the `/user/login` link will redirect to `https://auth.snap4idtcity.com` again. Remove these settings to revert to the built-in login.

---

## 📊 Monitoring

### Health Checks
```bash
# Check container health
docker-compose ps

# Check CKAN API
curl -k https://your-domain.com/api/action/status_show

# Check database connection
docker exec ckan-docker-db-1 pg_isready -U ckan
```

### Log Monitoring
```bash
# Real-time logs
docker-compose logs -f

# Log rotation
docker system prune -f
```

### Performance Monitoring
```bash
# Container resource usage
docker stats

# Disk usage
docker system df
```

---

## 🚨 Troubleshooting

### Common Issues

#### **1. Container Won't Start**
```bash
# Check logs
docker-compose logs ckan

# Check disk space
df -h

# Check memory
free -h
```

#### **2. SAML2 Authentication Fails**
```bash
# Verify Entity ID matches Keycloak
grep "ENTITY_ID" docker-compose.yml

# Check Keycloak client configuration
# Verify domain in Keycloak admin console
```

#### **3. Session Not Persisting**
```bash
# Re-apply session fix
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan
```

#### **4. SSL Certificate Issues**
```bash
# Check certificate validity
openssl x509 -in /path/to/certificate.crt -text -noout

# Test SSL connection
openssl s_client -connect your-domain.com:443
```

#### **5. Database Connection Issues**
```bash
# Check database logs
docker-compose logs db

# Test database connection
docker exec ckan-docker-ckan-1 psql -h db -U ckan -d ckan -c "SELECT 1;"
```

### Debug Mode
```bash
# Enable debug logging
echo "CKAN__DEBUG=true" >> .env
docker-compose restart ckan

# View detailed logs
docker-compose logs -f ckan | grep DEBUG
```

---

## 📈 Performance Optimization

### Resource Allocation
```yaml
# In docker-compose.yml, add resource limits
services:
  ckan:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### Database Optimization
```sql
-- Connect to database and run optimizations
docker exec -it ckan-docker-db-1 psql -U ckan -d ckan

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY idx_package_name ON package(name);
CREATE INDEX CONCURRENTLY idx_resource_package_id ON resource(package_id);
```

### Cache Configuration
```bash
# Redis optimization
echo "maxmemory 512mb" >> redis.conf
echo "maxmemory-policy allkeys-lru" >> redis.conf
```

---

## 🔄 Updates and Maintenance

### Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose pull
docker-compose up -d

# Clean up old images
docker system prune -f
```

### Security Updates
```bash
# Update CKAN extensions
docker exec ckan-docker-ckan-1 pip install --upgrade ckanext-saml2auth

# Update base images
docker-compose pull
docker-compose up -d --build
```

---

## 📞 Support

### Documentation
- [CKAN Documentation](https://docs.ckan.org/)
- [SAML2 Extension](https://github.com/keitaroinc/ckanext-saml2auth)
- [Keycloak Documentation](https://www.keycloak.org/documentation)

### Community
- [CKAN Community](https://github.com/ckan/ckan)
- [Docker Community](https://forums.docker.com/)

### Professional Support
- **Enterprise Support**: Available for production deployments
- **Custom Development**: Tailored solutions for specific needs
- **Training**: CKAN and SAML2 administration training

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0**.

See [LICENSE](LICENSE) file for details.

---

## 🎯 Success Metrics

### Deployment Checklist
- [ ] All containers running and healthy
- [ ] SSL certificate installed and valid
- [ ] SAML2 authentication working
- [ ] Session persistence verified
- [ ] Custom theme applied
- [ ] Data visualization working
- [ ] Security headers configured
- [ ] Backup strategy implemented
- [ ] Monitoring configured
- [ ] Performance optimized

---

## 🚀 Production Readiness

### Pre-Launch Checklist
- [ ] Domain configured correctly
- [ ] SSL certificate valid
- [ ] Keycloak client updated
- [ ] Firewall configured
- [ ] Backup strategy in place
- [ ] Monitoring alerts set up
- [ ] Performance testing completed
- [ ] Security audit passed
- [ ] Documentation updated
- [ ] Team training completed

---

## 📞 Contact

**For technical support or questions:**
- **Email**: support@your-organization.com
- **Documentation**: [Your Documentation Site]
- **Issues**: [GitHub Issues](https://github.com/your-org/ckan-docker/issues)

---

## 🎉 Congratulations!

You now have a **production-ready CKAN portal** with **enterprise-grade SAML2 SSO**!

**Key Features Working:**
- ✅ **SAML2 Authentication** with Keycloak
- ✅ **Session Persistence** across all pages
- ✅ **Custom Theme** with modern UI
- ✅ **Data Visualization** and processing
- ✅ **Security** (SAML2 only)
- ✅ **Scalability** with Docker containers

**Your data portal is ready to serve your organization! 🚀**

---

*Last Updated: October 24, 2025*  
*Version: 1.0.0*  
*Status: Production Ready*