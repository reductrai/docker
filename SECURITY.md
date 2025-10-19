# ReductrAI Security Hardening Guide

This guide covers security best practices for deploying ReductrAI as a proxy in production environments.

## Security Model

ReductrAI is a **transparent proxy** between your applications and monitoring services:

```
Your Apps → ReductrAI Proxy → Datadog/NewRelic/etc (YOUR monitoring service)
             ↓
          Local Storage (compressed)
```

**Key Security Points:**
- ReductrAI forwards data to YOUR monitoring service unchanged
- Your monitoring service handles compliance (SOC2, HIPAA, GDPR, etc.)
- ReductrAI stores compressed copies locally for cost savings
- API keys for your monitoring services pass through the proxy

## Quick Security Checklist

- [ ] API keys stored securely (not in .env files)
- [ ] TLS/SSL enabled between apps and proxy
- [ ] Network isolation with firewalls
- [ ] Container running as non-root user
- [ ] File permissions restricted on data volumes
- [ ] Regular security updates applied
- [ ] Monitoring and logging configured

## 1. Secrets Management

### ❌ NEVER DO THIS IN PRODUCTION

```bash
# DO NOT commit secrets to .env files
DATADOG_API_KEY=abc123secret
NEW_RELIC_API_KEY=xyz789secret
```

### ✅ USE SECURE SECRETS MANAGEMENT

#### Option 1: Environment Variables from Vault

```bash
# HashiCorp Vault
vault kv put secret/reductrai \
  datadog_api_key="your_key" \
  reductrai_license_key="your_key"

# Start with secrets from Vault
export DATADOG_API_KEY=$(vault kv get -field=datadog_api_key secret/reductrai)
export REDUCTRAI_LICENSE_KEY=$(vault kv get -field=reductrai_license_key secret/reductrai)
docker-compose up -d
```

#### Option 2: Docker Secrets (Swarm)

```bash
echo "your_datadog_key" | docker secret create datadog_api_key -
echo "your_license_key" | docker secret create reductrai_license_key -
```

```yaml
# docker-compose.yml
services:
  proxy:
    secrets:
      - datadog_api_key
      - reductrai_license_key
    environment:
      - DATADOG_API_KEY_FILE=/run/secrets/datadog_api_key
      - REDUCTRAI_LICENSE_KEY_FILE=/run/secrets/reductrai_license_key

secrets:
  datadog_api_key:
    external: true
  reductrai_license_key:
    external: true
```

#### Option 3: Kubernetes Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: reductrai-secrets
type: Opaque
stringData:
  datadog-api-key: "your_datadog_key"
  reductrai-license-key: "your_license_key"
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: proxy
        env:
        - name: DATADOG_API_KEY
          valueFrom:
            secretKeyRef:
              name: reductrai-secrets
              key: datadog-api-key
```

#### Option 4: AWS Secrets Manager

```bash
# Store secrets
aws secretsmanager create-secret \
  --name reductrai/datadog-api-key \
  --secret-string "your_datadog_key"

# Retrieve at runtime
DATADOG_API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id reductrai/datadog-api-key \
  --query SecretString --output text)
```

## 2. Network Security

### Firewall Configuration

Only expose necessary ports:

```bash
# Allow inbound to proxy (from your applications)
sudo ufw allow from 10.0.0.0/8 to any port 8080 comment 'ReductrAI Proxy'

# Allow outbound to monitoring services (Datadog/NewRelic/etc)
sudo ufw allow out to any port 443 comment 'HTTPS to monitoring services'

# Block direct internet access to proxy
sudo ufw deny from any to any port 8080

# Enable firewall
sudo ufw enable
```

### TLS/SSL Termination

Use a reverse proxy for TLS:

```nginx
# /etc/nginx/sites-available/reductrai
upstream reductrai_proxy {
    server localhost:8080;
}

server {
    listen 443 ssl http2;
    server_name reductrai.internal.company.com;

    ssl_certificate /etc/ssl/certs/reductrai.crt;
    ssl_certificate_key /etc/ssl/private/reductrai.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://reductrai_proxy;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Network Isolation

```yaml
# docker-compose.yml
version: '3.8'

networks:
  reductrai-internal:
    driver: bridge
    internal: true
  reductrai-external:
    driver: bridge

services:
  proxy:
    networks:
      - reductrai-internal  # Internal services
      - reductrai-external  # Internet for Datadog/NewRelic

  dashboard:
    networks:
      - reductrai-internal  # No internet access
```

## 3. Container Security

### Run as Non-Root User

```yaml
# docker-compose.yml
services:
  proxy:
    user: "1001:1001"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

### Image Security Scanning

```bash
# Scan for vulnerabilities
trivy image reductrai/proxy:latest
docker scout cves reductrai/proxy:latest
```

### Read-Only Filesystem

```yaml
services:
  proxy:
    read_only: true
    tmpfs:
      - /tmp
    volumes:
      - reductrai-data:/app/data  # Only writable location
```

### Resource Limits

```yaml
services:
  proxy:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## 4. Data Security

### Encryption at Rest

Encrypt local storage volumes:

```bash
# LUKS encrypted volume (Linux)
sudo cryptsetup luksFormat /dev/sdb1
sudo cryptsetup luksOpen /dev/sdb1 reductrai-data
sudo mkfs.ext4 /dev/mapper/reductrai-data
sudo mount /dev/mapper/reductrai-data /var/lib/docker/volumes/reductrai-data
```

### File Permissions

```bash
# Restrict access to data directory
sudo chown -R 1001:1001 /var/lib/docker/volumes/reductrai-data
sudo chmod 700 /var/lib/docker/volumes/reductrai-data
```

## 5. Authentication

### API Key Validation

Applications send API keys through ReductrAI to your monitoring service:

```bash
# Application → ReductrAI → Datadog
curl -X POST https://reductrai.internal.company.com/api/v2/series \
  -H "DD-API-KEY: your_datadog_key" \
  -d '{"series":[...]}'
```

ReductrAI passes the API key to Datadog unchanged. Datadog validates it.

### Dashboard Access Control

Protect the dashboard with basic authentication:

```nginx
# Nginx basic auth
location / {
    auth_basic "ReductrAI Dashboard";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://localhost:5173;
}
```

## 6. Monitoring & Logging

### Security Event Logging

```yaml
services:
  proxy:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

Monitor for:
- Failed health checks
- High error rates
- Unusual traffic patterns
- Container restarts

### Health Monitoring

```bash
# Health check endpoint
curl http://localhost:8080/health

# Expected response
{"status":"ok","uptime":12345,"version":"1.0.0"}
```

## 7. Backup & Disaster Recovery

### Backup Compressed Data

```bash
# Daily backup script
#!/bin/bash
docker run --rm \
  -v reductrai-data:/data \
  -v /backup:/backup \
  alpine tar czf /backup/reductrai-$(date +%Y%m%d).tar.gz /data
```

### Encrypted Backups

```bash
# Backup with encryption
docker run --rm \
  -v reductrai-data:/data \
  -v /backup:/backup \
  alpine tar czf - /data | \
  openssl enc -aes-256-cbc -pbkdf2 -out /backup/reductrai-$(date +%Y%m%d).tar.gz.enc
```

### Restore from Backup

```bash
# Restore encrypted backup
openssl enc -aes-256-cbc -d -pbkdf2 -in /backup/reductrai-20241019.tar.gz.enc | \
  docker run --rm -i -v reductrai-data:/data alpine tar xzf - -C /
```

## 8. Updates & Patching

### Update Process

```bash
# 1. Pull latest images
docker pull reductrai/proxy:latest
docker pull reductrai/dashboard:latest
docker pull reductrai/ai-query:latest
docker pull reductrai/ollama:latest

# 2. Backup data
./backup-reductrai.sh

# 3. Update with zero downtime
docker-compose up -d

# 4. Verify
curl http://localhost:8080/health
```

### Security Updates

Subscribe to security announcements:
- GitHub: https://github.com/reductrai/docker
- Email: security-announce@reductrai.com

## 9. Incident Response

### If Compromised

1. **Isolate**: Disconnect from network
   ```bash
   docker network disconnect reductrai-external proxy
   ```

2. **Rotate secrets**: Update API keys immediately
   ```bash
   # Update in Datadog/NewRelic
   # Update in your secrets vault
   # Restart ReductrAI
   ```

3. **Investigate**: Check logs
   ```bash
   docker logs reductrai-proxy | grep ERROR
   ```

4. **Restore**: From clean backup if needed
   ```bash
   ./restore-reductrai.sh
   ```

## 10. Compliance & Auditing

### Important: ReductrAI is a Proxy

**ReductrAI forwards data to YOUR monitoring service unchanged.**

Your monitoring service (Datadog, New Relic, etc.) is responsible for:
- SOC2 compliance
- HIPAA compliance
- GDPR compliance
- PCI-DSS compliance
- Data retention policies
- Access controls
- Audit logging

**ReductrAI's role:**
- Store compressed copies locally (for cost savings and AI queries)
- Forward 10% sample to your monitoring service
- Provide API for querying local compressed data

**Your responsibility:**
- Ensure your monitoring service meets compliance requirements
- Secure the ReductrAI deployment (this guide)
- Manage access to local compressed data
- Encrypt local storage if required by your compliance needs

## Security Best Practices Summary

1. **Secrets in vault** - Never commit API keys to .env
2. **TLS everywhere** - Use reverse proxy with certificates
3. **Run as non-root** - Container security hardening
4. **Network isolation** - Firewalls and segmentation
5. **Encrypt volumes** - Local storage encryption if needed
6. **Regular updates** - Stay current with patches
7. **Monitor health** - Automated health checks
8. **Backup regularly** - Encrypted backups
9. **Access control** - Dashboard authentication

## Additional Resources

- [High Availability Guide](./HIGH-AVAILABILITY.md)
- [Storage Configuration](./STORAGE.md)
- [Build & Publish Guide](./BUILD.md)

## Support

Security questions:
- Documentation: https://docs.reductrai.com/security
- Security Team: security@reductrai.com
- Enterprise Support: support@reductrai.com
