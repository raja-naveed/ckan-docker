# 🚀 Server Deployment Guide - SAML2 SSO CKAN

## ⚠️ CRITICAL: What You Need to Copy to Your Server

### 📁 **REQUIRED FILES TO COPY:**

#### 1. **Core Configuration Files:**
```
✅ docker-compose.yml          (MAIN CONFIG - MUST COPY)
✅ Dockerfile.custom           (CUSTOM CKAN BUILD - MUST COPY)
✅ .env                       (ENVIRONMENT VARIABLES - MUST COPY)
```

#### 2. **Directory Structure:**
```
✅ ckan/
   ├── setup/
   │   └── prerun.py.override  (SAML2 CONFIG - MUST COPY)
   └── docker-entrypoint.d/
✅ nginx/
   ├── Dockerfile
   └── setup/
       └── default.conf        (NGINX CONFIG - MUST COPY)
✅ postgresql/
   └── docker-entrypoint-initdb.d/
✅ datapusher/
   └── Dockerfile
✅ src/
   └── ckanext-custom-theme/   (CUSTOM THEME - MUST COPY)
✅ ckanext-scheming/           (SCHEMING EXTENSION - MUST COPY)
```

#### 3. **Critical Scripts:**
```
✅ fix_session.py              (SESSION PERSISTENCE FIX - MUST COPY)
```

---

## 🔧 **SERVER SETUP REQUIREMENTS**

### **Prerequisites on Your Server:**
```bash
# 1. Docker & Docker Compose
sudo apt update
sudo apt install docker.io docker-compose-plugin

# 2. Git (to clone or copy files)
sudo apt install git

# 3. Make sure Docker is running
sudo systemctl start docker
sudo systemctl enable docker
```

### **Port Requirements:**
- **Port 8443** - HTTPS access (nginx)
- **Port 5000** - CKAN internal (container only)
- **Port 5432** - PostgreSQL (internal only)
- **Port 8983** - Solr (internal only)
- **Port 6379** - Redis (internal only)
- **Port 8800** - Datapusher (internal only)

---

## 📋 **DEPLOYMENT STEPS**

### **Step 1: Copy Files to Server**
```bash
# Option A: Copy entire directory
scp -r ckan-docker/ user@your-server:/home/user/

# Option B: Copy specific files
scp docker-compose.yml user@your-server:/home/user/ckan-docker/
scp Dockerfile.custom user@your-server:/home/user/ckan-docker/
scp .env user@your-server:/home/user/ckan-docker/
# ... copy all required files
```

### **Step 2: Update Configuration for Your Server**

#### **CRITICAL CHANGES NEEDED:**

1. **Update Entity ID in docker-compose.yml:**
```yaml
# CHANGE THIS LINE:
- CKANEXT__SAML2AUTH__ENTITY_ID=https://localhost:8443/saml2/metadata

# TO YOUR SERVER'S DOMAIN:
- CKANEXT__SAML2AUTH__ENTITY_ID=https://your-server-domain.com/saml2/metadata
```

2. **Update Keycloak Client Configuration:**
   - Go to Keycloak Admin: `https://auth.idtcities.com/admin/`
   - Update Client ID: `https://your-server-domain.com/saml2/metadata`
   - Update Valid Redirect URIs: `https://your-server-domain.com/*`
   - Update Master SAML Processing URL: `https://your-server-domain.com/saml2/acs`

3. **Update nginx/setup/default.conf:**
```nginx
# Change server_name if needed
server_name your-server-domain.com;
```

### **Step 3: Deploy on Server**
```bash
# SSH to your server
ssh user@your-server

# Navigate to project directory
cd /home/user/ckan-docker

# Start the services
docker-compose up -d

# Wait for services to be healthy
docker-compose ps

# Apply session persistence fix
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan
```

---

## ⚠️ **CRITICAL SERVER-SPECIFIC CHANGES**

### **1. Domain Configuration**
```bash
# In docker-compose.yml, update:
- CKANEXT__SAML2AUTH__ENTITY_ID=https://YOUR-DOMAIN.com/saml2/metadata

# In Keycloak, update client:
Client ID: https://YOUR-DOMAIN.com/saml2/metadata
Valid Redirect URIs: https://YOUR-DOMAIN.com/*
Master SAML Processing URL: https://YOUR-DOMAIN.com/saml2/acs
```

### **2. SSL Certificate**
```bash
# If you have a real SSL certificate, update nginx/setup/default.conf:
ssl_certificate /path/to/your/certificate.crt;
ssl_certificate_key /path/to/your/private.key;

# If using Let's Encrypt:
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

### **3. Firewall Configuration**
```bash
# Allow HTTPS traffic
sudo ufw allow 443
sudo ufw allow 8443

# Check firewall status
sudo ufw status
```

---

## 🔍 **VERIFICATION CHECKLIST**

### **After Deployment:**
```bash
# 1. Check all containers are running
docker-compose ps

# 2. Check logs for errors
docker-compose logs ckan

# 3. Test SAML2 endpoint
curl -k https://your-domain.com/user/saml2login

# 4. Verify session fix is applied
docker exec ckan-docker-ckan-1 grep -c "session_info_copy" /usr/local/lib/python3.10/site-packages/ckanext/saml2auth/cache.py
```

### **Expected Results:**
- ✅ All containers healthy
- ✅ No errors in logs
- ✅ SAML2 login redirects to Keycloak
- ✅ Session persistence fix applied

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues:**

#### **1. Container Won't Start:**
```bash
# Check logs
docker-compose logs ckan

# Rebuild if needed
docker-compose down
docker-compose up -d --build
```

#### **2. SAML2 Not Working:**
```bash
# Check Entity ID matches Keycloak client
# Check Keycloak client configuration
# Verify domain in docker-compose.yml
```

#### **3. Session Not Persisting:**
```bash
# Re-apply session fix
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan
```

#### **4. SSL Certificate Issues:**
```bash
# Check certificate paths in nginx config
# Verify certificate is valid
# Test with curl -k
```

---

## 📊 **PRODUCTION RECOMMENDATIONS**

### **Security:**
1. **Use real SSL certificates** (Let's Encrypt recommended)
2. **Configure firewall** properly
3. **Use strong passwords** in .env file
4. **Regular backups** of database
5. **Monitor logs** for security issues

### **Performance:**
1. **Allocate sufficient resources** (4GB RAM minimum)
2. **Configure database** for production
3. **Set up monitoring** (Prometheus/Grafana)
4. **Regular updates** of containers

### **Backup Strategy:**
```bash
# Database backup
docker exec ckan-docker-db-1 pg_dump -U ckan ckan > backup.sql

# Volume backup
docker run --rm -v ckan-docker_ckan_storage:/data -v $(pwd):/backup alpine tar czf /backup/ckan-storage.tar.gz /data
```

---

## ✅ **FINAL CHECKLIST**

Before going live:
- [ ] Domain configured correctly
- [ ] SSL certificate installed
- [ ] Keycloak client updated
- [ ] All containers healthy
- [ ] Session persistence fix applied
- [ ] Firewall configured
- [ ] Backup strategy in place
- [ ] Monitoring configured

---

## 🎯 **QUICK DEPLOYMENT COMMANDS**

```bash
# 1. Copy files to server
scp -r ckan-docker/ user@server:/home/user/

# 2. SSH to server
ssh user@server

# 3. Navigate and start
cd ckan-docker
docker-compose up -d

# 4. Apply session fix
docker cp fix_session.py ckan-docker-ckan-1:/tmp/
docker exec -u root ckan-docker-ckan-1 python3 /tmp/fix_session.py
docker-compose restart ckan

# 5. Verify
docker-compose ps
curl -k https://your-domain.com/user/saml2login
```

---

## 🚀 **YOU'RE READY!**

**With these files and steps, your SAML2 SSO CKAN will work perfectly on your server!**

**Just remember to:**
1. ✅ Update domain in docker-compose.yml
2. ✅ Update Keycloak client configuration  
3. ✅ Apply session persistence fix
4. ✅ Configure SSL certificate

**Good luck with your deployment! 🎉**
