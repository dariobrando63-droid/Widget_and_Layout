import 'package:flutter/foundation.dart';

import '../../core/utils/password_hasher.dart';
import '../../core/utils/validators.dart';
import '../../data/auth_storage.dart';
import '../../data/models/akun.dart';

const List<String> pertanyaanKeamanan = [
  'Apa nama hewan peliharaan pertamamu?',
  'Di kota mana kamu lahir?',
  'Apa makanan favoritmu saat kecil?',
  'Siapa nama guru favoritmu?',
];

const _guestSessionId = 'guest';

/// Mengatur akun lokal dan state sesi tanpa layanan jaringan.
class AuthController extends ChangeNotifier {
  AuthController({required AuthStorage storage, DateTime Function()? clock})
    : this._internal(storage, clock);

  AuthController._internal(this._storage, DateTime Function()? clock)
    : _clock = clock ?? DateTime.now;

  final AuthStorage _storage;
  final DateTime Function() _clock;
  List<Akun> _accounts = [];
  String? _activeId;
  bool _isLoading = true;
  bool _onboardingDone = false;
  Object? lastError;

  /// Menunjukkan proses pemulihan state akun lokal.
  bool get isLoading => _isLoading;

  /// Menunjukkan onboarding sudah pernah diselesaikan.
  bool get onboardingDone => _onboardingDone;

  /// Mengembalikan ID sesi aktif, termasuk sesi tamu.
  String? get currentSessionId => _activeId;

  /// Menunjukkan pengguna sedang memakai aplikasi tanpa akun.
  bool get isGuest => _activeId == _guestSessionId;

  /// Mengembalikan akun yang sedang aktif, bila ada.
  Akun? get currentAccount {
    for (final account in _accounts) {
      if (account.id == _activeId) return account;
    }
    return null;
  }

  /// Mengembalikan pertanyaan pemulihan untuk email lokal yang cocok.
  String? securityQuestionFor(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.email == normalizedEmail) return account.pertanyaanKeamanan;
    }
    return null;
  }

  /// Memulihkan akun dan sesi yang dipilih untuk diingat.
  Future<void> initialize() async {
    _accounts = _storage.loadAccounts();
    _onboardingDone = _storage.onboardingDone;
    final sessionId = _storage.loadSessionId();
    if (sessionId == _guestSessionId ||
        (sessionId != null &&
            _accounts.any((account) => account.id == sessionId))) {
      _activeId = sessionId;
    } else if (sessionId != null) {
      await _storage.saveSessionId(null);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Menyimpan pilihan onboarding pertama kali.
  Future<void> completeOnboarding() async {
    await _storage.completeOnboarding();
    _onboardingDone = true;
    notifyListeners();
  }

  /// Membuka sesi tamu dan menyimpannya agar data timer tetap dapat dipakai.
  Future<void> enterGuest() async {
    await _storage.saveSessionId(_guestSessionId);
    _activeId = _guestSessionId;
    notifyListeners();
  }

  /// Membuat akun baru; hasil null berarti pendaftaran berhasil.
  Future<String?> register({
    required String nama,
    required String email,
    required String kataSandi,
    required String pertanyaan,
    required String jawaban,
  }) async {
    final nameError = validasiNama(nama);
    if (nameError != null) return nameError;
    final emailError = validasiEmail(email);
    if (emailError != null) return emailError;
    final passwordError = validasiKataSandi(kataSandi);
    if (passwordError != null) return passwordError;
    final answerError = validasiJawaban(jawaban);
    if (answerError != null) return answerError;
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.any((account) => account.email == normalizedEmail)) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (!pertanyaanKeamanan.contains(pertanyaan)) {
      return 'Pilih pertanyaan keamanan yang tersedia.';
    }
    final passwordSalt = buatSalt();
    final answerSalt = buatSalt();
    final account = Akun(
      id: 'u${_clock().microsecondsSinceEpoch}',
      nama: nama.trim(),
      email: normalizedEmail,
      saltSandi: passwordSalt,
      hashSandi: hashRahasia(kataSandi, passwordSalt),
      pertanyaanKeamanan: pertanyaan,
      saltJawaban: answerSalt,
      hashJawaban: hashRahasia(normalisasiJawaban(jawaban), answerSalt),
      dibuatPada: _clock(),
    );
    _accounts = [..._accounts, account];
    await _persistAccounts();
    notifyListeners();
    return null;
  }

  /// Masuk; pesan kesalahan sandi/email sengaja dibuat sama.
  Future<String?> login({
    required String email,
    required String kataSandi,
    required bool ingatSaya,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final attempts = _storage.loadAttempts();
    final info = attempts[normalizedEmail];
    if (info is Map<String, dynamic>) {
      final lockedUntil = info['lockedUntil'];
      if (lockedUntil is int && lockedUntil > _clock().millisecondsSinceEpoch) {
        final remaining =
            ((lockedUntil - _clock().millisecondsSinceEpoch) / 1000).ceil();
        return 'Terlalu banyak percobaan. Coba lagi dalam $remaining detik.';
      }
    }
    Akun? account;
    for (final item in _accounts) {
      if (item.email == normalizedEmail) {
        account = item;
        break;
      }
    }
    if (account != null &&
        cocokHash(
          hashRahasia(kataSandi, account.saltSandi),
          account.hashSandi,
        )) {
      attempts.remove(normalizedEmail);
      await _storage.saveAttempts(attempts);
      await _storage.saveSessionId(ingatSaya ? account.id : null);
      _activeId = account.id;
      notifyListeners();
      return null;
    }
    final previous = info is Map<String, dynamic> ? info['count'] : 0;
    var count = previous is int && previous >= 0 ? previous : 0;
    count++;
    attempts[normalizedEmail] = {
      'count': count >= 5 ? 0 : count,
      'lockedUntil': count >= 5
          ? _clock().add(const Duration(seconds: 30)).millisecondsSinceEpoch
          : 0,
    };
    await _storage.saveAttempts(attempts);
    notifyListeners();
    return 'Email atau kata sandi salah.';
  }

  /// Mengakhiri sesi dalam memori dan penyimpanan tanpa menghapus timer akun.
  Future<void> logout() async {
    _activeId = null;
    await _storage.saveSessionId(null);
    notifyListeners();
  }

  /// Memastikan jawaban keamanan sebelum mengubah kata sandi.
  Future<String?> resetPassword({
    required String email,
    required String jawaban,
    required String kataSandiBaru,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final accountIndex = _accounts.indexWhere(
      (account) => account.email == normalizedEmail,
    );
    if (accountIndex < 0) return 'Email atau jawaban keamanan salah.';
    final account = _accounts[accountIndex];
    final attempts = _storage.loadAttempts();
    final info = attempts[normalizedEmail];
    if (info is Map<String, dynamic>) {
      final lockedUntil = info['lockedUntil'];
      if (lockedUntil is int && lockedUntil > _clock().millisecondsSinceEpoch) {
        final remaining =
            ((lockedUntil - _clock().millisecondsSinceEpoch) / 1000).ceil();
        return 'Terlalu banyak percobaan. Coba lagi dalam $remaining detik.';
      }
    }
    if (!cocokHash(
      hashRahasia(normalisasiJawaban(jawaban), account.saltJawaban),
      account.hashJawaban,
    )) {
      final previous = info is Map<String, dynamic> ? info['count'] : 0;
      var count = previous is int && previous >= 0 ? previous : 0;
      count++;
      attempts[normalizedEmail] = {
        'count': count >= 5 ? 0 : count,
        'lockedUntil': count >= 5
            ? _clock().add(const Duration(seconds: 30)).millisecondsSinceEpoch
            : 0,
      };
      await _storage.saveAttempts(attempts);
      return 'Email atau jawaban keamanan salah.';
    }
    final passwordError = validasiKataSandi(kataSandiBaru);
    if (passwordError != null) return passwordError;
    final salt = buatSalt();
    _accounts[accountIndex] = Akun(
      id: account.id,
      nama: account.nama,
      email: account.email,
      saltSandi: salt,
      hashSandi: hashRahasia(kataSandiBaru, salt),
      pertanyaanKeamanan: account.pertanyaanKeamanan,
      saltJawaban: account.saltJawaban,
      hashJawaban: account.hashJawaban,
      dibuatPada: account.dibuatPada,
    );
    attempts.remove(normalizedEmail);
    await _storage.saveAttempts(attempts);
    await _persistAccounts();
    notifyListeners();
    return null;
  }

  /// Mengubah nama akun setelah validasi.
  Future<String?> updateName(String nama) async {
    final error = validasiNama(nama);
    if (error != null) return error;
    final account = currentAccount;
    if (account == null) return 'Sesi akun tidak tersedia.';
    _replaceAccount(
      account,
      Akun(
        id: account.id,
        nama: nama.trim(),
        email: account.email,
        saltSandi: account.saltSandi,
        hashSandi: account.hashSandi,
        pertanyaanKeamanan: account.pertanyaanKeamanan,
        saltJawaban: account.saltJawaban,
        hashJawaban: account.hashJawaban,
        dibuatPada: account.dibuatPada,
      ),
    );
    await _persistAccounts();
    notifyListeners();
    return null;
  }

  /// Mengubah sandi hanya setelah sandi lama terbukti benar.
  Future<String?> updatePassword({
    required String kataSandiLama,
    required String kataSandiBaru,
  }) async {
    final account = currentAccount;
    if (account == null) return 'Sesi akun tidak tersedia.';
    if (!cocokHash(
      hashRahasia(kataSandiLama, account.saltSandi),
      account.hashSandi,
    )) {
      return 'Kata sandi lama tidak sesuai.';
    }
    if (kataSandiLama == kataSandiBaru) {
      return 'Kata sandi baru harus berbeda dari kata sandi lama.';
    }
    final error = validasiKataSandi(kataSandiBaru);
    if (error != null) return error;
    final salt = buatSalt();
    _replaceAccount(
      account,
      Akun(
        id: account.id,
        nama: account.nama,
        email: account.email,
        saltSandi: salt,
        hashSandi: hashRahasia(kataSandiBaru, salt),
        pertanyaanKeamanan: account.pertanyaanKeamanan,
        saltJawaban: account.saltJawaban,
        hashJawaban: account.hashJawaban,
        dibuatPada: account.dibuatPada,
      ),
    );
    await _persistAccounts();
    notifyListeners();
    return null;
  }

  /// Menghapus akun terpilih beserta seluruh penyimpanan timer per akun.
  Future<String?> deleteAccount(String kataSandi) async {
    final account = currentAccount;
    if (account == null) return 'Sesi akun tidak tersedia.';
    if (!cocokHash(
      hashRahasia(kataSandi, account.saltSandi),
      account.hashSandi,
    )) {
      return 'Kata sandi tidak sesuai.';
    }
    _accounts = _accounts.where((item) => item.id != account.id).toList();
    await _persistAccounts();
    _activeId = null;
    await _storage.saveSessionId(null);
    await _storage.deleteAccountData(account.id);
    notifyListeners();
    return null;
  }

  void _replaceAccount(Akun oldAccount, Akun newAccount) {
    final index = _accounts.indexOf(oldAccount);
    if (index >= 0) _accounts[index] = newAccount;
  }

  Future<void> _persistAccounts() async {
    try {
      await _storage.saveAccounts(_accounts);
      lastError = null;
    } catch (error) {
      lastError = error;
      _accounts = _storage.loadAccounts();
      if (_activeId != null &&
          !_accounts.any((account) => account.id == _activeId)) {
        _activeId = null;
      }
      rethrow;
    }
  }
}
