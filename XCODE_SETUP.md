# Xcode Setup Instructions

Follow these steps **in order** to configure the Xcode project properly.

## Step 1: Add KlarnaMobileSDK Package

1. Open `msdk-demo.xcodeproj` in Xcode
2. Select the **project** (blue icon) in the Project Navigator
3. Select the **msdk-demo** target
4. Click the **"Package Dependencies"** tab (or **"Frameworks, Libraries, and Embedded Content"**)
5. Click the **"+"** button at the bottom
6. In the search field, enter: `https://github.com/klarna/klarna-mobile-sdk-spm`
7. Click **"Add Package"**
8. Select **"Up to Next Major Version"** with `2.0.0`
9. Click **"Add Package"** again
10. Make sure **KlarnaMobileSDK** is checked
11. Click **"Add Package"** to confirm

## Step 2: Configure URL Scheme (Info.plist)

Since we removed the custom Info.plist to fix the build conflict, add the URL scheme via Xcode:

1. Select the **msdk-demo** target in Xcode
2. Go to the **"Info"** tab
3. Scroll down to **"URL Types"**
4. Click the **"+"** button to add a new URL type
5. Set:
   - **Identifier**: `com.klarna.msdk-demo`
   - **URL Schemes**: `msdk-demo`
   - **Role**: `Editor`

### Visual Guide:
```
Info
└── URL Types (Array)
    └── Item 0 (Dictionary)
        ├── Document Role (String): Editor
        ├── URL identifier (String): com.klarna.msdk-demo
        └── URL Schemes (Array)
            └── Item 0 (String): msdk-demo
```

## Step 3: Clean Build Folder

1. In Xcode menu: **Product → Clean Build Folder** (or press **⇧⌘K**)
2. Close and reopen the project if needed

## Step 4: Verify Package Resolution

1. Go to **File → Packages → Resolve Package Versions**
2. Wait for the package to download (you'll see progress in the top bar)
3. Verify `KlarnaMobileSDK` appears under **Package Dependencies**

## Step 5: Update Klarna Credentials

Before running, update the Klarna API credentials:

1. Open `msdk-demo/Services/KlarnaService.swift`
2. Find the `makeDefaultService()` method:
   ```swift
   static func makeDefaultService() -> KlarnaService {
       return KlarnaService(
           username: "YOUR_KLARNA_USERNAME",
           password: "YOUR_KLARNA_API_KEY"
       )
   }
   ```
3. Add your Klarna Playground credentials

**Where to get credentials:**
- Go to [Klarna Merchant Portal](https://portal.playground.klarna.com/)
- Navigate to Settings → API Keys
- Copy your Username (UID) and API Key

## Step 6: Build and Run

1. Select a simulator (iPhone 15 Pro or later recommended)
2. Press **⌘+R** to build and run
3. If you see errors, try:
   - Clean build folder again (**⇧⌘K**)
   - Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/msdk-demo-*`
   - Restart Xcode

## Troubleshooting

### "Unable to find module dependency: 'KlarnaMobileSDK'"

**Solution**: Make sure you completed Step 1. The package must be added before building.

To verify:
- Project Navigator → Project → Package Dependencies
- You should see `klarna-mobile-sdk-spm` listed

### "Multiple commands produce Info.plist"

**Solution**: This has been fixed by removing the custom Info.plist. Make sure you complete Step 2 to add the URL scheme manually.

### Build succeeds but app shows error creating session

**Solution**: 
1. Verify credentials are set in `KlarnaService.swift`
2. Check that you're using Klarna **Playground** credentials (not production)
3. Ensure your credentials have proper permissions

### Package won't download

**Solution**:
1. Check your internet connection
2. Try: **File → Packages → Reset Package Caches**
3. Remove and re-add the package

## Verification Checklist

Before running the app, verify:

- ✅ KlarnaMobileSDK package is added and resolved
- ✅ URL scheme `msdk-demo` is configured in Info tab
- ✅ Build folder is cleaned
- ✅ Klarna credentials are updated in `KlarnaService.swift`

## Next Steps

Once the app builds successfully:

1. Run the app in simulator
2. You'll see the product detail page
3. Tap "Buy with Klarna"
4. The payment flow will initiate
5. Complete the test payment in the Klarna UI

## Architecture Note

This app uses a **monolithic architecture** - the iOS app communicates directly with the Klarna Playground API:

```
iOS App → https://api.playground.klarna.com
```

No backend server is required. All Klarna API calls are made directly from the app.
