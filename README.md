# Managed Favs Generator

A native macOS app to generate Microsoft Edge Managed Favorites configuration files for enterprise deployment via Group Policy (GPO) and Microsoft Intune.

## 🎯 What Does It Do?

This app helps IT administrators create and manage Microsoft Edge favorites that can be deployed to users across an organization. It generates properly formatted configuration files for:

- **Windows devices** (via Group Policy or Intune)
- **macOS devices** (via Intune)

Instead of manually creating complex JSON or Plist files, you use a simple, intuitive interface to:
1. Add favorites (name + URL)
2. Generate configuration files automatically
3. Copy or export them for deployment

## ✨ Key Features

- 🎨 **Native macOS Design** - Modern, fluid interface with animations
- ⌨️ **Keyboard Shortcuts** - Fast workflow (⌘N to add, ⌘S to export, ⌘⇧C to copy)
- 💾 **Persistent Storage** - Your favorites are saved automatically
- 📋 **Multiple Formats** - Generates both JSON (Windows) and Plist (macOS)
- 🚀 **Export Ready** - One-click export or copy to clipboard
- ⚙️ **Configurable** - Customize toplevel names for your organization

## 📋 Requirements

- **macOS 15.0 (Sequoia)** or later
- **Xcode 16** or later (for building from source)

## 🚀 Quick Start

### Build & Run

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

## 📖 How To Use

### 1. **Add Favorites**

Press **⌘N** or click the **Add Favorite** button in the toolbar:
- **Name**: Display name (e.g., "Company Portal")
- **URL**: Full URL including `https://`

### 2. **Generate Outputs**

The app automatically generates two formats as you add favorites:

#### **JSON Format** (for Windows/GPO)
- Used for on-premises Group Policy
- Used for Intune Settings Catalog (Windows)
- Press **⌘⇧C** to copy to clipboard

#### **Plist Format** (for macOS/Intune)
- Used for Intune Device Configuration Profiles
- Press **⌘S** to export as file
- Or click Copy to copy to clipboard

### 3. **Configure Toplevel Name**

The toplevel name (default: `managedFavs`) is the root key in your configuration. Change it in Settings (⌘,) if needed.

### 4. **Deploy to Your Organization**

See deployment guides below for Windows GPO, Intune Windows, or Intune macOS.

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

### Invalid Configuration Errors

- ✅ Ensure all URLs start with `https://` or `http://`
- ✅ Check for special characters in names
- ✅ Verify JSON/Plist is properly formatted (app does this automatically)
- ✅ Ensure toplevel name doesn't contain spaces or special characters

### App Issues

- ✅ **Favorites not saved**: Check file permissions in `~/Library/Application Support/`
- ✅ **Export fails**: Verify write permissions for target directory
- ✅ **App won't start**: Ensure macOS 15+ and try rebuilding

## 🛠️ Technical Details

For developers and technical documentation, see **[AGENTS.md](../AGENTS.md)** - Development guidelines, architecture, and best practices.

## 📚 Additional Resources

### Microsoft Edge Management
- [Microsoft Edge Enterprise landing page](https://www.microsoft.com/edge/business)
- [Microsoft Edge for Business](https://docs.microsoft.com/en-us/deployedge/)
- [Microsoft Edge Policy documentation](https://docs.microsoft.com/en-us/deployedge/microsoft-edge-policies)

### Microsoft Intune
- [Microsoft Intune documentation](https://docs.microsoft.com/en-us/mem/intune/)
- [Manage Microsoft Edge with Intune](https://docs.microsoft.com/en-us/mem/intune/apps/manage-microsoft-edge)

### Group Policy
- [Group Policy Overview](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831791(v=ws.11))
- [Administrative Templates for Microsoft Edge](https://www.microsoft.com/en-us/edge/business/download)

## 📄 License

[Add your license here]

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 💬 Support

- **App Issues**: Open an issue in this repository
- **Edge Policy Questions**: Check Microsoft Edge documentation
- **Intune/GPO Questions**: Consult Microsoft documentation or your IT team

---

**Made with ❤️ for IT Administrators**
