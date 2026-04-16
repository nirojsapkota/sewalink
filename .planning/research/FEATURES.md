# Feature Landscape: sewaLink

**Domain:** Marketplace Platform (Nepal Context)
**Researched:** 2024-05-24

## Table Stakes

Features users expect in a marketplace platform.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Task Posting | Core functionality. | Low | Multi-step form (what, where, when, budget). |
| Task Bidding | Providers need a way to offer services. | Med | Needs notification for the task creator. |
| User Profiles | Trust building. | Low | Includes basic info and phone verification. |
| eSewa Integration | Standard payment in Nepal. | Med | Requires merchant setup and callback handling. |
| Chat Messaging | Coordination between users. | High | Real-time via Hotwire/ActionCable. |
| Review System | Quality control. | Med | Ratings and text reviews after task completion. |

## Differentiators

Features that set sewaLink apart from competitors like Hamrobazaar.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AI "Magic Box" | Lowers barrier for less-tech-literate users via voice. | High | Whisper API + NLP extraction for task creation. |
| Geofencing | Prevents fraudulent completion claims. | Med | Validates tasker's location against task location. |
| Digital Escrow | Guarantees tasker gets paid and user gets work done. | High | Requires eSewa split payment agreement. |
| Bilingual UI | Essential for Nepal's multi-lingual population. | Low | Rails I18n for English/Nepali toggle. |

## Anti-Features

Features to explicitly NOT build for MVP.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| In-app Map Navigation | Google Maps already does this well. | Open Google Maps via deep link. |
| Advanced KYC | High friction for initial users. | SMS OTP for initial trust. |
| International Cards | High fees and low penetration in Nepal. | Stick to eSewa/Khalti/Cash. |

## Feature Dependencies

```
SMS OTP → Account Verification → Task Posting
eSewa Integration → Escrow System → Task Assigning
S3 Storage → Voice Recording → AI Magic Box
PostGIS → Geofencing → Task Completion
```

## MVP Recommendation

Prioritize:
1. **Core Task Lifecycle**: Post/Bid/Assign/Complete with cash-on-completion.
2. **SMS Auth**: Quick onboarding via phone number.
3. **eSewa (Standard)**: Simple payment for platform fees.
4. **AI Magic Box (v1)**: Voice-to-text only (manual confirmation).

Defer:
- **Full Escrow**: Launch after testing standard payments to ensure legal compliance.
- **Geofencing**: Add in Phase 2 for enhanced trust.

## Sources

- [Airtasker Feature Set Analysis](https://www.airtasker.com/how-it-works/)
- [eSewa Merchant Terms](https://esewa.com.np/common/terms)
