/// Memeriksa nama yang akan ditampilkan di sapaan.
String? validasiNama(String? value) {
  final nama = value?.trim() ?? '';
  if (nama.length < 2 || nama.length > 40) {
    return 'Nama harus terdiri dari 2–40 karakter.';
  }
  return null;
}

/// Memeriksa format email sederhana untuk akun lokal.
String? validasiEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Masukkan alamat email yang valid.';
  }
  return null;
}

/// Memeriksa aturan minimum sandi tanpa menyimpan teks aslinya.
String? validasiKataSandi(String? value) {
  final sandi = value ?? '';
  if (sandi.trim().isEmpty) return 'Kata sandi wajib diisi.';
  if (sandi.length < 8 || sandi.length > 64) {
    return 'Kata sandi harus terdiri dari 8–64 karakter.';
  }
  if (!RegExp('[A-Za-z]').hasMatch(sandi) ||
      !RegExp('[0-9]').hasMatch(sandi)) {
    return 'Kata sandi harus berisi huruf dan angka.';
  }
  return null;
}

/// Memastikan konfirmasi sama persis dengan kata sandi.
String? validasiKonfirmasi(String? value, String kataSandi) =>
    value == kataSandi ? null : 'Konfirmasi kata sandi tidak cocok.';

/// Memeriksa jawaban keamanan setelah spasi tepi diabaikan.
String? validasiJawaban(String? value) =>
    (value?.trim().length ?? 0) < 3
    ? 'Jawaban minimal 3 karakter.'
    : null;

/// Menghitung kriteria kekuatan yang dipenuhi, dari nol sampai empat.
int hitungKekuatanKataSandi(String sandi) {
  var skor = 0;
  if (sandi.length >= 8) skor++;
  if (RegExp('[a-z]').hasMatch(sandi)) skor++;
  if (RegExp('[A-Z]').hasMatch(sandi)) skor++;
  if (RegExp('[0-9]').hasMatch(sandi)) skor++;
  const simbol = r'!@#$%^&*()-_=+[]{};:,.?/|~';
  for (final karakter in sandi.split('')) {
    if (karakter.trim().isEmpty) continue;
    if (simbol.contains(karakter)) {
      skor++;
      break;
    }
  }
  return skor.clamp(0, 4);
}

/// Mengubah skor menjadi label yang dapat dibaca.
String labelKekuatanKataSandi(int skor) {
  switch (skor) {
    case 0:
    case 1:
      return 'Lemah';
    case 2:
      return 'Sedang';
    case 3:
      return 'Kuat';
    case 4:
      return 'Sangat kuat';
    default:
      return 'Tidak diketahui';
  }
}

/// Menghasilkan inisial nama untuk avatar profil.
String inisialNama(String nama) {
  final bagian = nama.trim().split(RegExp(r'\s+'));
  if (bagian.isEmpty || bagian.first.isEmpty) return '?';
  if (bagian.length == 1) return bagian.first[0].toUpperCase();
  return '${bagian.first[0]}${bagian.last[0]}'.toUpperCase();
}
