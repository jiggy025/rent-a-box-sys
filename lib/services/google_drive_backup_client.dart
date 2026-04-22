import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path/path.dart' as p;

import '../models/cloud_backup_file.dart';
import 'cloud_backup_client.dart';

class GoogleDriveBackupClient implements CloudBackupClient {
  GoogleDriveBackupClient({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]);

  final GoogleSignIn _googleSignIn;
  auth.AuthClient? _authClient;

  @override
  Future<CloudBackupAccount?> currentAccount() async {
    final account =
        _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently(suppressErrors: true);
    if (account == null) {
      return null;
    }
    return CloudBackupAccount(email: account.email);
  }

  @override
  Future<CloudBackupAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    return CloudBackupAccount(email: account.email);
  }

  @override
  Future<void> signOut() async {
    close();
    await _googleSignIn.signOut();
  }

  void close() {
    _authClient?.close();
    _authClient = null;
  }

  @override
  Future<String> uploadBackup({
    required File localFile,
    required String fileName,
    required String sha256,
  }) async {
    final driveApi = await _driveApi();
    final uploadFile = drive.File()
      ..name = fileName
      ..parents = const ['appDataFolder']
      ..appProperties = {'sha256': sha256};
    final media = drive.Media(localFile.openRead(), await localFile.length());
    final created = await driveApi.files.create(
      uploadFile,
      uploadMedia: media,
      $fields: 'id',
    );
    final id = created.id;
    if (id == null || id.isEmpty) {
      throw StateError('Google Drive did not return a file id.');
    }
    return id;
  }

  @override
  Future<List<CloudBackupFile>> listBackups() async {
    final driveApi = await _driveApi();
    final files = <drive.File>[];
    String? pageToken;
    do {
      final response = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'espasyo-backup-' and trashed = false",
        orderBy: 'createdTime desc',
        pageToken: pageToken,
        $fields: 'nextPageToken,files(id,name,createdTime,size,appProperties)',
      );
      files.addAll(response.files ?? const <drive.File>[]);
      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return files
        .where((file) => file.id != null && file.name != null)
        .map(_mapDriveFile)
        .toList(growable: false);
  }

  @override
  Future<File> downloadBackup({
    required CloudBackupFile file,
    required Directory destinationDirectory,
  }) async {
    final driveApi = await _driveApi();
    await destinationDirectory.create(recursive: true);
    final destinationFile = File(p.join(destinationDirectory.path, file.name));
    final media =
        await driveApi.files.get(
              file.id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    await media.stream.pipe(destinationFile.openWrite());
    return destinationFile;
  }

  Future<drive.DriveApi> _driveApi() async {
    final cachedClient = _authClient;
    if (cachedClient != null) {
      return drive.DriveApi(cachedClient);
    }

    final account =
        _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently(suppressErrors: true);
    if (account == null) {
      throw StateError('Google Drive is not connected.');
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Google Drive is not connected.');
    }
    _authClient = client;
    return drive.DriveApi(client);
  }

  CloudBackupFile _mapDriveFile(drive.File file) {
    final createdAt =
        file.createdTime?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final sizeBytes = int.tryParse(file.size ?? '');
    return CloudBackupFile(
      id: file.id!,
      name: file.name!,
      createdAt: createdAt,
      sizeBytes: sizeBytes,
      sha256: file.appProperties?['sha256'],
    );
  }
}
