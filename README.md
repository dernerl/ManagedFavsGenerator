# Managed Favs Generator

A native macOS app to generate Microsoft Edge Managed Favorites configuration files for enterprise deployment via Group Policy (GPO) and Microsoft Intune.
All code come from Atlassian Rovo Dev (anthropic.claude-sonnet-4-5-20250929-v1:0)
<img width="1185" height="654" alt="image" src="https://github.com/user-attachments/assets/d0c26272-f577-44ee-8651-291afb68d25b" />

<img width="680" height="262" alt="image" src="https://github.com/user-attachments/assets/054c9dfa-f9ad-43fb-88cb-27aae5d7cc02" />


## 🎯 What Does It Do?

This app helps IT administrators create and manage Microsoft Edge favorites that can be deployed to users across an organization. It generates properly formatted configuration files for:

- **Windows devices** (via Group Policy or Intune) — device-wide
- **macOS devices** (via Intune) — device-wide
- **A specific audience, any platform** (via the Edge management service's Cloud Policy) — per-profile, assignable to an Entra ID group, works on Windows/macOS/iOS/Android from one policy

The first two channels write into the OS-level Managed Preferences domain, so every browser profile on the device gets the same favorites. The Cloud Policy channel is resolved per the identity signed into the Edge profile instead, so it's the one to reach for when only part of your organization should get a given set of favorites. See [Deployment Scenarios](#-deployment-scenarios) below.

Instead of manually creating complex JSON or Plist files, you use a simple, intuitive interface to:
1. Add favorites (name + URL)
2. Generate configuration files automatically
3. Copy or export them for deployment

## ✨ Key Features

- 🎨 **Native macOS Design** - Modern, fluid interface with animations
- ⌨️ **Keyboard Shortcuts** - Fast workflow (⌘N to add, ⌘S to export, ⌘⇧C to copy)
- 💾 **Persistent Storage** - Your favorites are saved automatically
- 📋 **Multiple Formats** - Generates JSON (Windows GPO/Settings Catalog, Cloud Policy) and Plist (macOS Intune)
- 🎯 **Target Groups** - Maintain extra favorites for a specific audience (e.g. an Entra group) alongside the base set, either merged in as a subfolder or replacing the base set for that audience — exported as its own ready-to-paste Cloud Policy value
- 🚀 **Export Ready** - One-click export or copy to clipboard
- ⚙️ **Configurable** - Customize toplevel names for your organization

## 📋 Requirements

- **macOS 15.0 (Sequoia)** or later
- **Xcode 16** or later (for building from source)

## 🚀 Quick Start

### Option 1: Download Pre-built Release

1. **Download** the latest release from [GitHub Releases](https://github.com/dernerl/ManagedFavsGenerator/releases/latest)
2. **Unzip** `ManagedFavsGenerator-vX.X.X.zip`
3. **Move** `ManagedFavsGenerator.app` to your Applications folder
4. **Launch** the app

### Option 2: Build from Source

```bash
# Clone the repository
git clone <repository-url>
cd ManagedFavsGenerator

# Build
swift build -c release

# Run
.build/release/ManagedFavsGenerator
```

Or open `Package.swift` in Xcode and press ⌘R.

---

### 🔒 macOS Gatekeeper (First Launch)

Since this app is not notarized by Apple, macOS Gatekeeper will block it on first launch. You need to allow it manually.

#### **Method 1: Terminal (Quick)**

Remove the quarantine attribute to bypass Gatekeeper:

```bash
# Navigate to where you saved the app
cd ~/Downloads

# Remove quarantine flag
xattr -cr ManagedFavsGenerator.app

# Now open normally
open ManagedFavsGenerator.app
```

**Explanation:**
- `xattr` = Extended attributes tool
- `-c` = Clear all attributes
- `-r` = Recursive (for app bundles)

#### **Method 2: GUI (System Settings)**

1. Try to open `ManagedFavsGenerator.app`
2. macOS shows: _"ManagedFavsGenerator.app can't be opened because it is from an unidentified developer"_
3. Click **OK**
4. Open **System Settings** → **Privacy & Security**
5. Scroll down to **Security** section
6. Click **Open Anyway** next to the blocked app message
7. Click **Open** in the confirmation dialog
8. App will launch successfully

**Screenshot:**
```
System Settings → Privacy & Security
┌─────────────────────────────────────────┐
│ Security                                │
│ "ManagedFavsGenerator.app" was blocked │
│ [Open Anyway]                           │
└─────────────────────────────────────────┘
```

#### **Method 3: Right-Click (Alternative)**

1. **Right-click** (or Control-click) on `ManagedFavsGenerator.app`
2. Select **Open** from context menu
3. macOS shows modified dialog with **Open** button
4. Click **Open**
5. App will launch and be remembered for future launches

---

### ✅ Verification (Optional)

Verify the download integrity using checksums:

```bash
# Download checksums
curl -L -O https://github.com/dernerl/ManagedFavsGenerator/releases/download/vX.X.X/checksums.txt

# Verify ZIP file
shasum -a 256 ManagedFavsGenerator-vX.X.X.zip
cat checksums.txt

# Both SHA-256 hashes should match
```

---

## 📖 How To Use

### 1. **Add Favorites**
<img width="344" height="73" alt="image" src="https://github.com/user-attachments/assets/751075e3-8b0c-4776-8087-105daa42cb4f" />

Press **⌘N** or click the **Add Favorite** button in the toolbar:
- **Name**: Display name (e.g., "Company Portal")
- **URL**: Full URL including `https://`

**Add Folders**

<img width="329" height="68" alt="image" src="https://github.com/user-attachments/assets/3789c903-734d-4d95-a7f4-3ffcbe1eba4a" />

Press **(⌘⇧N)** or click the **Add Folders** button to organize favorites hierarchically.
<img width="467" height="250" alt="image" src="https://github.com/user-attachments/assets/f70e268d-995f-490a-9188-65b7f0f311d2" />


### 2. **Move position by Drag and Drop

<img width="235" height="143" alt="image" src="https://github.com/user-attachments/assets/bdcd796e-6eb1-4652-ab99-9217c8fad0eb" />



### 2. **Import Existing Configuration** 

Import existing configurations from other sources or backups:

#### **JSON Import (Copy/Paste)** - ⌘I
<img width="336" height="68" alt="image" src="https://github.com/user-attachments/assets/19fb6204-f558-490f-bf11-97db2324aa4a" />

- Click **Import JSON** or press **⌘I**
- Dialog opens with text editor
- Paste your JSON configuration
- Click **Import**
- Perfect for quick imports, testing, or snippets

#### **Plist Import (File Selection)** - ⌘⇧I
<img width="412" height="65" alt="image" src="https://github.com/user-attachments/assets/47ca89c5-650e-48c1-97e0-d7d66ad4fa7b" />

- Click **Import Plist** or press **⌘⇧I**
- Select `.plist` file from your system
- Supports full Plist files and Intune fragments
- Automatically handles files without XML headers

### 3. **Generate Outputs**

The app automatically generates three outputs as you add favorites:

#### **JSON Format** (for Windows/GPO)
- Used for on-premises Group Policy
- Used for Intune Settings Catalog (Windows)
- Press **⌘⇧C** to copy to clipboard

#### **Plist Format** (for macOS/Intune)
- Used for Intune Device Configuration Profiles
- Press **⌘S** to export as file
- Or click Copy to copy to clipboard

#### **Cloud Policy** (for the Edge management service)
- Same JSON schema as the GPO/Settings Catalog output — paste it as the `ManagedFavorites` value of a Cloud configuration policy in the Microsoft 365 Admin Center
- Resolved per signed-in Edge profile and assignable to an Entra ID group, so it reaches only the intended audience instead of the whole device
- Select the card's text and copy manually (no dedicated shortcut yet)

### 3a. **Target Groups (optional)**

If part of your organization needs extra favorites that the rest shouldn't get, add a **Target Group** below the main favorites list instead of maintaining a second document:
- **Merge into base set**: the base favorites stay, the group is appended as its own subfolder — assign as an additive, lower-priority Cloud policy
- **Replace base set**: the group becomes its own toplevel folder, replacing the base set for that audience — assign as the *highest*-priority Cloud policy for that Entra group, since `ManagedFavorites` does not merge across policies (the highest-priority policy wins completely)

Each Target Group gets its own output card, generated the same way as the base set.

### 4. **Configure Toplevel Name**
<img width="519" height="111" alt="image" src="https://github.com/user-attachments/assets/0e1d3dd3-7e6d-4d4d-9a1e-43fc38cd872d" />

The toplevel name (default: `managedFavs`) is the root key in your configuration. Change it in Settings (⌘,) if needed.

### 5. **Deploy to Your Organization**

See deployment guides below for Windows GPO, Intune Windows, or Intune macOS.

### 6. **Choose Favicon Provider
<img width="605" height="108" alt="image" src="https://github.com/user-attachments/assets/9b560300-c968-4042-b9f5-94e9a0bb6515" />

Favicons load automatically when URL is entered. Display favicons next to favorite entries to make them visually recognizable.

## 🏢 Deployment Scenarios

### Windows - Group Policy (On-Premises)

**For organizations using Active Directory and Group Policy:**

1. Copy the **JSON output** from the app
2. Open **Group Policy Management Console**
3. Navigate to: `Computer Configuration → Administrative Templates → Microsoft Edge → Favorites`
4. Enable **"Configure favorites"** policy
5. Paste the JSON configuration
6. Link the GPO to the appropriate Organizational Unit (OU)
7. Run `gpupdate /force` on client machines

**Documentation:**
- [Microsoft Edge - Enterprise Documentation](https://docs.microsoft.com/en-us/deployedge/)
- [Configure Microsoft Edge policies](https://docs.microsoft.com/en-us/deployedge/configure-microsoft-edge)

---

### Windows - Intune Settings Catalog

**For cloud-managed Windows devices:**
<img width="756" height="304" alt="image" src="https://github.com/user-attachments/assets/e662be35-d211-4dff-a56d-6d1b832fa46e" />

1. Copy the **JSON output** from the app
2. In **Microsoft Intune admin center**: `Devices → Configuration profiles`
3. Create profile:
   - Platform: **Windows 10 and later**
   - Profile type: **Settings catalog**
4. Add settings: Search for **"Microsoft Edge"** → **"Favorites"**
5. Enable **"Configure favorites"** and paste JSON
6. Assign to device groups
7. Devices will sync and apply the policy

**Documentation:**
- [Use the settings catalog](https://docs.microsoft.com/en-us/mem/intune/configuration/settings-catalog)
- [Microsoft Edge policies](https://docs.microsoft.com/en-us/deployedge/microsoft-edge-policies)

---

### Any Platform - Edge management service (Cloud Policy)

**For targeting a specific audience instead of a whole device — Windows, macOS, iOS, and Android in one policy:**

1. Copy the **Cloud Policy (JSON)** output from the app
2. In the **Microsoft 365 Admin Center**: `Settings → Microsoft Edge`
3. Create a configuration policy:
   - Type: **Cloud** (not the Intune type — that one is Windows-only)
   - Setting: **Managed favorites** → paste the JSON as the `ManagedFavorites` value
4. Assign the policy to an **Entra ID group** (e.g. a dynamic group for a naming pattern, or a static group for a team)
5. Set policy priority — if you're also assigning a base-set policy to a broader group, put the more specific policy at higher priority (`ManagedFavorites` does not merge across policies; the highest-priority assigned policy wins completely for a given profile)
6. Fully quit and restart Edge on the client (⌘Q, not just closing the window) — cloud policies also refresh automatically roughly every 90 minutes

**Why this instead of GPO/Intune for a partial rollout:** GPO and the Intune "Preference file" profile both land in the OS-level Managed Preferences domain, which every browser profile on the device reads identically — there's no way to target "just this profile" through either channel, regardless of how the config file itself was produced. The Edge management service's Cloud policy type is resolved through the Entra identity signed into the profile instead, which is what makes per-audience targeting possible without replacing the policy for every other user of that device.

**Precedence gotcha:** if the same device also receives `ManagedFavorites` from a GPO or an Intune device profile, that value wins over the Cloud policy — check `edge://policy` on the client to see which source is actually active before assuming the Cloud policy isn't working.

**Documentation:**
- [ManagedFavorites policy reference](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/managedfavorites) (see "Per Profile: Yes")
- [Get started with configuration policies — Microsoft Edge management service](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-management-service)

---

### macOS - Intune Preference File

**For cloud-managed macOS devices:**

1. **Export the Plist** from the app (⌘S)
2. In **Microsoft Intune admin center**: `Devices → Configuration profiles`
3. Create profile:
   - Platform: **macOS**
   - Profile type: **Templates → Preference file**
4. Upload the `.plist` file
5. Set preference domain: **`com.microsoft.Edge`**
6. Assign to device groups
7. Devices will sync and apply the configuration

**Documentation:**
- [Add a property list file to macOS devices](https://docs.microsoft.com/en-us/mem/intune/configuration/preference-file-settings-macos)
- [Deploy Microsoft Edge for macOS](https://docs.microsoft.com/en-us/deployedge/deploy-edge-mac-intune)

---

## 📝 Configuration Format Examples

### JSON (Windows)

```json
{
  "managedFavs": [
    {
      "toplevel_name": "Company",
      "name": "Intranet",
      "url": "https://intranet.company.com"
    },
    {
      "toplevel_name": "Company",
      "name": "Support Portal",
      "url": "https://support.company.com"
    }
  ]
}
```

### Plist (macOS)

The app generates a complete macOS Configuration Profile with:
- `ManagedFavorites` array containing your favorites
- Proper payload structure for Intune deployment
- Unique UUIDs for identification

## 🔧 Troubleshooting

### Favorites Don't Appear in Edge

**Windows (GPO):**
- Run `gpupdate /force` to apply policies immediately
- Check policy status: `gpresult /r`
- Verify Edge is managed: `edge://policy`

**Windows (Intune):**
- Wait for device sync (can take up to 8 hours, or force sync)
- Check policy status in Intune portal
- Verify Edge is up to date

**macOS (Intune):**
- Force device sync from Company Portal
- Check profile installation: System Settings → Profiles
- Verify Edge is installed and up to date

**Cloud Policy (Edge management service):**
- Check `edge://policy` on the client — it shows both the effective value and its source (Cloud vs. Platform)
- If the source shown is Platform, a GPO or Intune device profile is winning; that always takes precedence over a Cloud policy
- Confirm the signed-in profile's account is actually a member of the assigned Entra ID group
- Fully quit Edge (⌘Q) and reopen — cloud policies apply on restart, not live

### Invalid Configuration Errors

- ✅ Ensure all URLs start with `https://` or `http://`
- ✅ Check for special characters in names
- ✅ Verify JSON/Plist is properly formatted (app does this automatically)
- ✅ Ensure toplevel name doesn't contain spaces or special characters

### App Issues

- ✅ **Favorites not saved**: Check file permissions in `~/Library/Application Support/`
- ✅ **Export fails**: Verify write permissions for target directory
- ✅ **App won't start**: Ensure macOS 15+ and try rebuilding

## 🔍 Debugging & Verification

### Verify Favicon Provider

You can verify which favicon provider (Google or DuckDuckGo) the app is using in real-time:

```bash
# Live stream of favicon loading logs
log stream --predicate 'subsystem == "ManagedFavsGenerator" AND category == "Favicons"' --level info --style compact
```

**Example output:**
```
Loading favicon for 'github.com' using Google provider: https://www.google.com/s2/favicons?domain=github.com&sz=32
Loading favicon for 'microsoft.com' using DuckDuckGo provider: https://icons.duckduckgo.com/ip3/microsoft.com.ico
```

**To change the provider:**
1. Open Settings (⌘,)
2. Navigate to **Appearance** section
3. Select your preferred **Favicon Provider**:
   - **Google**: More reliable, comprehensive coverage
   - **DuckDuckGo**: Privacy-focused, no tracking

Changes take effect immediately without restart.

## 🛠️ Technical Details

For developers and technical documentation, see **[AGENTS.md](../AGENTS.md)** - Development guidelines, architecture, and best practices.

## 📚 Additional Resources

### Microsoft Edge Management
- [Microsoft Edge Enterprise landing page](https://www.microsoft.com/edge/business)
- [Microsoft Edge for Business](https://docs.microsoft.com/en-us/deployedge/)
- [Microsoft Edge Policy documentation](https://docs.microsoft.com/en-us/deployedge/microsoft-edge-policies)
- [Microsoft Edge - managed Favorites](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/managedfavorites)

### Microsoft Intune
- [Microsoft Intune documentation](https://docs.microsoft.com/en-us/mem/intune/)
- [Manage Microsoft Edge with Intune](https://docs.microsoft.com/en-us/mem/intune/apps/manage-microsoft-edge)

### Group Policy
- [Group Policy Overview](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831791(v=ws.11))
- [Administrative Templates for Microsoft Edge](https://www.microsoft.com/en-us/edge/business/download)

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 💬 Support

- **App Issues**: Open an issue in this repository
- **Edge Policy Questions**: Check Microsoft Edge documentation
- **Intune/GPO Questions**: Consult Microsoft documentation or your IT team

---

**Made with ❤️ for IT Administrators**
