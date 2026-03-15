class HisseModel {
  final String kod;
  final String ad;
  double? fiyat;
  double? degisim;
  List<double> gecmisFiyatlar;
  bool favori;

  HisseModel({
    required this.kod,
    required this.ad,
    this.fiyat,
    this.degisim,
    List<double>? gecmisFiyatlar,
    this.favori = false,
  }) : gecmisFiyatlar = gecmisFiyatlar ?? [];
}