# ReductrAI Storage Configuration Guide

**ReductrAI is intelligent middleware, not infrastructure.** You provide the compute and storage, we provide the compression algorithms, tiered storage management, and AI-powered queries.

---

## Table of Contents

1. [Understanding ReductrAI's Role](#understanding-reductrai-role)
2. [Storage Architecture](#storage-architecture)
3. [Tiered Storage Strategy](#tiered-storage-strategy)
4. [Supported Storage Backends](#supported-storage-backends)
5. [Configuration Examples](#configuration-examples)
6. [Cost Optimization](#cost-optimization)
7. [Best Practices](#best-practices)

---

## Understanding ReductrAI's Role

**IMPORTANT**: ReductrAI does NOT replace your monitoring service. Instead, it sits between your applications and your existing monitoring service (Datadog, New Relic, etc.) to reduce costs while improving visibility.

### The ReductrAI Value Proposition

**Problem**: Monitoring services charge based on data volume. More metrics = higher bills.

**Traditional Solution (Sampling)**: Send only 10% of data → Save 90% on costs, but LOSE 90% of visibility.

**ReductrAI Solution (Dual-Path Architecture)**:
1. Store 100% of data locally (compressed, AI-queryable)
2. Forward only 10% to monitoring service (cost savings)
3. Result: FULL visibility + 90% cost reduction

### Required Components for Production

To use ReductrAI in production, you need BOTH:

1. **Backend Monitoring Service** (REQUIRED) - Datadog, New Relic, Prometheus, etc.
   - You must configure credentials in `.env` (DATADOG_API_KEY, etc.)
   - ReductrAI forwards 10% sample here
   - Your existing dashboards and alerts continue to work
   - Cost: 90% LESS than current bills

2. **Local Storage** (REQUIRED) - Your infrastructure for 100% data retention
   - Configure tiered storage (hot/warm/cold) based on your needs
   - Options: Local disk, AWS S3, GCS, Azure, Redis, PostgreSQL, MinIO
   - Cost: ~$24/month for 1TB/year (vs $3,000/month for monitoring service)

**Together**: You get better observability at 10% of the cost.

---

## Storage Architecture

### How ReductrAI Works

```
Your Application
      ↓
ReductrAI Proxy (runs on YOUR infrastructure)
      ↓
      ├─────────────────────────┐
      │                         │
LOCAL STORAGE              FORWARD 10%
(Your disk/S3)            (To Datadog/NewRelic/etc - REQUIRED)
100% of data              Sampled data
Compressed 89%            Original format
AI-queryable              Dashboard/Alerts
$24/month                 $1,000/month (down from $10,000)
```

### Key Principles

1. **ReductrAI is middleware** - Sits between your apps and monitoring service
2. **You need BOTH components**:
   - Backend service (Datadog/NewRelic) - receives 10% sample for dashboards
   - Local storage (your infrastructure) - stores 100% for AI queries
3. **You own the infrastructure** - ReductrAI runs on your servers/k8s/Docker
4. **You provide the storage** - Local disk, EBS volumes, S3 buckets, etc.
5. **We manage efficiency** - Compression, tiering, retention, AI queries

**Analogy**: This is like running PostgreSQL - we're the database software, you provide the hardware. But unlike a database, you ALSO need a backend monitoring service configured (this is what makes the cost savings possible).

---

## Tiered Storage Strategy

**What is Tiered Storage For?**

Tiered storage manages the **100% local copy** of your data. It does NOT replace the backend monitoring service - both work together:

- **Backend Service** (Datadog/NewRelic) → Receives 10% sample for dashboards/alerts
- **Tiered Local Storage** → Stores 100% for AI queries and compliance

ReductrAI implements a three-tier storage system similar to major observability platforms:

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCOMING DATA (100%)                          │
│                  All Observability Signals                       │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│  🔥 HOT STORAGE (Last 7 days)                                   │
│  • Fast SSD storage                                              │
│  • Full-resolution data (no aggregation)                         │
│  • Instant query access (<100ms)                                 │
│  • Path: /app/data/hot                                           │
│  • Size: ~100GB for 1M metrics/day                              │
└─────────────┬───────────────────────────────────────────────────┘
              │ Auto-migration after 7 days
              ▼
┌─────────────────────────────────────────────────────────────────┐
│  🌡️  WARM STORAGE (8-30 days)                                    │
│  • Standard disk storage                                         │
│  • 5-minute aggregation                                          │
│  • Query latency: ~1-2 seconds                                   │
│  • Path: /app/data/warm                                          │
│  • Size: ~20GB (80% smaller than hot)                           │
└─────────────┬───────────────────────────────────────────────────┘
              │ Auto-migration after 30 days
              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ❄️  COLD STORAGE (31-365 days)                                  │
│  • S3/Object storage or local archive                            │
│  • 1-hour aggregation + zstd compression                         │
│  • Query latency: ~5-10 seconds                                  │
│  • Path: /app/data/cold or S3                                    │
│  • Size: ~2GB (98% smaller than hot)                            │
└─────────────┬───────────────────────────────────────────────────┘
              │ Auto-cleanup after 365 days
              ▼
           DELETED
```

### Data Lifecycle Example

```
Day 0:   New metric arrives → Stored in HOT (full resolution)
Day 7:   Metric migrated → WARM (5-min aggregation)
Day 30:  Metric migrated → COLD (1-hr aggregation + compression)
Day 365: Metric deleted → Space freed
```

### Storage Requirements

For **1 million metrics per day**:

| Tier | Duration | Storage Size | Total |
|------|----------|--------------|-------|
| Hot | 7 days | ~14GB/day | ~100GB |
| Warm | 23 days | ~3GB/day | ~70GB |
| Cold | 335 days | ~0.5GB/day | ~170GB |
| **TOTAL** | **365 days** | | **~340GB** |

Compare to uncompressed: **5TB+** (93% savings!)

---

## Supported Storage Backends

ReductrAI supports all major cloud storage providers and databases:

| Backend | Type | Best For | Cost Estimate | Speed |
|---------|------|----------|---------------|-------|
| **Local** | Filesystem | Development, single-server | Free (your disk) | ⚡⚡⚡ |
| **AWS S3** | Object Storage | Production, multi-region | ~$0.023/GB/month | ⚡ |
| **GCS** | Object Storage | Google Cloud native | ~$0.020/GB/month | ⚡ |
| **Azure Blob** | Object Storage | Microsoft Azure native | ~$0.018/GB/month | ⚡ |
| **Redis** | In-Memory | Ultra-fast cold tier | ~$0.10/GB/month | ⚡⚡⚡ |
| **PostgreSQL** | SQL Database | Queryable archive | Variable | ⚡⚡ |
| **MinIO** | S3-Compatible | Self-hosted, air-gapped | Free (your hardware) | ⚡⚡ |
| **DigitalOcean Spaces** | S3-Compatible | Simpler S3 alternative | $5/250GB/month | ⚡ |
| **Wasabi** | S3-Compatible | Cheap S3 alternative | $5.99/TB/month | ⚡ |

### Backend Selection Guide

**Choose Local if:**
- Development/testing environment
- Single-server deployment
- Small data volume (<100GB)
- No external dependencies wanted

**Choose S3/GCS/Azure if:**
- Production environment
- Need durability and backups
- Multi-region deployment
- Large data volume (TB+)

**Choose Redis if:**
- Need fast queries on "cold" data
- Have existing Redis cluster
- Want TTL-based expiration

**Choose PostgreSQL if:**
- Need SQL queries on archived data
- Want ACID guarantees
- Existing PostgreSQL infrastructure

**Choose MinIO if:**
- Air-gapped environment
- On-premises data center
- S3 compatibility required
- No cloud connectivity

---

## Configuration Examples

### Basic Configuration (Local Storage Only)

**Recommended for:** Development, testing, small deployments

```bash
# .env
STORAGE_HOT_ENABLED=true
STORAGE_HOT_RETENTION_DAYS=7
STORAGE_HOT_PATH=/app/data/hot

STORAGE_WARM_ENABLED=true
STORAGE_WARM_RETENTION_DAYS=30
STORAGE_WARM_PATH=/app/data/warm
STORAGE_WARM_AGGREGATION=5m

STORAGE_COLD_ENABLED=true
STORAGE_COLD_RETENTION_DAYS=365
STORAGE_COLD_PATH=/app/data/cold
STORAGE_COLD_AGGREGATION=1h
STORAGE_COLD_TYPE=local
```

**Storage needed:** ~340GB for 1M metrics/day over 1 year

---

### Production Configuration (AWS S3 Cold Tier)

**Recommended for:** Production, multi-server, enterprise

```bash
# .env
# Backend monitoring service (REQUIRED - this is where cost savings come from)
DATADOG_API_KEY=your_datadog_api_key_here
DATADOG_ENDPOINT=https://api.datadoghq.com

# Hot tier: Local SSD
STORAGE_HOT_ENABLED=true
STORAGE_HOT_RETENTION_DAYS=7
STORAGE_HOT_PATH=/app/data/hot

# Warm tier: Local HDD
STORAGE_WARM_ENABLED=true
STORAGE_WARM_RETENTION_DAYS=30
STORAGE_WARM_PATH=/app/data/warm
STORAGE_WARM_AGGREGATION=5m

# Cold tier: AWS S3
STORAGE_COLD_ENABLED=true
STORAGE_COLD_RETENTION_DAYS=365
STORAGE_COLD_TYPE=s3
S3_BUCKET=my-company-reductrai-archive
S3_REGION=us-east-1
S3_ACCESS_KEY=AKIA...
S3_SECRET_KEY=...
```

**Complete cost breakdown (for 1M metrics/day):**

| Component | Monthly Cost | What You Get |
|-----------|-------------|--------------|
| **ReductrAI Storage** | | |
| - Local (hot+warm) | ~$20 | 100% data, instant queries |
| - S3 (cold) | ~$4 | Long-term compliance |
| **Datadog (10% sample)** | ~$1,000 | Dashboards, alerts (same as before) |
| **TOTAL** | **~$1,024/month** | Full observability |

**Compare to Datadog alone (100% data):** ~$10,000/month

**Your savings:** ~$9,000/month (90% reduction)

---

### Google Cloud Storage Configuration

```bash
# .env
STORAGE_COLD_TYPE=gcs
GCS_BUCKET=my-company-observability
GCS_PROJECT_ID=my-project-12345
GCS_CREDENTIALS_PATH=/app/config/gcs-credentials.json
```

**Note:** Mount your service account JSON:

```yaml
# docker-compose.yml
volumes:
  - ./gcs-credentials.json:/app/config/gcs-credentials.json:ro
```

---

### Azure Blob Storage Configuration

```bash
# .env
STORAGE_COLD_TYPE=azure
AZURE_STORAGE_ACCOUNT=mycompanystorage
AZURE_STORAGE_KEY=abcdef1234567890...
AZURE_CONTAINER=reductrai-cold
```

---

### Redis Configuration (Fast Cold Tier)

**Use case:** When you need sub-second queries even on "cold" data

```bash
# .env
STORAGE_COLD_TYPE=redis
REDIS_HOST=redis.company.com
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
REDIS_DB=0
REDIS_TTL_DAYS=365
```

**Benefits:**
- Sub-second query times on archived data
- Built-in TTL expiration
- Good for high-cardinality data

**Drawbacks:**
- Higher cost (~$0.10/GB vs $0.02/GB for S3)
- Memory-based (limited capacity)

---

### PostgreSQL Configuration (Queryable Archive)

**Use case:** When you want SQL analytics on archived data

```bash
# .env
STORAGE_COLD_TYPE=postgres
POSTGRES_HOST=postgres.company.com
POSTGRES_PORT=5432
POSTGRES_DB=reductrai
POSTGRES_USER=reductrai_user
POSTGRES_PASSWORD=secure_password
POSTGRES_SCHEMA=cold_storage
```

**Benefits:**
- Standard SQL queries
- ACID guarantees
- Easy integration with BI tools

**Queries like:**
```sql
SELECT metric_name, AVG(value)
FROM cold_storage.metrics
WHERE timestamp > NOW() - INTERVAL '90 days'
GROUP BY metric_name;
```

---

### MinIO Configuration (Self-Hosted S3)

**Use case:** Air-gapped environments, on-premises

```bash
# .env
STORAGE_COLD_TYPE=s3
S3_BUCKET=reductrai-cold
S3_REGION=us-east-1
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_ENDPOINT=http://minio:9000
```

**docker-compose.yml addition:**

```yaml
services:
  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER=minioadmin
      - MINIO_ROOT_PASSWORD=minioadmin
    volumes:
      - minio-data:/data
```

---

### Cost-Optimized Configuration (Short Retention)

**Recommended for:** Startups, cost-conscious deployments

```bash
# .env
# Only 3 days of hot data
STORAGE_HOT_ENABLED=true
STORAGE_HOT_RETENTION_DAYS=3

# Only 14 days of warm data
STORAGE_WARM_ENABLED=true
STORAGE_WARM_RETENTION_DAYS=14

# No cold storage
STORAGE_COLD_ENABLED=false
```

**Storage needed:** ~50GB for 1M metrics/day

---

## Cost Optimization

### Complete Cost Comparison (ReductrAI vs Traditional)

For **1TB of observability data per year**, here's the complete picture:

#### Traditional Approach (Datadog only, 100% data)
- Datadog: ~$10,000/month
- **Total: $10,000/month**

#### ReductrAI Approach (Dual-path: 100% local + 10% forwarded)
- ReductrAI storage (100% local): ~$24/month
- Datadog (10% sample): ~$1,000/month
- **Total: $1,024/month** (90% savings!)

### ReductrAI Storage Cost Breakdown by Backend

**Local Storage Tiers** (required for all deployments):

| Tier | Local SSD | AWS S3 | S3 Glacier | Redis | PostgreSQL |
|------|-----------|--------|------------|-------|------------|
| Hot (7d) | ~$100/mo | N/A | N/A | ~$100/mo | ~$50/mo |
| Warm (30d) | ~$50/mo | $23/mo | N/A | ~$100/mo | ~$50/mo |
| Cold (365d) | ~$30/mo | $23/mo | $4/mo | ~$100/mo | ~$50/mo |

**Backend Monitoring Service** (REQUIRED):
- Datadog/NewRelic (10% sample): ~$1,000/month (down from $10,000)

### Typical Enterprise Setup

```
🔥 HOT (7 days)     → Local NVMe SSD       (fast, expensive)
🌡️ WARM (30 days)   → Local SATA SSD      (medium speed/cost)
❄️  COLD (365 days) → AWS S3 Glacier Deep (slow, very cheap)
📊 BACKEND         → Datadog (10% sample, dashboards)
```

**Complete monthly costs for 10TB/year:**

| Component | Cost | Details |
|-----------|------|---------|
| **ReductrAI Local Storage** | | |
| - Hot (7 days) | $105 | 70GB × $1.50/GB |
| - Warm (30 days) | $105 | 210GB × $0.50/GB |
| - Cold (365 days) | $13 | 3.3TB × $0.004/GB |
| **Backend (Datadog 10%)** | $3,000 | Down from $30,000 |
| **TOTAL** | **$3,223/month** | Full observability |

**Compare to Datadog alone:** ~$30,000/month for same 10TB

**Your savings:** ~$27,000/month (90% reduction)

### Cost Reduction Strategies

1. **Shorter Hot Tier** - Reduce hot retention to 3 days
   - Saves: ~57% on hot storage costs

2. **Disable Warm Tier** - Go directly from hot to cold
   - Saves: ~$105/month (in example above)

3. **Use S3 Glacier Deep Archive** - For rarely accessed data
   - Saves: ~80% compared to S3 Standard

4. **Aggressive Aggregation** - Use 15-min warm, 6-hour cold
   - Saves: ~50% on warm/cold storage size

---

## Best Practices

### 1. Choose the Right Backend per Tier

```bash
# Optimal configuration for most enterprises:
STORAGE_HOT_PATH=/mnt/nvme/reductrai/hot        # Fast local SSD
STORAGE_WARM_PATH=/mnt/sata/reductrai/warm      # Slower local disk
STORAGE_COLD_TYPE=s3                             # Cheap object storage
```

### 2. Set Appropriate Retention

```bash
# Match your SLA requirements:
STORAGE_HOT_RETENTION_DAYS=7     # Active debugging
STORAGE_WARM_RETENTION_DAYS=30   # Weekly reviews
STORAGE_COLD_RETENTION_DAYS=365  # Compliance/audit
```

### 3. Monitor Storage Usage

```bash
# Check storage consumption
docker exec reductrai-proxy du -sh /app/data/*

# Monitor per tier
docker exec reductrai-proxy du -sh /app/data/hot
docker exec reductrai-proxy du -sh /app/data/warm
docker exec reductrai-proxy du -sh /app/data/cold
```

### 4. Configure Cleanup

```bash
# Enable automatic cleanup
AUTO_CLEANUP_ENABLED=true
CLEANUP_SCHEDULE=0 2 * * *  # Daily at 2 AM
```

### 5. Use Compression Wisely

```bash
# Heavy compression for cold tier (slower write, better ratio)
COLD_COMPRESSION_ALGORITHM=zstd
COLD_COMPRESSION_LEVEL=9  # Maximum compression

# Faster compression for hot tier (if needed)
# This is configured in the proxy code
```

### 6. Backup Important Data

Even though you control the storage, always backup:

```bash
# S3 versioning
aws s3api put-bucket-versioning \
  --bucket my-company-reductrai-archive \
  --versioning-configuration Status=Enabled

# Or use lifecycle policies for secondary backup
```

### 7. Test Disaster Recovery

```bash
# Periodically test restoration
# 1. Stop proxy
docker-compose down

# 2. Delete local data
rm -rf ./data/*

# 3. Restore from S3/backup
aws s3 sync s3://my-bucket/cold ./data/cold

# 4. Restart proxy
docker-compose up -d
```

---

## Troubleshooting

### "Out of disk space" errors

```bash
# Check usage
df -h /app/data

# Manually trigger cleanup
docker exec reductrai-proxy curl -X POST http://localhost:8080/api/storage/cleanup

# Or reduce retention
STORAGE_HOT_RETENTION_DAYS=3  # Down from 7
STORAGE_WARM_RETENTION_DAYS=14  # Down from 30
```

### S3 connection errors

```bash
# Verify credentials
aws s3 ls s3://my-bucket --profile your-profile

# Check proxy logs
docker logs reductrai-proxy | grep S3

# Test endpoint
docker exec reductrai-proxy curl -v https://s3.amazonaws.com
```

### Slow queries on cold storage

```bash
# Consider switching to Redis for faster cold tier
STORAGE_COLD_TYPE=redis
REDIS_HOST=redis.company.com

# Or reduce cold data aggregation
STORAGE_COLD_AGGREGATION=30m  # Down from 1h
```

---

## Migration Guide

### Migrating from Local to S3

1. **Configure S3 settings** in `.env`:
   ```bash
   STORAGE_COLD_TYPE=s3
   S3_BUCKET=my-bucket
   S3_REGION=us-east-1
   S3_ACCESS_KEY=...
   S3_SECRET_KEY=...
   ```

2. **Restart proxy** - It will start using S3 for new cold data

3. **Migrate existing data** (optional):
   ```bash
   # Copy existing cold data to S3
   docker exec reductrai-proxy \
     aws s3 sync /app/data/cold s3://my-bucket/cold
   ```

4. **Clean up local** (after verifying):
   ```bash
   docker exec reductrai-proxy rm -rf /app/data/cold/*
   ```

---

## Summary

**Key Takeaways:**

✅ **ReductrAI is middleware** - Sits between your apps and monitoring service (NOT a replacement)
✅ **Backend credentials REQUIRED** - Datadog/NewRelic API keys needed to demonstrate cost savings
✅ **Dual-path architecture** - 100% local storage + 10% forwarded to backend
✅ **Complete cost picture** - ReductrAI storage ($24/mo) + Backend service (90% less)
✅ **Three-tier storage** - Hot (fast), warm (medium), cold (cheap) for local 100% copy
✅ **Multi-cloud support** - AWS S3, GCS, Azure, Redis, PostgreSQL, MinIO, etc.
✅ **93% storage savings** - Compression reduces local storage requirements dramatically
✅ **90% cost reduction** - Pay 10% of monitoring service costs while keeping full visibility

**What You Need for Production:**
1. Backend monitoring service credentials (DATADOG_API_KEY, etc.)
2. Local storage backend (local disk, S3, GCS, Azure, etc.)
3. ReductrAI license key

**Example Total Cost (1M metrics/day):**
- ReductrAI local storage: $24/month (100% data, AI-queryable)
- Datadog (10% sample): $1,000/month (dashboards, alerts)
- **Total: $1,024/month** vs $10,000/month (90% savings)

**For more information:**
- [Main README](./README.md)
- [Configuration Reference](./.env.example)
- [Docker Compose](./docker-compose.yml)
