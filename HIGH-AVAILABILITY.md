# ReductrAI High Availability Deployment Guide

This guide covers deploying ReductrAI with high availability for production environments.

## HA Architecture Overview

```
                         Load Balancer
                              |
           +------------------+------------------+
           |                  |                  |
    ReductrAI-1        ReductrAI-2        ReductrAI-3
           |                  |                  |
           +------------------+------------------+
                              |
                    Shared Storage Backend
                   (S3/GCS/Azure/NFS/etc)
                              |
                    Datadog/NewRelic/etc
```

**Key HA Components:**
- **Multiple proxy instances** - Run 3+ replicas for redundancy
- **Load balancer** - Distribute traffic across instances
- **Shared storage** - Centralized storage for compressed data
- **Health checks** - Automatic failover on instance failure
- **Zero-downtime updates** - Rolling deployments

## Why HA Matters for a Proxy

As the data path between your applications and monitoring services, ReductrAI must be highly available:

- **Downtime = Lost data** - If proxy is down, metrics/logs/traces are lost
- **Single point of failure** - One instance means one point of failure
- **Update risk** - Need to update without disrupting data flow
- **Scaling** - Handle increased traffic without bottlenecks

## Quick HA Checklist

- [ ] 3+ proxy instances running
- [ ] Load balancer configured
- [ ] Shared storage backend (S3/GCS/Azure)
- [ ] Health checks enabled
- [ ] Auto-restart configured
- [ ] Monitoring and alerting setup
- [ ] Backup and recovery tested
- [ ] Rolling update strategy defined

## 1. Multi-Instance Deployment

### Docker Swarm

```yaml
# docker-compose-swarm.yml
version: '3.8'

services:
  proxy:
    image: reductrai/proxy:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: any
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    ports:
      - "8080:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY}
      - DATADOG_API_KEY=${DATADOG_API_KEY}
      # Shared storage configuration
      - STORAGE_COLD_TYPE=s3
      - S3_BUCKET=reductrai-production
      - S3_REGION=us-east-1
    networks:
      - reductrai
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 40s

networks:
  reductrai:
    driver: overlay
```

Deploy:

```bash
docker stack deploy -c docker-compose-swarm.yml reductrai

# Verify replicas
docker service ls
docker service ps reductrai_proxy
```

### Kubernetes

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reductrai-proxy
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: reductrai-proxy
  template:
    metadata:
      labels:
        app: reductrai-proxy
    spec:
      containers:
      - name: proxy
        image: reductrai/proxy:latest
        ports:
        - containerPort: 8080
        env:
        - name: REDUCTRAI_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: reductrai-secrets
              key: license-key
        - name: DATADOG_API_KEY
          valueFrom:
            secretKeyRef:
              name: reductrai-secrets
              key: datadog-api-key
        - name: STORAGE_COLD_TYPE
          value: "s3"
        - name: S3_BUCKET
          value: "reductrai-production"
        - name: S3_REGION
          value: "us-east-1"
        resources:
          limits:
            cpu: "2"
            memory: "2Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - reductrai-proxy
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: reductrai-proxy
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: reductrai-proxy
```

Deploy:

```bash
kubectl apply -f kubernetes/deployment.yaml

# Verify
kubectl get pods -l app=reductrai-proxy
kubectl get svc reductrai-proxy
```

### Manual Multi-Instance (Docker Compose)

```yaml
# docker-compose-ha.yml
version: '3.8'

services:
  proxy-1:
    image: reductrai/proxy:latest
    container_name: reductrai-proxy-1
    ports:
      - "8081:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY}
      - DATADOG_API_KEY=${DATADOG_API_KEY}
      - STORAGE_COLD_TYPE=s3
      - S3_BUCKET=reductrai-production
    restart: unless-stopped

  proxy-2:
    image: reductrai/proxy:latest
    container_name: reductrai-proxy-2
    ports:
      - "8082:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY}
      - DATADOG_API_KEY=${DATADOG_API_KEY}
      - STORAGE_COLD_TYPE=s3
      - S3_BUCKET=reductrai-production
    restart: unless-stopped

  proxy-3:
    image: reductrai/proxy:latest
    container_name: reductrai-proxy-3
    ports:
      - "8083:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY}
      - DATADOG_API_KEY=${DATADOG_API_KEY}
      - STORAGE_COLD_TYPE=s3
      - S3_BUCKET=reductrai-production
    restart: unless-stopped
```

## 2. Load Balancing

### Nginx Load Balancer

```nginx
# /etc/nginx/conf.d/reductrai-lb.conf
upstream reductrai_cluster {
    least_conn;  # Distribute to least busy instance

    server 10.0.1.10:8080 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:8080 max_fails=3 fail_timeout=30s;
    server 10.0.1.12:8080 max_fails=3 fail_timeout=30s;

    # Health check (requires nginx-plus or custom module)
    # health_check interval=10s fails=3 passes=2 uri=/health;
}

server {
    listen 443 ssl http2;
    server_name reductrai.company.com;

    ssl_certificate /etc/ssl/certs/reductrai.crt;
    ssl_certificate_key /etc/ssl/private/reductrai.key;

    location / {
        proxy_pass http://reductrai_cluster;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Retry on failure
        proxy_next_upstream error timeout http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
    }

    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://reductrai_cluster/health;
    }
}
```

### HAProxy Load Balancer

```haproxy
# /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    maxconn 4096

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    retries 3

frontend reductrai_front
    bind *:443 ssl crt /etc/ssl/certs/reductrai.pem
    default_backend reductrai_back

    # Rate limiting
    stick-table type ip size 100k expire 30s store http_req_rate(10s)
    http-request track-sc0 src
    http-request deny if { sc_http_req_rate(0) gt 1000 }

backend reductrai_back
    balance leastconn
    option httpchk GET /health
    http-check expect status 200

    server proxy1 10.0.1.10:8080 check inter 10s fall 3 rise 2
    server proxy2 10.0.1.11:8080 check inter 10s fall 3 rise 2
    server proxy3 10.0.1.12:8080 check inter 10s fall 3 rise 2
```

### AWS Application Load Balancer

```bash
# Create target group
aws elbv2 create-target-group \
  --name reductrai-proxy \
  --protocol HTTP \
  --port 8080 \
  --vpc-id vpc-12345678 \
  --health-check-path /health \
  --health-check-interval-seconds 10 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3

# Create load balancer
aws elbv2 create-load-balancer \
  --name reductrai-lb \
  --subnets subnet-12345678 subnet-87654321 \
  --security-groups sg-12345678 \
  --scheme internal

# Register targets
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-1234567890abcdef0 Id=i-0fedcba0987654321
```

## 3. Shared Storage Configuration

For HA, all instances must share the same storage backend. See [STORAGE.md](./STORAGE.md) for details.

### AWS S3 (Recommended for AWS deployments)

```yaml
environment:
  - STORAGE_COLD_TYPE=s3
  - S3_BUCKET=reductrai-production
  - S3_REGION=us-east-1
  - S3_ACCESS_KEY=${AWS_ACCESS_KEY_ID}
  - S3_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}
```

### Google Cloud Storage (Recommended for GCP deployments)

```yaml
environment:
  - STORAGE_COLD_TYPE=gcs
  - GCS_BUCKET=reductrai-production
  - GCS_PROJECT_ID=my-project
  - GCS_CREDENTIALS_PATH=/app/config/gcs-credentials.json
volumes:
  - ./gcs-credentials.json:/app/config/gcs-credentials.json:ro
```

### Azure Blob Storage (Recommended for Azure deployments)

```yaml
environment:
  - STORAGE_COLD_TYPE=azure
  - AZURE_STORAGE_ACCOUNT=reductrai
  - AZURE_STORAGE_KEY=${AZURE_STORAGE_KEY}
  - AZURE_CONTAINER=reductrai-cold
```

### NFS Shared Volume (On-premise)

```yaml
volumes:
  reductrai-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=10.0.1.100,rw,nfsvers=4
      device: ":/exports/reductrai"

services:
  proxy:
    volumes:
      - reductrai-data:/app/data
```

## 4. Health Checks & Auto-Recovery

### Health Check Endpoint

```bash
# Health check returns 200 OK if healthy
curl http://localhost:8080/health

# Response
{
  "status": "ok",
  "uptime": 123456,
  "version": "1.0.0",
  "storage": "connected",
  "datadog": "connected"
}
```

### Docker Health Check

```yaml
services:
  proxy:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 40s
```

### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

### External Monitoring

```bash
# Datadog monitoring
datadog:
  http_check:
    instances:
      - name: reductrai_health
        url: http://reductrai.company.com/health
        timeout: 5
        interval: 10
        threshold: 3

# Prometheus monitoring
scrape_configs:
  - job_name: 'reductrai'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['proxy1:8080', 'proxy2:8080', 'proxy3:8080']
```

## 5. Zero-Downtime Updates

### Rolling Update Strategy

#### Docker Swarm

```bash
# Update one instance at a time, wait 10s between
docker service update \
  --image reductrai/proxy:v2.0.0 \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-order start-first \
  reductrai_proxy

# Monitor rollout
docker service ps reductrai_proxy
```

#### Kubernetes

```bash
# Rolling update with zero downtime
kubectl set image deployment/reductrai-proxy \
  proxy=reductrai/proxy:v2.0.0

# Monitor rollout
kubectl rollout status deployment/reductrai-proxy

# Rollback if needed
kubectl rollout undo deployment/reductrai-proxy
```

#### Manual Rolling Update (Docker Compose)

```bash
# Update proxy-1, wait for health, then proceed
docker-compose up -d proxy-1
sleep 30
curl http://localhost:8081/health || exit 1

# Update proxy-2
docker-compose up -d proxy-2
sleep 30
curl http://localhost:8082/health || exit 1

# Update proxy-3
docker-compose up -d proxy-3
sleep 30
curl http://localhost:8083/health || exit 1
```

### Blue-Green Deployment

```bash
# Start new "green" environment
docker-compose -f docker-compose-green.yml up -d

# Verify green environment is healthy
curl http://green-lb:8080/health

# Switch load balancer to green
# (Update nginx/haproxy config)

# Verify traffic flowing correctly
# Monitor for 10 minutes

# Shut down old "blue" environment
docker-compose -f docker-compose-blue.yml down
```

## 6. Monitoring & Alerting

### Key Metrics to Monitor

```yaml
# Prometheus metrics example
reductrai_requests_total
reductrai_requests_errors_total
reductrai_compression_ratio
reductrai_storage_bytes_total
reductrai_datadog_forward_errors_total
reductrai_health_status
```

### Alerting Rules

```yaml
# Prometheus alerting
groups:
  - name: reductrai
    rules:
      - alert: ReductrAIInstanceDown
        expr: up{job="reductrai"} == 0
        for: 1m
        annotations:
          summary: "ReductrAI instance {{ $labels.instance }} is down"

      - alert: ReductrAIHighErrorRate
        expr: rate(reductrai_requests_errors_total[5m]) > 0.05
        for: 5m
        annotations:
          summary: "ReductrAI error rate above 5%"

      - alert: ReductrAIStorageDown
        expr: reductrai_storage_connected == 0
        for: 1m
        annotations:
          summary: "ReductrAI cannot connect to storage backend"
```

### Dashboard Monitoring

Use Grafana or similar to monitor:
- Request throughput per instance
- Error rates
- Compression ratios
- Storage usage
- Health status
- Load balancer distribution

## 7. Disaster Recovery

### Backup Strategy

```bash
# Daily backup of compressed data
0 2 * * * /usr/local/bin/backup-reductrai.sh

# backup-reductrai.sh
#!/bin/bash
aws s3 sync s3://reductrai-production s3://reductrai-backup-$(date +%Y%m%d)
```

### Recovery Procedures

```bash
# 1. Restore from backup
aws s3 sync s3://reductrai-backup-20241019 s3://reductrai-production

# 2. Deploy new instances
kubectl apply -f kubernetes/deployment.yaml

# 3. Verify health
kubectl get pods -l app=reductrai-proxy
curl http://load-balancer/health

# 4. Resume traffic
# (Update load balancer if needed)
```

### Multi-Region Deployment

For ultimate HA, deploy across multiple regions:

```yaml
# Region 1: us-east-1
AWS_REGION=us-east-1
S3_BUCKET=reductrai-us-east-1

# Region 2: us-west-2
AWS_REGION=us-west-2
S3_BUCKET=reductrai-us-west-2

# Use Route53 for DNS failover
# Or deploy with active-active and regional load balancers
```

## 8. Scaling

### Horizontal Scaling

Add more instances when needed:

```bash
# Docker Swarm
docker service scale reductrai_proxy=5

# Kubernetes
kubectl scale deployment reductrai-proxy --replicas=5
```

### Auto-Scaling

#### Kubernetes HPA (Horizontal Pod Autoscaler)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: reductrai-proxy-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: reductrai-proxy
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Scaling

Increase resources per instance:

```yaml
resources:
  limits:
    cpu: "4"      # Increased from 2
    memory: "4Gi" # Increased from 2Gi
  requests:
    cpu: "2"
    memory: "2Gi"
```

## 9. Testing HA Configuration

### Chaos Testing

```bash
# Kill random instance
docker kill reductrai-proxy-1

# Verify:
# - Load balancer detects failure
# - Traffic routes to healthy instances
# - Auto-restart brings instance back up
# - No data loss

# Network partition simulation
iptables -A INPUT -s 10.0.1.10 -j DROP

# Verify graceful degradation
```

### Load Testing

```bash
# Send high volume traffic
hey -z 60s -c 100 -m POST \
  -H "DD-API-KEY: test" \
  -H "Content-Type: application/json" \
  -d '{"series":[{"metric":"test","points":[[1234567890,42]]}]}' \
  http://load-balancer:8080/api/v2/series

# Monitor:
# - Even distribution across instances
# - No instance overwhelmed
# - Consistent response times
# - No errors
```

## HA Best Practices Summary

1. **Run 3+ instances** - Minimum for true HA
2. **Use load balancer** - Nginx, HAProxy, or cloud LB
3. **Shared storage** - S3/GCS/Azure for all instances
4. **Health checks** - Automated failover on failure
5. **Rolling updates** - Zero-downtime deployments
6. **Monitor everything** - Prometheus + Grafana
7. **Alert on issues** - Proactive incident response
8. **Test failover** - Regular chaos testing
9. **Backup regularly** - Automated backups to separate region
10. **Document procedures** - Runbooks for common scenarios

## Additional Resources

- [Security Hardening Guide](./SECURITY.md)
- [Storage Configuration](./STORAGE.md)
- [Build & Publish Guide](./BUILD.md)

## Support

HA deployment questions:
- Documentation: https://docs.reductrai.com/ha
- Enterprise Support: support@reductrai.com (24/7)
- Slack: #reductrai-ha
