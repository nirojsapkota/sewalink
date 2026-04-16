# Technology Stack: sewaLink

**Project:** sewaLink
**Researched:** 2024-05-24

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

```bash
# Core
bundle add rails tailwindcss-rails hotwire-rails sidekiq aasm rgeo devise

# Geospatial dependencies (System)
# Ubuntu/Debian
sudo apt-get install libgeos-dev libproj-dev postgis
```

## Sources

- [Rails Hotwire Documentation](https://hotwired.dev/)
- [Sparrow SMS API Docs](http://sparrowsms.com/api/)
- [OpenAI Whisper API Docs](https://platform.openai.com/docs/guides/speech-to-text)
