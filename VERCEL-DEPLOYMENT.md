# Vercel Deployment Guide - NASA Demo

This guide walks you through deploying the NASA telemetry demo to your existing Vercel infrastructure and integrating it with your Webflow website.

## Overview

You have:
- ✅ Webflow website with NASA demo section added (lines 296-451 in index.html)
- ✅ Vercel configuration ready (vercel.json)
- ✅ 2 existing Vercel projects:
  - Main: `prj_KHQfzJsyFhUA1jU7YQtaR6VQoE14`
  - Webflow: `prj_yFdAX2FnQZ2CLpXnccT1uEDXH6Yb`

## Step 1: Deploy Backend to Vercel (10 minutes)

### Install Vercel CLI (if not already installed)

```bash
npm install -g vercel
```

### Deploy Mock Receiver

```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-docker

# Login to Vercel (use your existing account)
vercel login

# Deploy to production
vercel --prod

# Follow prompts:
# - Link to existing project? No (create new)
# - Project name: reductrai-backend-demo
# - Directory: .
# - Override settings? No
```

This will deploy the mock receiver to a URL like:
`https://reductrai-backend-demo.vercel.app`

### Save Your Backend URL

After deployment completes, note your backend URL:

```bash
# Get deployment URL
vercel ls

# Example output:
# reductrai-backend-demo  Production  https://reductrai-backend-demo.vercel.app
```

## Step 2: Update Webflow HTML with Production URLs (5 minutes)

You need to update the NASA demo section in your Webflow HTML to use the deployed backend URL instead of localhost.

### Edit index.html

Open `/Users/jessiehermosillo/Apiflow/reductrai-website/reductrai-36180f.webflow/index.html`

**Find and replace these URLs:**

1. **Line 343** - Iframe source (demo dashboard):
   ```html
   <!-- Current (localhost) -->
   src="http://localhost:3000"

   <!-- Update to your deployed demo URL -->
   src="https://your-demo-dashboard.vercel.app"
   ```

2. **Line 396** - "Open Full Demo" button:
   ```html
   <!-- Current -->
   href="http://localhost:3000"

   <!-- Update to -->
   href="https://your-demo-dashboard.vercel.app"
   ```

3. **Line 412** - Stats API endpoint:
   ```html
   <!-- Current -->
   const response = await fetch('http://localhost:8888/stats');

   <!-- Update to -->
   const response = await fetch('https://reductrai-backend-demo.vercel.app/stats');
   ```

### Quick Find & Replace

Use your editor's find and replace:

```
Find:    http://localhost:8888
Replace: https://reductrai-backend-demo.vercel.app

Find:    http://localhost:3000
Replace: https://your-demo-dashboard.vercel.app
```

## Step 3: Deploy Demo Dashboard to Vercel (10 minutes)

The demo dashboard (port 3000) also needs to be deployed.

### Option A: Deploy from Docker Image

If you have a pre-built demo dashboard:

```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-docker/demo-dashboard

# Create vercel.json
cat > vercel.json <<'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "index.html",
      "use": "@vercel/static"
    }
  ]
}
EOF

# Deploy
vercel --prod
```

### Option B: Use Existing Dashboard

If you already have a dashboard, just point the iframe to it in Step 2.

## Step 4: Deploy Updated Webflow Site (5 minutes)

### Deploy Webflow Export to Vercel

```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-website/reductrai-36180f.webflow

# Deploy to your existing Webflow Vercel project
vercel --prod

# Link to existing project
# Select: prj_yFdAX2FnQZ2CLpXnccT1uEDXH6Yb
```

## Step 5: Verify Deployment (5 minutes)

### Check Backend API

```bash
# Test stats endpoint
curl https://reductrai-backend-demo.vercel.app/stats

# Expected response:
{
  "totalReceived": 0,
  "byService": {},
  "recent": [],
  "supported": ["datadog", "newrelic", "azure", ...]
}
```

### Check Frontend

Visit your Webflow site URL and verify:

1. **NASA Demo section appears** (after hero section)
2. **Stats counters update** (if backend has data)
3. **Iframe loads** (or shows "Demo Starting..." fallback)
4. **AI Query examples display** correctly
5. **CTA buttons work** (links to pricing, calculator)

### Test CORS

If you see CORS errors in browser console:

```bash
# Check response headers
curl -I https://reductrai-backend-demo.vercel.app/stats

# Should include:
# Access-Control-Allow-Origin: *
```

## Step 6: Start NASA Telemetry Generator (Optional)

To feed live data to the demo:

### Option A: Local Testing

```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-validation

# Update generator to point to Vercel backend
export PROXY_URL=https://reductrai-backend-demo.vercel.app

./start-nasa-continuous.sh
```

### Option B: Deploy Generator to Cloud

For continuous operation, deploy the NASA generator to a cloud service:

**Railway.app (Free tier):**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
cd /Users/jessiehermosillo/Apiflow/reductrai-validation
railway init
railway up

# Set environment variable
railway variables set PROXY_URL=https://reductrai-backend-demo.vercel.app
```

**Heroku:**
```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-validation

# Create Procfile
echo "worker: node nasa-telemetry-generator.js" > Procfile

heroku create reductrai-nasa-generator
git push heroku main

heroku config:set PROXY_URL=https://reductrai-backend-demo.vercel.app
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Webflow Website (Vercel)                               │
│  https://reductrai.com                                   │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  NASA Demo Section                              │    │
│  │  - Live stats counters                          │    │
│  │  - Iframe (demo dashboard)                      │    │
│  │  - AI Query showcase                            │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                    ↓
                    ↓ (fetch stats API)
                    ↓
┌─────────────────────────────────────────────────────────┐
│  Backend API (Vercel Serverless)                        │
│  https://reductrai-backend-demo.vercel.app              │
│                                                          │
│  GET  /stats       - Live statistics                    │
│  POST /api/v1/*    - Datadog endpoints                  │
│  POST /metric/v1/* - New Relic endpoints                │
│  POST /v2.1/*      - Azure Monitor endpoints            │
│  ...20+ monitoring formats                              │
└─────────────────────────────────────────────────────────┘
                    ↑
                    ↑ (sends telemetry)
                    ↑
┌─────────────────────────────────────────────────────────┐
│  NASA Telemetry Generator (Railway/Heroku)              │
│                                                          │
│  - Generates 16,800+ metrics/sec                        │
│  - 4 missions: ISS, Perseverance, JWST, Voyager1        │
│  - Sends to all 20+ monitoring formats                  │
└─────────────────────────────────────────────────────────┘
```

## Environment Variables

### Backend (Vercel)

Set in Vercel dashboard:

```
NODE_ENV=production
PORT=8888
```

### NASA Generator (Railway/Heroku)

```
PROXY_URL=https://reductrai-backend-demo.vercel.app
DURATION=86400
BATCH_SIZE=500
INTERVAL_MS=100
MISSIONS=ISS,Perseverance,JWST,Voyager1
```

## Troubleshooting

### Issue: Stats not updating on website

**Check:**
1. Backend API is deployed and responding:
   ```bash
   curl https://reductrai-backend-demo.vercel.app/stats
   ```

2. CORS headers are present:
   ```bash
   curl -I https://reductrai-backend-demo.vercel.app/stats | grep -i "access-control"
   ```

3. JavaScript console for errors (F12 in browser)

### Issue: Iframe not loading

**Check:**
1. Demo dashboard is deployed
2. URL in iframe src is correct (line 343)
3. No mixed content warnings (HTTPS only)

### Issue: Vercel deployment fails

**Common fixes:**
```bash
# Clear Vercel cache
vercel --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Redeploy
vercel --prod
```

### Issue: Stats show 0 even with generator running

**Check:**
1. Generator is pointing to correct backend URL
2. Backend is receiving requests:
   ```bash
   vercel logs
   ```

3. Generator is running:
   ```bash
   # If on Railway
   railway logs

   # If on Heroku
   heroku logs --tail
   ```

## Monitoring

### View Backend Logs

```bash
# Vercel logs
vercel logs

# Or in Vercel dashboard:
# https://vercel.com/dashboard/deployments
```

### Check Deployment Status

```bash
# List all deployments
vercel ls

# Get deployment details
vercel inspect <deployment-url>
```

## Next Steps

Once deployed:

1. **Test the demo** - Visit your Webflow site and interact with the NASA demo
2. **Monitor stats** - Watch the live counters update
3. **Share the demo** - Use it in sales presentations and marketing
4. **Add analytics** - Track demo engagement with Google Analytics/Mixpanel

## Cost Estimate

### Vercel (Free Tier)
- ✅ Serverless Functions: 100GB-hours/month free
- ✅ Bandwidth: 100GB/month free
- ✅ Build Minutes: Unlimited for Hobby plan

### Railway (Free Tier)
- ✅ $5/month free credit
- ✅ 500 hours/month execution
- ✅ 1GB RAM

**Total estimated cost: $0-5/month** for demo

## Production Considerations

For high-traffic production use:

1. **CDN**: Enable Vercel Edge Network (automatic)
2. **Caching**: Add cache headers to /stats endpoint
3. **Rate Limiting**: Implement rate limiting for API endpoints
4. **Monitoring**: Add Vercel Analytics or Sentry
5. **Database**: Store telemetry in PostgreSQL/Redis instead of in-memory

## Support

If you encounter issues:

1. Check Vercel deployment logs
2. Verify all URLs are updated to production (not localhost)
3. Test backend API endpoints directly with curl
4. Check browser console for JavaScript errors

## Summary

Your NASA demo is now live! 🚀

- **Frontend**: Webflow site on Vercel
- **Backend**: Mock receiver on Vercel
- **Generator**: NASA telemetry on Railway/Heroku
- **Live stats**: Updating every 2 seconds
- **AI Query showcase**: Demonstrating plain English queries
- **Cost savings**: Displayed in real-time

This demo will help convert website visitors into customers by showing ReductrAI in action with real NASA-scale telemetry data.
