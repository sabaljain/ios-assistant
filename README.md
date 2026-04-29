# ios-assistant

An iPhone app that turns natural language into calendar events using **Apple Intelligence on-device** — no internet, no cloud. Built with Swift, FoundationModels, and EventKit.

> "Team standup tomorrow at 9am for 30 minutes in Conference Room B" → event created instantly on-device.

---

## What you need

- Windows PC with [Git for Windows](https://git-scm.com/download/win) installed
- iPhone 15 Pro or later (iPhone 17 is perfect) with iOS 18.1+
- A free Apple ID
- A free Apple Developer account (different from Apple ID — see Step 2)

No Mac. No Xcode. No App Store.

---

## One-time setup

### Step 1 — Install AltStore on your iPhone

AltStore is the app that installs and auto-refreshes your app on your iPhone.

1. On your Windows PC, go to **[altstore.io](https://altstore.io)** and download **AltServer for Windows**.
2. Install AltServer and launch it — it appears as a tray icon.
3. Connect your iPhone to your PC with a USB cable. Trust the computer when prompted on your iPhone.
4. Click the AltServer tray icon → **Install AltStore** → select your iPhone.
5. On your iPhone, go to **Settings → General → VPN & Device Management** → trust the AltStore profile.
6. Open AltStore on your iPhone. Sign in with your Apple ID when prompted.

---

### Step 2 — Create a free Apple Developer account

This is free and separate from your Apple ID. You need it to create signing certificates.

1. Go to **[developer.apple.com](https://developer.apple.com)** and click **Account**.
2. Sign in with your Apple ID.
3. If prompted to enroll, choose **Enroll as an Individual** → follow the steps. **No payment required** — stop before any payment screen. Basic enrollment is free.
4. Once in, you'll land on the developer dashboard. Leave this tab open.

---

### Step 3 — Create a signing certificate

Open **Git Bash** (right-click any folder → "Git Bash Here", or search for it in Start menu) and run these commands one at a time:

```bash
# 1. Create a private key
openssl genrsa -out AppleDevKey.key 2048

# 2. Create a Certificate Signing Request
#    Replace the email and name with your own
openssl req -new -key AppleDevKey.key -out AppleDevRequest.csr \
  -subj "/emailAddress=you@example.com/CN=Your Name/C=US"
```

Now upload the CSR to Apple:

1. In the Apple Developer dashboard, go to **Certificates, Identifiers & Profiles → Certificates → +**
2. Choose **Apple Development** → Continue
3. Click **Choose File** and upload `AppleDevRequest.csr` (it's in whichever folder you ran Git Bash from)
4. Click **Continue** → **Download** — you get a file called `ios_development.cer`

Move `ios_development.cer` to the same folder as your key files, then back in Git Bash:

```bash
# 3. Convert the downloaded certificate to .pem format
openssl x509 -in ios_development.cer -inform DER -out AppleDev.pem

# 4. Bundle the key and certificate into a .p12 file
#    You will be asked to set an export password — remember it, you need it in Step 6
openssl pkcs12 -export -out AppleDev.p12 \
  -inkey AppleDevKey.key -in AppleDev.pem \
  -name "Apple Development"

# 5. Base64-encode the .p12 for GitHub
base64 -w0 AppleDev.p12 > AppleDev.p12.b64
```

---

### Step 4 — Register your iPhone

Apple needs to know your device's unique ID (UDID) before it will let you install a development app.

**Find your UDID:**

- Open AltStore on your iPhone → tap your profile picture (top right) → your UDID is shown on screen. Tap it to copy.

**Register it:**

1. In the Apple Developer dashboard → **Devices → +**
2. Platform: iOS — give it a name (e.g. "My iPhone 17")
3. Paste your UDID → Continue → Register

---

### Step 5 — Create a provisioning profile

1. In the Apple Developer dashboard → **Profiles → +**
2. Choose **iOS App Development** → Continue
3. **App ID**: choose **Wildcard** (`*`) → Continue
4. **Certificate**: select the one you just created → Continue
5. **Devices**: check your iPhone → Continue
6. Name it `CalendarAssistantDev` → Generate → **Download** — you get a `.mobileprovision` file

Back in Git Bash, encode it:

```bash
base64 -w0 CalendarAssistantDev.mobileprovision > profile.b64
```

---

### Step 6 — Add secrets to GitHub

1. Open this repository on GitHub → **Settings → Secrets and variables → Actions → New repository secret**

2. Add these four secrets one at a time:

   | Name | Value |
   |---|---|
   | `CERTIFICATE_P12_BASE64` | Paste the entire contents of `AppleDev.p12.b64` |
   | `CERTIFICATE_PASSWORD` | The export password you chose in Step 3 |
   | `PROVISIONING_PROFILE_BASE64` | Paste the entire contents of `profile.b64` |
   | `APPLE_TEAM_ID` | Your 10-character Team ID — find it at developer.apple.com → Account → top of page |

---

### Step 7 — Set your bundle ID and Team ID in project.yml

Open `project.yml` in any text editor (Notepad is fine) and replace the two placeholder values:

```yaml
# Change this:
bundleIdPrefix: com.replace.with.yourname
# To something unique like:
bundleIdPrefix: com.john.iosassistant

# And change this:
PRODUCT_BUNDLE_IDENTIFIER: com.replace.with.yourname.CalendarAssistant
# To match:
PRODUCT_BUNDLE_IDENTIFIER: com.john.iosassistant.CalendarAssistant

# And change this:
DEVELOPMENT_TEAM: REPLACEME
# To your 10-character Team ID, e.g.:
DEVELOPMENT_TEAM: ABC1234XYZ
```

Save the file, then commit and push:

```bash
git add project.yml
git commit -m "Set bundle ID and team ID"
git push
```

---

### Step 8 — Watch GitHub build your app

1. Go to this repository on GitHub → **Actions** tab
2. You'll see a workflow run triggered by your push — click it to watch the progress
3. It takes about 5–8 minutes
4. When it finishes, click the run → scroll down to **Artifacts** → download **CalendarAssistant-[hash]**
5. Unzip the downloaded file — you'll find a `.ipa` file inside

---

### Step 9 — Install on your iPhone

1. Make sure AltServer is running on your PC (tray icon) and your iPhone is on the same WiFi
2. Open **AltStore** on your iPhone → tap **+** (top left) → **Browse Files**
3. The `.ipa` file may not appear in Files directly — instead:
   - On your PC, open **iTunes** (or **Apple Devices**) while iPhone is connected via USB
   - Drag the `.ipa` onto AltStore's "Sideload" option in the tray icon → select your iPhone
4. The app installs. Open it from your home screen.
5. If iOS blocks it: **Settings → General → VPN & Device Management** → trust the developer profile

---

## Ongoing use

**Rebuilding after code changes:** Push to GitHub → Actions builds a new IPA → download and reinstall via AltStore.

**7-day certificate refresh:** AltStore handles this automatically whenever your iPhone and PC are on the same WiFi with AltServer running. You don't need to do anything.

---

## Project structure

```
Sources/CalendarAssistant/
├── App/
│   ├── CalendarAssistantApp.swift   Entry point
│   ├── AppViewModel.swift           Intent router
│   └── ContentView.swift            UI
├── Connectors/
│   ├── ConnectorProtocol.swift      Add new capabilities here
│   └── Calendar/
│       ├── CalendarConnector.swift  Creates calendar events
│       └── CalendarEventDetails.swift
└── Services/
    ├── FoundationModelsService.swift  On-device Apple Intelligence
    └── MemoryService.swift            Conversation context
```

## Adding new connectors

1. Create `Sources/CalendarAssistant/Connectors/YourThing/YourConnector.swift`
2. Define a `@Generable` struct for what the LLM should extract
3. Conform to `ConnectorProtocol` — implement `intentKeywords` and `execute(input:memory:)`
4. Register in `AppViewModel.init()`: add it to the `connectors` array

Planned: Reminders, Contacts lookup, Notes, Email drafting.
