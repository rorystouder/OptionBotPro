# OptionBotPro Bug Tracker

**Created:** August 16, 2025  
**Last Updated:** August 16, 2025  
**Status:** In Progress - Collecting Issues

---

## 🐛 ACTIVE BUGS & ISSUES

### 1. "Connect TastyTrade" Button Non-Functional + Live Data Integration
- **Status:** 🟢 Fixed & Enhanced
- **Priority:** High
- **Component:** TastyTrade Integration
- **Description:** The "Connect TastyTrade" button is not working/functional + dashboard needs live account data
- **Impact:** Users cannot connect their brokerage accounts or see live trading data
- **Location:** Dashboard (/dashboard) - Quick Actions section
- **Expected Behavior:** Should connect user's TastyTrade account and display live data
- **Actual Behavior:** ~~Button linked to login page instead of TastyTrade connection~~ **FIXED**
- **Resolution:** ✅ **COMPLETED**
  - ✅ Created `TastytradeController` with connect/disconnect functionality
  - ✅ Added routes: `GET/POST /tastytrade/connect`, `DELETE /tastytrade/disconnect`
  - ✅ Built secure credential storage form with encryption
  - ✅ Integrated with existing `Tastytrade::AuthService`
  - ✅ Updated dashboard button to link to proper connection form
  - ✅ Added environment selection (Sandbox/Production)
  - ✅ Implemented disconnect functionality with dropdown menu
  - ✅ **Enhanced Dashboard with Live TastyTrade Integration:**
    - ✅ Updated `DashboardController#fetch_tastytrade_data` to pull live account data
    - ✅ Integrated real-time positions, balances, and transactions from TastyTrade API
    - ✅ Enhanced dashboard view to show connection status and account information
    - ✅ Added live data badges and account details display
    - ✅ Implemented `calculate_tastytrade_portfolio_summary` for live portfolio calculations
    - ✅ Updated positions table to handle TastyTrade API response format with instrument types
    - ✅ Added proper error handling for API failures
    - ✅ Connection works (user successfully authenticated) with token caching system

### 2. "Check Risk Status" Button Not Working
- **Status:** 🔴 Open
- **Priority:** High
- **Component:** Risk Management / Portfolio Protection
- **Description:** Check risk status button is not working
- **Impact:** Users cannot check their current risk protection status
- **Location:** TBD (likely dashboard or risk management section)
- **Error Message:** "Risk status available at: GET /api/v1/portfolio_protections/status"
- **Expected Behavior:** Should display current risk protection status
- **Actual Behavior:** Button fails with API endpoint error message
- **Notes:** API endpoint exists but button implementation may be broken
- **Technical Details:** 
  - API Route: `GET /api/v1/portfolio_protections/status`
  - Suggests frontend/backend integration issue

### 3. "Refresh Positions" Button Error
- **Status:** 🔴 Open
- **Priority:** High
- **Component:** Portfolio Management / Position Sync
- **Description:** Refresh positions button is not working
- **Impact:** Users cannot sync/refresh their current trading positions
- **Location:** TBD (likely dashboard or positions section)
- **Error Message:** "Use the API to sync positions. Endpoint: GET /api/v1/positions?account_id=YOUR_ID"
- **Expected Behavior:** Should sync current positions from TastyTrade account
- **Actual Behavior:** Button fails with API endpoint instruction message
- **Notes:** API endpoint exists but requires account_id parameter - frontend may not be passing it
- **Technical Details:** 
  - API Route: `GET /api/v1/positions?account_id=YOUR_ID`
  - Requires dynamic account_id parameter
  - Suggests frontend not properly integrating with backend API

### 4. "Place Order" Button Not Functional
- **Status:** 🔴 Open
- **Priority:** Critical
- **Component:** Trading / Order Management
- **Description:** Place Order button is not working
- **Impact:** Users cannot place trades - core functionality broken
- **Location:** TBD (likely trading/scanner interface)
- **Error Message:** "Use the API to place orders. Check /docs/api/API_INTEGRATION.md"
- **Expected Behavior:** Should submit trading orders to TastyTrade
- **Actual Behavior:** Button fails with documentation reference message
- **Notes:** Core trading functionality is non-functional - highest priority
- **Technical Details:** 
  - References: `/docs/api/API_INTEGRATION.md`
  - API implementation likely exists but frontend not connected
  - Critical for core application functionality

### 5. Payment Integration Not Connected
- **Status:** 🔴 Open
- **Priority:** Critical
- **Component:** Billing / Subscription Management
- **Description:** Payment integration is not connected/functional
- **Impact:** Users cannot subscribe or pay for services - revenue blocking
- **Location:** TBD (likely subscription/pricing pages)
- **Expected Behavior:** Should process payments for subscription tiers ($49/$149/$299)
- **Actual Behavior:** Payment system not connected
- **Notes:** Business-critical - blocks all revenue generation
- **Technical Details:** 
  - Needs Stripe or similar payment processor integration
  - Subscription tiers defined but payment flow missing
  - Related to MONETIZATION_STRATEGY.md implementation

### 6. Admin Metrics Page Missing Action
- **Status:** 🔴 Open
- **Priority:** Medium
- **Component:** Admin Panel / Analytics
- **Description:** Admin metrics page throws "Unknown action" error
- **Impact:** Admins cannot view business metrics and analytics
- **Location:** `http://127.0.0.1:3000/admin/metrics`
- **Error Message:** "Unknown action - The action 'metrics' could not be found for Admin::DashboardController"
- **Expected Behavior:** Should display admin business metrics dashboard
- **Actual Behavior:** Application error page with missing controller action
- **Notes:** Route exists but controller action not implemented
- **Technical Details:** 
  - Route defined in routes.rb: `get "metrics", to: "dashboard#metrics"`
  - Admin::DashboardController missing `metrics` action method
  - Need to implement metrics view and controller logic

### 7. Admin Subscription Tiers Controller Missing
- **Status:** 🔴 Open
- **Priority:** Medium
- **Component:** Admin Panel / Subscription Management
- **Description:** Admin subscription tiers page has missing controller
- **Impact:** Admins cannot manage subscription tiers and pricing
- **Location:** `http://127.0.0.1:3000/admin/subscription_tiers`
- **Error Message:** "Routing Error - uninitialized constant Admin::SubscriptionTiersController"
- **Expected Behavior:** Should display subscription tier management interface
- **Actual Behavior:** Routing error due to missing controller class
- **Notes:** Route exists but entire controller class is missing
- **Technical Details:** 
  - Route defined in routes.rb: `resources :subscription_tiers`
  - Need to create `Admin::SubscriptionTiersController` class
  - Need corresponding views for CRUD operations

### 8. Cloud Deployment Build Failures
- **Status:** 🔴 Open
- **Priority:** High
- **Component:** DevOps / Deployment Infrastructure
- **Description:** Unable to build/deploy on cloud platforms
- **Impact:** Cannot deploy to production - blocks go-live
- **Location:** Render.com and Railway.com deployment pipelines
- **Expected Behavior:** Should successfully build and deploy Rails application
- **Actual Behavior:** Build failures on multiple cloud platforms
- **Notes:** Deployment-blocking issue preventing production launch
- **Technical Details:** 
  - Affected Platforms: Render.com, Railway.com
  - Likely issues: Build configuration, environment setup, dependencies
  - Previous deployment configs exist but failing
  - Need to investigate build logs and fix deployment pipeline

### 9. Documentation Files in Wrong Directory Structure
- **Status:** 🟢 Fixed
- **Priority:** Low
- **Component:** Documentation / Project Organization
- **Description:** MD files are in root folder instead of proper docs structure
- **Impact:** Poor project organization, hard to find documentation
- **Location:** Root directory (/) 
- **Expected Behavior:** MD files should be in appropriate docs subfolders
- **Actual Behavior:** ~~All MD files except CLAUDE.md and README.md are in root~~ **FIXED**
- **Notes:** ✅ **COMPLETED** - Documentation properly organized
- **Resolution:** 
  - ✅ Moved deployment files to `docs/deployment/`: DEPLOY_NOW.md, DEPLOY_TO_HEROKU.md, INSTANT_DEPLOY.md, RAILWAY_FIX.md, RENDER_DEPLOYMENT.md, SIMPLE_DEPLOY.md, railway-fix.md
  - ✅ Moved setup files to `docs/setup/`: QUICKSTART.md, QUICK_START.md, SETUP.md
  - ✅ Moved PROJECT_SUMMARY.md to `docs/`
  - ✅ Kept README.md in root (CLAUDE.md already in docs/development/)

---

## 📝 COLLECTION STATUS
- **Issues Collected:** 9
- **Collection Complete:** ✅ Yes
- **Issues Fixed:** 2 (#1 Enhanced, #9)
- **Issues Remaining:** 7

---

## 🏷️ LEGEND
- 🔴 Open (Not Started)
- 🟡 In Progress
- 🟢 Fixed
- 🔵 Testing
- ⚫ Closed

**Priority Levels:**
- **Critical:** System broken, blocking core functionality
- **High:** Major feature broken, significant user impact
- **Medium:** Feature partially broken, moderate impact
- **Low:** Minor issue, cosmetic or edge case