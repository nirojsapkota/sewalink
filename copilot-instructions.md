<!-- GSD:project-start source:PROJECT.md -->
## Project

**PROJECT: sewaLink**

A mobile-first marketplace platform tailored for the Nepali market that connects individuals needing small tasks done with local service providers (taskers). Built with **Ruby on Rails and Hotwire Native**, it aims to bridge the gap in Nepal's service economy by prioritizing trust, simplicity, and low-tech accessibility.

**Core Value:** To provide a reliable, culturally-adapted, and AI-enhanced platform where Nepalis can easily outsource tasks and taskers can find secure work opportunities with guaranteed payments.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ruby on Rails | 7.1+ | Backend & API | Industry standard for rapid development; strong convention-over-configuration. |
| Hotwire Native | Latest | Mobile App Wrapper | Allows building native iOS/Android apps using the same Rails views. |
| Tailwind CSS | 3.0+ | Styling | Fast, utility-first styling for responsive mobile views. |
### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | 15+ | Primary DB | Reliable relational data storage; excellent support for PostGIS. |
| Redis | 7+ | Job Queue / Cache | Required for Sidekiq (background jobs) and session management. |
| PostGIS | Latest | Spatial Queries | Essential for geofencing and distance-based task matching. |
### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Fly.io / Render | N/A | Hosting | Simple deployment for Rails; allows hosting in regions close to Nepal (India). |
| AWS S3 | N/A | Object Storage | For storing task images and voice recordings. |
| Sidekiq | 7+ | Background Jobs | For async tasks like AI processing and SMS sending. |
### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `devise` | Latest | Authentication | Standard user auth. |
| `aasm` | Latest | State Machine | Managing task lifecycle transitions. |
| `rgeo` | Latest | Geospatial Logic | Interface for PostGIS in Rails. |
| `google-maps-services` | Latest | Geocoding | Converting addresses to lat/long. |
## Alternatives Considered
| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Mobile | Hotwire Native | React Native | RN requires a separate codebase and higher development overhead for MVP. |
| STT | OpenAI Whisper | Google Cloud STT | Whisper has higher accuracy for diverse accents and lower cost if self-hosted. |
| SMS | Sparrow SMS | Twilio | Twilio is expensive for Nepal and lacks direct local carrier optimization. |
## Installation
# Core
# Geospatial dependencies (System)
# Ubuntu/Debian
## Sources
- [Rails Hotwire Documentation](https://hotwired.dev/)
- [Sparrow SMS API Docs](http://sparrowsms.com/api/)
- [OpenAI Whisper API Docs](https://platform.openai.com/docs/guides/speech-to-text)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.github/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
