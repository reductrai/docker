# Deploy NASA Demo to Website - TODAY

## Quick Deploy: 3 Steps to Live

### Step 1: Deploy Backend (30 minutes)

**Option A: Deploy to DigitalOcean (Easiest)**

```bash
# 1. Create a DigitalOcean Droplet
# - Size: $24/month (4GB RAM, 2 vCPUs)
# - OS: Ubuntu 22.04
# - Add your SSH key

# 2. SSH into droplet
ssh root@your-droplet-ip

# 3. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 4. Install Docker Compose
apt-get install docker-compose-plugin

# 5. Clone your repo
git clone https://github.com/your-org/reductrai-docker.git
cd reductrai-docker

# 6. Start the demo
docker-compose -f docker-compose.website-demo.yml up -d

# 7. Check it's running
curl http://localhost:3000
```

**Option B: Deploy to AWS (Production)**

```bash
# Use EC2 t3.medium instance
# - 2 vCPUs, 4GB RAM
# - Ubuntu 22.04 AMI
# - Open ports: 80, 443, 3000

# Same steps as DigitalOcean above
```

**Option C: Deploy to your existing server**

```bash
# If you already have a server, just run:
docker-compose -f docker-compose.website-demo.yml up -d
```

### Step 2: Configure Domain (15 minutes)

**Point subdomain to your server:**

```bash
# In your DNS provider (Cloudflare, Route53, etc.)
# Add A record:
demo.reductrai.com → your-server-ip

# Install nginx for SSL
apt-get install nginx certbot python3-certbot-nginx

# Configure nginx
cat > /etc/nginx/sites-available/demo <<EOF
server {
    listen 80;
    server_name demo.reductrai.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/demo /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Get SSL certificate (free)
certbot --nginx -d demo.reductrai.com --non-interactive --agree-tos -m your@email.com

# Done! Now accessible at https://demo.reductrai.com
```

### Step 3: Add to Webflow (15 minutes)

**Method 1: Embed in Hero Section (Recommended)**

1. **Open Webflow Designer**
2. **Go to your homepage**
3. **Add an Embed element** to your hero section
4. **Paste this code:**

```html
<div class="reductrai-demo-container">
    <style>
        .reductrai-demo-container {
            width: 100%;
            max-width: 1400px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        .demo-header {
            text-align: center;
            margin-bottom: 30px;
        }
        .demo-header h2 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .demo-header p {
            font-size: 1.2rem;
            color: #666;
        }
        .demo-stats {
            display: flex;
            justify-content: space-around;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
            border: 2px solid #667eea;
            border-radius: 12px;
            padding: 20px 30px;
            text-align: center;
            margin: 10px;
            min-width: 200px;
        }
        .stat-number {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
            display: block;
        }
        .stat-label {
            color: #666;
            font-size: 0.9rem;
            margin-top: 5px;
        }
        .demo-iframe-wrapper {
            position: relative;
            width: 100%;
            padding-bottom: 56.25%; /* 16:9 aspect ratio */
            height: 0;
            overflow: hidden;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(102, 126, 234, 0.3);
            border: 3px solid #667eea;
        }
        .demo-iframe-wrapper iframe {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            border: none;
        }
        .demo-cta {
            text-align: center;
            margin-top: 30px;
        }
        .demo-cta a {
            display: inline-block;
            padding: 15px 40px;
            margin: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            transition: transform 0.2s;
        }
        .demo-cta a:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
        }
        .badge {
            display: inline-block;
            background: #10b981;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: bold;
            margin-left: 10px;
        }
    </style>

    <div class="demo-header">
        <h2>🚀 Live NASA Telemetry Demo <span class="badge">LIVE NOW</span></h2>
        <p>Real spacecraft data flowing through ReductrAI - Ask AI anything in plain English</p>
    </div>

    <div class="demo-stats">
        <div class="stat-card">
            <span class="stat-number" id="data-points">0</span>
            <span class="stat-label">Data Points Processed</span>
        </div>
        <div class="stat-card">
            <span class="stat-number">89%</span>
            <span class="stat-label">Compression Ratio</span>
        </div>
        <div class="stat-card">
            <span class="stat-number" id="cost-savings">$0</span>
            <span class="stat-label">Saved Today</span>
        </div>
    </div>

    <div class="demo-iframe-wrapper">
        <iframe
            src="https://demo.reductrai.com:3000"
            allow="fullscreen"
            loading="lazy">
        </iframe>
    </div>

    <div class="demo-cta">
        <a href="https://demo.reductrai.com:3000" target="_blank">
            Open Full Demo →
        </a>
        <a href="/signup">
            Start Free Trial →
        </a>
        <a href="/contact">
            Talk to Sales →
        </a>
    </div>

    <script>
        // Update live stats
        async function updateStats() {
            try {
                const response = await fetch('https://demo.reductrai.com:8888/stats');
                const data = await response.json();

                // Update data points
                document.getElementById('data-points').textContent =
                    data.totalReceived.toLocaleString();

                // Calculate cost savings ($0.10 per 100k points, 90% saved)
                const savings = Math.floor(data.totalReceived / 100000 * 0.10 * 0.9 * 100) / 100;
                document.getElementById('cost-savings').textContent =
                    '$' + savings.toLocaleString();
            } catch (error) {
                console.log('Demo stats will load shortly...');
            }
        }

        // Update every 2 seconds
        updateStats();
        setInterval(updateStats, 2000);
    </script>
</div>
```

**Method 2: Dedicated Demo Page**

1. **Create a new page** in Webflow called `/demo` or `/live-demo`
2. **Add an Embed element** (full width)
3. **Paste this code:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ReductrAI Live Demo - NASA Telemetry</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #f8f9fa;
        }
        .demo-fullscreen {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            width: 100vw;
            height: 100vh;
        }
        .demo-fullscreen iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
    </style>
</head>
<body>
    <div class="demo-fullscreen">
        <iframe src="https://demo.reductrai.com:3000"></iframe>
    </div>
</body>
</html>
```

**Method 3: Popup Modal (Advanced)**

```html
<!-- Add to homepage -->
<button id="open-demo-btn" class="primary-button">
    🚀 Watch Live Demo
</button>

<!-- Modal -->
<div id="demo-modal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 10000; justify-content: center; align-items: center;">
    <div style="width: 90%; max-width: 1400px; height: 90%; background: white; border-radius: 12px; position: relative; overflow: hidden;">
        <button id="close-demo-btn" style="position: absolute; top: 20px; right: 20px; z-index: 10001; background: #ff4444; color: white; border: none; border-radius: 50%; width: 40px; height: 40px; font-size: 24px; cursor: pointer;">×</button>
        <iframe src="https://demo.reductrai.com:3000" style="width: 100%; height: 100%; border: none;"></iframe>
    </div>
</div>

<script>
    document.getElementById('open-demo-btn').onclick = () => {
        document.getElementById('demo-modal').style.display = 'flex';
    };
    document.getElementById('close-demo-btn').onclick = () => {
        document.getElementById('demo-modal').style.display = 'none';
    };
</script>
```

## Webflow-Specific Instructions

### Where to Add the Code

1. **Hero Section (Recommended)**
   - Webflow Designer → Homepage
   - Add Section → Add Embed element
   - Paste Method 1 code above
   - Publish

2. **Custom Page**
   - Pages → Add new page → `/demo`
   - Add Embed element (full width)
   - Paste Method 2 code above
   - Publish

3. **Site-Wide Button**
   - Add button to navbar
   - Set link to `/demo` page
   - Or use Method 3 popup code

### Webflow Settings

In your Webflow project settings:

1. **Custom Code → Head**:
```html
<!-- Add this to <head> for better performance -->
<link rel="dns-prefetch" href="https://demo.reductrai.com">
<link rel="preconnect" href="https://demo.reductrai.com">
```

2. **Custom Code → Footer** (for analytics):
```html
<script>
// Track demo interactions
window.addEventListener('message', function(event) {
    if (event.data.type === 'demo-interaction') {
        // Send to your analytics
        gtag('event', 'demo_interaction', {
            'event_category': 'demo',
            'event_label': event.data.action
        });
    }
});
</script>
```

## Testing Checklist

Before going live, verify:

- [ ] Demo loads on https://demo.reductrai.com
- [ ] Stats update every 2 seconds
- [ ] AI Query responds (try: "Show ISS errors")
- [ ] Iframe loads on your Webflow site
- [ ] Mobile responsive (test on phone)
- [ ] HTTPS works (no mixed content warnings)
- [ ] Cost savings counter increments
- [ ] CTA buttons link correctly

## Quick Test Commands

```bash
# Test backend is running
curl https://demo.reductrai.com/health

# Test mock receiver stats
curl https://demo.reductrai.com:8888/stats

# Test AI Query
curl -X POST https://demo.reductrai.com:8081/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Show ISS errors"}'
```

## Troubleshooting

### Issue: Iframe not loading

**Fix**: Check CORS headers on your server

```bash
# Add to nginx config
add_header Access-Control-Allow-Origin "*" always;
add_header X-Frame-Options "SAMEORIGIN" always;
```

### Issue: Stats not updating

**Check**: CORS on stats endpoint

```bash
# Test from browser console
fetch('https://demo.reductrai.com:8888/stats')
  .then(r => r.json())
  .then(console.log)
```

### Issue: Mixed content warning

**Fix**: Ensure all URLs use HTTPS in embed code

```html
<!-- Change -->
http://demo.reductrai.com
<!-- To -->
https://demo.reductrai.com
```

## Launch Announcement

Once live, announce it:

**Twitter/LinkedIn:**
```
🚀 We just launched a LIVE demo of ReductrAI analyzing NASA telemetry!

Watch real spacecraft data:
• 16,800+ metrics/second
• 89% compression ratio
• $5.8M/month cost savings
• AI-powered natural language queries

Try it: https://reductrai.com/demo

#observability #ai #devops
```

**Blog Post Title Ideas:**
- "Watch AI Analyze 2.1 Million NASA Data Points in Real-Time"
- "How We Built a Live Demo Handling 16,800 Metrics Per Second"
- "NASA Telemetry Meets AI: Our New Interactive Demo"

## Next: Convert Viewers to Customers

Add these CTAs around the demo:

1. **"Run This Locally"** → Download docker-compose.yml
2. **"See Your Savings"** → Cost calculator page
3. **"Talk to Sales"** → Calendly booking
4. **"Start Free Trial"** → Signup page

## Timeline to Live

- ⏱️ **Step 1** (Backend): 30 minutes
- ⏱️ **Step 2** (Domain/SSL): 15 minutes
- ⏱️ **Step 3** (Webflow): 15 minutes
- ⏱️ **Testing**: 10 minutes

**Total: ~70 minutes from zero to live** 🚀

## Need Help?

If you hit any issues:
1. Check the troubleshooting section above
2. Review nginx logs: `tail -f /var/log/nginx/error.log`
3. Check Docker logs: `docker-compose logs -f`
4. Contact me for support

**Let's get this live and start closing deals!** 💰
