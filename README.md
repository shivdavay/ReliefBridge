# ReliefBridge 🌍

**Bridge the gap between crisis and compassion.**

ReliefBridge is an iOS app that transforms a 3D interactive globe into a live humanitarian crisis dashboard. See real disasters happening right now — earthquakes, floods, cyclones, wildfires, droughts — then "bridge" them by pledging support and connecting with verified relief organizations you can contact and donate to.

Every data point is real. Every crisis is live. Zero mock data.

![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![iOS](https://img.shields.io/badge/iOS-17%2B-blue) ![APIs](https://img.shields.io/badge/APIs-USGS%20%7C%20GDACS%20%7C%20Every.org-green) ![Data](https://img.shields.io/badge/Data-100%25%20Live-brightgreen)

---

## What It Does

ReliefBridge pulls live crisis data from USGS and GDACS, renders it on a 3D satellite globe, and lets users take action:

- **Bridge Tab** — Interactive 3D globe with color-coded crisis hotspots (red = severe, orange = significant, green = limited). Tap any hotspot to see details, pledge support, and contact verified relief orgs. Geodesic arcs animate from your location to each need you bridge. Pulsing LIVE indicator + severity legend with real-time counts. Auto-refreshes every 2 minutes.

- **Respond Tab** — Urgency-ranked triage feed of every active crisis worldwide. Each need is scored by a deterministic urgency index (severity + recency + magnitude + geographic reach). Filter by severity or hazard type, search by country or crisis name. Every row shows how many verified relief orgs you can contact.

- **Surplus Tab** — Register what you can give (supplies, skills, volunteer hours, blood), and the app matches your surplus to the nearest, most urgent live crises ranked by real Haversine distance from your GPS location.

- **Impact Tab** — Dashboard tracking your real bridges: funds pledged, needs fulfilled, regions reached. Swift Charts visualizations of your contribution breakdown and the global crisis pulse (severity split + hazard distribution).

- **Every.org Integration** — Verified nonprofit organizations matched to each crisis type, prefetched so they appear instantly. Tap "Contact" to open their Every.org profile where you can donate or reach out.

---

## Tech Stack

### Language
- **Swift** (100% — 36 source files, ~4,500 lines)

### Apple Frameworks
| Framework | Purpose |
|---|---|
| **SwiftUI** | Declarative UI — tabs, sheets, animations, glassmorphism dark theme |
| **MapKit** | 3D satellite globe (`.imagery(elevation: .realistic)`), `MKGeodesicPolyline` bridge arcs, `Annotation` hotspots |
| **CoreLocation** | Device GPS for bridge-arc origin + proximity-based surplus matching |
| **Swift Charts** | `BarMark` charts for impact dashboard and global crisis pulse |
| **Combine** | Reactive `@Published` / `ObservableObject` data binding |
| **Foundation** | `URLSession` async/await, `JSONDecoder`, `UserDefaults` persistence |

### Live APIs (no mock data, ever)
| API | What it provides |
|---|---|
| [**USGS Earthquake Hazards Program**](https://earthquake.usgs.gov) | Real-time M4.5+ earthquakes worldwide (GeoJSON, updated every minute) |
| [**GDACS**](https://www.gdacs.org) (Global Disaster Alert & Coordination System) | Multi-hazard events — floods, cyclones, droughts, volcanoes, wildfires (GeoJSON) |
| [**Every.org Partners API**](https://www.every.org/docs/partners) | Verified nonprofit organizations matched by crisis type, with donate/contact links |

### Architecture
- **Zero backend** — all networking is on-device via `URLSession`
- **UserDefaults persistence** — contributions and surplus offers survive app restarts
- **Deterministic urgency scoring** — `urgencyScore = f(severity, recency, magnitude, reach)` — no AI black box
- **Per-kind org caching** — Every.org results cached by hazard type (~8 calls covers all 187+ needs)
- **120-second auto-refresh** — timer-based live feed with tolerance for battery efficiency

---

## How to Build & Run

1. Open `ReliefBridgeApp.xcodeproj` in Xcode 15+
2. Select an iOS 17+ Simulator (e.g., iPhone 15 Pro)
3. Build & Run (⌘R)
4. The app pulls live data on launch — give it a few seconds for USGS + GDACS + Every.org to load

> **Tip:** Set the `RB_TAB` environment variable to `0`–`3` in your scheme to launch directly to a specific tab.

---

## Inspiration

We were struck by the disconnect between how much crisis data exists in the world and how hard it is for regular people to find, understand, and act on it. USGS and GDACS publish incredibly detailed real-time feeds — but they're JSON endpoints that most people will never see. We wanted to take that raw data and put it on a 3D globe where a crisis isn't just a data point — it's a place, with real people, that you can *bridge* to with a single tap. The name "ReliefBridge" captures exactly that: you're not just viewing a crisis, you're building a bridge from where you are to where help is needed.

## What We Learned

- **Live APIs are messy.** USGS and GDACS have completely different schemas, date formats, severity scales, and coordinate conventions. Making them feel like one unified feed required careful normalization — null-island guards, severity mapping, deduplication, and graceful degradation when one feed fails.
- **MapKit's 3D globe is powerful but underdocumented.** Getting `MKGeodesicPolyline` to render great-circle arcs over a realistic satellite globe with custom annotations required a lot of experimentation. The result — watching a bridge arc animate from San Francisco to a flood in Bangladesh — made it all worth it.
- **Caching strategy matters.** Our first Every.org integration made one API call per need (187+ calls). Refactoring to cache per hazard kind brought it down to ~8 calls total, making orgs appear instantly.
- **"Make it work first" is real wisdom.** We built the entire data pipeline and interaction model before touching visuals. When we did the polish pass (glassmorphism panels, severity legends, pulsing LIVE dots), the foundation was rock solid.

## How We Built It

1. **Data layer first.** We curl-tested every API candidate (USGS, GDACS, ReliefWeb) before writing a line of Swift. ReliefWeb v2 returned 403s (requires an approved appname) — we excluded it rather than faking it. We decoded real GeoJSON responses to design our `Need` model.
2. **ReliefService as the single source of truth.** One `@MainActor ObservableObject` manages all live data, contributions, surplus offers, org caching, and location. Every view reads from it reactively.
3. **Globe + interactions.** MapKit's `.imagery(elevation: .realistic)` gives us the 3D satellite globe. Crisis hotspots are `Annotation` views with pulsing severity-colored rings. Bridge arcs use `MKGeodesicPolyline` for accurate great-circle paths. Tapping opens a detail sheet with pledge actions and verified org contacts.
4. **Four real-data tabs.** Bridge (globe), Respond (urgency triage), Surplus (proximity matching via Haversine), Impact (Swift Charts dashboard). All pull from the same live `ReliefService`.
5. **Every.org integration.** Prefetch verified nonprofits for all hazard types after each refresh. Cache per search term. Surface contact buttons in the crisis detail sheet + org count pills in every Respond list row + "Orgs to Contact" KPI on the globe.
6. **Polish pass.** Glassmorphism dark theme, pulsing LIVE indicator, severity legend with counts, rebranded boot screen, auto-refresh timer.

## Challenges We Faced

- **ReliefWeb API lockout.** v1 was decommissioned (410 Gone), v2 requires a pre-approved `appname` header (returns 403 without it). Rather than fake credentials, we honestly excluded it and built richer features on USGS + GDACS instead.
- **No synthetic taps in Simulator.** macOS blocks `osascript` accessibility without explicit permission, so we couldn't programmatically tap hotspots for QA screenshots. We built a `RB_TAB` environment variable workaround to launch directly to any tab.
- **Xcode project registration without Xcodegen.** Every new Swift file had to be hand-registered in `project.pbxproj` with unique file reference IDs, build phase entries, and group membership. A single misplaced character = build failure with no useful error message.
- **GDACS date formats.** GDACS uses ISO 8601 dates... sometimes with fractional seconds, sometimes without, sometimes with timezone, sometimes without. We needed a two-pass parser with fallback.
- **Making 187+ crises feel actionable, not overwhelming.** The urgency scoring system (severity × recency × magnitude × reach) was our answer — it ranks crises so the most actionable ones surface first, whether you're on the globe, the triage list, or the surplus matcher.

---

## License

MIT

---

*Built with SwiftUI, MapKit, live data from USGS + GDACS + Every.org, and the belief that bridging the gap between crisis and compassion should be one tap away.*
