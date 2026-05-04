# Google Drive Backup Setup

If Google Drive sign-in shows `PlatformException(sign_in_failed, ... 10 ...)`,
Android OAuth is not configured for the installed APK signing certificate.

Create an Android OAuth client in Google Cloud with:

- Package name: `com.rentabox.ledger.rent_a_box_sys`
- SHA-1: the certificate fingerprint for the APK you are installing

Also enable the Google Drive API for the same Google Cloud project. The app
requests only the Drive app-data scope:

`https://www.googleapis.com/auth/drive.appdata`

For local debug builds, you can inspect the default debug SHA-1 with:

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

For production builds, use your own release keystore and add that release
certificate SHA-1 as a separate Android OAuth client. Do not commit keystores,
`key.properties`, client secrets, or local environment files to the repository.
