# Google Drive Backup Design

**Date:** 2026-04-21
**Platform:** Android phone
**App Type:** Local-first Flutter + Dart app with optional Google Drive backup
**Primary Users:** Store owner and cashier protecting Espasyo sales and seller records

## 1. Goal

Add a safe backup system that keeps Espasyo local-first while giving the store owner an off-device backup when internet is available.

The backup system must:
- create local backups first
- upload backups to Google Drive only when enabled and online
- keep dated backup versions instead of overwriting one file
- avoid broad Google Drive access
- allow future restore from local or cloud backups
- never block daily cashier workflows when internet or Google sign-in is unavailable

## 2. Product Principles

- **Local-first remains required:** The live app database is SQLite on-device. Google Drive is backup storage, not the live database.
- **Offline-safe:** Creating sales, assigning boxes, cashing out, and deductions continue without internet.
- **Backup before upload:** Every cloud upload starts from a completed local backup file.
- **Versioned history:** Daily backups are stored by date/time so an accidental deletion does not overwrite the last good copy.
- **Least privilege:** Use Google Drive `appDataFolder` with the `drive.appdata` scope, not full Drive access.
- **Human-controlled restore:** Restoring data is manual and confirmed. The app does not auto-restore or auto-merge data.

## 3. User Experience

### 3.1 Backup Settings

Add a backup area in settings or a future admin screen.

Content:
- Google Drive backup status
- last local backup time
- last successful cloud upload time
- pending upload count
- `Connect Google Drive`
- `Back Up Now`
- `View Backups`

States:
- `Local backups active`
- `Google Drive not connected`
- `Google Drive connected`
- `Pending upload`
- `Last upload failed`

### 3.2 First Google Drive Connection

Flow:
1. cashier opens backup settings
2. taps `Connect Google Drive`
3. signs in with Google
4. grants the limited app-data Drive permission
5. app stores enough auth state to upload future backups
6. app immediately tries to upload any pending local backups

The UI should explain that Espasyo only stores hidden app backups in the connected Google account and does not browse personal Drive files.

### 3.3 Manual Backup

`Back Up Now` should:
1. create a local database backup immediately
2. mark it as `local_ready`, shown to users as pending upload
3. upload it to Drive if online and connected
4. show success or a friendly pending/offline message

### 3.4 Restore

Restore should be a separate confirmed flow.

Restore behavior:
- show local backups first
- show Drive backups when Google Drive is connected and online
- require confirmation before replacing current local data
- create a safety backup of the current database before restoring another backup
- restart or reload app state after restore

Restore is not required in the first implementation pass if backup/upload is already large, but the backup format must support it.

## 4. Backup Timing

Target schedule:
- create one automatic backup per Philippine calendar day
- preferred time is after `12:00 AM Asia/Manila`

Android reality:
- exact midnight is not guaranteed because Android can delay background work for battery reasons
- the app should create the missed daily backup on next app open if the day changed and no backup exists yet
- background work can also try to run periodic backup/upload, but app-open catch-up is the reliability guarantee

Daily rule:
- if the latest successful local backup date is before today in Philippine time, create a new backup
- if backup creation fails, do not modify the live database and show backup health as failed/pending

## 5. Storage Model

### 5.1 Local Files

Store backups in the app documents directory:

```text
backups/
  espasyo-backup-2026-04-21-0005.db
  espasyo-backup-2026-04-22-0003.db
```

Rules:
- use timestamped filenames
- never overwrite an existing backup
- keep a local retention window, recommended `14` or `30` daily backups
- failed or partial backups must not appear as restorable backups

### 5.2 Backup Metadata Table

Add a table such as `backup_records`.

Fields:
- `id`
- `fileName`
- `localPath`
- `createdAt`
- `backupDate`
- `sizeBytes`
- `sha256`
- `status`
- `driveFileId`
- `uploadedAt`
- `lastError`

Statuses:
- `local_ready`
- `uploading`
- `uploaded`
- `failed`

`local_ready` means the backup exists locally and is waiting for cloud upload.

### 5.3 Google Drive Files

Use Google Drive `appDataFolder`.

Drive filename format:

```text
espasyo-backup-2026-04-21-0005.db
```

Rules:
- upload each backup as a separate file
- do not use a single `latest.db` file
- store checksum metadata if practical
- keep Drive retention aligned with local retention or slightly longer
- never delete cloud backups just because local app data was deleted

## 6. Data Flow

### 6.1 Automatic Local Backup

1. app opens or background worker runs
2. backup service checks Philippine date
3. if today has no local backup, copy the SQLite database into a temporary file
4. verify the temporary file exists and has non-zero size
5. compute checksum
6. move temp file into `backups/`
7. insert `backup_records` row as `local_ready`
8. queue upload if Google Drive is connected

### 6.2 Cloud Upload

1. upload service checks Google Drive auth state
2. upload service checks connectivity
3. query `backup_records` where status is `local_ready` or `failed`
4. mark one backup `uploading`
5. upload file to Drive `appDataFolder`
6. store returned `driveFileId`
7. mark backup `uploaded`
8. if upload fails, mark `failed` with `lastError`

Upload failure must not delete the local backup.

### 6.3 App Startup Catch-Up

On app launch after splash:
- run a lightweight backup health check
- create today's backup if missing
- try pending uploads if online and connected
- avoid blocking the dashboard while this runs

The dashboard or settings can show backup status, but backup work should run in the background from the user's perspective.

## 7. Google Drive Integration

Use:
- Google sign-in for account connection
- Drive API file upload
- `drive.appdata` scope

Recommended Flutter packages:
- `google_sign_in`
- `googleapis`
- `extension_google_sign_in_as_googleapis_auth`
- `connectivity_plus`
- optionally `workmanager` for Android background attempts

OAuth scope:

```text
https://www.googleapis.com/auth/drive.appdata
```

Drive upload target:

```text
parents: ['appDataFolder']
```

## 8. Safety Rules

- Cloud backup is optional.
- The live SQLite database remains on-device.
- Backups are append-only by date/time.
- A backup upload must never overwrite a previous dated backup.
- Uploading a bad current database must not erase older good backups.
- If the seller/cashier deletes app data or uninstalls the app, local backups may be lost, but Drive backups can still be available after reconnecting the same Google account.
- Restore must create a pre-restore safety backup first.
- Restore must require explicit confirmation.
- The app must not sync partial records between devices in V1.

## 9. Error Handling

Handle:
- no internet
- Google account disconnected
- Drive permission revoked
- upload quota or API failure
- missing local backup file
- corrupted or zero-byte backup file
- restore file checksum mismatch

User-facing messages should be simple:
- `Backup saved locally. Google Drive will upload when online.`
- `Google Drive needs to be reconnected.`
- `Backup upload failed. Your local backup is still safe.`
- `Restore failed. Your current data was not changed.`

## 10. Testing Strategy

### 10.1 Unit and Database Tests

Test:
- backup metadata creation
- one backup per Philippine date
- pending upload status transitions
- failed upload keeps local file
- retention cleanup preserves latest backups
- restore creates a pre-restore safety backup

### 10.2 Service Tests

Use fakes for:
- clock/timezone
- file system
- Drive client
- connectivity

Test:
- offline creates local backup only
- online uploads pending backups
- upload failure records `lastError`
- retry uploads previously failed backups
- `appDataFolder` parent is used

### 10.3 Widget Tests

Test:
- backup settings show disconnected state
- connected state shows last upload
- pending upload state is visible
- manual backup button shows local success when offline
- restore flow requires confirmation

## 11. V1 Scope

Recommended first implementation:
- local daily backup metadata and files
- Google Drive connection
- upload pending local backups to Drive
- backup status UI
- manual `Back Up Now`
- app-open catch-up backup/upload

Can be deferred:
- full restore UI
- Android background worker
- passphrase encryption
- multi-device sync
- conflict merging

## 12. Success Criteria

The feature is successful if:
- Espasyo still works fully offline
- a daily local backup is created after midnight or next app open
- Google Drive upload happens automatically when online and connected
- offline backups remain pending and upload later
- cloud backups are versioned by date/time
- the app uses limited Drive app-data permission only
- a failed cloud upload never harms the local database or local backup
- users can understand whether their latest backup is local-only, pending, or uploaded
