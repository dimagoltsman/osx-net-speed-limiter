# NetLimiter

A minimal macOS app to limit network bandwidth. Useful for testing how your applications behave under slow network conditions.

## Use Cases

- Test web apps on slow 3G/4G connections
- Simulate poor network conditions for mobile app development
- Debug timeout handling and loading states
- Test progressive image loading
- Verify offline-first functionality

## Features

- Limit bandwidth from 100 Kbps to 1 Gbps
- Quick presets: 512K, 1M, 10M, 100M, 500M, 1G
- Manual input for precise values
- Real-time speed adjustment (no restart needed)
- Minimal, native macOS UI

## Requirements

- macOS 13.0 or later
- Swift 5.9+

## Building

```bash
# Clone the repo
git clone https://github.com/dimagoltsman/netLimiter.git
cd netLimiter

# Build the .app bundle
./build.sh
```

This creates `NetLimiter.app` in the project directory.

## Installation

```bash
mv NetLimiter.app /Applications/
```

## Running

### First Launch (Gatekeeper)

Since the app is not signed with an Apple Developer certificate, macOS will block it on first launch.

**Option 1: Right-click to open**
1. Right-click (or Control-click) on `NetLimiter.app`
2. Select "Open" from the context menu
3. Click "Open" in the dialog that appears

**Option 2: System Settings**
1. Try to open the app normally (it will be blocked)
2. Go to **System Settings → Privacy & Security**
3. Scroll down to find the message about NetLimiter being blocked
4. Click **"Open Anyway"**

**Option 3: Terminal**
```bash
xattr -cr NetLimiter.app
open NetLimiter.app
```

### Admin Password

When you enable the limiter, macOS will prompt for your admin password. This is required because network throttling uses system-level tools (`dnctl` and `pfctl`).

The password is only requested once per session - you can adjust the speed without re-entering it.

## How It Works

NetLimiter uses macOS's built-in BSD traffic shaping tools:

- **dnctl** (dummynet) - Creates bandwidth-limited pipes
- **pfctl** (packet filter) - Routes traffic through the pipes

These are the same tools used by Apple's Network Link Conditioner, but with a simpler interface.

## Development

Run directly without creating .app bundle:
```bash
./run.sh
# or
swift build && .build/debug/NetLimiter
```

## License

MIT

## Author

[Dima Goltsman](https://github.com/dimagoltsman)
