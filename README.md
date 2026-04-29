# ios-assistant

An iPhone app that turns natural language into calendar events using **Apple Intelligence on-device** — no internet, no cloud. Built with Swift, FoundationModels, and EventKit.

> "Team standup tomorrow at 9am for 30 minutes in Conference Room B" → event created instantly on-device.

---

## What you need

- Windows PC
- iPhone 15 Pro or later (iPhone 17 is perfect) with iOS 18.1+ and Apple Intelligence enabled
- A free Apple ID
- A GitHub account (free)

No Mac. No Xcode. No paid developer account. No certificates to manage.

---

## How it works

1. You push code to GitHub
2. GitHub Actions builds the app on a cloud Mac and produces an `.ipa` file
3. You download the `.ipa` and install it on your iPhone using **AltStore** (free, Windows)
4. AltStore handles all signing automatically using your free Apple ID

---

## Setup (one time, ~10 minutes)

### Step 1 — Install AltStore on your iPhone

1. On your Windows PC, go to **[altstore.io](https://altstore.io)** and download **AltServer for Windows**
2. Install AltServer and launch it — it appears as an icon in the system tray (bottom-right of taskbar)
3. Connect your iPhone to your PC with a USB cable and unlock it. Tap **Trust** if prompted
4. Click the AltServer tray icon → **Install AltStore** → select your iPhone
5. On your iPhone: **Settings → General → VPN & Device Management** → find the AltStore entry → tap **Trust**
6. Open AltStore on your iPhone and sign in with your Apple ID when prompted

### Step 2 — Set your bundle ID

Open `project.yml` in any text editor (Notepad works) and replace the two instances of `com.replace.with.yourname` with any unique reverse-domain string — for example `com.john` or `com.myname2026`. It just needs to be unique to you.

```yaml
# Change these two lines:
bundleIdPrefix: com.replace.with.yourname
PRODUCT_BUNDLE_IDENTIFIER: com.replace.with.yourname.CalendarAssistant

# To something like:
bundleIdPrefix: com.john
PRODUCT_BUNDLE_IDENTIFIER: com.john.CalendarAssistant
```

Save the file, then commit and push:

```bash
git add project.yml
git commit -m "Set bundle ID"
git push
```

### Step 3 — Download and install the app

1. Go to this repository on GitHub → click the **Actions** tab
2. Click the most recent workflow run → wait for it to finish (5–8 minutes, green checkmark)
3. Scroll to the bottom of the run page → **Artifacts** → click **CalendarAssistant-[hash]** to download
4. Unzip the downloaded file — you'll find `CalendarAssistant.ipa` inside
5. Make sure AltServer is running (tray icon) and your iPhone is connected via USB or on the same WiFi
6. Click the AltServer tray icon → **Sideload .ipa** → select your iPhone → pick `CalendarAssistant.ipa`
7. Open the app on your iPhone. When iOS asks, go to **Settings → General → VPN & Device Management** → trust the profile

---

## Ongoing use

**After making code changes:** push to GitHub → Actions builds a new IPA → download and sideload again via AltServer.

**Certificate refresh (every 7 days):** AltServer does this automatically in the background whenever your iPhone is on the same WiFi network. You don't need to do anything.

---

## Project structure

```
Sources/CalendarAssistant/
├── App/
│   ├── CalendarAssistantApp.swift   Entry point
│   ├── AppViewModel.swift           Intent router — register new connectors here
│   └── ContentView.swift            Chat-style SwiftUI UI
├── Connectors/
│   ├── ConnectorProtocol.swift      Base protocol for all capabilities
│   └── Calendar/
│       ├── CalendarConnector.swift  EventKit wrapper
│       └── CalendarEventDetails.swift  Typed LLM output schema (@Generable)
└── Services/
    ├── FoundationModelsService.swift  On-device Apple Intelligence
    └── MemoryService.swift            Short-term conversation context
```

## Adding new connectors

1. Create `Sources/CalendarAssistant/Connectors/YourThing/YourConnector.swift`
2. Define a `@Generable` struct for what the LLM should extract from the input
3. Conform to `ConnectorProtocol` — implement `intentKeywords` and `execute(input:memory:)`
4. Register in `AppViewModel.init()`: add it to the `connectors` array

Planned: Reminders, Contacts lookup, Notes, Email drafting.
