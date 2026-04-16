# Domain Pitfalls: sewaLink (Marketplace in Nepal)

**Domain:** Marketplace Platform (Nepal Context)
**Researched:** 2024-05-24

## Critical Pitfalls

Mistakes that cause rewrites or major business failure.

### Pitfall 1: Platform Leakage (The "Offline Payment" Trap)
**What goes wrong:** Users and taskers exchange phone numbers and bypass the platform for payment to avoid commissions.
**Why it happens:** Friction in digital payments or high commission fees.
**Consequences:** Revenue loss, zero dispute protection for users, and no data for rating systems.
**Prevention:** Implement "Guaranteed Payment" badges for escrow-paid tasks, keep commissions low for MVP, and provide value-added features (e.g., insurance/dispute resolution) only for platform-mediated tasks.

### Pitfall 2: SMS Delivery Reliability
**What goes wrong:** OTPs don't arrive on certain local carriers (e.g., Ncell vs NTC issues).
**Why it happens:** Inter-carrier routing or outdated bulk SMS gateways.
**Consequences:** High onboarding drop-off rate.
**Prevention:** Use a reputable local provider like Sparrow SMS or Aakash SMS with high delivery rates and fallback options.

## Moderate Pitfalls

### Pitfall 3: eSewa Signature Spoofing
**What goes wrong:** Attackers spoof the "Success" response URL from eSewa.
**Prevention:** Always perform a **Server-to-Server status check** after a redirect to verify the transaction status and amount.

### Pitfall 4: Location Accuracy in Nepal
**What goes wrong:** Geofencing fails because users/taskers aren't mapped correctly in remote areas or due to GPS noise.
**Prevention:** Allow a reasonable radius (e.g., 200m) and provide a "Manual Override with Reason" feature for edge cases.

## Minor Pitfalls

### Pitfall 5: Bilingual Data Inconsistency
**What goes wrong:** Mixing Nepali and English in search results (e.g., searching "Plumber" vs "प्लम्वर").
**Prevention:** Implement fuzzy search or synonym mapping (e.g., "Plumber" maps to both).

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Authentication | User frustration with SMS delays | Add "Resend OTP" button after 60s and a WhatsApp fallback if possible. |
| Payments | eSewa UAT vs Production differences | Test early with a real small transaction in a controlled "Production Sandbox." |
| AI Integration | STT failing on thick local accents | Allow users to manually correct the AI-extracted task draft easily. |

## Sources

- [Nepal FinTech Ecosystem Analysis 2023](https://www.nrb.org.np/)
- [Local Developer Community Discussions (IT Entrepreneurs Nepal)](https://www.facebook.com/groups/ITEntrepreneursNepal/)
