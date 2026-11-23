# 📱 Mobile Product, Dual-Store, Growth & Operations Master Playbook (Expert Edition)

> **Objective:** Build expertise across the full mobile product lifecycle — from production-quality code to **Google Play** and **Apple App Store** compliance, discoverability, retention, revenue, campaigns, multi-device resilience, and category leadership.
>
> **Scope:** Both stores equally. Development alone is not enough; this book covers product, legal, store ops, growth, monetization, sales, and operations.
>
> **How to use:** Treat every checkbox as a competence area. Mark what you can execute end-to-end without help. Gaps = learning roadmap.

---

## Table of Contents

0. [Expertise Map — What “Mobile Expert” Must Cover](#0-expertise-map--what-mobile-expert-must-cover)
1. [Phase 1 — Product Strategy, Market & Pre-Build Decisions](#phase-1-product-strategy-market--pre-build-decisions)
2. [Phase 2 — Foundation, Telemetry, Security & Multi-Device Resilience](#phase-2-foundation-telemetry-security--multi-device-resilience)
3. [Phase 3 — Apple App Store Review Guidelines (Deep)](#phase-3-apple-app-store-review-guidelines-deep)
4. [Phase 4 — Google Play Developer Policies (Deep)](#phase-4-google-play-developer-policies-deep)
5. [Phase 5 — Dual-Store Console Configuration & Release Engineering](#phase-5-dual-store-console-configuration--release-engineering)
6. [Phase 6 — App Store Optimization (ASO), Charts & Featuring](#phase-6-app-store-optimization-aso-charts--featuring)
7. [Phase 7 — Userbase Management, Retention & Engagement](#phase-7-userbase-management-retention--engagement)
8. [Phase 8 — Support, Reputation, Reviews & Trust](#phase-8-support-reputation-reviews--trust)
9. [Phase 9 — Revenue Architecture & Monetization Yield](#phase-9-revenue-architecture--monetization-yield)
10. [Phase 10 — Sales Motions (B2C, B2B, Partnerships)](#phase-10-sales-motions-b2c-b2b-partnerships)
11. [Phase 11 — Organic Reach, Brand, PR & Community](#phase-11-organic-reach-brand-pr--community)
12. [Phase 12 — Paid User Acquisition, Campaigns & Attribution](#phase-12-paid-user-acquisition-campaigns--attribution)
13. [Phase 13 — Privacy, Legal, Tax & Regional Compliance](#phase-13-privacy-legal-tax--regional-compliance)
14. [Phase 14 — Localization, Accessibility & Inclusive Design](#phase-14-localization-accessibility--inclusive-design)
15. [Phase 15 — Platform Surfaces Beyond the Phone](#phase-15-platform-surfaces-beyond-the-phone)
16. [Phase 16 — Soft Launch, GTM, Launch Ops & Incident Response](#phase-16-soft-launch-gtm-launch-ops--incident-response)
17. [Phase 17 — Competitive Intelligence & Category Domination](#phase-17-competitive-intelligence--category-domination)
18. [Phase 18 — Org, Skills Ladder & Operating Cadence](#phase-18-org-skills-ladder--operating-cadence)
19. [Master KPI Scorecard](#master-kpi-scorecard-weekly-executive-review)
20. [Annual Dual-Store Compliance Calendar](#annual-dual-store-compliance-calendar)
21. [Appendix — Glossary & Primary Official Sources](#appendix--glossary--primary-official-sources)

---

## 0. Expertise Map — What “Mobile Expert” Must Cover

Shipping Flutter/Kotlin/Swift code is **one slice**. Category leadership requires mastery across these domains (both stores unless noted):

| Domain | What expertise looks like |
| :--- | :--- |
| **Product & UX** | Activation, habit loops, platform HIG/Material patterns, offline UX |
| **Engineering quality** | Crash/ANR, performance, battery, security, CI/CD, flavors |
| **Multi-device** | OEM killers, foldables, tablets, iPad, low-RAM, wearables, cars/TV |
| **Apple guidelines** | Review Guidelines 1–5, StoreKit, ATT, Privacy Manifest, Account Deletion |
| **Play policies** | Payments, Data Safety, permissions, Families, Deceptive Behavior, target API |
| **Store console ops** | Listings, tracks, staged rollout, content ratings, IAP catalog, tax |
| **ASO & charts** | Keywords, CVR creatives, experiments, featuring pitches |
| **Retention & CRM** | Cohorts, push journeys, in-app messaging, referral loops |
| **Support & reputation** | Review ops, CSAT, refunds, trust & safety |
| **Monetization** | IAP/subs, ads mediation, hybrid models, PPP pricing, churn recovery |
| **Sales** | B2C conversion, B2B demos/trials, partnerships, OEM preloads (rare) |
| **Growth marketing** | Organic, PR, influencers, communities, content SEO → store |
| **Paid UA** | ASA, UAC, Meta, MMP, SKAN, deep links, LTV:CAC |
| **Legal/privacy** | GDPR, CCPA, DPDP (India), COPPA, age ratings, export compliance |
| **Ops** | Soft launch, incidents, policy change monitoring, postmortems |

---

## Phase 1: Product Strategy, Market & Pre-Build Decisions

*Decide category, audience, monetization, and platform bets before writing features that fight store policy.*

### 1.1 Category, ICP & Problem Definition
- [ ] **Primary category + secondary category** chosen for both stores (they affect Browse/Explore ranking).
- [ ] **ICP (Ideal Customer Profile):** geography, language, device tier (flagship vs 2–3GB RAM), age band, B2C vs B2B.
- [ ] **Job-to-be-done:** one primary outcome the app must deliver in under 60 seconds on first open.
- [ ] **Competitive set:** top 10 apps in category on Play **and** App Store; map feature gaps, pricing, ratings, review themes.
- [ ] **Moat hypothesis:** offline, speed, local payments (UPI), hardware integration, workflow depth, brand trust — something hard to copy.

### 1.2 Monetization Model Decision (Before UI)
- [ ] Choose primary model: **Free + ads**, **Freemium + IAP**, **Subscription**, **Paid upfront**, **Hybrid**, **B2B SaaS (web pay for physical/service goods only where allowed)**.
- [ ] Map each SKU to **digital vs physical/real-world service** — this decides StoreKit / Play Billing vs external gateway legality.
- [ ] Define **trial length**, intro offers, family sharing (Apple), and Play base plans / offer tags.
- [ ] Decide **refund / cancellation UX** and where it lives (in-app manage subscription deep links to store).

### 1.3 Platform & Distribution Strategy
- [ ] **Android first / iOS first / simultaneous** based on ICP (e.g., India often Android-heavy; US premium often iOS-heavy).
- [ ] **Min OS versions** trade-off: coverage vs API surface (document % of addressable market).
- [ ] **Sideloading / alternative stores** (Amazon, Samsung Galaxy Store, Huawei) — only if ICP needs it; keep Play/App Store binaries policy-clean.
- [ ] **Web companion / admin panel** for B2B — never let the mobile app become a thin WebView wrapper (Apple 4.2 risk).

### 1.4 Pre-Launch Legal & Brand Assets
- [ ] Trademark search for app name; reserve domains + social handles.
- [ ] Privacy Policy + Terms of Service URLs (HTTPS, public, linked in both store consoles and in-app).
- [ ] Support email / help center URL that humans answer.
- [ ] Age rating questionnaire draft (IARC / App Store age rating) before screenshots are locked.

---

## Phase 2: Foundation, Telemetry, Security & Multi-Device Resilience

*Build kill-switches, observability, and hardware resilience before scaling traffic.*

### 2.1 Remote Control & Kill-Switch Infrastructure
- [ ] Integrate **Firebase Remote Config** (or PostHog / Statsig / LaunchDarkly).
- [ ] Startup gates:
  - `min_supported_version` → non-dismissible update dialog → store listing
  - `recommended_version` → dismissible banner
  - `is_maintenance_mode` → downtime screen with ETA / status link
  - `kill_switch_<feature>` → disable broken SDK/feature without waiting for review
- [ ] Feature-flag **every** new feature, paywall variant, ad unit, and risky third-party SDK.
- [ ] Config fetch strategy: cached defaults for offline; short TTL for critical gates; never block first paint forever.

### 2.2 Observability, Crash Reporting & Store Vitals
- [ ] **Crash tooling:** Firebase Crashlytics / Sentry / Bugsnag.
- [ ] CI must upload:
  - **Android:** R8/ProGuard mapping files per versionCode
  - **iOS:** dSYMs per build (Bitcode legacy N/A; still upload dSYMs)
- [ ] **Google Play Android Vitals** (weekly; ranking + warning banners):
  - User-perceived crash rate: bad behavior **≥ 1.09%** · Target **< 0.30%**
  - User-perceived ANR: bad behavior **≥ 0.47%** · Target **< 0.15%**
  - Per-device-model crash/ANR: threshold **~8%**
  - Excessive wakeups / stuck partial wake locks / slow cold start where applicable
- [ ] **Apple Xcode Organizer / MetricKit:** Hang Rate, Launch Time, Scroll Hitches, Disk Writes, Memory / Jetsam (OOM), Battery.
- [ ] **Performance budgets:** cold start p50/p95, frame time (jank), network p95, DB query p95.
- [ ] **Session replay / heatmaps** on onboarding + checkout (UXCam / PostHog / Clarity) — respect privacy & consent.
- [ ] Structured logging + correlation IDs; **no PII in logs**; no `print` in production builds.

### 2.3 App Security, Integrity & Anti-Abuse
- [ ] **Google Play Integrity API** / **Apple App Attest / DeviceCheck** for sensitive APIs.
- [ ] Certificate pinning where threat model requires it (with remote pin rotation plan).
- [ ] Secure storage for tokens (Keychain / EncryptedSharedPreferences); never in plain UserDefaults/SharedPreferences.
- [ ] Root/jailbreak heuristics only as soft signals — do not brick legitimate users.
- [ ] Rate-limit auth, OTP, and payment-adjacent endpoints; bot & credential-stuffing defenses.
- [ ] Backup/export rules: exclude secrets from Android Auto Backup / iCloud where needed.

### 2.4 Multi-Device Support & Hardware Fragmentation
#### Android
- [ ] OEM background killers (Xiaomi/HyperOS, Oppo ColorOS, Vivo, Realme, OnePlus): WorkManager, correct **Foreground Service types** (Android 14+), battery optimization education UI.
- [ ] Profile on **2GB/3GB RAM** devices; shrink images; avoid giant JSON on main isolate/thread.
- [ ] Offline-first local DB (SQLite / Drift / Room) for patchy 3G/4G.
- [ ] Adaptive layouts: phones, **tablets**, **foldables** (posture/hinge), ChromeOS, desktop windowing.
- [ ] Edge-to-edge, gesture nav, cutouts, 16 KB page-size readiness as Google requires.
- [ ] Dark theme, dynamic color / Material You where brand allows.

#### Apple
- [ ] Safe areas: notch, Dynamic Island, home indicator, Stage Manager windows.
- [ ] **iPad:** Split View, Slide Over, multitasking size classes, pointer/keyboard.
- [ ] **Mac Catalyst / Apple Silicon Mac** listing only if UX is truly desktop-capable.
- [ ] Native expectations when relevant: Sign in with Apple, Widgets, Live Activities, App Intents, Share Extension, Apple Watch companion.

#### Cross-platform quality bar
- [ ] Real-device matrix before production: low/mid/high Android OEMs + recent iPhones + one iPad.
- [ ] **Play Pre-Launch Reports / Firebase Test Lab** + **TestFlight** + BrowserStack/Firebase device lab.
- [ ] Network condition testing: offline, flaky, captive portal, IPv6-only.

### 2.5 Performance, Battery & Data Cost
- [ ] Image pipelines: WebP/AVIF, caching, correct decode size.
- [ ] Background work batched; respect Doze / App Standby / BGTaskScheduler.
- [ ] Minimize cellular payload; compress APIs; pagination everywhere.
- [ ] Startup path: defer non-critical SDK init (ads, analytics heavy kits) behind first frame / consent.

---

## Phase 3: Apple App Store Review Guidelines (Deep)

*Primary source: [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/). Rejections and account termination risk live here.*

### 3.1 Safety (Guideline 1)
- [ ] **1.1 Objectionable Content:** No porn, defamation, or illegal content; UGC apps need filter + report + block.
- [ ] **1.2 User-Generated Content:** moderation plan, EULA, filtering, report mechanism, timely response.
- [ ] **1.3 Kids Category:** COPPA-aligned; limited data; parental gates; no behavioral ads.
- [ ] **1.4 Physical Harm:** medical apps — disclaimers; no reckless behavior encouragement.
- [ ] **1.5 Developer Information:** accurate support contact; no fake identity.
- [ ] **1.6 Data Security:** protect user data in transit/rest; breach readiness.
- [ ] **1.7 Reporting Criminal Activity:** where required by category.

### 3.2 Performance (Guideline 2)
- [ ] **2.1 App Completeness:**
  - No placeholder content, broken links, or “lorem ipsum”.
  - Provide **demo account / OTP bypass** in Review Notes for login walls, hardware, region locks.
  - Hardware accessories: provide loaner hardware or video + demo path if needed.
- [ ] **2.2 Beta Testing:** TestFlight for betas; don’t use production App Store for unfinished apps.
- [ ] **2.3 Accurate Metadata:** screenshots = real UI; no other apps visible; no misleading tips/reviews.
- [ ] **2.4 Hardware Compatibility:** declare required capabilities; don’t crash on unsupported devices.
- [ ] **2.5 Software Requirements:** public APIs only; no private API; background modes must be justified; IPv6; UIWebView banned (use WKWebView).

### 3.3 Business (Guideline 3) — Payments & Commerce
- [ ] **3.1.1 In-App Purchase:** digital goods, unlocks, subscriptions, coins, ad removal → **StoreKit** only.
- [ ] **No external payment CTAs** for digital content (buttons, links, “subscribe on website”) unless under allowed entitlements (e.g., reader, multiplatform services, or region-specific external link entitlements with strict rules).
- [ ] **3.1.3(a) “Reader” apps**, **3.1.3(b) Multiplatform services**, **3.1.3(c) Enterprise**, **3.1.3(d) Person-to-person**, **3.1.3(e) Services outside app**, **3.1.3(f) Free stand-alone apps** — know which bucket you are in.
- [ ] **3.1.2 Subscriptions:** clear length/price; easy manage/cancel; functional value across term.
- [ ] **3.1.5 Cryptocurrencies / NFTs:** follow extra restrictions; mining on-device banned.
- [ ] **3.2.1 Acceptable:** fair business; no spam apps; no forced ratings.
- [ ] **3.2.2 Unacceptable:** creating multiple spammy apps; purchasing reviews; artificially manipulating charts.

### 3.4 Design (Guideline 4)
- [ ] **4.1 Copycats:** no clone of another app’s brand/UI/identity.
- [ ] **4.2 Minimum Functionality:** not a repackaged website; not a thin marketing brochure; provide lasting native value.
- [ ] **4.2.3** HTML5 games / streaming game services — follow special rules.
- [ ] **4.3 Spam:** don’t submit near-duplicate apps.
- [ ] **4.4 Extensions:** correct extension types; Shared with You / widgets quality bar.
- [ ] **4.5 Apple Sites & Services:** follow Music, ARKit, etc. rules.
- [ ] **4.7 Mini apps / streaming games / chatbots / plugins:** disclosure & IAP rules.
- [ ] **4.8 Login Services:** if third-party social login exists → **Sign in with Apple** with equivalent prominence + privacy options.
- [ ] **4.9 Apple Pay:** use when offering Apple Pay; correct merchant experience.

### 3.5 Legal (Guideline 5)
- [ ] **5.1.1 Data Collection & Storage:** privacy policy; purpose strings (`NSCameraUsageDescription`, etc.) must be accurate and specific.
- [ ] **5.1.1(v) Account Deletion:** if account creation exists → **in-app** permanent deletion of account **and** associated data (web-only link is insufficient).
- [ ] **5.1.2 Data Use & Sharing / ATT:** request tracking permission only when required; explain clearly; don’t gate core features behind ATT.
- [ ] **5.1.3 Health / HomeKit / Kids:** extra consent & data limits.
- [ ] **5.2 Intellectual Property:** no trademark infringement; licensed content only.
- [ ] **5.3 Gaming / Gambling / Contests:** legal in each region; geofence if needed.
- [ ] **5.4 VPN Apps:** use NEVPNManager; disclose; no sell of user data.
- [ ] **5.5 Mobile Device Management:** MDM entitlement restrictions.
- [ ] **Privacy Manifest (`PrivacyInfo.xcprivacy`):** declare Required Reason APIs + ensure third-party SDKs ship manifests.
- [ ] **Nutrition Labels / App Privacy** in App Store Connect must match actual SDK behavior.

### 3.6 Apple Review Operations Checklist
- [ ] Review Notes: demo credentials, 2FA bypass, geographic notes, hardware notes.
- [ ] Contact info current; reply to Resolution Center within 24–48h.
- [ ] Appeal vs fix decision framework; never argue without a guideline citation.
- [ ] Export compliance / encryption questionnaire answered correctly.
- [ ] Content rights attachments when using third-party brands/media.

---

## Phase 4: Google Play Developer Policies (Deep)

*Primary sources: [Play Console Policies](https://play.google.com/about/developer-content-policy/) + [Developer Program Policies](https://support.google.com/googleplay/android-developer/topic/9858052). Violations → removal, ranking suppression, or **developer account termination**.*

### 4.1 Restricted Content & Misrepresentation
- [ ] **Restricted content:** hate, violence, sexual content, illegal activities — follow category rules.
- [ ] **Deceptive behavior:** no misleading functionality; no cloaking different behavior post-review.
- [ ] **Impersonation:** no competitor names/logos in title, icon, screenshots, or developer name.
- [ ] **Misleading claims:** avoid “#1”, “100% Free” when paid IAP exists; screenshots must show real UI.
- [ ] **Device / network abuse:** no unauthorized SMS, call fraud, cryptomining, spam.

### 4.2 Monetization & Payments Policy
- [ ] **Play Billing** required for digital goods, subscriptions, and in-app virtual currency.
- [ ] External gateways (**Razorpay / Cashfree / Stripe / Paytm**) only for **physical goods**, **real-world services** (rides, food, bookings), or **peer-to-peer** where policy allows.
- [ ] **User Choice Billing / alternative billing** only in eligible countries/programs — implement Play’s required disclosures and fee remittance.
- [ ] Subscriptions: use Play Billing base plans + offers; clear renewal terms; deep link to Play subscription center.
- [ ] Ads: disclosure; no ad fraud; Families / Ads certifications when applicable.

### 4.3 Permissions, APIs & Sensitive Capabilities
Declare and justify; often need **Permissions Declaration Form** + **video walkthrough**:
- [ ] `ACCESS_BACKGROUND_LOCATION` (strongly discouraged unless core)
- [ ] SMS / Call Log permissions — prefer **SMS Retriever / User Consent API** for OTP
- [ ] `QUERY_ALL_PACKAGES` / package visibility — minimize; declare
- [ ] `MANAGE_EXTERNAL_STORAGE` — prefer Photo Picker / SAF / MediaStore
- [ ] Exact alarms / full-screen intents / FGS types — declare correctly for Android 14+
- [ ] Accessibility API — only for genuine accessibility tools, not for overlay adware/fraud
- [ ] Health / Finance / VPN / Cryptocurrency — follow vertical policies

### 4.4 Target API, Packages & Technical Requirements
- [ ] Meet Google’s annual **targetSdkVersion** deadline or lose update ability / visibility on new Android.
- [ ] Publish **AAB** (Android App Bundle); enable Play App Signing.
- [ ] 64-bit compliance; page-size / memory requirements as announced.
- [ ] No dangerous downloaded code that bypasses Play review (policy on dynamic code loading).

### 4.5 Data Safety, Privacy & Account Deletion
- [ ] **Data Safety form:** declare collection, sharing, encryption in transit, deletion practices for **your code + all SDKs** (Firebase, Ads, MMP, Meta, etc.).
- [ ] Independent **security review** if required for certain categories.
- [ ] **In-app account deletion** + **public web deletion URL** both required when accounts exist.
- [ ] Prominent disclosure + in-app consent for sensitive data (location, mic, camera) before permission prompt.
- [ ] Families Policy / Designed for Families / Teacher Approved if kids are audience.

### 4.6 Store Listing, Ratings & UGC
- [ ] Content ratings questionnaire (IARC) accurate.
- [ ] News / Political / Government apps — additional requirements.
- [ ] UGC: moderation, flagging, blocking, under-age protections.
- [ ] Health claims substantiation where needed.

### 4.7 Malware, Spam & Multiple Accounts
- [ ] No malware, phishing, social engineering.
- [ ] No repetitive spam apps / keyword stuffing across catalog.
- [ ] **Associated developer accounts:** never share keystores, payment profiles, browsers, static office IPs across unrelated Play accounts — association bans are common and brutal.
- [ ] Closed testing requirements for new personal accounts: often **≥ 12 testers for ≥ 14 days** before production.

### 4.8 Play Review / Enforcement Operations
- [ ] Policy status dashboard monitored weekly.
- [ ] Pre-launch report + internal testing before production.
- [ ] Appeals via Play Console with evidence; fix root cause before resubmit.
- [ ] Instant freeze plan if app is suspended (comms, status page, user email).

---

## Phase 5: Dual-Store Console Configuration & Release Engineering

*Make store infrastructure correct so binaries, money, and metadata don’t become the bottleneck.*

### 5.1 Developer Accounts & Access Control
- [ ] **Apple:** Apple Developer Program (org vs individual); App Store Connect roles (Account Holder, Admin, App Manager, Developer, Marketing, Finance, Sales).
- [ ] **Google:** Play Console users/roles; link merchant account; verify organization (D-U-N-S where required).
- [ ] Enforce 2FA everywhere; hardware keys preferred for Account Holder.
- [ ] Separate CI service accounts; never commit secrets; rotate upload keys / API keys.

### 5.2 Fee Reduction, Tax & Banking
- [ ] **Google Play:** enroll **15% service fee tier** (first $1M USD/year after enrollment rules).
- [ ] **Apple:** apply **App Store Small Business Program** (15% under $1M USD/year).
- [ ] Tax forms: W-8BEN / W-9 / local GST-PAN (India) in **both** consoles.
- [ ] Bank details verified; understand withholding, GST on digital services, invoice flows.
- [ ] Track **net revenue** after commission (15–30%) for all LTV math.

### 5.3 App Identity & Store Listing Shell (Both Stores)
#### Google Play Console
- [ ] Package name final (`com.brand.app`) — immutable; include keyword carefully.
- [ ] Default store listing: title (30), short (80), full (4000), icon (512), feature graphic (1024×500), phone + tablet + Chromebook screenshots as needed.
- [ ] Categories, tags, contact email/website/phone, Privacy Policy URL.
- [ ] Data Safety, Ads declaration, Content rating, Target audience, News app declaration if any.
- [ ] Countries/regions distribution set.
- [ ] App access instructions for reviewers (login/OTP).

#### App Store Connect
- [ ] Bundle ID, SKU, primary locale.
- [ ] Name (30), Subtitle (30), Keyword field (100), Promotional Text (170), Description, What’s New.
- [ ] Icon, screenshots per required device sizes (6.7", 6.5", 5.5", iPad if supported), optional App Preview videos.
- [ ] Age rating questionnaire, App Privacy nutrition labels, Encryption export compliance.
- [ ] Pricing and availability; pre-order if used.
- [ ] Review Notes + contact + demo account.
- [ ] Sign in with Apple capability if required; associated domains for Universal Links.

### 5.4 IAP / Subscription Catalog Setup
- [ ] **Play:** products, base plans, offers, tags, prepaid/auto-renewing as applicable; license testers.
- [ ] **Apple:** consumable / non-consumable / non-renewing / auto-renewable; subscription groups; introductory / promotional offers; StoreKit Configuration for local tests; Sandbox / StoreKit Testing.
- [ ] Server source of truth for entitlements; webhook handling (RevenueCat/Adapty or native).
- [ ] Restore purchases UX on both platforms.

### 5.5 Binary Optimization
- [ ] **Play:** AAB, `minifyEnabled` + `shrinkResources`, R8, per-ABI splits via Play, Play Feature Delivery for heavy modules, WebP/AVIF.
- [ ] **Apple:** App Thinning, asset catalogs, On-Demand Resources, strip unused architectures, bitcode N/A on modern Xcode — still watch download size.
- [ ] Track install size vs update size; set internal budgets (e.g., < 50–100MB download when possible).

### 5.6 Testing Tracks & Review Pipelines
| Stage | Google Play | Apple |
| :--- | :--- | :--- |
| Dev team | Internal testing | Internal TestFlight (≤100) |
| Trusted users | Closed testing (12+ / 14 days often required for new accounts) | External TestFlight (≤10k, Beta App Review) |
| Public beta | Open testing | External TestFlight public link |
| Prod | Production + staged rollout | App Store + phased release |

- [ ] Versioning scheme: `major.minor.patch` + monotonic `versionCode` / `CFBundleVersion`.
- [ ] Changelog (“What’s New”) written for humans + lightly keyword-aware on Play.
- [ ] Smoke checklist per RC: login, paywall, restore, offline, permission denials, deep links.

### 5.7 Staged / Phased Rollouts & Kill Criteria
- [ ] **Play staged rollout:** 5% → 10% → 25% → 50% → 100%; halt on crash/ANR spike or policy issue.
- [ ] **Apple phased release:** 7-day ramp 1% → 2% → 5% → 10% → 20% → 50% → 100%; Pause or Release to All.
- [ ] Pre-define **kill criteria** (e.g., crash-free < 99.5%, checkout error rate > X%, payment success < Y%).
- [ ] Hotfix / expedited review request process documented (Apple Expedited Review — use sparingly).

### 5.8 CI/CD & Supply Chain
- [ ] Automated build flavors/schemes (dev/staging/prod).
- [ ] Signing in secure CI (Play upload key, Apple distribution certs via Asc / Match / ESC).
- [ ] Upload symbols every release.
- [ ] Dependency scanning; pin versions; review SDK privacy manifests.
- [ ] Release train cadence (e.g., biweekly) with code freeze + QA window.

---

## Phase 6: App Store Optimization (ASO), Charts & Featuring

*Engineer discoverability + conversion on **both** stores; charts follow velocity × retention × rating quality.*

### 6.1 Research & Keyword Strategy
- [ ] Tools: AppTweak / Sensor Tower / data.ai / Appfigures / Play Console & ASC search suggestions.
- [ ] Build keyword map: brand, generic category, problem/outcome, competitor conquesting (ethical — no trademark abuse in metadata where forbidden).
- [ ] Local keyword lists per locale (Hindi/English India, Spanish LATAM, Portuguese BR, Arabic, etc.).
- [ ] Track impressions → product page views → conversion → installs weekly.

### 6.2 Google Play Listing Indexing
- [ ] **Title (30):** `Brand – Primary Keyword` (highest weight).
- [ ] **Short description (80):** value prop + secondary keywords.
- [ ] **Long description (4000):** crawlable; **~2–3% natural density**; scannable bullets; no stuffing.
- [ ] Hidden signals: package name, developer name, ratings volume/velocity, review text keywords.
- [ ] Custom Store Listings (up to ~50): by country, acquisition source, or installed base.
- [ ] Store Listing Experiments: icon, feature graphic, screenshots, short description.

### 6.3 Apple App Store Listing Indexing
- [ ] **Name (30) + Subtitle (30) + Keywords (100):** comma-separated, **no spaces**, singular, no duplicates of Name/Subtitle words.
- [ ] Description: conversion-focused (Apple search does **not** index description the way Play does).
- [ ] **Promotional Text:** change anytime without binary review — seasonal CRO.
- [ ] IAP display names/descriptions are searchable — keyword them carefully.
- [ ] Custom Product Pages (up to ~35) + Product Page Optimization (≤3 treatments).

### 6.4 Visual CRO (Both Stores)
- [ ] **First 3 screenshots rule** (users decide in ~3 seconds):
  1. Core outcome + clean UI
  2. Primary differentiator
  3. Trust / social proof / secondary power feature
- [ ] Localized caption language; avoid unreadable tiny UI.
- [ ] App Preview / demo video: show task completion in first 5–8 seconds.
- [ ] Icon: recognizable at 48px; unique silhouette; A/B test.

### 6.5 Ratings, Reviews & Ranking Signals
- [ ] In-app review prompts **only after Happy Moment** (`InAppReview` / `SKStoreReviewController`; Apple ~3× per 365 days).
- [ ] Never prompt on cold launch, after crash, or after payment failure.
- [ ] Respond to 1–3★ within 24h; include natural keywords in **Play** replies.
- [ ] 72-hour launch velocity plan (PR + social + email + light paid) for Trending / Similar Apps algorithms.
- [ ] Editorial featuring: ASC “Promote Your App” + Play editorial pitch **4–6 weeks** before major native-feature releases (Widgets, Live Activities, Material You, foldables, Accessibility).

### 6.6 Chart & Category Domination Levers
- [ ] Optimize for **conversion × retention × rating** — paid installs with instant uninstall hurt rank.
- [ ] Category choice: competitive vs winnable subcategory.
- [ ] Update cadence: meaningful updates beat spammy micro-updates.
- [ ] Seasonal events calendar aligned to store featuring themes.

---

## Phase 7: Userbase Management, Retention & Engagement

*Most installs are wasted without activation and a Day-0–7 system. Dominate usage before dominating spend.*

### 7.1 Analytics & Activation
- [ ] Stack: Firebase Analytics + Mixpanel / Amplitude / PostHog (pick one product analytics depth tool).
- [ ] Define **Aha! Moment** correlated with D30 retention; reach it in **< 60 seconds** when possible.
- [ ] Canonical funnel: `app_first_open` → `onboarding_completed` → `signup_completed` → `aha_moment_reached` → `paywall_viewed` → `trial_started` → `purchase_completed` → `core_action_repeat`.
- [ ] Cohorts: **D1 / D3 / D7 / D14 / D30**; stickiness **DAU/MAU** (utilities ~15–20%+, daily habit ~40%+).
- [ ] Segment by: geo, device tier, acquisition source, platform (iOS vs Android).

### 7.2 Onboarding & Habit Design
- [ ] Deferred signup when legally/product-wise possible (value before wall).
- [ ] Progressive permissions: ask in context, never stack-prompt on launch.
- [ ] Habit loop: cue → action → reward → investment (streaks, saved work, social proof).
- [ ] Empty states that teach the next best action.

### 7.3 Lifecycle CRM
- [ ] Messaging stack: OneSignal / CleverTap / MoEngage / Customer.io / Firebase + ESP.
- [ ] Channels: push, in-app messages, email, SMS/WhatsApp where consented and legal.
- [ ] Example journeys:
  - T+2h incomplete onboarding
  - T+24h zero core actions
  - D3/D7 milestone + review prompt eligibility
  - D5–D7 at-risk winback
  - Post-purchase education / activation
  - Billing failure dunning
- [ ] Quiet hours, frequency caps, preference center, easy unsubscribe (store + privacy expectations).

### 7.4 Push, Deep Links & Re-engagement Hygiene
- [ ] Rich push; actionable categories; Android notification channels.
- [ ] Deep link every campaign to the exact screen (see Phase 12).
- [ ] Measure push-attributed opens and incremental lift (holdout groups).
- [ ] Remove dead tokens; respect OS permission rates; track opt-in %.

### 7.5 Product-Led Growth Loops
- [ ] Shareable outputs (PDF/image/link) branded.
- [ ] Referral rewards compliant with store payment rules.
- [ ] Invite / collaboration features for multiplayer or multi-role products (e.g., POS cashier + owner).
- [ ] UGC that creates network effects with moderation.

---

## Phase 8: Support, Reputation, Reviews & Trust

*High usage dies if trust dies. Support is a growth and ranking function.*

### 8.1 Support Operations
- [ ] Help center (searchable) + in-app contact.
- [ ] SLAs: critical billing bugs &lt; 24h; general &lt; 48–72h.
- [ ] Macros for common issues; escalate path to engineering.
- [ ] Track CSAT / ticket themes → product backlog.

### 8.2 Reviews & Store Reputation
- [ ] Daily review inbox monitoring (Play + ASC).
- [ ] Public reply playbook: apologize, solve, invite to update, don’t argue.
- [ ] Detect review bombing / fraud; report to store when appropriate.
- [ ] “What’s New” addresses top review complaints each release.

### 8.3 Refunds, Chargebacks & Trust & Safety
- [ ] Know store refund policies; respond to Apple/Google refund notifications.
- [ ] Fraudulent purchase / account sharing policy.
- [ ] Abuse reporting for UGC; illegal content takedown process.
- [ ] Status page for outages; proactive store review replies during incidents.

---

## Phase 9: Revenue Architecture & Monetization Yield

*Predictable net revenue after store commission; optimize yield without destroying retention.*

### 9.1 Subscriptions & IAP
- [ ] Unify with **RevenueCat / Adapty** (or solid native + server validation).
- [ ] Paywall after value demonstration; social proof; clear comparison table.
- [ ] Price anchoring: weekly/monthly vs annual (“Best value”).
- [ ] Trials: 3-day / 7-day experiments; trial-to-paid conversion tracking.
- [ ] **PPP pricing** by country; India UPI AutoPay via Play where available.
- [ ] Grace period + account hold (both stores) + dunning messages.
- [ ] Win-back offers; pause subscriptions where supported.
- [ ] Family Sharing / Play multiple-user considerations for consumer apps.
- [ ] Entitlement sync across devices; restore purchases tested on both OS.

### 9.2 Ads Monetization
- [ ] Mediation: AdMob Mediation / AppLovin MAX / Unity LevelPlay.
- [ ] Networks: Meta AN, Mintegral, Liftoff, Pangle, etc.
- [ ] Prefer **Rewarded** + **Native**; cap **Interstitials**; never cold-launch or back-button spam.
- [ ] Geo eCPM floors (Tier-1 higher).
- [ ] Ad quality / UX metrics vs retention; kill units that tank D1.
- [ ] Families / kids ad certifications if applicable.

### 9.3 Hybrid & B2B Revenue Notes
- [ ] Hybrid: ads for free tier + sub for pro — ensure policy-clean messaging (“remove ads” = IAP).
- [ ] B2B: physical devices, SaaS seats, services may use external billing when policy allows — document rationale; keep digital unlock paths on store billing.
- [ ] Track **ARPDAU**, **ARPU**, **trial start rate**, **gross vs net revenue**, **refund rate**.

### 9.4 Pricing Experiments
- [ ] Run geo and paywall creative experiments continuously.
- [ ] Guardrails: never test illegal external payment CTAs on iOS digital goods.
- [ ] Annual planning: price increases with grandfathering strategy.

---

## Phase 10: Sales Motions (B2C, B2B, Partnerships)

*“Sales” for mobile = conversion systems, not only enterprise AE motions.*

### 10.1 B2C Sales System
- [ ] Store page = landing page; paywall = closer.
- [ ] Objection handling in UI: price, trust, “will I be charged”, cancel path clarity.
- [ ] Cart/paywall abandonment messaging (compliant).
- [ ] Seasonal promotions via Promotional Offers / Play offers.

### 10.2 B2B / Prosumer Sales (e.g., POS, field tools)
- [ ] Demo accounts, sandbox tenants, sales deck, ROI one-pager.
- [ ] Trial length for businesses; onboarding concierge for high ACV.
- [ ] Contract + invoice path that does **not** violate IAP rules for digital features.
- [ ] Device fleet realities: cheap Android terminals, printers, barcode scanners — test hardware.
- [ ] Admin web + mobile role separation.

### 10.3 Partnerships & Distribution
- [ ] Affiliate / influencer contracts with MMP tracking.
- [ ] OEM / carrier / retailer partnerships (long lead times).
- [ ] Marketplace integrations; accountant/consultant channel for business apps.
- [ ] Cross-promo with non-competing apps (policy-safe).

---

## Phase 11: Organic Reach, Brand, PR & Community

*Paid UA amplifies a machine that already converts organically.*

### 11.1 Content & SEO → Store
- [ ] Brand site with ASO-aligned messaging + store badges.
- [ ] Comparison pages, use-case blogs, tutorial content ranking in Google → store.
- [ ] YouTube / short-form demos of the aha moment.

### 11.2 PR & Launch Velocity
- [ ] Press kit: icon, screenshots, founder story, fact sheet.
- [ ] Product Hunt / regional launch sites / niche newsletters.
- [ ] 72-hour launch burst plan (see 6.5).

### 11.3 Community & Social Proof
- [ ] Discord/Telegram/WhatsApp/Reddit/Facebook groups as fits ICP.
- [ ] Case studies; user-generated before/after.
- [ ] Influencer seeding with unique CPP/CSL links.

### 11.4 Brand Safety
- [ ] Consistent naming, icon, color across stores and ads (trust + recognition).
- [ ] Crisis comms templates for outages / data issues / policy strikes.

---

## Phase 12: Paid User Acquisition, Campaigns & Attribution

*Scale only after D7 retention and monetization unit economics are proven.*

### 12.1 Measurement Foundations
- [ ] MMP: AppsFlyer / Adjust / Branch / Singular.
- [ ] **Android App Links** (`assetlinks.json`) + **iOS Universal Links** (`apple-app-site-association`) + deferred deep linking.
- [ ] **SKAN 4.0** conversion value map (0–63) for early events: onboarding, trial, purchase.
- [ ] Android Privacy Sandbox / Topics awareness as ecosystem evolves.
- [ ] Consent Mode / ATT-aware analytics configuration.
- [ ] Fraud controls: click injection, install hijacking (MMP protect).

### 12.2 Channel Playbooks
1. **Apple Search Ads (ASA):** high-intent; Custom Product Pages; brand vs category vs competitor campaigns; CPT/CPA goals.
2. **Google App Campaigns (UAC):** tCPI → tCPA → tROAS as conversion volume matures (aim 50+ conversions/day before climbing goal types).
3. **Meta (FB/IG):** 3–5 creative hooks every 10–14 days; UGC & problem/solution; AEM / aggregated events priority.
4. **Others when ready:** TikTok, Unity, ironSource, Reddit, Snap — only with creative + MMP readiness.
5. **Influencer / affiliate:** trackable links; disclose paid partnerships.

### 12.3 Creative Ops
- [ ] Creative backlog: hooks, demos, testimonials, founder story.
- [ ] Localize creatives for top geos.
- [ ] Kill rules: CPI/CPA regression or retention of paid cohort below organic.

### 12.4 Unit Economics Guardrails
- [ ] Metrics: CPI, CPA, CAC, ARPU, ARPDAU, LTV (net), payback period, ROAS D7/D30.
- [ ] Target **net LTV ≥ 3 × CAC**.
- [ ] Payback **&lt; 30–60 days** for bootstrapped sustainability.
- [ ] Separate iOS vs Android economics (ATT / SKAN changes iOS math).
- [ ] Never scale a channel with good CPI but catastrophic D1 retention.

---

## Phase 13: Privacy, Legal, Tax & Regional Compliance

*Store policies ∩ national law. Experts track both.*

### 13.1 Global Privacy Regimes
- [ ] **GDPR (EU/EEA/UK):** lawful basis, DPA with vendors, DSR (access/delete), DPO if required, cookie/tracker consent.
- [ ] **CCPA/CPRA (California):** notice, opt-out of sale/share, sensitive data limits.
- [ ] **India DPDP Act:** consent, purpose limitation, deletion, significant data fiduciary duties as applicable.
- [ ] Others as you expand: LGPD (Brazil), PIPEDA (Canada), APPI (Japan), etc.

### 13.2 Platform Privacy Overlays
- [ ] Apple ATT + Privacy Manifest + nutrition labels.
- [ ] Play Data Safety + prominent disclosures.
- [ ] Age gates / parental consent for minors; Families / Kids policies.

### 13.3 Vertical & Regional Law
- [ ] Fintech / lending / health / dating / gambling — licenses & geo restrictions.
- [ ] Consumer protection & dark-pattern bans (subscriptions clarity).
- [ ] Accessibility laws (ADA / EAA / AODA) for consumer apps.

### 13.4 Tax & Accounting Ops
- [ ] Store tax forms complete; GST/VAT implications for digital services.
- [ ] Revenue recognition for subscriptions; refund reserves.
- [ ] Transfer pricing if multi-entity.

---

## Phase 14: Localization, Accessibility & Inclusive Design

*Top charts in multiple countries require more than translated strings.*

### 14.1 Localization (L10n / i18n)
- [ ] Externalize all user strings; ICU plural/gender rules.
- [ ] Localize store metadata + screenshots, not just UI.
- [ ] RTL layouts (Arabic/Hebrew); date/number/currency formats.
- [ ] Local payment methods & PPP prices.
- [ ] Customer support language coverage for top geos.
- [ ] Cultural QA (images, colors, examples).

### 14.2 Accessibility
- [ ] Dynamic type / font scaling; TalkBack / VoiceOver labels.
- [ ] Contrast, hit targets, captions, reduce motion.
- [ ] Accessibility as featuring angle (Apple/Google love this in pitches).
- [ ] Test with real assistive tech users when possible.

---

## Phase 15: Platform Surfaces Beyond the Phone

*More surfaces = more engagement opportunities and more review surface area.*

- [ ] Widgets (home screen / lock screen / Stacks)
- [ ] Watch apps / complications
- [ ] Live Activities / Dynamic Island / ongoing notifications
- [ ] App Clips (Apple) / Instant Apps (Android) for lightweight tasks
- [ ] Share extensions / App Intents / Shortcuts / Google Assistant actions
- [ ] Foldables & large screens (see 2.4)
- [ ] Automotive (Android Auto / Automotive OS, CarPlay) if ICP fits
- [ ] TV (Android TV / tvOS) only with lean-back UX
- [ ] Desktop parity (ChromeOS / macOS) when declared supported

---

## Phase 16: Soft Launch, GTM, Launch Ops & Incident Response

### 16.1 Soft Launch
- [ ] Pick 1–2 geos with cheaper CPI and similar ICP (e.g., soft launch countries before India/US scale).
- [ ] Validate: crash-free, onboarding→aha, D1/D7, paywall CVR, support load.
- [ ] Freeze scope; fix retention before marketing spend.

### 16.2 Go-to-Market Checklist (Both Stores Live)
- [ ] Listings localized; IAPs approved; privacy links live; support live.
- [ ] ASA/UAC campaigns built but budget-capped.
- [ ] PR/community calendar; featuring request submitted if applicable.
- [ ] Force-update + maintenance mode tested.
- [ ] War room channel for first 72 hours.

### 16.3 Incident Response
- [ ] Severities: SEV1 payments/auth down → SEV4 cosmetic.
- [ ] Playbook: detect → feature-flag off → staged rollback → store halt rollout → user comms → postmortem.
- [ ] Expedited review criteria documented.
- [ ] Policy strike response: acknowledge, fix, evidence, appeal.

### 16.4 Policy & Platform Change Monitoring
- [ ] Subscribe: Apple News & Updates, App Store Review Guideline diffs, Play Console policy updates, Android / iOS beta notes.
- [ ] Quarterly compliance audit (Data Safety, Privacy labels, permissions, target SDK).
- [ ] SDK inventory review each release train.

---

## Phase 17: Competitive Intelligence & Category Domination

- [ ] Weekly: competitor version diffs, screenshot changes, rating moves, pricing changes.
- [ ] Review mining: top complaints in competitor 1–3★ reviews → your roadmap.
- [ ] Share of voice: ASA keyword auction insights; share of category chart.
- [ ] Win themes: speed, price, offline, local language, integrations, support quality.
- [ ] Defensive ASO: brand keyword protection campaigns on ASA/UAC.

---

## Phase 18: Org, Skills Ladder & Operating Cadence

### 18.1 Skills Ladder (Individual Expert)
| Level | You can… |
| :--- | :--- |
| **L1 Builder** | Ship features on one OS; basic crash-free |
| **L2 Store-ready** | Pass review on both stores; Data Safety + Privacy labels; staged rollout |
| **L3 Growth-aware** | ASO experiments; funnel analytics; CRM journeys; in-app review ops |
| **L4 Revenue owner** | Subs/ads yield; LTV:CAC; ASA/UAC; MMP/SKAN literacy |
| **L5 Category leader** | Dual-store featuring; multi-geo expansion; incident + policy mastery; mentors team |

### 18.2 Team Roles (When Scaling)
- [ ] Mobile eng (Android/iOS/Flutter), backend, QA/device lab
- [ ] Product + designer (platform-native UX)
- [ ] ASO / growth marketer
- [ ] UA buyer + creative
- [ ] Lifecycle/CRM
- [ ] Support / trust & safety
- [ ] Finance/tax + legal fractional

### 18.3 Cadence
- [ ] **Daily:** vitals, reviews, SEV tickets, ad spend anomalies
- [ ] **Weekly:** KPI scorecard, ASO experiment readout, CRM performance, competitor scan
- [ ] **Biweekly:** release train
- [ ] **Monthly:** pricing/paywall review, UA cohort LTV, localization priorities
- [ ] **Quarterly:** policy audit, SDK audit, soft-launch new geos, featuring pitches

---

## Master KPI Scorecard (Weekly Executive Review)

| Domain | Metric | Healthy Target | Immediate Action If Off-Target |
| :--- | :--- | :--- | :--- |
| **Quality (both)** | Crash-free users | **> 99.7%** | Pause features; hotfix top stacks; halt rollout |
| **Android Vitals** | User-perceived ANR | **< 0.15%** | Main-thread I/O audit; freeze heavy releases |
| **Apple quality** | Hang rate / launch time | Top quartile vs category | Profile startup + main-thread work |
| **ASO** | Store CVR (view→install) | **25–45%+** | Experiment icon + shots 1–3 |
| **Activation** | Onboarding → Aha | **> 60%** | Cut steps; defer signup; fix empty states |
| **Retention** | D1 / D7 / D30 | **40% / 20% / 10%+** | Habit loop + Day 0–7 journeys |
| **Engagement** | DAU/MAU | **15–40%+** by category | Push relevance; core loop rewards |
| **Reputation** | Avg rating | **≥ 4.5** | Review ops; fix top complaint themes |
| **Monetization** | Install→trial/paid | **3–10%+** | Paywall placement/price/trial tests |
| **Ads** | ARPDAU vs D1 impact | Yield ↑ without D1 ↓ | Cap interstitials; shift to rewarded |
| **UA** | Net LTV : CAC | **≥ 3 : 1** | Kill creatives/channels; retarget goals |
| **Support** | Billing ticket SLA | **< 24h** | Staffing + macros + status comms |
| **Privacy** | Open policy issues | **0 unresolved** | Compliance war room |

---

## Annual Dual-Store Compliance Calendar

| When | Apple | Google Play | Both |
| :--- | :--- | :--- | :--- |
| **Each release** | Privacy labels & Review Notes updated; dSYM upload | Data Safety/permissions still accurate; mapping upload | Crash gate; feature flags; What’s New |
| **OS beta season (WWDC / I/O)** | Xcode + iOS beta smoke | targetSdk plan; behavior changes | Fix breakages early |
| **Annual** | Small Business Program eligibility check | 15% fee tier + target API deadline | Tax forms, privacy policy review, SDK audit |
| **Every 4–6 weeks before big native feature** | Featuring pitch (Promote Your App) | Editorial pitch | PR + ASO creative refresh |
| **Quarterly** | ATT/SKAN conversion map review | Vitals + permission declarations | Full policy checklist pass |
| **Geo expansion** | New locale metadata + legal | CSL + content rating + pricing | L10n QA + support readiness |

---

## Appendix — Glossary & Primary Official Sources

### Glossary (selected)
- **AHA / Activation:** first user action that predicts long-term retention  
- **ANR:** Application Not Responding (Android)  
- **ASA:** Apple Search Ads  
- **ASO:** App Store Optimization  
- **ATT:** App Tracking Transparency  
- **CAC / CPI / CPA / LTV / ROAS:** acquisition & return metrics  
- **CPP / CSL:** Custom Product Page (Apple) / Custom Store Listing (Play)  
- **IAP:** In-App Purchase  
- **MMP:** Mobile Measurement Partner  
- **PPP:** Purchasing Power Parity pricing  
- **SKAN:** SKAdNetwork  
- **UAC:** Google App Campaigns  

### Primary Official Sources (bookmark these)
- Apple App Store Review Guidelines  
- App Store Connect Help + StoreKit / Subscription docs  
- Apple Privacy / ATT / Privacy Manifest docs  
- Google Play Developer Program Policies  
- Play Console Help: Payments, Data Safety, Permissions, Target API  
- Android Vitals / Play Integrity  
- Platform HIG (Apple) + Material Design (Google)

---

## Expert Practice Rule

> If you cannot explain **how a decision differs on Google Play vs Apple App Store** — payments, privacy, listing, ads, review, or rollout — you do not yet own that topic. Rehearse every phase above as a dual-store answer.

*End of Master Playbook (Expert Edition).*
