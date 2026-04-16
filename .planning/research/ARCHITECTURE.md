# Architecture Research: sewaLink

**Domain:** Marketplace Platform (Nepal Context)
**Researched:** 2024-05-24
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile Client (Hotwire Native)           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ Task UI │  │ Payment │  │ AI Mic  │  │ Geofence│        │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       │            │            │            │              │
├───────┴────────────┴────────────┴────────────┴──────────────┤
│                Backend (Ruby on Rails Monolith)             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │            Task Engine & State Machine               │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │       Escrow Service (eSewa Integration)            │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │       AI Assistant Service (Whisper/NLP)            │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    Data & Infrastructure                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ Postgres │  │  Redis   │  │  S3/OSS  │                   │
│  │ (PostGIS)│  │ (Sidekiq)│  │ (Assets) │                   │
│  └──────────┘  └──────────┘  └──────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Task Engine** | Owns task lifecycle (Draft -> Posted -> Assigned -> Completed -> Paid). | Rails State Machine (e.g., `aasm` gem). |
| **Escrow Service** | Manages eSewa payments, holds funds, and handles split settlements (Tasker payout vs Platform commission). | Custom Rails Service calling eSewa ePay v2 API. |
| **AI Magic Box** | Converts voice to task data and provides bilingual NLP support. | Service calling OpenAI Whisper (STT) + GPT-4o (NLP for extraction). |
| **Geofencing** | Validates that a tasker is within the required perimeter of the task location before allowing "Complete" mark. | PostGIS queries via `rgeo` gem or client-side location checks. |
| **Identity Service** | Handles user registration and vetting via phone number verification. | Devise (Rails) + Sparrow SMS / Aakash SMS API for OTP. |

## Recommended Project Structure

```
app/
├── services/           # Business logic outside models
│   ├── ai/             # Whisper & NLP extraction
│   ├── payments/       # eSewa integration logic
│   └── tasks/          # Complex task transitions
├── state_machines/      # Task lifecycle definitions
├── view_components/     # Reusable UI parts for Hotwire
├── controllers/
│   └── api/v1/         # Mobile-first endpoints
└── models/
    └── concerns/       # Shared logic (e.g., Locatable)
```

### Structure Rationale

- **app/services/:** Essential for a marketplace to prevent "Fat Models". Payments and AI logic are volatile and need isolation.
- **app/state_machines/:** A marketplace is fundamentally a state machine. Defining transitions clearly prevents invalid state bugs (e.g., paying before completion).

## Architectural Patterns

### Pattern 1: Sidecar Escrow (External Wallet)

**What:** The platform does not hold funds itself. Instead, it instructs eSewa to hold funds in an "Escrow Merchant Account" and releases them via API.
**When to use:** Mandatory for Nepal to avoid the complexity of becoming a "Payment Service Provider" (PSP) and complying with NRB licensing.
**Trade-offs:** Dependency on eSewa's "Release/Capture" API availability.

### Pattern 2: Voice-to-Draft (Async AI Processing)

**What:** Voice is uploaded to S3, a background job (Sidekiq) processes STT/NLP, and the user receives a notification to "Confirm Draft".
**When to use:** When STT latency > 2 seconds.
**Trade-offs:** Not real-time, but more robust for slow mobile data (common in Nepal).

## Data Flow

### Request Flow (Task Creation)

```
[User Records Voice]
    ↓
[Mobile App] → [Rails API] → [S3 Upload] → [Sidekiq Job]
    ↓              ↓           ↓            ↓
[Response: Ack] ← [STT API] ← [NLP Extractor] ← [S3 URL]
    ↓
[Task Draft Created]
```

### Key Data Flows

1. **Payment Verification:** User completes payment on eSewa app → eSewa redirects to `success_url` → Rails verifies signature with eSewa Backend (Server-to-Server) → Task status updated to `Paid`.
2. **Geofence Validation:** Tasker clicks "Mark Complete" → App sends GPS coords → Rails checks distance against Task `lat/long` using PostGIS → If < 100m, allow transition to `Completed`.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Single Rails monolith on Fly.io (Amsterdam/India region) + managed Postgres. |
| 1k-50k users | Move Sidekiq to dedicated worker. Use Redis for session caching. Implement CDN for images. |
| 50k+ users | DB Read Replicas. Migrate AI processing to dedicated microservice. Optimize PostGIS queries with spatial indexing. |

## Anti-Patterns

### Anti-Pattern 1: Direct P2P Payments

**What people do:** Let users exchange phone numbers and pay via personal eSewa transfer.
**Why it's wrong:** Platform loses commission, and there's no recourse for disputes.
**Do this instead:** Mandatory escrow via platform for "Guaranteed Payment" badge.

### Anti-Pattern 2: Client-side Payment Verification

**What people do:** Trust the `success` query param from the redirect URL.
**Why it's wrong:** Easy to spoof by changing the URL.
**Do this instead:** Always perform a server-to-server **Status Check API** call to eSewa to verify the transaction.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **eSewa** | Redirect + Server Verify | Requires HMAC-SHA256 signature and UAT testing. |
| **Sparrow SMS** | REST API | Used for OTP login; essential for Nepal's mobile-first user base. |
| **OpenAI Whisper** | REST API | High accuracy for Nepali; can be slow for large files. |
| **Google Maps** | JS SDK / Mobile SDK | Best-in-class geocoding for Nepal. |

## Sources

- [eSewa Developer Documentation](https://developer.esewa.com.np/)
- [Airtasker Engineering Blog (State Machines)](https://www.airtasker.com/blog/)
- [PostGIS Official Docs](https://postgis.net/docs/)

---
*Architecture research for: sewaLink (Marketplace)*
*Researched: 2024-05-24*
