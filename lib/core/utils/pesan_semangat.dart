/// Memilih kalimat motivasi berdasarkan sesi fokus yang selesai hari ini.
String pesanSemangat(int sesiHariIni) {
  if (sesiHariIni < 0) {
    return 'Data tidak valid';
  } else if (sesiHariIni == 0) {
    return 'Yuk mulai sesi pertamamu';
  } else if (sesiHariIni <= 2) {
    return 'Awal yang bagus, lanjutkan';
  } else if (sesiHariIni <= 4) {
    return 'Hebat, ritme belajarmu stabil';
  } else {
    return 'Luar biasa, jangan lupa istirahat cukup';
  }
}
