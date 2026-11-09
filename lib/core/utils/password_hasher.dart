import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const int _jumlahIterasiHash = 10000;

/// Menghasilkan salt acak yang berbeda untuk setiap rahasia.
String buatSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64UrlEncode(bytes);
}

/*
 * Pengulangan SHA-256 memperlambat tebakan sandi lokal. Ini bukan pengganti
 * autentikasi server atau penyimpanan rahasia yang dilindungi sistem operasi.
 */
/// Menghash kata sandi bersama salt dengan putaran berulang.
String hashRahasia(String rahasia, String salt) {
  List<int> hasil = utf8.encode('$salt:$rahasia');
  var putaran = 0;
  while (putaran < _jumlahIterasiHash) {
    hasil = sha256.convert(hasil).bytes;
    putaran++;
  }
  return base64UrlEncode(hasil);
}

/// Membandingkan hash tanpa berhenti pada karakter pertama yang berbeda.
bool cocokHash(String pertama, String kedua) {
  var perbedaan = pertama.length ^ kedua.length;
  final panjang = max(pertama.length, kedua.length);
  for (var indeks = 0; indeks < panjang; indeks++) {
    final a = indeks < pertama.length ? pertama.codeUnitAt(indeks) : 0;
    final b = indeks < kedua.length ? kedua.codeUnitAt(indeks) : 0;
    perbedaan |= a ^ b;
  }
  return perbedaan == 0;
}

/// Menormalisasi jawaban agar variasi kapital dan spasi tepi tidak mengunci akun.
String normalisasiJawaban(String jawaban) => jawaban.trim().toLowerCase();
