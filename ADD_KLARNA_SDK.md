# How to Add KlarnaMobileSDK Package

## ⚠️ The Swift Package MUST be added through Xcode UI

I cannot add Swift Package Manager dependencies programmatically - you need to do this manually in Xcode.

---

## 📋 Step-by-Step Instructions (Takes 2 minutes)

### Step 1: Open Project in Xcode
```bash
open msdk-demo.xcodeproj
```

### Step 2: Add Package Dependency

1. In Xcode, look at the **left sidebar** (Project Navigator)
2. Click on the **blue "msdk-demo"** project icon at the very top
3. You'll see two sections in the middle:
   - PROJECT
   - TARGETS
4. Under **TARGETS**, click on **"msdk-demo"** (the app target)

### Step 3: Navigate to Package Dependencies

You have **two options**:

#### Option A: Via Package Dependencies Tab (Xcode 15+)
5. Look for tabs at the top: General, Signing & Capabilities, Resource Tags, Info, **Build Settings**, etc.
6. Scroll right if needed to find: **"Package Dependencies"** tab
7. Click **"Package Dependencies"**

#### Option B: Via General Tab
5. Click the **"General"** tab
6. Scroll down to **"Frameworks, Libraries, and Embedded Content"** section
7. Click the **"+"** button
8. Select **"Add Package Dependency..."**

### Step 4: Add the Klarna Package

9. A dialog will open asking for a package URL
10. Copy and paste this **EXACT URL**:
   ```
   https://github.com/klarna/klarna-mobile-sdk-spm
   ```

11. Click **"Add Package"** button (bottom right)

12. Xcode will fetch the package (you'll see a progress indicator)

### Step 5: Select Package Product

13. A new dialog shows package products
14. Make sure **"KlarnaMobileSDK"** is **CHECKED** ✅
15. Click **"Add Package"** button again

### Step 6: Verify Installation

16. In the Project Navigator (left sidebar), you should now see:
    ```
    msdk-demo
    ├── msdk-demo (folder)
    └── Package Dependencies
        └── klarna-mobile-sdk-spm
    ```

17. Under the target's **"Frameworks, Libraries, and Embedded Content"**, you should see:
    ```
    KlarnaMobileSDK
    ```

---

## ✅ Verification

After adding, try building:

1. Press **⌘+B** (Command + B) to build
2. If successful, you'll see "Build Succeeded" ✅
3. If you still see errors, continue to troubleshooting below

---

## 🔧 Troubleshooting

### Still seeing "No such module 'KlarnaMobileSDK'"?

Try these in order:

#### Fix 1: Clean Build Folder
```
Product → Clean Build Folder (or press ⇧⌘K)
```
Then build again (⌘+B)

#### Fix 2: Reset Package Caches
```
File → Packages → Reset Package Caches
```
Wait for it to finish, then build again

#### Fix 3: Update Package to Latest Commit
```
File → Packages → Update to Latest Package Versions
```

#### Fix 4: Remove and Re-add Package
1. Select **"msdk-demo"** target
2. Go to **"Package Dependencies"** tab (or General → Frameworks)
3. Find **KlarnaMobileSDK** in the list
4. Click the **"-"** button to remove it
5. Click the **"+"** button
6. Add the package again: `https://github.com/klarna/klarna-mobile-sdk-spm`

#### Fix 5: Delete Derived Data
Close Xcode, then run:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/msdk-demo-*
```
Re-open Xcode and build

#### Fix 6: Check Xcode Version
The package requires **Xcode 14.0+**. Check your version:
```
Xcode → About Xcode
```
You're running Xcode 17 (Tools: 17B100), so this should be fine.

---

## 🎯 Visual Guide: Where to Click

```
Xcode Window Layout:
┌────────────────────────────────────────────────────┐
│ Project Navigator │  Editor Area                   │
├────────────────────┼───────────────────────────────┤
│  📁 msdk-demo      │  ← Click blue project icon    │
│    📱 msdk-demo    │                                │
│    📦 Package Deps │  TARGETS:                      │
│                    │  - msdk-demo ← Click this      │
│                    │                                │
│                    │  Tabs:                         │
│                    │  General | Signing | Info...  │
│                    │  ...| Package Dependencies ←  │
│                    │                                │
│                    │  [+ button to add package]     │
└────────────────────┴───────────────────────────────┘
```

---

## 🆘 Still Not Working?

If you've tried all the above and still see the error, please share:

1. What happens when you try to add the package?
2. Any error messages in Xcode?
3. Can you see "Package Dependencies" in the Project Navigator?

You can also try the alternative: **CocoaPods** (see next section)

---

## 🔄 Alternative: Use CocoaPods Instead

If Swift Package Manager isn't working, you can use CocoaPods:

### 1. Install CocoaPods (if not installed)
```bash
sudo gem install cocoapods
```

### 2. Create Podfile
```bash
cd /Users/jing.hao/apps/msdk-demo
cat > Podfile <<'EOF'
platform :ios, '14.0'
use_frameworks!

target 'msdk-demo' do
  pod 'KlarnaMobileSDK', '~> 2.0'
end
EOF
```

### 3. Install Pods
```bash
pod install
```

### 4. **IMPORTANT**: Open the .xcworkspace, NOT .xcodeproj
```bash
open msdk-demo.xcworkspace
```

From now on, always use `.xcworkspace` if using CocoaPods.

---

## 📞 Need More Help?

The package URL is correct: `https://github.com/klarna/klarna-mobile-sdk-spm`

Make sure:
- ✅ You're clicking the blue **project** icon (not the folder)
- ✅ You're selecting the **target** (not the project under PROJECTS)
- ✅ You're pasting the full URL including `https://`
- ✅ You have an internet connection (package needs to download)

Let me know which step is failing and I can provide more specific help!

