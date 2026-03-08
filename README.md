# PiggyPulse iOS

Native iOS client for [PiggyPulse](https://piggy-pulse.com) — a personal finance app with custom budget periods, spending tracking, and financial health insights.

Built with SwiftUI, targeting iOS 26+.

## Features

### Core
- **Dashboard** — Current period spending, projected pace, spending consistency score, and net position overview
- **Transactions** — Full CRUD with direction filters (Incoming/Outgoing/Transfers), infinite scroll pagination, and pull-to-refresh
- **Budget Periods** — Create, view, and manage custom-length budget periods with auto-creation scheduling
- **Budget Plan** — Category-level budget breakdown with progress tracking

### Structure Management
- **Accounts** — Overview grouped by type (Liquid, Protected, Debt) with balance summaries; create and edit
- **Categories** — Incoming/Outgoing/Archived management with icon and color pickers
- **Vendors** — Track transaction vendors with usage counts
- **Overlays** — Temporary spending plans with cap tracking, active/upcoming/past grouping

### Settings & Security
- **Profile** — Edit name, timezone, view email
- **Password** — Change password from within the app
- **Preferences** — View theme, date format, number format settings

### Authentication
- Email/password login with Bearer token auth
- Two-factor authentication (2FA) support
- Auto-refresh access tokens with secure Keychain storage
- Register and forgot password flows

## Architecture

```
PiggyPulse/
├── App/                    # Entry point, AppState (global auth + period state)
├── Core/
│   ├── Models/             # Codable data models
│   ├── Network/            # APIClient, APIEndpoints, APIError, TokenManager
│   ├── Repositories/       # Data fetching layer
│   └── Utilities/          # KeychainHelper, shared formatters
├── Design/                 # Theme.swift (colors, typography, spacing, radii)
└── Features/
    ├── Auth/               # Login, Register, ForgotPassword, 2FA
    ├── Dashboard/          # Dashboard cards and view model
    ├── Transactions/       # List, Add, Edit sheets
    ├── Periods/            # List, Detail, Create, AutoCreation
    ├── Budget/             # Budget plan view
    ├── Accounts/           # List, Add, Edit sheets
    ├── Categories/         # List, Add, Edit sheets
    ├── Vendors/            # List, Add, Edit sheets
    ├── Overlays/           # List view
    ├── Settings/           # Settings, EditProfile, ChangePassword
    └── Navigation/         # RootView, MainTabView, PeriodSelector
```

**Pattern:** MVVM + Repository, with `@EnvironmentObject` for shared state.

## Tech Stack

- **UI:** SwiftUI, iOS 26+
- **Auth:** Bearer tokens with Keychain persistence, auto-refresh
- **Networking:** URLSession with async/await, snake_case JSON decoding
- **Backend:** [Rust + Rocket + PostgreSQL](https://github.com/your-org/budget) REST API
- **CI:** GitHub Actions (macOS runner, build on PR/push to main)
- **Distribution:** TestFlight via Xcode Cloud

## Getting Started

### Prerequisites
- Xcode 26+
- iOS 26+ device or simulator
- Apple Developer account (for TestFlight)

### Setup
```bash
git clone https://github.com/your-org/piggy-pulse-ios.git
cd piggy-pulse-ios
open PiggyPulse.xcodeproj
```

The app connects to the PiggyPulse API. For local development, update the base URL in `APIClient.swift` to point to your local backend instance.

### Build & Run
1. Select your target device/simulator
2. ⌘R to build and run

### Archive for TestFlight
1. Select "Any iOS Device (arm64)"
2. Product → Archive
3. Distribute App → App Store Connect

## License

PiggyPulse is licensed under the GNU Affero General Public License v3.0 (AGPLv3).

You are free to use, modify, and self-host the software.  
If you run a modified version as a network service, you must make the modified source code available under the same license.

See the LICENSE file for full details.
