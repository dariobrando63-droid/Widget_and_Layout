import '../constants/app_constants.dart';

/// Memformat detik menjadi hitung mundur MM:SS yang tidak negatif.
String formatMmSs(int totalDetik) {
  final aman = totalDetik < 0 ? 0 : totalDetik;
  final menit = aman ~/ detikPerMenit;
  final sisaDetik = aman % detikPerMenit;
  return '${menit.toString().padLeft(2, '0')}:'
      '${sisaDetik.toString().padLeft(2, '0')}';
}

/// Menghitung persentase aman dan membatasi hasil ke rentang 0–1.
double persen(num bagian, num total) {
  if (total <= 0) return 0.0;
  return (bagian / total).clamp(0.0, 1.0).toDouble();
}
