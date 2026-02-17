# Nextcloud User Management

A native iOS/iPadOS app for managing Nextcloud users and groups.

## Features

- ✅ View all users on your Nextcloud server
- ✅ View all groups on your Nextcloud server
- ✅ Enable/disable user accounts
- ✅ Add users to groups
- ✅ Remove users from groups
- ✅ View user details (email, quota, last login, etc.)
- ✅ View group members
- ✅ Search users and groups
- ✅ Modern SwiftUI interface

## Setup

1. Open the app and tap the settings icon (gear) in the top right
2. Enter your Nextcloud server details:
   - **Server URL**: Your Nextcloud server URL (e.g., `https://cloud.example.com`)
   - **Username**: Your Nextcloud username
   - **Password**: Your password or app password

> **Security Tip**: For better security, create an app password in your Nextcloud settings (Settings → Security → Devices & sessions → Create new app password) and use that instead of your main password.

3. Tap "Save" and the app will automatically load your users and groups

## Usage

### Viewing Users

- The **Users** tab shows all users on your server
- Tap any user to see detailed information
- Use the search bar to find specific users
- User rows show:
  - Display name and user ID
  - Email address
  - Enabled/disabled status
  - Number of groups
  - Storage quota usage (if available)

### Managing Users

From a user's detail page, you can:

- **Enable/Disable**: Toggle the user's account status
- **Manage Groups**: 
  - See all groups the user belongs to
  - Remove the user from a group by tapping the red minus icon
  - Add the user to a group by tapping "Add to Group"

### Viewing Groups

- The **Groups** tab shows all groups on your server
- Tap any group to see its members
- Use the search bar to find specific groups
- Group rows show the number of members

### Refreshing Data

- Tap the refresh icon (circular arrow) in the top right to reload users and groups
- Data is automatically loaded when the app starts

## Requirements

- iOS 17.0+ / ~~iPadOS 17.0+~~ (iPhone-only for v1.0)
- Nextcloud server with OCS API enabled (Nextcloud 15+)
- Admin or group admin permissions on the Nextcloud server

**Note:** This app is currently iPhone-only. iPad support will be added in a future version.

## Architecture

The app is built using modern Swift and SwiftUI:

- **Models**: `NextcloudUser` and `NextcloudGroup` represent the data
- **Services**: `NextcloudAPIService` handles all API communication using async/await
- **ViewModels**: `UserManagementViewModel` manages state and business logic
- **Views**: SwiftUI views for a native, responsive interface

## API Endpoints Used

This app uses the Nextcloud OCS API (v1.php):

- `GET /ocs/v1.php/cloud/users` - List all users
- `GET /ocs/v1.php/cloud/users/{userid}` - Get user details
- `PUT /ocs/v1.php/cloud/users/{userid}/enable` - Enable a user
- `PUT /ocs/v1.php/cloud/users/{userid}/disable` - Disable a user
- `POST /ocs/v1.php/cloud/users/{userid}/groups` - Add user to group
- `DELETE /ocs/v1.php/cloud/users/{userid}/groups` - Remove user from group
- `GET /ocs/v1.php/cloud/groups` - List all groups

## App Store Submission

**✅ This app is ready for the App Store!**

All production features are implemented:
- ✅ Secure Keychain storage for passwords
- ✅ Face ID / Touch ID authentication
- ✅ Lock screen when backgrounding
- ✅ Complete privacy policy
- ✅ Production-ready code

**Ready to submit?** Start here:
👉 **[IPHONE_ONLY_SUMMARY.md](IPHONE_ONLY_SUMMARY.md)** - ⚡ NEW: iPhone-only configuration!
👉 **[SUBMISSION_SUMMARY.md](SUBMISSION_SUMMARY.md)** - Complete submission overview

Quick guides:
- [iPhone-Only Setup](IPHONE_ONLY_SETUP.md) - Configure for iPhone-only (saves 2-3 hours!)
- [Quick Submission Guide](QUICK_SUBMISSION_GUIDE.md) - Step-by-step action plan
- [App Icon Guide](APP_ICON_GUIDE.md) - Create your app icon
- [Test Server Setup](TEST_CREDENTIALS_GUIDE.md) - Set up demo for Apple reviewers
- [Privacy Policy Hosting](GITHUB_PAGES_SETUP.md) - Host on GitHub Pages

## Security Notes

**Production Security Features:**

✅ **Keychain Storage** - Passwords stored in iOS Keychain (hardware-encrypted)
✅ **Biometric Authentication** - Optional Face ID/Touch ID to unlock app
✅ **Secure Communication** - HTTPS-only connections to Nextcloud
✅ **No Tracking** - Zero analytics or telemetry
✅ **Local Storage** - All data stays on your device

## Future Enhancements

Potential features to add:

- [ ] Create new users
- [ ] Delete users
- [ ] Edit user details (email, display name, etc.)
- [ ] Create and delete groups
- [ ] Set user quotas
- [ ] Send welcome emails
- [ ] Bulk operations
- [ ] Audit log viewing
- [ ] macOS support using Mac Catalyst
- [ ] Offline mode with local caching

## License

This is a demonstration project. Modify as needed for your use case.
