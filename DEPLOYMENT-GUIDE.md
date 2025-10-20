# ReductrAI Deployment Guide

**Complete guide to deploying ReductrAI across all platforms and use cases**

---

## Table of Contents

1. [Deployment Decision Guide](#deployment-decision-guide)
2. [All-in-One Container](#1-all-in-one-container-recommended-for-getting-started)
3. [Docker Compose](#2-docker-compose-recommended-for-production)
4. [Standalone Package](#3-standalone-package-recommended-for-development)
5. [Kubernetes/Helm](#4-kuberneteshelm-recommended-for-enterprise)
6. [Migration Paths](#migration-paths)
7. [Comparison Table](#comparison-table)

---

## Deployment Decision Guide

Choose your deployment option based on your use case:

| Use Case | Recommended Option | Why |
|----------|-------------------|-----|
| **Quick demo/trial** | All-in-One Container | Single command, runs in 30 seconds |
| **Development/testing** | Standalone Package | Direct source code access, hot reload |
| **Single server production** | All-in-One Container | Simple, all services included |
| **Multi-server production** | Docker Compose | Independent service scaling |
| **Cloud/Kubernetes** | Helm Chart | Cloud-native, auto-scaling |
| **High availability** | Docker Compose or Helm | Load balancing, redundancy |
| **Air-gapped environments** | Standalone Package | No external dependencies |

---

## 1. All-in-One Container (Recommended for Getting Started)

**Best for:** Demos, quick testing, single-server deployments, simple production

### Features

- **Single container** with all 4 services (proxy, dashboard, AI query, Ollama)
- **Zero configuration** required to start
- **Smallest footprint** for deployment (1.41GB vs separate containers)
- **Supervisord** manages all processes automatically
- **All ports exposed**: 8080 (proxy), 5173 (dashboard), 8081 (AI query), 11434 (Ollama)

### Quick Start

```bash
# Pull image from Docker Hub
docker pull reductrai/reductrai:latest

# Run with minimal configuration
docker run -d \
  --name reductrai \
  -p 8080:8080 -p 5173:5173 -p 8081:8081 -p 11434:11434 \
  -e REDUCTRAI_LICENSE_KEY=RF-DEMO-2025 \
  reductrai/reductrai:latest

# Verify all services are running
curl http://localhost:8080/health    # Proxy
curl http://localhost:5173           # Dashboard
curl http://localhost:8081/health    # AI Query
curl http://localhost:11434/api/tags # Ollama
```

### Production Configuration

```bash
docker run -d \
  --name reductrai \
  -p 8080:8080 -p 5173:5173 -p 8081:8081 -p 11434:11434 \
  -e REDUCTRAI_LICENSE_KEY=your_license_key \
  -e DATADOG_API_KEY=your_datadog_key \
  -e DATADOG_ENDPOINT=https://api.datadoghq.com \
  -e FORWARD_TO=https://api.datadoghq.com \
  -e REDUCTRAI_COMPRESSION=true \
  -e REDUCTRAI_COMPRESSION_LEVEL=heavy \
  -e PROXY_MODE=sample \
  -e SAMPLE_RATE=0.1 \
  -v reductrai-data:/app/data \
  -v ollama-models:/root/.ollama \
  --restart unless-stopped \
  reductrai/reductrai:latest
```

### Health Checks

```bash
# Check all services
docker exec reductrai supervisorctl status

# Expected output:
# proxy                            RUNNING   pid 12, uptime 0:01:23
# dashboard                        RUNNING   pid 13, uptime 0:01:23
# ai-query                         RUNNING   pid 14, uptime 0:01:23
# ollama                           RUNNING   pid 15, uptime 0:01:23

# View logs
docker logs -f reductrai
```

### Pros & Cons

✅ **Pros:**
- Fastest to deploy (1 command)
- Simplest management (1 container)
- Guaranteed service compatibility
- Lower resource overhead (shared base image)
- Perfect for demos and POCs

❌ **Cons:**
- Cannot scale services independently
- All services restart together
- Larger image size (1.41GB)
- Less flexible for complex deployments

---

## 2. Docker Compose (Recommended for Production)

**Best for:** Production deployments, multi-server setups, independent service scaling

### Features

- **Independent services** - Scale proxy separately from dashboard
- **Flexible networking** - Services communicate via Docker network
- **Separate resources** - Dedicated CPU/memory per service
- **Easy updates** - Update one service without affecting others
- **Production-ready** - Health checks, restart policies, volumes

### Quick Start

```bash
# Clone repository
git clone https://github.com/reductrai/reductrai-docker.git
cd reductrai-docker

# Configure environment
cp .env.example .env
nano .env  # Add your license and API keys

# Start all services
docker-compose up -d

# Verify services
docker-compose ps
```

### Production docker-compose.yml

```yaml
version: '3.8'

services:
  proxy:
    image: reductrai/proxy:latest
    container_name: reductrai-proxy
    ports:
      - "8080:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY}
      - NODE_ENV=production
      - REDUCTRAI_COMPRESSION=true
      - REDUCTRAI_COMPRESSION_LEVEL=heavy
      - PROXY_MODE=sample
      - SAMPLE_RATE=0.1
      - DATADOG_API_KEY=${DATADOG_API_KEY}
      - DATADOG_ENDPOINT=${DATADOG_ENDPOINT:-https://api.datadoghq.com}
      - FORWARD_TO=https://api.datadoghq.com
      - LOCAL_LLM_ENDPOINT=http://ai-query:8081
    volumes:
      - reductrai-data:/app/data
    networks:
      - reductrai
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  dashboard:
    image: reductrai/dashboard:latest
    container_name: reductrai-dashboard
    ports:
      - "5173:80"
    environment:
      - VITE_API_URL=http://proxy:8080
    depends_on:
      - proxy
    networks:
      - reductrai
    restart: unless-stopped

  ollama:
    image: ollama/ollama:latest
    container_name: reductrai-ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    networks:
      - reductrai
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

  ai-query:
    image: reductrai/ai-query:latest
    container_name: reductrai-ai-query
    ports:
      - "8081:8081"
    environment:
      - OLLAMA_HOST=http://ollama:11434
      - AI_MODEL=${AI_MODEL:-mistral}
      - AI_QUERY_PORT=8081
    volumes:
      - ai-models:/models
      - reductrai-data:/app/data
    networks:
      - reductrai
    depends_on:
      - ollama
    restart: unless-stopped

networks:
  reductrai:
    driver: bridge

volumes:
  reductrai-data:
    driver: local
  ai-models:
    driver: local
  ollama-data:
    driver: local
```

### Environment Variables (.env)

```bash
# ReductrAI License (Required)
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025

# Datadog Integration (Optional)
DATADOG_API_KEY=your_datadog_api_key
DATADOG_ENDPOINT=https://api.datadoghq.com

# New Relic Integration (Optional)
NEW_RELIC_API_KEY=your_newrelic_key

# Prometheus Integration (Optional)
PROMETHEUS_ENDPOINT=http://prometheus:9090

# OTLP Integration (Optional)
OTLP_ENDPOINT=http://jaeger:4318

# AI Model Configuration (Optional)
AI_MODEL=mistral
```

### Service Management

```bash
# Start services
docker-compose up -d

# Start specific service
docker-compose up -d proxy

# Stop all services
docker-compose down

# View logs
docker-compose logs -f proxy

# Scale services (requires load balancer)
docker-compose up -d --scale proxy=3

# Update service
docker-compose pull proxy
docker-compose up -d proxy

# Restart service
docker-compose restart proxy
```

### Monitoring

```bash
# Check service health
docker-compose ps

# View resource usage
docker stats

# View logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f proxy
docker-compose logs -f dashboard
docker-compose logs -f ai-query
docker-compose logs -f ollama
```

### Pros & Cons

✅ **Pros:**
- Independent service scaling
- Update services without downtime
- Better resource allocation
- Production-grade orchestration
- Easy backup/restore (volumes)

❌ **Cons:**
- Requires Docker Compose knowledge
- More complex configuration
- Separate images to pull (total ~2.4GB)
- Need to manage service dependencies

---

## 3. Standalone Package (Recommended for Development)

**Best for:** Development, debugging, source code access, air-gapped environments

### Features

- **Direct source code access** - Modify and test immediately
- **No Docker required** - Run directly on host machine
- **Hot reload** - Changes reflect instantly
- **Full debugging** - Attach debugger to any service
- **Air-gapped compatible** - No external dependencies
- **Development tools** - TypeScript, linting, testing built-in

### System Requirements

- **Node.js**: 20.x or higher
- **npm**: 10.x or higher
- **Ollama** (optional): For AI query features
- **OS**: macOS, Linux, or Windows (WSL2)
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 2GB free space

### Installation

```bash
# Clone monorepo
git clone https://github.com/reductrai/reductrai.git
cd reductrai

# Install dependencies for each service
cd reductrai-proxy && npm install && cd ..
cd reductrai-dashboard && npm install && cd ..
cd reductrai-ai-query && npm install && cd ..
cd reductrai-core && npm install && cd ..

# Or use installation script
./install-all.sh
```

### Running Services

#### Option 1: Run All Services Together

```bash
# From reductrai-proxy directory
cd reductrai-proxy
npm run dev:all

# This starts:
# - Proxy on port 8080
# - Dashboard on port 5173
# Both with hot reload enabled
```

#### Option 2: Run Services Independently

```bash
# Terminal 1: Proxy
cd reductrai-proxy
npm run proxy:dev

# Terminal 2: Dashboard
cd reductrai-dashboard
npm run dev

# Terminal 3: AI Query (optional)
cd reductrai-ai-query
npm run dev

# Terminal 4: Ollama (optional)
ollama serve
```

### Configuration

Create `.env` file in each service directory:

**reductrai-proxy/.env**
```bash
REDUCTRAI_PORT=8080
REDUCTRAI_HOST=0.0.0.0
REDUCTRAI_COMPRESSION=true
REDUCTRAI_COMPRESSION_LEVEL=heavy
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025

# Backend forwarding
DATADOG_API_KEY=your_key
DATADOG_ENDPOINT=https://api.datadoghq.com
FORWARD_TO=https://api.datadoghq.com

# LLM endpoint
LOCAL_LLM_ENDPOINT=http://localhost:8081
```

**reductrai-dashboard/.env**
```bash
VITE_API_URL=http://localhost:8080
```

**reductrai-ai-query/.env**
```bash
AI_QUERY_PORT=8081
OLLAMA_HOST=http://localhost:11434
AI_MODEL=mistral
```

### Development Workflow

```bash
# Make changes to TypeScript files
nano reductrai-proxy/apps/proxy/src/index.ts

# Changes auto-reload (if using dev mode)
# Or manually restart:
npm run proxy:dev

# Run tests
npm test

# Run specific test suite
npm run test:unit
npm run test:integration
npm run test:compression

# Build for production
npm run build

# Run production build
NODE_ENV=production npm run proxy
```

### Debugging

```bash
# Run with debug logging
DEBUG=* npm run proxy:dev

# Run with Node debugger
node --inspect apps/proxy/src/index.ts

# Attach VS Code debugger
# Add to .vscode/launch.json:
{
  "type": "node",
  "request": "launch",
  "name": "Debug Proxy",
  "program": "${workspaceFolder}/apps/proxy/src/index.ts",
  "preLaunchTask": "tsc: build - tsconfig.json",
  "outFiles": ["${workspaceFolder}/dist/**/*.js"]
}
```

### Building Standalone Package

```bash
# Build all services
cd reductrai-proxy && npm run build
cd reductrai-dashboard && npm run build
cd reductrai-ai-query && npm run build

# Create distribution package
./package-standalone.sh

# This creates:
# reductrai-standalone-v1.0.0.tar.gz
# - All compiled services
# - Node.js runtime (optional)
# - Configuration templates
# - Start/stop scripts
```

### Distribution Package Structure

```
reductrai-standalone-v1.0.0/
├── bin/
│   ├── start.sh              # Start all services
│   ├── stop.sh               # Stop all services
│   ├── proxy.sh              # Start proxy only
│   ├── dashboard.sh          # Start dashboard only
│   └── ai-query.sh           # Start AI query only
├── proxy/                    # Proxy service (compiled)
├── dashboard/                # Dashboard build
├── ai-query/                 # AI Query service (compiled)
├── config/
│   ├── .env.example
│   └── README.md
├── data/                     # Data directory
├── logs/                     # Log directory
└── README.md                 # Installation instructions
```

### Installing Standalone Package

```bash
# Extract package
tar -xzf reductrai-standalone-v1.0.0.tar.gz
cd reductrai-standalone-v1.0.0

# Configure
cp config/.env.example .env
nano .env  # Add your license key

# Start all services
./bin/start.sh

# Or start specific service
./bin/proxy.sh

# Stop all services
./bin/stop.sh
```

### Pros & Cons

✅ **Pros:**
- Full source code access
- Hot reload for development
- No Docker dependency
- Easiest debugging
- Air-gapped compatible
- Smallest resource footprint
- Direct performance profiling

❌ **Cons:**
- Requires Node.js installation
- Manual service management
- No automatic restarts
- Manual dependency updates
- Platform-specific setup

---

## 4. Kubernetes/Helm (Recommended for Enterprise)

**Best for:** Cloud deployments, auto-scaling, high availability, enterprise production

### Features

- **Auto-scaling** - HorizontalPodAutoscaler for traffic spikes
- **High availability** - Multiple replicas with load balancing
- **Rolling updates** - Zero-downtime deployments
- **Health monitoring** - Kubernetes-native health checks
- **Resource limits** - CPU/memory quotas
- **Cloud-native** - Works with EKS, GKE, AKS, etc.

### Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x installed
- kubectl configured

### Quick Start

```bash
# Add Helm repository
helm repo add reductrai https://charts.reductrai.com
helm repo update

# Install with default values
helm install reductrai reductrai/reductrai \
  --namespace reductrai \
  --create-namespace \
  --set license.key=RF-DEMO-2025

# Or install from local chart
cd reductrai-helm
helm install reductrai ./charts/reductrai \
  --namespace reductrai \
  --create-namespace \
  --set license.key=RF-DEMO-2025
```

### Production Installation

```bash
# Create values file
cat > production-values.yaml <<EOF
# License
license:
  key: "your_license_key"

# Proxy configuration
proxy:
  replicas: 3
  image:
    repository: reductrai/proxy
    tag: latest
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 2Gi
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

# Dashboard configuration
dashboard:
  replicas: 2
  image:
    repository: reductrai/dashboard
    tag: latest

# AI Query configuration
aiQuery:
  replicas: 2
  image:
    repository: reductrai/ai-query
    tag: latest

# Storage
storage:
  enabled: true
  size: 100Gi
  storageClass: "fast-ssd"

# Backends
backends:
  datadog:
    enabled: true
    apiKey: "your_datadog_key"
    endpoint: "https://api.datadoghq.com"

# Ingress
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: reductrai.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: reductrai-tls
      hosts:
        - reductrai.example.com
EOF

# Install with custom values
helm install reductrai reductrai/reductrai \
  --namespace reductrai \
  --create-namespace \
  -f production-values.yaml
```

### Managing Deployment

```bash
# Check deployment status
kubectl get all -n reductrai

# View pods
kubectl get pods -n reductrai

# View logs
kubectl logs -n reductrai deployment/reductrai-proxy -f

# Check service endpoints
kubectl get svc -n reductrai

# Check persistent volumes
kubectl get pvc -n reductrai

# Scale deployment
kubectl scale deployment/reductrai-proxy --replicas=5 -n reductrai

# Update configuration
helm upgrade reductrai reductrai/reductrai \
  --namespace reductrai \
  -f production-values.yaml
```

### Monitoring

```bash
# View pod metrics
kubectl top pods -n reductrai

# View resource usage
kubectl describe pod -n reductrai reductrai-proxy-xxxxx

# Check autoscaler status
kubectl get hpa -n reductrai

# View events
kubectl get events -n reductrai --sort-by='.lastTimestamp'
```

### Uninstall

```bash
# Uninstall Helm release
helm uninstall reductrai -n reductrai

# Delete namespace (including PVCs)
kubectl delete namespace reductrai
```

### Current Status

⚠️ **Helm charts are partially complete**. See `/Users/jessiehermosillo/Apiflow/reductrai-helm/TODO.md` for details.

**Complete:**
- Chart.yaml
- values.yaml
- _helpers.tpl
- deployment-proxy.yaml

**Missing:**
- Service templates (proxy, dashboard, ai-query)
- Deployment templates (dashboard, ai-query)
- Secret templates (license, backends)
- PVC template
- HPA templates
- Ingress template
- RBAC templates

**Estimated completion time:** 4-6 hours

### Pros & Cons

✅ **Pros:**
- Enterprise-grade high availability
- Auto-scaling for traffic spikes
- Zero-downtime updates
- Cloud-native monitoring
- Multi-region deployments
- Kubernetes ecosystem integration

❌ **Cons:**
- Most complex setup
- Requires Kubernetes expertise
- Higher infrastructure costs
- Helm charts incomplete (as of now)

---

## Migration Paths

### From All-in-One to Docker Compose

```bash
# 1. Backup data from all-in-one
docker cp reductrai:/app/data ./backup-data

# 2. Stop all-in-one
docker stop reductrai
docker rm reductrai

# 3. Start Docker Compose
cd reductrai-docker
docker-compose up -d

# 4. Restore data
docker cp ./backup-data/. reductrai-proxy:/app/data
```

### From Docker Compose to Kubernetes

```bash
# 1. Backup data
docker-compose exec proxy tar -czf /app/data-backup.tar.gz /app/data

# 2. Copy backup
docker cp reductrai-proxy:/app/data-backup.tar.gz ./

# 3. Deploy to Kubernetes
helm install reductrai reductrai/reductrai \
  --namespace reductrai \
  --create-namespace \
  -f production-values.yaml

# 4. Restore data
kubectl cp data-backup.tar.gz reductrai/reductrai-proxy-xxxxx:/app/
kubectl exec -n reductrai reductrai-proxy-xxxxx -- tar -xzf /app/data-backup.tar.gz
```

### From Standalone to Docker

```bash
# 1. Stop standalone services
./bin/stop.sh

# 2. Backup data
tar -czf data-backup.tar.gz data/

# 3. Build custom Docker image (optional)
docker build -t reductrai/proxy:custom -f dockerfiles/Dockerfile.proxy .

# 4. Run container
docker run -d \
  --name reductrai \
  -v $(pwd)/data:/app/data \
  reductrai/reductrai:latest
```

---

## Comparison Table

| Feature | All-in-One | Docker Compose | Standalone | Kubernetes |
|---------|-----------|----------------|------------|------------|
| **Setup Time** | 1 min | 5 min | 10 min | 30 min |
| **Complexity** | ⭐ Simple | ⭐⭐ Moderate | ⭐⭐ Moderate | ⭐⭐⭐⭐ Complex |
| **Scaling** | ❌ No | ✅ Manual | ❌ No | ✅ Auto |
| **High Availability** | ❌ No | ⚠️ Limited | ❌ No | ✅ Yes |
| **Development** | ⚠️ OK | ⚠️ OK | ✅ Excellent | ❌ No |
| **Production** | ✅ Simple prod | ✅ Multi-server | ⚠️ Small scale | ✅ Enterprise |
| **Resource Usage** | Low | Medium | Lowest | High |
| **Update Flexibility** | Low | High | Highest | High |
| **Air-gapped** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Complex |
| **Cost** | Lowest | Low | Lowest | Highest |
| **Monitoring** | Basic | Good | Manual | Excellent |

---

## Best Practices

### Security

- **Never commit** `.env` files with real API keys
- Use **secrets management** (Kubernetes secrets, Docker secrets, HashiCorp Vault)
- **Rotate license keys** quarterly
- **Enable TLS** for all external endpoints
- **Restrict network access** to required ports only
- **Regular updates** - pull latest images weekly

### Performance

- **Monitor resource usage** - Set CPU/memory limits
- **Use persistent volumes** - Never lose compression data
- **Enable compression** - Set `REDUCTRAI_COMPRESSION=true`
- **Tune compression level** - `light` for speed, `heavy` for ratio
- **Adjust sample rate** - 0.1 = 90% cost savings, 0.2 = 80% savings

### Reliability

- **Health checks** - Always configure healthcheck endpoints
- **Restart policies** - Use `unless-stopped` or `always`
- **Backup data** - Regular backups of `/app/data` volume
- **Log rotation** - Configure log limits to prevent disk fill
- **Monitor forwarding** - Alert if forward rate drops below threshold

---

## Support

- **Documentation**: https://docs.reductrai.com
- **GitHub Issues**: https://github.com/reductrai/reductrai/issues
- **Email**: support@reductrai.com
- **Enterprise Support**: enterprise@reductrai.com

---

**Last Updated**: 2025-10-20
**Version**: 1.0.0
