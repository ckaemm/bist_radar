import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PortfolioItem {
  final String kod;
  final String ad;
  int adet;
  double ortalamaFiyat;
  double? anlikFiyat;

  PortfolioItem({
    required this.kod,
    required this.ad,
    required this.adet,
    required this.ortalamaFiyat,
    this.anlikFiyat,
  });

  double get maliyet => adet * ortalamaFiyat;
  double get anlikDeger => adet * (anlikFiyat ?? ortalamaFiyat);
  double get karZarar => anlikDeger - maliyet;
  double get karZararYuzde => ((anlikFiyat ?? ortalamaFiyat) - ortalamaFiyat) / ortalamaFiyat * 100;
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Timer? _timer;
  int? _hoveredIndex;

  final List<PortfolioItem> portfoy = [
    PortfolioItem(kod: 'ISMEN.IS', ad: 'İş Yatırım', adet: 20, ortalamaFiyat: 47.0),
  ];

  @override
  void initState() {
    super.initState();
    fiyatGuncelle();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fiyatGuncelle());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fiyatGuncelle() async {
    for (var item in portfoy) {
      try {
        final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${item.kod}?interval=1d&range=1d',
        );
        final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final meta = data['chart']['result'][0]['meta'];
          final fiyat = (meta['regularMarketPrice'] as num).toDouble();
          if (mounted) setState(() => item.anlikFiyat = fiyat);
        }
      } catch (_) {}
    }
  }

  void _hisseDialog({PortfolioItem? mevcutItem, int? index}) {
    String kod = mevcutItem?.kod.replaceAll('.IS', '') ?? '';
    String ad = mevcutItem?.ad ?? '';
    String adet = mevcutItem?.adet.toString() ?? '';
    String fiyat = mevcutItem?.ortalamaFiyat.toString() ?? '';
    final bool duzenle = mevcutItem != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(duzenle ? '✏️ Düzenle' : '➕ Hisse Ekle',
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _alan('Hisse Kodu (örn: GARAN)', kod, (v) => kod = v, enabled: !duzenle),
          const SizedBox(height: 8),
          _alan('Hisse Adı', ad, (v) => ad = v),
          const SizedBox(height: 8),
          _alan('Adet', adet, (v) => adet = v, sayi: true),
          const SizedBox(height: 8),
          _alan('Ortalama Alış (₺)', fiyat, (v) => fiyat = v, sayi: true),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          if (duzenle)
            TextButton(
              onPressed: () {
                setState(() => portfoy.removeAt(index!));
                Navigator.pop(ctx);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA)),
            onPressed: () {
              if (kod.isNotEmpty && adet.isNotEmpty && fiyat.isNotEmpty) {
                setState(() {
                  if (duzenle) {
                    portfoy[index!].adet = int.tryParse(adet) ?? mevcutItem!.adet;
                    portfoy[index].ortalamaFiyat = double.tryParse(fiyat) ?? mevcutItem!.ortalamaFiyat;
                  } else {
                    portfoy.add(PortfolioItem(
                      kod: '${kod.toUpperCase()}.IS',
                      ad: ad.isEmpty ? kod.toUpperCase() : ad,
                      adet: int.tryParse(adet) ?? 0,
                      ortalamaFiyat: double.tryParse(fiyat) ?? 0,
                    ));
                  }
                });
                Navigator.pop(ctx);
                fiyatGuncelle();
              }
            },
            child: Text(duzenle ? 'Kaydet' : 'Ekle',
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _alan(String hint, String baslangic, Function(String) onChange,
      {bool sayi = false, bool enabled = true}) {
    return TextField(
      enabled: enabled,
      controller: TextEditingController(text: baslangic),
      keyboardType: sayi ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: enabled ? Colors.white : Colors.white38),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00D4AA))),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00D4AA))),
        disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white12)),
      ),
      onChanged: onChange,
    );
  }

  @override
  Widget build(BuildContext context) {
    double toplamMaliyet = portfoy.fold(0, (s, i) => s + i.maliyet);
    double toplamDeger = portfoy.fold(0, (s, i) => s + i.anlikDeger);
    double toplamKarZarar = toplamDeger - toplamMaliyet;
    double toplamYuzde = toplamMaliyet > 0 ? (toplamKarZarar / toplamMaliyet) * 100 : 0;
    bool toplamPozitif = toplamKarZarar >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('💼 Portföyüm',
            style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00D4AA), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('CANLI', style: TextStyle(
                  color: Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00D4AA),
        onPressed: () => _hisseDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [

          // Özet kart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              const Text('Toplam Portföy Değeri',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 8),
              Text('₺${toplamDeger.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(toplamPozitif ? Icons.arrow_upward : Icons.arrow_downward,
                    color: toplamPozitif ? const Color(0xFF00D4AA) : Colors.redAccent,
                    size: 16),
                const SizedBox(width: 4),
                Text(
                  '₺${toplamKarZarar.abs().toStringAsFixed(2)} (${toplamYuzde.abs().toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: toplamPozitif ? const Color(0xFF00D4AA) : Colors.redAccent,
                    fontWeight: FontWeight.bold, fontSize: 15,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Maliyet: ₺${toplamMaliyet.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),

          const SizedBox(height: 16),

          // Pasta grafik
          if (portfoy.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                const Text('Portföy Dağılımı',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          _hoveredIndex = response?.touchedSection?.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: portfoy.asMap().entries.map((e) {
                      final colors = [
                        const Color(0xFF00D4AA), Colors.blueAccent, Colors.orange,
                        Colors.purple, Colors.redAccent, Colors.yellow,
                      ];
                      final renk = colors[e.key % colors.length];
                      final yuzde = toplamDeger > 0
                          ? (e.value.anlikDeger / toplamDeger) * 100 : 0;
                      final isHovered = _hoveredIndex == e.key;
                      return PieChartSectionData(
                        color: renk,
                        value: e.value.anlikDeger,
                        title: '${yuzde.toStringAsFixed(1)}%',
                        radius: isHovered ? 65 : 55,
                        titleStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    }).toList(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  )),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 6,
                  children: portfoy.asMap().entries.map((e) {
                    final colors = [
                      const Color(0xFF00D4AA), Colors.blueAccent, Colors.orange,
                      Colors.purple, Colors.redAccent, Colors.yellow,
                    ];
                    return Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(e.value.kod.replaceAll('.IS', ''),
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]);
                  }).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Hisse listesi
          ...portfoy.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final pozitif = item.karZarar >= 0;
            final renk = pozitif ? const Color(0xFF00D4AA) : Colors.redAccent;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.kod.replaceAll('.IS', ''),
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${item.adet} adet @ ₺${item.ortalamaFiyat.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                  Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        item.anlikFiyat != null
                            ? '₺${item.anlikFiyat!.toStringAsFixed(2)}' : '--',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('₺${item.anlikDeger.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                    const SizedBox(width: 10),
                    // Düzenle butonu
                    GestureDetector(
                      onTap: () => _hisseDialog(mevcutItem: item, index: index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white38, size: 16),
                      ),
                    ),
                  ]),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: renk.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Kâr/Zarar', style: TextStyle(color: renk, fontSize: 12)),
                    Row(children: [
                      Icon(pozitif ? Icons.arrow_upward : Icons.arrow_downward,
                          color: renk, size: 13),
                      Text(
                        '₺${item.karZarar.abs().toStringAsFixed(2)} (${item.karZararYuzde.abs().toStringAsFixed(2)}%)',
                        style: TextStyle(color: renk,
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ]),
                  ]),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}