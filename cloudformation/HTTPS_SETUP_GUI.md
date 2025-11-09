# HTTPS Setup with Custom Domain - AWS Console (GUI) Guide

Step-by-step guide to configure `freeinterestcal.com` with HTTPS using the AWS Console.

**Learning Objective:** Understand how AWS services work together to enable HTTPS for your application.

---

## Prerequisites

✅ Domain registered in Route 53: `freeinterestcal.com`  
✅ ALB deployed and running  
✅ AWS Console access

---

## Overview: What We'll Do

```
Step 1: Request SSL Certificate (ACM)
   ↓
Step 2: Validate Certificate (Route 53)
   ↓
Step 3: Add HTTPS Listener to ALB
   ↓
Step 4: Create DNS Records (Route 53)
   ↓
Step 5: Configure HTTP Redirect
   ↓
Step 6: Update Frontend Configuration
   ↓
Step 7: Test Everything
```

**Estimated Time:** 30-45 minutes (includes waiting for certificate validation)

---

## Step 1: Request SSL/TLS Certificate (ACM)

### 1.1 Navigate to Certificate Manager

1. Open AWS Console
2. Search for **"Certificate Manager"** or **"ACM"** in the search bar
3. Click **"Certificate Manager"**
4. **Important:** Make sure you're in the **same region** as your ALB (e.g., `us-east-1`)
   - Check region in top-right corner

### 1.2 Request Certificate

1. Click **"Request a certificate"** button (orange button)
2. Select **"Request a public certificate"**
3. Click **"Next"**

### 1.3 Add Domain Names

1. **Domain name:** Enter `freeinterestcal.com`
2. Click **"Add another name to this certificate"**
3. **Domain name:** Enter `www.freeinterestcal.com`
4. Click **"Next"**

**Why both?** This allows users to access your site with or without "www"

### 1.4 Select Validation Method

1. Select **"DNS validation - recommended"**
2. Click **"Next"**

**Why DNS validation?**
- Automatic renewal
- No need to upload files to your server
- More secure

### 1.5 Add Tags (Optional)

1. Add tags if you want (e.g., `Name: task-manager-cert`)
2. Click **"Next"**

### 1.6 Review and Request

1. Review your settings:
   - Domain names: `freeinterestcal.com`, `www.freeinterestcal.com`
   - Validation: DNS
2. Click **"Request"**

### 1.7 Success Screen

You'll see:
- ✅ **"Success! Your certificate has been requested"**
- Certificate Status: **"Pending validation"**
- Certificate ID: `abc123...`

**Keep this page open!** We'll need it for the next step.

---

## Step 2: Validate Certificate with Route 53

### 2.1 View Certificate Details

1. On the success screen, click **"View certificate"**
2. You'll see certificate status: **"Pending validation"**
3. Scroll down to **"Domains"** section

### 2.2 Understand Validation Records

You'll see something like:

```
Domain: freeinterestcal.com
Status: Pending validation
CNAME name: _abc123def456.freeinterestcal.com
CNAME value: _xyz789ghi012.acm-validations.aws.
```

**What does this mean?**
- AWS needs to verify you own the domain
- You prove ownership by adding a special DNS record
- AWS will check for this record

### 2.3 Create Records in Route 53 (Easy Method)

1. Click **"Create records in Route 53"** button
2. A popup appears showing the records to be created
3. Review the records (should show 2 CNAME records)
4. Click **"Create records"**
5. You'll see: **"Success! The DNS records have been created"**

**What just happened?**
- AWS automatically added validation records to your Route 53 hosted zone
- No manual work needed!

### 2.4 Wait for Validation

1. Stay on the certificate details page
2. Click the **refresh icon** (circular arrow) every minute
3. Status will change from **"Pending validation"** to **"Issued"**
4. This usually takes **5-30 minutes**

**While waiting, you can:**
- Take a coffee break ☕
- Read ahead to understand next steps
- Check email

### 2.5 Verify Certificate is Issued

Once issued, you'll see:
- Status: **"Issued"** ✅
- Green checkmark
- Certificate ARN: `arn:aws:acm:us-east-1:123456789012:certificate/abc123...`

**Copy the Certificate ARN** - you'll need it later!

---

## Step 3: Add HTTPS Listener to ALB

### 3.1 Navigate to Load Balancers

1. Search for **"EC2"** in AWS Console
2. Click **"EC2"**
3. In left sidebar, scroll down to **"Load Balancing"**
4. Click **"Load Balancers"**

### 3.2 Find Your ALB

1. Find your load balancer: `dev-task-manager-alb`
2. Click on it to select it
3. Look at the **"Description"** tab at the bottom

**Verify it's the right one:**
- Type: application
- Scheme: internet-facing
- DNS name: `dev-task-manager-alb-xxx.us-east-1.elb.amazonaws.com`

### 3.3 View Current Listeners

1. Click the **"Listeners"** tab
2. You should see:
   - **HTTP:80** → Forwarding to frontend target group

**What's a listener?**
- A process that checks for connection requests
- Currently only listening on port 80 (HTTP)
- We'll add port 443 (HTTPS)

### 3.4 Add HTTPS Listener

1. Click **"Add listener"** button
2. Configure the listener:

**Protocol:** Select **"HTTPS"**  
**Port:** `443` (default for HTTPS)

**Default action:**
- Type: **"Forward to"**
- Target group: Select `dev-task-manager-frontend-tg`

**Security policy:**
- Leave as **"ELBSecurityPolicy-2016-08"** (or use newer policy)

**Default SSL/TLS certificate:**
- Select **"From ACM"**
- Certificate: Select your certificate (shows `freeinterestcal.com`)

3. Click **"Add"**

### 3.5 Verify HTTPS Listener Created

You should now see:
- **HTTP:80** → Forward to frontend-tg
- **HTTPS:443** → Forward to frontend-tg ✅

---

## Step 4: Add Backend API Rule to HTTPS Listener

### 4.1 View HTTPS Listener Rules

1. In the **"Listeners"** tab
2. Click on **"HTTPS:443"** (click on the protocol, not the checkbox)
3. This opens the **"Rules"** tab

### 4.2 Understand Current Rules

You'll see:
- **Default:** Forward to frontend-tg

**What we need:**
- Route `/api/*` requests to backend-api-tg
- Route everything else to frontend-tg

### 4.3 Add Rule for Backend API

1. Click **"Add rule"** button (or the "+" icon)
2. Click **"Insert Rule"**

**Step 1: Add condition**
1. Click **"Add condition"**
2. Select **"Path"**
3. Enter: `/api/*`
4. Click **"Add condition"** again
5. Select **"Path"**
6. Enter: `/health`
7. Click **"Next"**

**Why two conditions?**
- `/api/*` catches all API calls
- `/health` is the health check endpoint

**Step 2: Add action**
1. Action type: **"Forward to"**
2. Target group: Select `dev-task-manager-api-tg`
3. Click **"Next"**

**Step 3: Set priority**
1. Priority: Enter `1`
2. Click **"Next"**

**Why priority 1?**
- Lower number = higher priority
- Checked before default rule
- Ensures API calls go to backend

**Step 4: Review**
1. Review your rule:
   - IF path is `/api/*` OR `/health`
   - THEN forward to backend-api-tg
2. Click **"Create"**

### 4.4 Verify Rules

You should now see:
- **Priority 1:** IF Path is `/api/*` OR `/health` THEN Forward to backend-api-tg ✅
- **Default:** Forward to frontend-tg

---

## Step 5: Configure HTTP to HTTPS Redirect

### 5.1 Edit HTTP Listener

1. Go back to **"Listeners"** tab
2. Select **"HTTP:80"** listener (checkbox)
3. Click **"Edit"** button

### 5.2 Change Default Action

1. Remove the current "Forward to" action:
   - Click the **trash icon** next to the action

2. Add redirect action:
   - Click **"Add action"**
   - Select **"Redirect to"**

3. Configure redirect:
   - Protocol: **"HTTPS"**
   - Port: `443`
   - Status code: **"301 - Permanently moved"**

4. Click **"Update"**

### 5.3 Verify Redirect

You should now see:
- **HTTP:80** → Redirect to HTTPS:443 ✅
- **HTTPS:443** → Forward to frontend-tg

**What this does:**
- Any HTTP request automatically redirects to HTTPS
- Users always get secure connection
- Search engines know to use HTTPS

---

## Step 6: Create DNS Records in Route 53

### 6.1 Navigate to Route 53

1. Search for **"Route 53"** in AWS Console
2. Click **"Route 53"**
3. Click **"Hosted zones"** in left sidebar

### 6.2 Select Your Hosted Zone

1. Click on **"freeinterestcal.com"**
2. You'll see existing DNS records

**What you'll see:**
- NS records (nameservers)
- SOA record (start of authority)
- CNAME records (from certificate validation)

### 6.3 Get ALB DNS Name

**Open a new tab:**
1. Go to **EC2** → **Load Balancers**
2. Select your ALB: `dev-task-manager-alb`
3. Copy the **DNS name** from Description tab
   - Example: `dev-task-manager-alb-123456789.us-east-1.elb.amazonaws.com`

**Keep this tab open!** We'll need the Hosted Zone ID too.

### 6.4 Get ALB Hosted Zone ID

1. Still in the ALB Description tab
2. Find **"Hosted zone"** field
3. Copy the ID (e.g., `Z35SXDOTRQ7X7K`)

**What's this?**
- Every ALB has a hosted zone ID
- Used for creating alias records
- Different from your Route 53 hosted zone ID

### 6.5 Create A Record for Root Domain

**Back in Route 53 tab:**

1. Click **"Create record"** button

2. Configure record:
   - **Record name:** Leave empty (this is for root domain)
   - **Record type:** Select **"A - Routes traffic to an IPv4 address"**
   - **Alias:** Toggle **ON** ✅

3. Alias configuration:
   - **Route traffic to:** Select **"Alias to Application and Classic Load Balancer"**
   - **Region:** Select your region (e.g., `us-east-1`)
   - **Load balancer:** Select your ALB (should auto-populate)
   
   If it doesn't auto-populate:
   - Select **"Alias to Application and Classic Load Balancer"**
   - Manually enter the ALB DNS name

4. **Routing policy:** Simple routing

5. **Evaluate target health:** Check ✅

6. Click **"Create records"**

### 6.6 Create A Record for WWW Subdomain

1. Click **"Create record"** button again

2. Configure record:
   - **Record name:** Enter `www`
   - **Record type:** **"A - Routes traffic to an IPv4 address"**
   - **Alias:** Toggle **ON** ✅

3. Alias configuration:
   - **Route traffic to:** **"Alias to Application and Classic Load Balancer"**
   - **Region:** Your region
   - **Load balancer:** Select your ALB

4. **Evaluate target health:** Check ✅

5. Click **"Create records"**

### 6.7 Verify DNS Records

You should now see:
- **freeinterestcal.com** → A record → Alias to ALB ✅
- **www.freeinterestcal.com** → A record → Alias to ALB ✅

**What's an Alias record?**
- Special AWS record type
- Free (no query charges)
- Automatically updates if ALB IP changes
- Better than CNAME for root domains

---

## Step 7: Update Frontend Environment Variable

### 7.1 Navigate to ECS

1. Search for **"ECS"** in AWS Console
2. Click **"Elastic Container Service"**
3. Click **"Task Definitions"** in left sidebar

### 7.2 Find Frontend Task Definition

1. Find: `dev-task-manager-frontend`
2. Click on it
3. You'll see all revisions (versions)

### 7.3 Create New Revision

1. Select the latest revision (checkbox)
2. Click **"Create new revision"** button
3. Scroll down to **"Container Definitions"**
4. Click on **"frontend"** container

### 7.4 Update Environment Variable

1. Scroll down to **"Environment variables"**
2. Find: `REACT_APP_API_URL`
3. Current value: `http://dev-task-manager-alb-xxx...`
4. Change to: `https://freeinterestcal.com`
5. Click **"Update"**

### 7.5 Create New Task Definition

1. Scroll to bottom
2. Click **"Create"**
3. New revision created (e.g., revision 2)

### 7.6 Update ECS Service

1. Click **"Clusters"** in left sidebar
2. Click on: `dev-task-manager-cluster`
3. Click **"Services"** tab
4. Select: `dev-task-manager-frontend` (checkbox)
5. Click **"Update"** button

### 7.7 Configure Service Update

1. **Revision:** Select latest (the one you just created)
2. **Force new deployment:** Check ✅
3. Scroll to bottom
4. Click **"Skip to review"**
5. Click **"Update Service"**

### 7.8 Wait for Deployment

1. Click **"View service"**
2. Click **"Deployments"** tab
3. Wait for:
   - New deployment: **"PRIMARY"** status
   - Running count: 2
   - Old deployment: Drained

**This takes 2-5 minutes**

---

## Step 8: Test Your Setup

### 8.1 Test DNS Resolution

**Wait 2-5 minutes for DNS propagation**

1. Open Command Prompt / Terminal
2. Test DNS:
   ```
   nslookup freeinterestcal.com
   nslookup www.freeinterestcal.com
   ```
3. Should return IP addresses

### 8.2 Test HTTPS in Browser

1. Open browser
2. Go to: `https://freeinterestcal.com`
3. Look for 🔒 **padlock icon** in address bar
4. Click the padlock
5. Verify:
   - Connection is secure
   - Certificate is valid
   - Issued to: freeinterestcal.com

### 8.3 Test HTTP Redirect

1. Go to: `http://freeinterestcal.com` (HTTP, not HTTPS)
2. Should automatically redirect to `https://freeinterestcal.com`
3. Check address bar changes from `http://` to `https://`

### 8.4 Test WWW Subdomain

1. Go to: `https://www.freeinterestcal.com`
2. Should work and show your app
3. Certificate should be valid

### 8.5 Test API Endpoint

1. Go to: `https://freeinterestcal.com/health`
2. Should return JSON:
   ```json
   {"status":"ok","service":"backend-api"}
   ```

### 8.6 Test Frontend Functionality

1. On `https://freeinterestcal.com`
2. Create a new task
3. Verify it appears in the list
4. Check browser console (F12) for any errors
5. No mixed content warnings should appear

---

## Step 9: View Certificate Details

### 9.1 Check Certificate in Browser

1. On `https://freeinterestcal.com`
2. Click the 🔒 padlock icon
3. Click **"Certificate"** or **"Connection is secure"**
4. View certificate details:
   - Issued to: freeinterestcal.com
   - Issued by: Amazon
   - Valid from: [date]
   - Valid to: [date] (13 months)

### 9.2 Check Certificate in ACM

1. Go to **Certificate Manager**
2. Click on your certificate
3. View details:
   - Status: **Issued** ✅
   - In use: **Yes** ✅
   - Domains: freeinterestcal.com, www.freeinterestcal.com
   - Renewal status: **Eligible for renewal**

**Auto-renewal:**
- ACM automatically renews certificates
- No action needed from you
- Renewal happens 60 days before expiration

---

## Understanding What You Built

### Architecture Overview

```
User types: https://freeinterestcal.com
        ↓
    DNS Lookup (Route 53)
        ↓
    Returns ALB IP address
        ↓
    Browser connects to ALB:443
        ↓
    ALB presents SSL certificate
        ↓
    Browser verifies certificate (ACM)
        ↓
    Secure connection established 🔒
        ↓
    ALB checks path:
        ├─ /api/* → Backend API container
        └─ /* → Frontend container
```

### Security Flow

```
HTTP Request (port 80)
    ↓
ALB receives request
    ↓
HTTP Listener: Redirect to HTTPS
    ↓
Browser redirected to HTTPS (port 443)
    ↓
HTTPS Listener: SSL/TLS handshake
    ↓
Encrypted connection established
    ↓
Route to appropriate container
```

### Components You Configured

1. **ACM Certificate**
   - Provides SSL/TLS encryption
   - Free from AWS
   - Auto-renews

2. **Route 53 DNS**
   - Translates domain to ALB IP
   - Alias records for root and www
   - Fast global DNS resolution

3. **ALB HTTPS Listener**
   - Terminates SSL/TLS
   - Handles certificate
   - Routes based on path

4. **HTTP Redirect**
   - Forces HTTPS usage
   - SEO friendly (301 redirect)
   - Better security

---

## Troubleshooting Guide

### Issue: Certificate Stuck in "Pending Validation"

**Symptoms:**
- Certificate status doesn't change to "Issued"
- Waiting more than 30 minutes

**Solutions:**

1. **Check DNS records created:**
   - Go to Route 53 → Hosted Zones → freeinterestcal.com
   - Look for CNAME records starting with `_`
   - Should see validation records

2. **Manually create records if missing:**
   - Go to ACM → Certificate details
   - Click "Create records in Route 53" again
   - Or manually copy CNAME name and value

3. **Verify domain nameservers:**
   - Go to Route 53 → Hosted Zones
   - Check NS records
   - Verify these match your domain registrar settings

4. **Wait longer:**
   - DNS propagation can take up to 48 hours
   - Usually completes in 5-30 minutes

---

### Issue: "Your connection is not private" Error

**Symptoms:**
- Browser shows security warning
- Certificate error message

**Solutions:**

1. **Check certificate status in ACM:**
   - Should be "Issued"
   - Should show "In use: Yes"

2. **Verify certificate attached to listener:**
   - EC2 → Load Balancers → Listeners
   - HTTPS:443 should show certificate

3. **Check domain name matches:**
   - Certificate: freeinterestcal.com
   - URL you're visiting: freeinterestcal.com
   - Must match exactly

4. **Clear browser cache:**
   - Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   - Or open incognito/private window

---

### Issue: DNS Not Resolving

**Symptoms:**
- "Site can't be reached"
- "DNS_PROBE_FINISHED_NXDOMAIN"

**Solutions:**

1. **Check A records exist:**
   - Route 53 → Hosted Zones → freeinterestcal.com
   - Should see A records for root and www

2. **Verify alias target:**
   - A record should point to ALB
   - Check ALB DNS name is correct

3. **Wait for DNS propagation:**
   - Can take 5-60 minutes
   - Test with: `nslookup freeinterestcal.com`

4. **Flush DNS cache:**
   - Windows: `ipconfig /flushdns`
   - Mac: `sudo dscacheutil -flushcache`
   - Linux: `sudo systemd-resolve --flush-caches`

---

### Issue: HTTP Not Redirecting to HTTPS

**Symptoms:**
- Accessing `http://` doesn't redirect
- Stays on HTTP

**Solutions:**

1. **Check HTTP listener configuration:**
   - EC2 → Load Balancers → Listeners
   - HTTP:80 should show "Redirect to HTTPS:443"

2. **Verify redirect action:**
   - Click on HTTP:80 listener
   - Default action should be "Redirect"
   - Protocol: HTTPS, Port: 443

3. **Test with curl:**
   ```bash
   curl -I http://freeinterestcal.com
   ```
   - Should return: `HTTP/1.1 301 Moved Permanently`
   - Location header should show HTTPS URL

---

### Issue: API Calls Failing

**Symptoms:**
- Frontend loads but can't fetch data
- Console shows CORS errors or connection errors

**Solutions:**

1. **Check HTTPS listener rules:**
   - HTTPS:443 → Rules
   - Should have rule for `/api/*`
   - Priority should be 1 (before default)

2. **Verify frontend environment variable:**
   - ECS → Task Definitions → frontend
   - Check `REACT_APP_API_URL`
   - Should be: `https://freeinterestcal.com`

3. **Test API directly:**
   - Visit: `https://freeinterestcal.com/health`
   - Should return JSON

4. **Check browser console:**
   - F12 → Console tab
   - Look for mixed content warnings
   - All requests should use HTTPS

---

### Issue: Mixed Content Warnings

**Symptoms:**
- Browser console shows: "Mixed Content"
- Some resources blocked
- Padlock icon has warning

**Solutions:**

1. **Update all HTTP URLs to HTTPS:**
   - Check frontend code
   - All API calls should use HTTPS
   - All external resources should use HTTPS

2. **Verify REACT_APP_API_URL:**
   - Should be `https://` not `http://`
   - Redeploy frontend if changed

3. **Check external resources:**
   - Images, fonts, scripts
   - Must all use HTTPS or relative URLs

---

## Best Practices You Implemented

### ✅ Security
- **SSL/TLS encryption** for all traffic
- **HTTP to HTTPS redirect** enforced
- **Certificate auto-renewal** enabled
- **Strong SSL policy** configured

### ✅ High Availability
- **Multi-AZ deployment** (ALB in 2 AZs)
- **Health checks** enabled
- **Alias records** with health evaluation

### ✅ Performance
- **DNS alias records** (faster than CNAME)
- **ALB caching** of SSL sessions
- **HTTP/2** support (automatic with HTTPS)

### ✅ Cost Optimization
- **Free SSL certificate** from ACM
- **No additional ALB cost** for HTTPS
- **Minimal Route 53 costs** (~$0.50/month)

---

## What You Learned

### AWS Services
1. **Certificate Manager (ACM)**
   - Request and manage SSL certificates
   - DNS validation process
   - Auto-renewal

2. **Route 53**
   - DNS management
   - Alias records
   - Hosted zones

3. **Application Load Balancer**
   - HTTPS listeners
   - SSL/TLS termination
   - Path-based routing
   - HTTP redirects

4. **ECS (Elastic Container Service)**
   - Task definitions
   - Environment variables
   - Service updates

### Concepts
- **SSL/TLS encryption**
- **DNS resolution**
- **Certificate validation**
- **Load balancer listeners**
- **Path-based routing**
- **HTTP status codes (301 redirect)**

### Skills
- ✅ Requesting and validating SSL certificates
- ✅ Configuring HTTPS on load balancers
- ✅ Managing DNS records
- ✅ Updating containerized applications
- ✅ Troubleshooting HTTPS issues

---

## Next Steps

### Enhance Security
1. **Add WAF (Web Application Firewall)**
   - Protect against common attacks
   - Rate limiting
   - IP blocking

2. **Enable Access Logs**
   - Track all requests
   - Security auditing
   - Troubleshooting

3. **Add Security Headers**
   - HSTS (Strict-Transport-Security)
   - X-Frame-Options
   - Content-Security-Policy

### Improve Performance
1. **Enable CloudFront CDN**
   - Faster content delivery
   - Global edge locations
   - Caching

2. **Optimize Images**
   - Compress images
   - Use modern formats (WebP)
   - Lazy loading

### Monitoring
1. **Set up CloudWatch Alarms**
   - Certificate expiration (backup)
   - High error rates
   - Latency alerts

2. **Enable Container Insights**
   - Monitor ECS performance
   - Track resource usage

---

## Cost Breakdown

### What You're Paying For

**Route 53:**
- Hosted Zone: **$0.50/month**
- DNS Queries: **$0.40 per million queries**
- Typical usage: **~$0.50-1.00/month**

**ACM Certificate:**
- **FREE** ✅

**ALB:**
- No additional cost for HTTPS
- Same price as HTTP-only

**Total Additional Cost: ~$0.50-1.00/month**

---

## Summary

### What You Accomplished

✅ Requested SSL/TLS certificate from ACM  
✅ Validated certificate using DNS  
✅ Configured HTTPS listener on ALB  
✅ Set up path-based routing for HTTPS  
✅ Configured HTTP to HTTPS redirect  
✅ Created DNS records in Route 53  
✅ Updated frontend configuration  
✅ Tested complete HTTPS setup  

### Your Application Now Has

🔒 **Secure HTTPS connection**  
🌐 **Custom domain** (freeinterestcal.com)  
🔄 **Automatic HTTP redirect**  
📜 **Valid SSL certificate**  
🔁 **Auto-renewing certificate**  
⚡ **Fast DNS resolution**  
🎯 **Professional appearance**  

---

**Congratulations!** 🎉

You've successfully configured HTTPS for your application using AWS services. Your application is now production-ready with enterprise-grade security!

**Access your secure application:**
- https://freeinterestcal.com
- https://www.freeinterestcal.com

Both URLs now work with HTTPS! 🚀🔒

