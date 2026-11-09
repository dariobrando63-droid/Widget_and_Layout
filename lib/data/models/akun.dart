/// Identitas akun lokal; rahasia hanya disimpan sebagai salt dan hash.
class Akun {
  const Akun({
    required this.id,
    required this.nama,
    required this.email,
    required this.saltSandi,
    required this.hashSandi,
    required this.pertanyaanKeamanan,
    required this.saltJawaban,
    required this.hashJawaban,
    required this.dibuatPada,
  });

  final String id;
  final String nama;
  final String email;
  final String saltSandi;
  final String hashSandi;
  final String pertanyaanKeamanan;
  final String saltJawaban;
  final String hashJawaban;
  final DateTime dibuatPada;

  /// Mengubah akun menjadi peta untuk penyimpanan JSON.
  Map<String, dynamic> toMap() => {
    'id': id,
    'nama': nama,
    'email': email,
    'saltSandi': saltSandi,
    'hashSandi': hashSandi,
    'pertanyaanKeamanan': pertanyaanKeamanan,
    'saltJawaban': saltJawaban,
    'hashJawaban': hashJawaban,
    'dibuatPada': dibuatPada.toIso8601String(),
  };

  /// Membaca akun tersimpan tanpa menerima data wajib yang tidak lengkap.
  static Akun? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final nama = map['nama'];
    final email = map['email'];
    final saltSandi = map['saltSandi'];
    final hashSandi = map['hashSandi'];
    final pertanyaan = map['pertanyaanKeamanan'];
    final saltJawaban = map['saltJawaban'];
    final hashJawaban = map['hashJawaban'];
    final dibuatPada = map['dibuatPada'];
    if (id is! String ||
        nama is! String ||
        email is! String ||
        saltSandi is! String ||
        hashSandi is! String ||
        pertanyaan is! String ||
        saltJawaban is! String ||
        hashJawaban is! String ||
        dibuatPada is! String) {
      return null;
    }
    final tanggal = DateTime.tryParse(dibuatPada);
    if (tanggal == null) return null;
    return Akun(
      id: id,
      nama: nama,
      email: email,
      saltSandi: saltSandi,
      hashSandi: hashSandi,
      pertanyaanKeamanan: pertanyaan,
      saltJawaban: saltJawaban,
      hashJawaban: hashJawaban,
      dibuatPada: tanggal,
    );
  }
}
