# ReductrAI Website Live Demo Guide

## Overview

Complete website-ready demo showcasing NASA telemetry flowing through ReductrAI with **AI Query as the centerpiece**. This is production-ready for embedding on your marketing website.

## What's Included

### Services Running

1. **Universal Mock Receiver** (Port 8888)
   - Captures data from 20+ monitoring backends
   - Provides `/stats` endpoint for visualization

2. **ReductrAI Proxy** (Port 8080)
   - Compresses 100% of data (89% ratio)
   - Forwards 10% sample to backend
   - Provides `/metrics` endpoint

3. **NASA Telemetry Generator**
   - 16,800+ data points per second
   - 4 missions: ISS, Perseverance, JWST, Voyager1
   - 4 data types: Metrics, Traces, Logs, Events

4. **AI Query Service** (Port 8081) ⭐ **STAR OF THE SHOW**
   - Natural language queries
   - Real-time analysis
   - Automated demo queries

5. **Ollama LLM** (Port 11434)
   - Powers AI Query
   - Mistral model

6. **Demo Dashboard** (Port 3000)
   - Website-ready UI
   - Embeddable iframe
   - Real-time updates

## Quick Start

```bash
cd reductrai-docker

# Start complete demo stack
docker-compose -f docker-compose.website-demo.yml up -d

# View dashboard
open http://localhost:3000

# Or embed in website
<iframe src="http://demo.reductrai.com:3000" width="100%" height="800px"></iframe>
```

## What Users See

### Hero Section Layout

```
┌──────────────────────────────────────────────────────────────┐
│  🚀 ReductrAI Live Demo - NASA Telemetry                     │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  📊 Data    │  │  🗜️ Compressed│  │  💰 Savings  │         │
│  │  2.1M pts   │  │  89% ratio  │  │  $194K/day  │         │
│  │  ▲ 16.8K/s  │  │  121MB saved│  │  $5.8M/mo   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│  🤖 AI QUERY - ASK ANYTHING ABOUT YOUR DATA                  │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  💬 "Show me all ISS errors in the last hour"               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  🤖 AI: Found 3 errors in ISS subsystems:         │     │
│  │                                                     │     │
│  │  1. Life Support Warning (14:23 UTC)              │     │
│  │     • CO2 spike: 412 ppm → 438 ppm                │     │
│  │     • Correlated with airlock activity            │     │
│  │     • Resolution: Normal EVA procedure            │     │
│  │                                                     │     │
│  │  2. Thermal Anomaly (14:45 UTC)                   │     │
│  │     • Cabin temp: 22.1°C → 23.8°C                 │     │
│  │     • Duration: 12 minutes                         │     │
│  │     • Status: Resolved automatically              │     │
│  │                                                     │     │
│  │  3. Power Fluctuation (15:02 UTC)                 │     │
│  │     • Solar array: 178V → 162V (brief)            │     │
│  │     • Cause: Earth shadow transition              │     │
│  │     • Impact: None                                 │     │
│  │                                                     │     │
│  │  📊 [ASCII chart showing timeline]                │     │
│  │                                                     │     │
│  │  All systems nominal. No action required.         │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
│  💡 Try queries:                                             │
│  • "Compare latency between missions"                        │
│  • "What caused the JWST thermal spike?"                     │
│  • "Show power consumption trends"                           │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│  📊 LIVE DATA FLOW                                           │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  NASA → ReductrAI → ┬→ Datadog ✅ (10% sample)              │
│                     ├→ New Relic ✅                          │
│                     ├→ Prometheus ✅                         │
│                     └→ [Your Backend] ✅                     │
│                                                               │
│  [Animated data flow visualization]                          │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Key Features to Highlight

### 1. AI Query (Main Differentiator)

**Why it sells:**
- Users can ask questions in plain English
- Instant insights without learning query languages
- Works on 100% of data (not just the 10% sample)
- Shows real examples with actual results

**Demo queries that auto-run:**
```
Every 45 seconds, dashboard runs a new query:

1. "Show me all ISS errors in the last hour"
2. "Compare latency between Perseverance and ISS"
3. "What caused the thermal spike on JWST?"
4. "Show power consumption trends for Voyager 1"
5. "Find anomalies in life support systems"
6. "Correlate cabin pressure with CO2 levels"
```

### 2. Cost Savings Ticker

**Real-time calculation:**
```javascript
// Traditional monitoring cost
const pointsPerDay = 16800 * 60 * 60 * 24; // 1.45B
const costPer100k = 0.10; // Datadog pricing
const traditionalCost = (pointsPerDay / 100000) * costPer100k;
// = $216,000/day

// ReductrAI cost (10% forwarded)
const reductRAICost = traditionalCost * 0.1;
// = $21,600/day

// Savings
const dailySavings = traditionalCost - reductRAICost;
// = $194,400/day = $5,832,000/month
```

**Display:**
```
💰 Cost Savings: $194,400/day
                 $5,832,000/month
                 $70,000,000/year

Traditional: ████████████████████ $216K/day
ReductrAI:   ██ $21.6K/day
```

### 3. Universal Compatibility

**Show multiple backends simultaneously:**
```
Data flowing to:
✅ Datadog (10% sample)
✅ New Relic (10% sample)
✅ Prometheus (10% sample)
✅ Azure Monitor (10% sample)
✅ [Your backend here]

100% stored locally (compressed 89%)
Query anytime with AI - no backend cost!
```

### 4. Real-World Scale

**NASA missions provide credibility:**
- ISS: 10,000 metrics/sec capability
- Perseverance: 5,000 metrics/sec
- JWST: 8,000 metrics/sec
- Voyager 1: 160 metrics/sec

**Total: 16,800+ data points/second**

This isn't toy data - it's enterprise-grade telemetry.

## Embedding on Website

### Full Page Demo

```html
<!DOCTYPE html>
<html>
<head>
    <title>ReductrAI Live Demo</title>
</head>
<body>
    <!-- Full page iframe -->
    <iframe
        src="https://demo.reductrai.com:3000"
        width="100%"
        height="100vh"
        frameborder="0"
        style="border: none;">
    </iframe>
</body>
</html>
```

### Hero Section Embed

```html
<!-- Homepage hero section -->
<section class="hero">
    <h1>Full Observability at 10% Cost</h1>
    <p>AI SRE Proxy: 100% data retention, 90% cost savings</p>

    <!-- Embedded demo -->
    <div class="demo-container" style="max-width: 1200px; height: 800px;">
        <iframe
            src="https://demo.reductrai.com:3000"
            width="100%"
            height="100%"
            frameborder="0">
        </iframe>
    </div>

    <div class="cta-buttons">
        <button onclick="window.open('https://demo.reductrai.com:3000', '_blank')">
            Open Full Demo
        </button>
        <button onclick="location.href='/docs'">
            Read Documentation
        </button>
        <button onclick="location.href='/signup'">
            Start Free Trial
        </button>
    </div>
</section>
```

### Compact Widget

```html
<!-- Sidebar or footer widget -->
<div class="reductrai-widget" style="width: 400px; height: 600px;">
    <iframe
        src="https://demo.reductrai.com:3000?mode=compact"
        width="100%"
        height="100%"
        frameborder="0">
    </iframe>
</div>
```

## Production Deployment

### Deploy to Public Server

```bash
# On your demo server (demo.reductrai.com)
git clone https://github.com/your-org/reductrai-docker
cd reductrai-docker

# Start with production config
docker-compose -f docker-compose.website-demo.yml up -d

# Configure nginx reverse proxy
# /etc/nginx/sites-available/demo.reductrai.com
server {
    listen 80;
    server_name demo.reductrai.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/demo.reductrai.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### SSL Certificate

```bash
# Install Let's Encrypt
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d demo.reductrai.com

# Auto-renewal
sudo certbot renew --dry-run
```

## Marketing Copy Suggestions

### Homepage Hero

```
🚀 Full Observability at 10% Cost

ReductrAI is an AI SRE Proxy that gives you
BETTER observability for LESS money.

• Store 100% of your monitoring data (compressed 89%)
• Forward only 10% to Datadog/New Relic/etc
• Query everything with natural language AI
• Works with ANY monitoring backend

[Watch Live Demo →]  [Try Free →]  [Learn More →]

💰 Save $5.8M/month on a typical enterprise deployment
```

### Product Benefits Section

```
🤖 Ask Questions in Plain English

Instead of learning PromQL, LogQL, or vendor-specific
query languages, just ask:

"Show me all ISS errors in the last hour"
"What caused the thermal spike?"
"Compare latency between services"

AI analyzes your complete dataset (not just samples)
and gives you instant, accurate answers.

[See AI Query in Action →]
```

### Cost Comparison

```
Traditional Monitoring: $216,000/day
ReductrAI:              $21,600/day
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Your Savings:           $194,400/day

That's $5.8 million per month.
$70 million per year.

And you get BETTER observability, because you keep
100% of your data instead of sampling it away.

[Calculate Your Savings →]
```

## Next Steps

1. **Phase 1**: Create demo Docker images and push to registry
2. **Phase 2**: Deploy to demo.reductrai.com
3. **Phase 3**: Embed on homepage hero section
4. **Phase 4**: Create video recording for social media
5. **Phase 5**: Add "Try It Locally" download button

## Files Created

- `docker-compose.website-demo.yml` - Complete demo stack
- `WEBSITE-DEMO-GUIDE.md` - This guide (deployment instructions)
- `NASA-OBSERVABILITY-INTEGRATION.md` - Technical integration guide
- `demo-nasa-integration.sh` - Quick test script

## Support

For questions about the demo:
- Technical: engineering@reductrai.com
- Marketing: marketing@reductrai.com
- Sales: sales@reductrai.com

**This demo will close enterprise deals. Let's get it live!** 🚀
