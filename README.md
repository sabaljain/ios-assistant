# ios-assistant

An iPhone app that turns natural language into calendar events using **Apple Intelligence on-device** — no internet, no cloud. Built with Swift, FoundationModels, and EventKit.

> "Team standup tomorrow at 9am for 30 minutes in Conference Room B" → event created instantly on-device.

---

## Requirements

| Requirement | Detail |
|---|---|
| iPhone | 15 Pro or later (A17 Pro+ required for Apple Intelligence) |
| iOS | 18.1+ with Apple Intelligence enabled |
| Windows | Git for Windows (provides Git Bash + OpenSSL — likely already installed) |
| Apple ID | Free Apple ID is sufficient for development sideloading |

---

## Project Structure

```
Sources/CalendarAssistant/
├── App/
│   ├── CalendarAssistantApp.swift   @main entry point
│   ├── AppViewModel.swift           Intent router — add connectors here
│   └── ContentView.swift            SwiftUI chat-style UI
├── Connectors/
│   ├── ConnectorProtocol.swift      Base protocol for all capabilities
│   └── Calendar/
│       ├── CalendarConnector.swift  EventKit wrapper
│       └── CalendarEventDetails.swift  @Generable LLM output schema
└── Services/
    ├── FoundationModelsService.swift  On-device LLM (Apple Intelligence)
    └── MemoryService.swift            Short-term conversation context
```

---

## Build & Install (Windows — No Mac Required After Setup)

### One-time setup (~45 minutes)

1. **Create Apple signing certificate on Windows** using Git Bash (comes with [Git for Windows](https://git-scm.com/download/win) — no Mac, no Xcode needed):

   ```bash
   # Open Git Bash, then run:

   # 1. Generate a private key
   openssl genrsa -out AppleDevKey.key 2048

   # 2. Generate a Certificate Signing Request (CSR)
   #    Fill in your name and email when prompted, or use -subj to skip prompts:
   openssl req -new -key AppleDevKey.key -out AppleDevRequest.csr \
     -subj "/emailAddress=you@example.com/CN=Your Name/C=US"

   # 3. Upload AppleDevRequest.csr to:
   #    developer.apple.com → Certificates → + → Apple Development → upload CSR
   #    Download the resulting ios_development.cer

   # 4. Convert the downloaded .cer to .pem
   openssl x509 -in ios_development.cer -inform DER -out AppleDev.pem

   # 5. Bundle key + cert into a .p12 (choose any export password)
   openssl pkcs12 -export -out AppleDev.p12 \
     -inkey AppleDevKey.key -in AppleDev.pem \
     -name "Apple Development"

   # 6. Base64-encode for GitHub Secrets
   base64 -w0 AppleDev.p12 > AppleDev.p12.b64
   ```

   Keep `AppleDev.p12.b64` and the export password — you'll need them in step 4.

2. **Register your device** — connect iPhone, open AltStore on Windows, find your UDID. Add it at [developer.apple.com/account/resources/devices](https://developer.apple.com/account/resources/devices).

3. **Create a provisioning profile** at [developer.apple.com](https://developer.apple.com/account/resources/profiles) → Development → iOS App Development. Download the `.mobileprovision` file.

4. **Add GitHub Secrets** — go to this repo → Settings → Secrets and variables → Actions:

   | Secret name | Value |
   |---|---|
   | `CERTIFICATE_P12_BASE64` | `base64 -w0 cert.p12` output |
   | `CERTIFICATE_PASSWORD` | Password for the .p12 file |
   | `PROVISIONING_PROFILE_BASE64` | `base64 -w0 profile.mobileprovision` output |
   | `APPLE_TEAM_ID` | Your 10-character Team ID from developer.apple.com |

5. **One-time Xcode project creation** (borrow a Mac or use a cloud Mac like MacInCloud for ~30 min):
   - Open `Package.swift` in Xcode 16
   - File → New → Target → iOS App → name it `CalendarAssistant`
   - Add all `.swift` files from `Sources/CalendarAssistant/` to the new target
   - Set deployment target to iOS 18.1
   - Add `FoundationModels.framework` under Frameworks and Libraries
   - Set Info.plist path to `Info.plist`
   - Commit the generated `.xcodeproj` to this repo

### Every push

Push code → GitHub Actions (macOS cloud runner) builds automatically → download the `.ipa` from the Actions tab.

### Every 7 days (install / refresh)

1. Download the `.ipa` from GitHub Actions → Artifacts
2. Open **AltServer** on Windows (free, [altstore.io](https://altstore.io))
3. Drag the `.ipa` onto AltStore — it signs and installs using your free Apple ID
4. AltServer **auto-refreshes** the certificate in the background when your phone is on the same WiFi

> **Upgrade**: A paid Apple Developer account ($99/yr) lets you use TestFlight — one-tap install, no 7-day refresh needed.

---

## Adding New Connectors

1. Create `Sources/CalendarAssistant/Connectors/YourThing/YourConnector.swift`
2. Define a `@Generable` struct for the LLM output schema
3. Conform to `ConnectorProtocol` — implement `intentKeywords` and `execute(input:memory:)`
4. Register in `AppViewModel.init()`: `connectors = [calendarConnector, YourConnector()]`

Planned connectors: Reminders, Contacts lookup, Notes, Email drafting.
