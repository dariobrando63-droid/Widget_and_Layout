/// Membuat kunci tanggal lokal tanpa bergantung pada zona waktu UTC.
String kunciTanggalLokal(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Memeriksa pergantian hari kalender lokal.
bool adaHariBerbeda(DateTime pertama, DateTime kedua) =>
    pertama.year != kedua.year ||
    pertama.month != kedua.month ||
    pertama.day != kedua.day;
