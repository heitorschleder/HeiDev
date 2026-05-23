import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage_item.dart';

@injectable
class SecureStorage {
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock, synchronizable: true),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(SecureStorageItem item) => _storage.write(key: item.key, value: item.value);

  Future<String?> get(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clear() => _storage.deleteAll();
}
