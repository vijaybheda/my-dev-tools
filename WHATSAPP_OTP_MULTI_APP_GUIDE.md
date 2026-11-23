# WhatsApp OTP for Multiple Products (Same Meta Account)

> **Audience:** First-time WhatsApp Business Platform users who still want production-grade OTP — for **one app** or **many apps under one organization**.
> **Stack assumed:** Your backend (Node / Nest / Laravel / Django / Go — any) + Flutter apps.
> **Official channel:** [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) (Meta-hosted). Avoid “unofficial WhatsApp” libraries — they violate ToS and get numbers banned.
>
> **How to use this guide:**  
> 1) Read [§0 Prerequisites](#0-prerequisites--zero-surprises-read-before-any-click) completely.  
> 2) Pick your path: [Requirement 1](#requirement-1--one-project-one-phone-number) or [Requirement 2](#requirement-2--five-apps-one-shared-phone-number).  
> 3) Follow phase checklists in order. Do not skip Business Verification, billing, or template APPROVED status.

Think of this like a cooking guide:

| Kitchen metaphor | WhatsApp OTP meaning |
| --- | --- |
| Kitchen / restaurant brand | Meta Business Manager (your company) |
| Recipe book shelf | WhatsApp Business Account (WABA) |
| Stove / outbound line | Phone Number (the WhatsApp number that sends OTP) |
| Recipe card | Message Template (Authentication category) |
| Ingredient portion | The OTP code your server generates |
| Waiter who delivers | Cloud API `POST /messages` |
| Customer table | End-user’s WhatsApp |
| Different dishes (App1…App5) | Different **templates** (and optionally different phone numbers) under the **same** account |

---

## Table of contents

0. [Prerequisites — zero surprises](#0-prerequisites--zero-surprises-read-before-any-click)
1. [What you are actually building](#1-what-you-are-actually-building)
2. [Two requirements (choose your path)](#2-two-requirements-choose-your-path)
3. [Ingredients to gather before you start](#3-ingredients-to-gather-before-you-start)
4. [Account map (same account, many products)](#4-account-map-same-account-many-products)
5. [Do / Don’t (read before clicking anything)](#5-do--dont-read-before-clicking-anything)
6. [Phase A — Account setup (once)](#6-phase-a--account-setup-once)
7. [Phase B — Testing mode (sandbox)](#7-phase-b--testing-mode-sandbox)
8. [Phase C — Production mode](#8-phase-c--production-mode)
9. [Phase D — Backend design (multi-product)](#9-phase-d--backend-design-multi-product)
10. [Phase E — Flutter app integration](#10-phase-e--flutter-app-integration)
11. [OTP UX modes (Copy / One-tap / Zero-tap)](#11-otp-ux-modes-copy--one-tap--zero-tap)
12. [Edge cases, failures, and how to handle them](#12-edge-cases-failures-and-how-to-handle-them)
13. [Security checklist](#13-security-checklist)
14. [Cost, rate limits, quality rating](#14-cost-rate-limits-quality-rating)
15. [Requirement 1 — action plan (one project, one number)](#requirement-1--one-project-one-phone-number)
16. [Requirement 2 — action plan (5 apps, one shared number)](#requirement-2--five-apps-one-shared-phone-number)
17. [Week-by-week rollout plan](#17-week-by-week-rollout-plan)
18. [Action-item checklists (summary)](#18-action-item-checklists-summary)
19. [Glossary](#19-glossary)
20. [Official docs](#20-official-docs)

---

## 0. Prerequisites — zero surprises (read before any click)

Collect and decide everything below **before** writing Flutter code, creating templates in a hurry, or expecting production sends to work. Most “integration surprises” are missing items from this list.

### 0.1 Business / legal (manual)

- [ ] Legal company name (must match verification documents)
- [ ] Business address, website (live), public support email, phone
- [ ] Privacy Policy URL (HTTPS, public) linked from apps and store listings later
- [ ] Country-specific business documents Meta may request (incorporation, GST, utility bill, etc.)
- [ ] Written use case for Meta: “OTP for login / signup / password reset”
- [ ] Named **Meta Business Admin** + **backup admin** (single-admin lockout is a real risk)
- [ ] Finance contact for WhatsApp billing / payment method / invoices

### 0.2 Architecture decisions (write once, do not change mid-flight)

- [ ] Path: **Requirement 1** (one app) and/or **Requirement 2** (5 apps, one shared sender number)
- [ ] Confirm stakeholders accept: on Requirement 2, **all apps share the same WhatsApp “From” name/number**
- [ ] Final list of `productId`s (e.g. `app1` … `app5`)
- [ ] OTP length (**6** recommended), TTL (**5 minutes**), resend cooldown (**30–60s**), max sends/hour, max verify attempts
- [ ] Languages needed (`en_US`, `hi`, …)
- [ ] Fallback when WhatsApp fails or user has no WhatsApp: **SMS / email / none** (none = production surprise)

### 0.3 Phone number (highest-surprise area)

- [ ] One production number **you control** (prefer not your personal daily WhatsApp)
- [ ] Confirm whether the number is already on WhatsApp Consumer — migration may require **deleting / migrating** consumer WA (downtime / logout)
- [ ] Display name that Meta will accept (must relate to the business)
- [ ] Profile photo, About text, business address ready
- [ ] At least one personal WhatsApp number available for **sandbox allow-list** testing

### 0.4 Technical readiness

- [ ] Backend with public **HTTPS** (required for webhooks)
- [ ] Redis or DB that supports TTL
- [ ] Secrets manager or gitignored `.env` (never commit tokens)
- [ ] Staging and production environments planned
- [ ] E.164 phone UX in apps (`+91…` with country picker)
- [ ] Flutter will call **only your backend** (no Meta token in the app)
- [ ] Optional later (not needed for v1): Android `applicationId` + signing key hash for one-tap

### 0.5 Hidden truths (read twice)

1. Flutter never talks to WhatsApp. **OTP + Meta token = backend only.**
2. OTP WhatsApp messages **must** use an **AUTHENTICATION** template — body text is mostly Meta-fixed; you cannot freely write “Welcome to App3!”.
3. Brand differentiation for multiple apps on one number is mainly **in-app UX + sender profile**, not free-form WhatsApp copy.
4. Templates must be **APPROVED** before sends work.
5. **Business verification** can take **days** (sometimes longer).
6. **Temporary tokens expire** (~24h). Production needs a **System User permanent token**.
7. Without a **payment method**, production billable sends fail.
8. New numbers start with **messaging limits**. Blocks/reports lower **quality rating** and throttle throughput.
9. On a **shared number**, one abused app can hurt **all** apps on that number.
10. User without WhatsApp → delivery failure → you need fallback or a clear error.
11. **Resend = new delivered message = new charge** (when delivered).
12. Bind every OTP to `productId` + `purpose` so App1’s code cannot verify on App2.
13. Store **hashed** OTP only; never log plaintext OTP in production.
14. Android one-tap / zero-tap do **not** work like that on iOS — start with **Copy code**.
15. Meta Console UI labels change; concepts (WABA, Phone Number ID, template name + language) stay.

---

## 1. What you are actually building

### The wrong mental model

> “Flutter app talks to WhatsApp and sends OTP.”

**Never do this.** WhatsApp API tokens in a mobile app can be extracted. OTP generation and WhatsApp calls belong on **your backend only**.

### The correct flow

```text
User opens App1 / App2 / … / App5
        │
        ▼
Flutter calls YOUR backend
  POST /v1/otp/send  { productId, phone, purpose }
        │
        ▼
Backend:
  1. Validate product + phone + rate limits
  2. Generate OTP (server-side)
  3. Store hash + expiry in Redis/DB (TTL)
  4. Pick template + phone_number_id for that product
  5. Call Meta Cloud API (Authentication template)
        │
        ▼
User receives WhatsApp message
        │
        ▼
Flutter calls YOUR backend
  POST /v1/otp/verify  { productId, phone, code, requestId }
        │
        ▼
Backend verifies → issues session / JWT
```

Also implement:

- `POST /v1/otp/resend` — cooldown, invalidate old OTP, send new code
- `POST /webhooks/whatsapp` — delivery / failure statuses from Meta

### Why “Authentication” templates (not Marketing / Utility free text)

If the message is an OTP / verification code, Meta **requires** an **AUTHENTICATION** category template. You cannot invent free-form OTP wording. Body text is mostly fixed by Meta:

- `{{1}} is your verification code.` (preset)
- Optional: “For your security, do not share this code.”
- Optional: “This code expires in N minutes.”
- Button: **Copy code**, **One-tap autofill** (Android), or **Zero-tap** (Android)

---

## 2. Two requirements (choose your path)

| | **Requirement 1 — One project** | **Requirement 2 — Org with 5 apps** |
| --- | --- | --- |
| Meta Business / WABA | 1 | 1 (same organization) |
| Phone number (sender) | **1** | **1 shared** for all 5 apps |
| AUTH templates | 1+ per purpose/language | **Separate template names per app** |
| Backend | send / verify / resend | Same service + `productId` routing |
| What users see as “From” | Your business WhatsApp profile | **Same number/name for every app** |
| Guide strategy name | Single-product | **Strategy A** (one number + many templates) |

```text
Requirement 2 (your stated org model):

Meta Business Manager  (ONE company)
 └── WABA  (ONE)
      └── Phone Number  (+91… shared)
           ├── otp_app1_login
           ├── otp_app2_login
           ├── otp_app3_login
           ├── otp_app4_login
           └── otp_app5_login
```

> Later upgrade path: **Strategy B** = one number per product (cleaner brand + isolated quality risk). Not required for your current “single number for all apps” goal.

---

## 3. Ingredients to gather before you start

### Business / legal

| Item | Why |
| --- | --- |
| Legal company name | Meta Business verification |
| Business address, website, email | Verification + display |
| Business documents (as Meta asks for your country) | Business verification |
| Privacy policy URL | Often required for apps / review |
| Clear use case: “OTP for login / signup / reset” | Template approval |

### People / access

| Role | Who |
| --- | --- |
| Meta Business Admin (+ backup) | Verify business and add assets |
| Developer with Meta developer account | Creates apps, tokens, webhooks |
| Finance contact | Billing / payment method for WhatsApp |

### Technical identifiers you will end up with

Write these in a password manager / secrets vault (never in git):

| Secret / ID | Example shape | Used for |
| --- | --- | --- |
| Meta Business Manager ID | numeric | Org root |
| WhatsApp Business Account ID (WABA ID) | numeric | Templates live here |
| Meta App ID + App Secret | `123…` / secret | OAuth, app config |
| Phone Number ID | numeric | `POST /{phone-number-id}/messages` |
| WhatsApp display phone | `+91…` | What users see as sender |
| Permanent System User token (prod) | long string | API auth |
| Temporary token (dev only) | expires ~24h | Testing only |
| Webhook Verify Token | you invent | Webhook handshake |
| App Secret for webhook signature | App Secret | Validate Meta callbacks |

### Per product (App1…App5)

| Item | Example |
| --- | --- |
| Internal `productId` | `app1`, `app2`, `pos_retail` |
| Brand display name users should trust | “1App”, “2App” |
| Android `applicationId` / package name | `com.company.app1` |
| iOS bundle id | `com.company.app1` |
| Android signing key hash (for one-tap / zero-tap) | 11-char hash Meta expects |
| Preferred OTP length | 6 digits (recommended) |
| OTP TTL | 5 minutes (align with template footer) |
| Languages needed | `en`, `en_US`, `hi`, … |

Fill this table before creating templates:

| productId | App name | Android package | iOS bundle | Purposes |
| --- | --- | --- | --- | --- |
| app1 | | | | login, reset |
| app2 | | | | login, reset |
| app3 | | | | login, reset |
| app4 | | | | login, reset |
| app5 | | | | login, reset |

---

## 4. Account map (same account, many products)

### Recommended architecture (one company, many products)

```text
Meta Business Manager  (ONE company)
 └── WhatsApp Business Account / WABA  (usually ONE)
      ├── Phone Number A  (+91…111)  → shared OR App1
      ├── Phone Number B  (+91…222)  → optional App2
      └── Phone Number C  (+91…333)  → optional App3
           │
           └── Message Templates (AUTHENTICATION)
                ├── otp_app1_login_en
                ├── otp_app2_login_en
                └── otp_app3_login_en
```

### Strategy comparison

| Strategy | Same WABA? | Different “From” name/number? | When to use |
| --- | --- | --- | --- |
| **A. One number + many templates** | Yes | No (same sender for all apps) | **Your Requirement 2** — early stage / same brand family / one org number |
| **B. One WABA + one number per product** | Yes | Yes | Best default when each product needs its own chat identity |
| **C. Separate WABA per product** | No | Yes | Strict brand isolation / different legal entities |
| **D. BSP (Twilio, MessageBird, Gupshup, etc.)** | Via partner | Depends | Partner billing / SMS+WA multi-channel |

**Practical recommendation:**

1. **Requirement 1:** Strategy A with one product’s templates.
2. **Requirement 2:** Strategy A with five template families on one Phone Number ID.
3. Keep **one backend OTP service** that routes by `productId` → `{ phoneNumberId, templateName, language }`.
4. Revisit Strategy B if users get confused by a shared sender or if quality risk becomes too high.

### What “different per product” can mean under one account

| Dimension | How to make it different per product |
| --- | --- |
| Sender identity | Different phone numbers + profile (Strategy B) — **not** available on pure Strategy A |
| Message copy | Still AUTHENTICATION presets — limited wording |
| Template name | `otp_<product>_<purpose>_<lang>` |
| Button type | Copy vs One-tap per Android app |
| Backend config | Separate rate limits, OTP length, TTL |
| Analytics | Tag every send with `productId` |
| Flutter UX | Product-specific strings / branding in your app |

---

## 5. Do / Don’t (read before clicking anything)

### DO

- Use **Cloud API** (official).
- Put **all** WhatsApp credentials on the **server**.
- Use **AUTHENTICATION** templates for OTP.
- Generate OTP on the server; send only the code as the template variable.
- Store **hashed** OTP + short TTL; never log plaintext OTP in production.
- Rate-limit by phone + IP + device + product.
- Use E.164 phone format (`+9198…`).
- Verify webhook signatures (`X-Hub-Signature-256`).
- Keep a **fallback** (SMS / email / voice) when WhatsApp fails or number has no WhatsApp.
- Separate **test** and **prod** Meta apps / tokens / phone numbers when possible.
- Document which `productId` maps to which `phone_number_id` + template.

### DON’T

- Don’t put access tokens in Flutter, APK, IPA, or public repos.
- Don’t use unofficial WhatsApp Web scrapers / “Baileys-like” bots for OTP.
- Don’t send OTP as a free-form `text` message to users who never messaged you (won’t work / policy risk). First business-initiated OTP **must** be a template.
- Don’t reuse the same OTP across products or sessions.
- Don’t keep OTP valid for hours.
- Don’t return “user exists / doesn’t exist” differently in a way that enables enumeration without rate limits.
- Don’t share one permanent token in Slack / screenshots.
- Don’t assume one-tap works on iOS (one-tap / zero-tap are **Android** flows; iOS falls back to copy / keyboard suggestions).
- Don’t create Marketing-category templates for OTP.
- Don’t skip Business Verification if you need production scale / display name.
- Don’t create five separate Meta Businesses just because you have five apps (unnecessary for Requirement 2).

---

## 6. Phase A — Account setup (once)

Do these in order. Skip nothing if you are new.

### A1. Create Meta accounts

1. Create / use a personal Facebook account that will be an admin (or use a work account policy your company allows).
2. Go to [Meta Business Suite / Business Manager](https://business.facebook.com/) → create a **Business Portfolio** (company).
3. Add at least one other admin if possible (bus-factor risk: one person leaves → lockout).

### A2. Create a Meta Developer App

1. Open [Meta for Developers](https://developers.facebook.com/).
2. **My Apps → Create App**.
3. Choose a type that supports WhatsApp (commonly **Business**).
4. Note **App ID** and **App Secret** (Settings → Basic).

### A3. Add WhatsApp product

1. In the app dashboard: **Add Product → WhatsApp → Set up**.
2. This attaches (or creates) a **WhatsApp Business Account (WABA)** and a **test phone number**.
3. Copy:
   - WABA ID
   - Test Phone Number ID
   - Temporary access token (dev only)

### A4. Business verification (needed for real production)

1. In Business Manager → **Security Center / Business verification**.
2. Submit documents Meta requests for your country.
3. Wait for approval (can take days).
4. Until verified, you are limited (test numbers, restricted sending).

### A5. Payment method (production sending)

1. Attach a payment method to the WABA / billing.
2. Without billing, production conversation/message fees cannot clear → sends fail.

### A6. Decide phone numbers for products

| If you choose… | Do this |
| --- | --- |
| **Requirement 1 or 2 (shared number)** | Add/claim **one** production number; all apps share sender |
| Strategy B (number per product) | Add multiple numbers under same WABA; set display name & photo per number |

**Phone number rules (high level):**

- Prefer a number you control (not your personal primary WhatsApp if you can avoid it).
- If the number is already on WhatsApp consumer app, Meta’s process may require migrating / deleting consumer WA — plan downtime.
- Display name must match / relate to business; Meta reviews names.

### A7. Create Authentication templates (per product)

In **WhatsApp Manager → Message templates** (or via Graph API):

For each product × language × purpose (login / signup / reset):

| Field | Value |
| --- | --- |
| Name | `otp_app1_login` (lowercase, underscores) |
| Category | `AUTHENTICATION` |
| Language | e.g. `en_US` |
| Body | Preset (enable security recommendation) |
| Footer | `code_expiration_minutes`: `5` |
| Button | Start with `COPY_CODE` (simplest) |

**Naming convention (recommended):**

```text
otp_<productId>_<purpose>
otp_app1_login
otp_app1_reset
otp_app2_login
…
otp_app5_login
```

Create matching languages (`en_US`, `hi`, …) as separate template language variants.

**Approval:** Templates go `PENDING` → `APPROVED` or `REJECTED`. Only **APPROVED** templates can be sent.

### A8. Webhooks (delivery + errors)

1. Host an HTTPS endpoint, e.g. `https://api.yourdomain.com/webhooks/whatsapp`.
2. In Meta App → WhatsApp → Configuration → Webhook:
   - Callback URL
   - Verify token (you choose)
3. Subscribe to fields: at least `messages` (includes status updates: sent / delivered / read / failed).
4. Validate `hub.challenge` on GET; validate signature on POST.

---

## 7. Phase B — Testing mode (sandbox)

Goal: send a real Authentication OTP to **your** phone without full production risk.

### B1. What “testing mode” means

| Item | Testing |
| --- | --- |
| Phone number | Meta-provided **test number** |
| Recipients | Only numbers you **add to the allow-list** (few numbers) |
| Token | Temporary token (rotates / expires) OK for learning |
| Templates | Can use test templates / create auth templates |
| Billing | Usually not real customer traffic |

### B2. Action items — Testing

1. In WhatsApp → API Setup, copy **Temporary token**, **Phone number ID**, **WABA ID**.
2. Under **To**, add your personal WhatsApp number to the recipient list (verify with code Meta sends).
3. Create (or use) an AUTHENTICATION template; wait until **APPROVED**.
4. Send a test via Meta’s “Send message” UI first (proves account works without your code).
5. Call Cloud API with curl from your laptop (proves token + template name + language).
6. Only then wire your backend.
7. Point Flutter **dev/staging** flavor at staging backend.

### B3. Example: send Authentication OTP (Cloud API)

```bash
curl -X POST "https://graph.facebook.com/v21.0/<PHONE_NUMBER_ID>/messages" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "messaging_product": "whatsapp",
    "recipient_type": "individual",
    "to": "9198XXXXXXXX",
    "type": "template",
    "template": {
      "name": "otp_app1_login",
      "language": { "code": "en_US" },
      "components": [
        {
          "type": "body",
          "parameters": [
            { "type": "text", "text": "123456" }
          ]
        },
        {
          "type": "button",
          "sub_type": "url",
          "index": "0",
          "parameters": [
            { "type": "text", "text": "123456" }
          ]
        }
      ]
    }
  }'
```

Notes:

- `to` is country code + number **without** `+` in many examples (use Meta’s current format; keep E.164 in your DB).
- For copy-code / OTP buttons, the **same code** is often passed in **body** and **button** parameters.
- Template `name` + `language.code` must match exactly what was approved.

### B4. Testing checklist (pass/fail)

| # | Check | Pass? |
| --- | --- | --- |
| 1 | Template status = APPROVED | ☐ |
| 2 | Recipient is on allow-list | ☐ |
| 3 | curl returns `messages[].id` | ☐ |
| 4 | WhatsApp message arrives < ~30s | ☐ |
| 5 | Code in message matches what you sent | ☐ |
| 6 | Webhook receives `sent` / `delivered` (if configured) | ☐ |
| 7 | Wrong code rejected by your backend | ☐ |
| 8 | Expired code rejected | ☐ |
| 9 | Resend blocked by rate limit | ☐ |
| 10 | App2 uses different template name successfully (Req 2) | ☐ |
| 11 | App1 OTP cannot verify on App2 (Req 2) | ☐ |

### B5. Testing mode Don’ts

- Don’t distribute temporary tokens to the whole team via chat.
- Don’t point production Flutter builds at test Phone Number ID.
- Don’t assume allow-list behavior = production (production can message opted-in users broadly under policy/billing).

---

## 8. Phase C — Production mode

### C1. What must be true before prod traffic

| Requirement | Why |
| --- | --- |
| Business verified | Trust / limits / display |
| Production phone number registered | Real sender |
| Display name approved | Users see correct brand |
| Payment method active | Messages are billable |
| Permanent token (System User) | Temp tokens expire |
| AUTH templates APPROVED per product/language | Can send |
| Webhooks on prod URL with signature check | Observe failures |
| Secrets in vault / env (not git) | Security |
| Staging smoke test completed | Confidence |
| SMS/email fallback configured (recommended) | No-WhatsApp / Meta failures |

### C2. Production token (do this properly)

1. Business Settings → **Users → System Users** → create Admin/Employee system user.
2. Add assets: your Meta App + WABA.
3. Generate token with WhatsApp permissions (`whatsapp_business_messaging`, `whatsapp_business_management` as required).
4. Store only in secrets manager; rotate on schedule / on leak.
5. Never embed in mobile apps.

### C3. Go-live action items

1. Register production phone number(s); set profile photo, about, address.
2. Recreate / migrate templates on production WABA if test was separate.
3. Map `productId` → prod `phone_number_id` + template names in config.
4. Enable monitoring: send success rate, webhook `failed` reasons, OTP verify success rate, cost by `productId`.
5. Configure alerts: spike in failures, quality rating drop, billing errors.
6. Soft-launch one product first (App1), then App2…App5.
7. Keep SMS fallback for the first weeks.

### C4. Production Don’ts

- Don’t hot-swap template names without a config flag / kill switch.
- Don’t delete a template still referenced by production config.
- Don’t ignore **quality rating** on the phone number (low quality → limits).
- Don’t send OTP to numbers that did not request it (consent / abuse).

---

## 9. Phase D — Backend design (multi-product)

### D1. Config table (source of truth)

**Requirement 1** — one product entry.  
**Requirement 2** — five entries, **same** `phoneNumberId`.

```yaml
products:
  app1:
    displayName: "1App"
    phoneNumberId: "SHARED_PNID"   # same for all apps on Requirement 2
    wabaId: "WABA_SHARED"
    templates:
      login: { name: otp_app1_login, language: en_US }
      reset: { name: otp_app1_reset, language: en_US }
    otpLength: 6
    ttlSeconds: 300
    maxSendsPerHour: 5
    maxVerifyAttempts: 5
  app2:
    displayName: "2App"
    phoneNumberId: "SHARED_PNID"   # SAME shared number
    wabaId: "WABA_SHARED"
    templates:
      login: { name: otp_app2_login, language: en_US }
    otpLength: 6
    ttlSeconds: 300
    maxSendsPerHour: 5
    maxVerifyAttempts: 5
  # app3, app4, app5 → same phoneNumberId, different template names
```

Load from env / remote config; never hardcode tokens next to this.

### D2. API surface (required)

| Endpoint | Purpose |
| --- | --- |
| `POST /v1/otp/send` | Start OTP for a product |
| `POST /v1/otp/verify` | Confirm OTP |
| `POST /v1/otp/resend` | Resend with cooldown |
| `POST /webhooks/whatsapp` | Meta callbacks |

**Send request**

```json
{
  "productId": "app1",
  "phone": "+9198XXXXXXXX",
  "purpose": "login",
  "locale": "en_US",
  "deviceId": "optional-stable-id"
}
```

**Send response (never return the OTP)**

```json
{
  "requestId": "01HZX...",
  "expiresInSeconds": 300,
  "resendAfterSeconds": 30,
  "channel": "whatsapp"
}
```

### D3. Server algorithm (send)

1. Resolve `productId` → config (404 if unknown).
2. Normalize phone to E.164; reject invalid.
3. Check rate limits (phone, IP, device, product).
4. Optional: check user exists / signup rules for `purpose`.
5. Generate cryptographically secure numeric OTP.
6. Store `hash(otp + secret/pepper)`, `requestId`, `productId`, `phone`, `purpose`, `attempts=0`, `expiresAt`.
7. Invalidate previous active OTPs for same phone+product+purpose.
8. Call Meta send template with plaintext OTP **only in the API call**.
9. Store Meta `wamid` / message id against `requestId`.
10. Return `requestId` + timers to client.
11. On Meta error: map to user-safe error; trigger fallback channel if configured.

### D4. Server algorithm (verify)

1. Load request by `requestId` + phone + product.
2. Reject if missing / expired / too many attempts.
3. Compare using constant-time hash compare.
4. On success: mark consumed (single use), issue auth session.
5. On failure: increment attempts; generic error message.

### D5. Server algorithm (resend)

1. Enforce `resendAfterSeconds` cooldown.
2. Invalidate previous OTP for phone+product+purpose.
3. Generate new OTP; store hash; call Meta again.
4. Return new timers (never return OTP).
5. Count toward rate limits and billing (new delivery = new charge).

### D6. Idempotency & concurrency

- Client may double-tap Send → use idempotency key or droppable lock per phone+product.
- Resend should rotate OTP (invalidate old).
- After success, OTP must not verify again.

### D7. Webhook handling

Process asynchronously:

| Status | Meaning | Your action |
| --- | --- | --- |
| `sent` | Accepted by WA | metrics |
| `delivered` | On user device | metrics |
| `read` | Opened | optional |
| `failed` | Not delivered | log error code; maybe auto-fallback SMS |

Always return 200 quickly after queueing; verify signature first.

---

## 10. Phase E — Flutter app integration

### E1. Responsibilities of Flutter

Flutter should:

- Collect phone (with country code UI).
- Call backend send / verify / resend.
- Show timers, errors, loading.
- Optionally deep-link / paste OTP (copy-code).
- For Android one-tap / zero-tap: native handshake + activity / receiver (via platform channel or plugin).

Flutter must **not**:

- Hold Meta tokens.
- Generate the OTP as source of truth.
- Call `graph.facebook.com` directly.

### E2. UX recipe (minimum)

1. Phone screen → Continue.
2. Explain: “We’ll send a code on WhatsApp to +91…”.
3. For Requirement 2, also say which **business WhatsApp name** will message them (same for all apps).
4. OTP screen: 6 boxes, paste support, resend after N seconds.
5. On verify success → navigate to app home / complete signup.
6. On failure → clear message + remaining attempts if you choose to show them carefully.

### E3. Multi-flavor / multi-product

If one codebase serves many products, inject `productId` via flavors / dart-define:

```text
--dart-define=PRODUCT_ID=app1
```

Backend already routes templates by that id.

### E4. Android one-tap / zero-tap (advanced)

Only if you need autofill without paste:

1. Create AUTH template with `otp_type`: `ONE_TAP` or `ZERO_TAP`.
2. Add `supported_apps` entries: `package_name` + `signature_hash` (up to 5 apps — useful for debug + release builds).
3. Implement Meta’s handshake **before** calling your backend send.
4. Eligibility failures silently fall back to **copy code** — design UX for that.
5. Only one listed app should have an active handshake window at a time.

**iOS:** do not expect Android one-tap. Use copy-code; keyboard suggestions may help autofill from notifications for auth templates on newer iOS versions.

---

## 11. OTP UX modes (Copy / One-tap / Zero-tap)

| Mode | Platforms | User action | Complexity | Good first step? |
| --- | --- | --- | --- | --- |
| **Copy code** | Android + iOS | Tap Copy → paste in app | Low | **Yes — start here** |
| **One-tap autofill** | Android (+ copy fallback) | Tap button → app opens with code | Medium | After copy works |
| **Zero-tap** | Android | Code auto-broadcast into app | High | Last |

**Recommendation for newcomers:** Ship **Copy code** for all products first. Add one-tap per Android app later without changing your backend OTP model.

---

## 12. Edge cases, failures, and how to handle them

### User / device

| Case | What happens | Handle by |
| --- | --- | --- |
| Number not on WhatsApp | Send fails / undeliverable | Detect via webhook error; offer SMS |
| User has WA Business app quirks | Rare delivery issues | Fallback channel |
| Dual SIM / wrong country code | OTP goes to wrong place | Strong country picker; show full E.164 before send |
| User blocks business | Failures | Support flow; alternate channel |
| User deletes chat | They can still get new messages generally | Resend |
| Clock skew | “Expired” fights | Prefer server TTL; show server `expiresIn` |

### Meta / template

| Case | Handle by |
| --- | --- |
| Template PENDING | Block send for that product/lang; show “temporarily unavailable” |
| Template REJECTED | Fix content; don’t invent wording |
| Wrong language code | Exact match `en` vs `en_US` |
| Parameter length / formatting | Digits only; keep within Meta limits |
| TTL (`message_send_ttl_seconds`) expired before delivery | Treat as failure; allow resend |

### Abuse / security

| Case | Handle by |
| --- | --- |
| OTP bombing a victim phone | Per-phone + per-IP limits; CAPTCHA / device attest on send |
| Brute force verify | Lock after N attempts; progressive delay |
| Credential stuffing | Bot detection; monitor verify ratios |
| Insider logging OTPs | Hash at rest; redact logs |

### Multi-product (Requirement 2)

| Case | Handle by |
| --- | --- |
| App1 OTP used on App2 verify | Bind OTP to `productId` + `purpose` |
| Shared number confuses users | Clear in-app text; consider Strategy B later |
| One-tap handshake collision between apps | Stagger / separate templates; understand Meta eligibility rules |
| Config drift (staging template in prod) | Environment-specific config; startup validation |
| One app burns quality rating for all | Per-product rate limits + alerts + pause that productId |

### Reliability

| Case | Handle by |
| --- | --- |
| Meta 5xx / timeout | Retry with jitter (idempotent send key); then SMS fallback |
| Your Redis down | Fail closed (no OTP) or degraded path with care |
| Webhook delayed | Don’t block verify on delivery webhook; verify is code-based |
| Partial success (WA sent, DB write failed) | Transactional outbox / compensate |

### Flutter-specific

| Case | Handle by |
| --- | --- |
| App killed during wait | Persist `requestId` + expiry locally (secure storage) |
| Paste from WhatsApp | Listen clipboard carefully; don’t steal unrelated clipboard |
| Deep link delays | Always allow manual entry |
| Offline | Disable send; queue nothing silently without UX |

---

## 13. Security checklist

- [ ] OTP generated with CSPRNG
- [ ] OTP hashed at rest (e.g. HMAC-SHA256 with server pepper)
- [ ] TTL short (3–10 minutes; match template footer)
- [ ] Single-use codes
- [ ] Max verify attempts
- [ ] Send rate limits (phone + IP + product)
- [ ] Tokens only on server
- [ ] Webhook signature verification
- [ ] TLS everywhere
- [ ] PII minimization in logs (mask phone)
- [ ] Separate staging / prod credentials
- [ ] Secret rotation plan
- [ ] Fraud alerts on send spikes
- [ ] Cross-product verify impossible (Req 2)

---

## 14. Cost, rate limits, quality rating

### 14.1 How Meta bills (important)

Effective **1 July 2025**, WhatsApp Cloud API charges are **per delivered template message** (not the old conversation model for these rates):

- You are charged when an Authentication (or other) **template is delivered**.
- Rates vary by **category** + **recipient country calling code**.
- Utility/Authentication can unlock **volume tier** discounts at high monthly volume.
- User → business messages are free.
- Official source: [WhatsApp Business Platform pricing](https://developers.facebook.com/docs/whatsapp/pricing/) — **re-check before go-live**; rate cards change by date/market.

### 14.2 Approximate Authentication cost (India recipients)

Indicative **INR** list rates from Meta rate cards shared by partners (e.g. effective around Oct 2025; verify live):

| Category | Approx India list rate |
| --- | --- |
| **Authentication** (OTP) | **~₹0.1150 per delivered message** |
| Utility | ~₹0.1150 |
| Marketing | much higher (often ~₹0.78+) — **do not use for OTP** |
| Authentication-international | much higher (often ~₹2+) if Meta applies international auth rules |

**Volume tiers (Authentication):** discounts typically start only at very high monthly volume (hundreds of thousands+). Early-stage apps usually pay near list rate.

### 14.3 Budget examples (India, ~₹0.115 / delivered OTP)

| Monthly delivered OTPs | Approx Meta cost |
| --- | --- |
| 1,000 | ~₹115 |
| 10,000 | ~₹1,150 |
| 50,000 | ~₹5,750 |
| 100,000 | ~₹11,500 |

**Remember:** each **resend** that is delivered is another charge. Failed/undelivered are generally not charged, but still monitor abuse so bots don’t waste capacity/reputation.

### 14.4 Other costs people forget

| Cost | Notes |
| --- | --- |
| Meta payment method / card | Required for production; failed billing → sends stop |
| SMS / email fallback | Separate provider pricing (MSG91, Twilio, etc.) |
| Server (API + Redis) | Your hosting |
| Phone number / SIM | Number you register |
| BSP markup (optional) | If you use Twilio/Gupshup/etc. instead of direct Cloud API |
| Engineering time | Verification + templates often take **days–weeks**, not hours |

### 14.5 Requirement 1 vs Requirement 2 cost difference

| | Req 1 | Req 2 (5 apps, one number) |
| --- | --- | --- |
| Meta per-message rate | Same | Same |
| Number of billable lines | 1 number | Still 1 number |
| Monthly bill | Volume of that app | **Sum of volume across all 5 apps** |
| Quality risk | Isolated to one product’s traffic | **Shared** — one noisy app can hurt all |

Tag every send with `productId` so finance can allocate cost per app.

### 14.6 Throughput & quality

- Each phone number has messaging limits that can increase with good quality.
- High blocks / reports → **quality rating** drops → throughput restricted.
- OTP abuse (spamming users) hurts the **whole number** — and if shared, **all products** on that number.

**Implication for multi-app:** Strategy A is fine to start; Strategy B (number per product) isolates quality risk when you scale.

---

## Requirement 1 — One project, one phone number

**Goal:** One Flutter app → your backend → WhatsApp AUTH template from **one** number. Features: **send, verify, resend**.

### Req1 — Phase checklist

#### Manual: Meta account
- [ ] Business Manager + backup admin
- [ ] Developer App + WhatsApp product
- [ ] Copy test Phone Number ID + temp token into gitignored secrets
- [ ] Start Business Verification
- [ ] Add payment method (before prod)
- [ ] Register/choose production phone number
- [ ] Set display name + photo

#### Manual: Template
- [ ] Create `otp_<app>_login` AUTHENTICATION + Copy code + 5 min expiry
- [ ] Wait until **APPROVED**
- [ ] Optional: `otp_<app>_reset` and other languages

#### Manual + curl: Sandbox
- [ ] Allow-list your WhatsApp number
- [ ] Send via Meta UI
- [ ] Send via curl (body + button params = same code)
- [ ] Message arrives; code matches

#### Implement: Backend
- [ ] `POST /v1/otp/send`
- [ ] `POST /v1/otp/verify`
- [ ] `POST /v1/otp/resend`
- [ ] Hash + TTL store; rate limits; never return OTP
- [ ] Webhook endpoint + signature validation

#### Implement: Flutter
- [ ] Phone → send → OTP UI → verify / resend
- [ ] Persist `requestId` if app backgrounded
- [ ] No Meta credentials in the app

#### Manual + ops: Production
- [ ] System User permanent token in secrets manager
- [ ] Prod Phone Number ID + APPROVED prod templates
- [ ] Prod webhooks
- [ ] Soft launch + monitoring + SMS fallback

### Req1 — Done when
- [ ] Send / resend / verify work on real devices
- [ ] Wrong + expired codes rejected
- [ ] Rate limit blocks OTP bombing
- [ ] Token only on server
- [ ] Billing + alerts live

---

## Requirement 2 — Five apps, one shared phone number

**Goal:** One organization, **one** WhatsApp sender number, OTP for users of **all five** applications. Differentiate with **template names** + backend `productId` — not five Meta phone numbers.

### Req2 — Extra prerequisites
- [ ] Stakeholder sign-off: same WhatsApp “From” for all five apps is acceptable
- [ ] Completed product table (productId, packages, purposes) in §3
- [ ] One shared OTP microservice (do not copy the Meta token into five backends)
- [ ] Accept shared quality-rating risk
- [ ] Plan per-`productId` rate limits so one app cannot burn the shared number

### Req2 — Phase checklist

#### Manual: Account (once for the org)
- [ ] Same Phase A as Requirement 1
- [ ] **Do not** create five Business Managers
- [ ] **Do not** add five phone numbers if you want a single sender

#### Manual: Templates (×5 apps)
- [ ] Create `otp_app1_login` … `otp_app5_login` (and reset variants if needed)
- [ ] All AUTHENTICATION + Copy code
- [ ] Every template **APPROVED**
- [ ] In-app copy explains: “Code sent on WhatsApp from &lt;Business Name&gt; for **this app**”

#### Sandbox
- [ ] curl/UI send with `otp_app1_login` and `otp_app2_login` on **same** Phone Number ID
- [ ] Both arrive from same sender
- [ ] Backend test: OTP for `app1` **fails** verify under `app2`

#### Backend
- [ ] Config map: all five products → **same** `phoneNumberId`, different `template.name`
- [ ] Every API call requires `productId`
- [ ] OTP rows store `productId` + `purpose` + `phone`
- [ ] Metrics + cost tagged by `productId`
- [ ] Global + per-product rate limits

#### Flutter (each app)
- [ ] Inject `PRODUCT_ID` via flavor / dart-define
- [ ] Same send / verify / resend UX as Req1
- [ ] Always pass `productId` to backend

#### Production
- [ ] One prod number + one System User token
- [ ] Soft-launch **App1 only**
- [ ] Watch delivery failures + quality rating
- [ ] Onboard App2…App5
- [ ] Alert if quality drops; pause the noisy `productId` if needed

### Req2 — Done when
- [ ] All five apps send / verify / resend via shared number
- [ ] Cross-app OTP verify impossible
- [ ] Cost dashboard by `productId`
- [ ] Quality monitoring on the single number
- [ ] Fallback SMS path tested

---

## 17. Week-by-week rollout plan

| Week | Focus |
| --- | --- |
| **0** | Finish §0 prerequisites + choose Req1 and/or Req2 shared-number policy |
| **1** | Business Manager + Dev App + WhatsApp + test number + first AUTH template APPROVED + Meta UI + curl |
| **2** | Backend send / verify / resend + Redis + rate limits + webhook for **one** product |
| **3** | Flutter staging E2E + security checklist |
| **4** | Business verification + billing + prod number + System User token + prod templates |
| **5** | Soft launch Req1 (or App1 of Req2) + SMS fallback |
| **6+** | Add templates + productIds for App2–App5; only then consider Android one-tap |

---

## 18. Action-item checklists (summary)

### 18.1 First week (learning + sandbox)

- [ ] Create Business Manager
- [ ] Create Meta Developer App + add WhatsApp
- [ ] Copy test Phone Number ID + temp token into a local `.env` (gitignored)
- [ ] Add your WhatsApp number as test recipient
- [ ] Create `otp_app1_login` AUTHENTICATION template (copy code)
- [ ] Wait for APPROVED
- [ ] Send via Meta UI
- [ ] Send via curl
- [ ] Implement backend `/otp/send` + `/otp/verify` + `/otp/resend` for **one** product
- [ ] Store hashed OTP in Redis with TTL
- [ ] Wire Flutter staging to backend
- [ ] Verify end-to-end on your phone

### 18.2 Multi-product on same account (Requirement 2)

- [ ] Define `productId` list (app1…app5)
- [ ] Confirm Strategy A (shared number)
- [ ] Create templates per product (`otp_app2_login`, …)
- [ ] Add config map product → **same** phoneNumberId + different template
- [ ] Ensure OTP rows include `productId`
- [ ] Test that App1 code cannot verify on App2
- [ ] Separate rate-limit buckets per product

### 18.3 Production cutover

- [ ] Complete Business Verification
- [ ] Add payment method
- [ ] Register production phone number
- [ ] Set display name / photo
- [ ] Create System User permanent token → secrets manager
- [ ] Recreate/approve prod templates
- [ ] Configure prod webhooks + signature validation
- [ ] Staging full regression
- [ ] Soft launch App1
- [ ] Enable SMS/email fallback
- [ ] Monitoring + alerts live
- [ ] Onboard App2…App5 (if Req2)

### 18.4 Optional advanced (after stable)

- [ ] Android one-tap for App1 release + debug hashes in `supported_apps`
- [ ] Zero-tap (only if UX needs it)
- [ ] Locale-dynamic template language selection
- [ ] Per-`productId` pricing dashboards
- [ ] Automatic fallback orchestration (WA → SMS)
- [ ] Revisit Strategy B (number per app) if shared sender/quality becomes a problem

---

## 19. Glossary

| Term | Meaning |
| --- | --- |
| **WABA** | WhatsApp Business Account — container for numbers + templates |
| **Phone Number ID** | API id used when sending messages |
| **Cloud API** | Meta-hosted WhatsApp Business API |
| **BSP** | Business Solution Provider (Twilio, Gupshup, etc.) |
| **Authentication template** | Required template category for OTP codes |
| **wamid** | WhatsApp message id returned on send |
| **E.164** | International phone format (`+9198…`) |
| **System User token** | Long-lived server token for production |
| **Quality rating** | Meta’s health score for your business number |
| **Handshake** | Android signal before one-tap / zero-tap OTP delivery |
| **productId** | Your internal app key used to pick template (+ optional phone) |
| **Strategy A** | One shared number + many templates (Requirement 2) |
| **Strategy B** | One number per product under the same WABA |

---

## 20. Official docs

Keep these bookmarked (UI labels change; concepts stay):

- [WhatsApp Cloud API overview](https://developers.facebook.com/docs/whatsapp/cloud-api)
- [WhatsApp pricing](https://developers.facebook.com/docs/whatsapp/pricing/)
- [Authentication templates](https://developers.facebook.com/docs/whatsapp/cloud-api/guides/send-message-templates/auth-otp-template-messages/)
- [Copy code authentication templates](https://developers.facebook.com/docs/whatsapp/business-management-api/authentication-templates/copy-code-button-authentication-templates/)
- [One-tap autofill authentication templates](https://developers.facebook.com/docs/whatsapp/business-management-api/authentication-templates/autofill-button-authentication-templates/)
- [Zero-tap authentication templates](https://developers.facebook.com/docs/whatsapp/business-management-api/authentication-templates/zero-tap-authentication-templates/)
- [Getting opt-in](https://developers.facebook.com/docs/whatsapp/overview/getting-opt-in)

---

## Final “recipe order” (one page)

1. **Buy groceries:** Finish §0 prerequisites; Business Manager + Developer App + WhatsApp product + test number.
2. **Write recipe cards:** AUTHENTICATION templates (`otp_app1_login`, and for Req2 also app2…app5).
3. **Taste in kitchen:** allow-list your phone → Meta UI → curl.
4. **Build the kitchen line:** backend OTP service with send / verify / resend; hash + TTL + rate limits; `productId` routing.
5. **Serve on plates:** Flutter calls only your backend; copy-code UX first.
6. **Open the restaurant:** verify business, billing, prod number, permanent token, webhooks, SMS fallback.
7. **Expand the menu:** App2…App5 templates on the **same** Phone Number ID (Requirement 2).
8. **Gourmet later:** Android one-tap / zero-tap + smart SMS fallback + optional Strategy B numbers.

If you only remember three rules:

1. **OTP + Meta token = backend only.**  
2. **OTP WhatsApp message = AUTHENTICATION template.**  
3. **Multi-product on one number = same WABA + same Phone Number ID + different templates + `productId` config map.**
