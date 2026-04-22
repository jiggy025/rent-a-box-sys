# Google Drive Backup Setup

If Google Drive sign-in shows `PlatformException(sign_in_failed, ... 10 ...)`,
Android OAuth is not configured for the installed APK signing certificate.

For the current local release APK, create an Android OAuth client in Google
Cloud with:

- Package name: `com.rentabox.ledger.rent_a_box_sys`
- SHA-1: `14:F2:E4:47:8E:B8:E9:BC:69:2F:83:50:42:B0:7D:2C:26:F0:6C:D4`

Also enable the Google Drive API for the same Google Cloud project. The app
requests only the Drive app-data scope:

`https://www.googleapis.com/auth/drive.appdata`

If the app is later signed with a real release keystore, add that release
certificate SHA-1 as another Android OAuth client.
