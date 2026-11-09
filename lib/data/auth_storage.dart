import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/akun.dart';

/// Membatasi persistensi akun, sesi, onboarding, dan kunci percobaan masuk.
class AuthStorage {
  AuthStorage(this._preferences);

  final SharedPreferences _preferences;
  static const _accountsKey = 'pomodoro_local_accounts_v1';
  static const _sessionKey = 'pomodoro_local_session_v1';
  static const _onboardingKey = 'pomodoro_onboarding_done_v1';
  static const _attemptsKey = 'pomodoro_login_attempts_v1';

  /// Membaca akun valid; entri rusak dilewati tanpa menghentikan aplikasi.
  List<Akun> loadAccounts() {
    final raw = _preferences.getString(_accountsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final result = <Akun>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final account = Akun.fromMap(item);
          if (account != null) result.add(account);
        }
      }
      return result;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  /// Menyimpan seluruh akun lokal dalam satu dokumen JSON.
  Future<void> saveAccounts(List<Akun> accounts) async {
    final saved = await _preferences.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toMap()).toList()),
    );
    if (!saved) throw StateError('Penyimpanan akun menolak perubahan.');
  }

  /// Mengembalikan id sesi yang hanya disimpan bila pengguna memilih ingat saya.
  String? loadSessionId() => _preferences.getString(_sessionKey);

  /// Menyimpan atau menghapus id sesi persisten.
  Future<void> saveSessionId(String? id) async {
    if (id == null) {
      await _preferences.remove(_sessionKey);
    } else {
      final saved = await _preferences.setString(_sessionKey, id);
      if (!saved) throw StateError('Penyimpanan sesi menolak perubahan.');
    }
  }

  /// Membaca status onboarding yang hanya ditampilkan pada penggunaan pertama.
  bool get onboardingDone => _preferences.getBool(_onboardingKey) ?? false;

  /// Menandai onboarding telah selesai.
  Future<void> completeOnboarding() async {
    final saved = await _preferences.setBool(_onboardingKey, true);
    if (!saved) throw StateError('Penyimpanan onboarding menolak perubahan.');
  }

  /// Memuat data percobaan gagal untuk satu alamat email.
  Map<String, dynamic> loadAttempts() {
    final raw = _preferences.getString(_attemptsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  /// Menyimpan waktu kunci sebagai timestamp, bukan penghitung mundur.
  Future<void> saveAttempts(Map<String, dynamic> attempts) async {
    final saved = await _preferences.setString(
      _attemptsKey,
      jsonEncode(attempts),
    );
    if (!saved) throw StateError('Penyimpanan percobaan masuk gagal.');
  }

  /// Menghapus kunci timer milik akun tanpa menyentuh akun lain.
  Future<void> deleteAccountData(String accountId) async {
    final prefix = 'pomodoro_${accountId}_';
    for (final key in _preferences.getKeys()) {
      if (key.startsWith(prefix)) await _preferences.remove(key);
    }
  }
}
