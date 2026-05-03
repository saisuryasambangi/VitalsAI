# VitalsAI

Privacy-first health intelligence powered by the Anthropic API. Analyze your HealthKit data with AI — all inference on your device or in the cloud, your choice.

## Demo

[Add 15-second screen recording here showing: app open → real health data → tap Analyze → insight streams in → tab to History]

All health data stays on your device. The AI runs via Anthropic Claude (streaming).

## Technical Highlights

- **HealthKit Integration** — reads steps, resting heart rate, HRV (SDNN), sleep, active energy over a rolling 7-day window
- **Anthropic Claude Streaming** — uses claude-haiku-4-5-20251001 with SSE streaming for real-time text generation
- **Hybrid Provider Architecture** — protocol-based `LLMService` abstraction supports on-device (iOS 26 stub) and Anthropic API; single settings toggle to switch
- **Swift 6 Strict Concurrency** — `HealthDataActor` isolates all HealthKit access; `@MainActor` view models; zero `@unchecked Sendable`
- **SwiftData Persistence** — `InsightRecord` with date-indexed history
- **AppIntents + Siri** — "Hey Siri, analyze my health in VitalsAI" invokes the full pipeline
- **Zero Third-Party Dependencies** — Foundation, HealthKit, SwiftUI, SwiftData only

## Architecture

```
┌─────────────────────────────────────┐
│        SwiftUI Views                │
│  (Dashboard / History / Settings)   │
└────────────┬────────────────────────┘
             │ @Observable
┌────────────▼────────────────────────┐
│    @MainActor ViewModels            │
│  (Dashboard, Insight, Settings)     │
└────────────┬────────────────────────┘
             │
     ┌───────┴────────┐
     │                │
┌────▼────────┐  ┌────▼─────────────┐
│ HealthKit   │  │ LLMService       │
│ Actor       │  │ (protocol)       │
│             │  │                  │
│ HealthData  │  ├─ Anthropic       │
│ Actor       │  │   (SSE stream)   │
│             │  │                  │
│             │  └─ OnDevice (iOS26)│
└─────────────┘  └──────────────────┘
     │                    │
     └─────────┬──────────┘
               │
       ┌───────▼────────┐
       │   SwiftData    │
       │ InsightRecord  │
       └────────────────┘
```

## Requirements

| Requirement | Detail |
|---|---|
| Xcode | 16.0+ |
| iOS | 18.0+ |
| Device | Any iPhone (simulator works for UI, not HealthKit) |
| Anthropic API Key | Required for cloud inference (add to Edit Scheme → Run → Environment) |

## Setup

1. Clone the repo
2. Open `VitalsAI.xcodeproj` in Xcode 16
3. Set your development team in Signing & Capabilities
4. Add your Anthropic API key: Edit Scheme → Run → Arguments → Add Environment Variable `ANTHROPIC_API_KEY`
5. Run on device or simulator
6. Grant HealthKit permissions when prompted
7. Go to Settings tab and configure: age, biological sex, AI provider preference

## Design Decisions

**Why a protocol-based LLM abstraction?**
Production health apps must handle device eligibility gracefully. Not all iPhones support iOS 26 / Foundation Models. A protocol lets us fall back to Anthropic without changing call sites.

**Why no streaming for Anthropic?**
Health insight generation is ~200 tokens. The latency difference between streaming and non-streaming is imperceptible. Collecting the full response and parsing keeps error handling simple.

**Why hardcode benchmarks instead of fetching them?**
Reduces network calls and improves privacy. Published WHO/Firstbeat/NSF guidelines don't change daily.

## What's Next

- **UserProfile refinement** — add optional fitness level, conditions, medications
- **Trend analysis** — compare week-to-week changes, surface actionable patterns
- **Apple Foundation Models** — when Xcode 26 is available, implement `FoundationModelsService` for on-device inference
- **Export insights** — PDF/CSV export of history

## Built With

- [Anthropic Claude](https://anthropic.com) — LLM inference
- Apple HealthKit, SwiftData, AppIntents, SwiftUI
- Swift 6 strict concurrency
