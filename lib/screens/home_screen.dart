import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/hisse_model.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  bool yukleniyor = true;
  String aramaMetni = '';
  bool sadeceFavori = false;

  double? bist100;
  double? bist100Degisim;
  double? usdTry;
  double? eurTry;

  final List<HisseModel> hisseler = [
    HisseModel(kod: 'ISMEN.IS', ad: 'İş Yatırım'),
    HisseModel(kod: 'THYAO.IS', ad: 'Türk Hava Yolları'),
    HisseModel(kod: 'GARAN.IS', ad: 'Garanti Bankası'),
    HisseModel(kod: 'ASELS.IS', ad: 'Aselsan'),
    HisseModel(kod: 'BIMAS.IS', ad: 'BİM Mağazaları'),
    HisseModel(kod: 'SISE.IS', ad: 'Şişe Cam'),
    HisseModel(kod: 'KCHOL.IS', ad: 'Koç Holding'),
    HisseModel(kod: 'EREGL.IS', ad: 'Ereğli Demir Çelik'),
    HisseModel(kod: 'AKBNK.IS', ad: 'Akbank'),
    HisseModel(kod: 'TUPRS.IS', ad: 'Tüpraş'),
  ];

  List<HisseModel> get filtrelenmis {
    var liste = sadeceFavori ? hisseler.where((h) => h.favori).toList() : hisseler;
    if (aramaMetni.isNotEmpty) {
      liste = liste.where((h) =>
        h.kod.toLowerCase().contains(aramaMetni.toLowerCase()) ||
        h.ad.toLowerCase().contains(aramaMetni.toLowerCase())
      ).toList();
    }
    return liste;
  }

  @override
  void initState() {
    super.initState();
    veriCek();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => veriCek());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tekVeriCek(String sembol, Function(Map) onSuccess) async {
    try {
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$sembol?interval=1d&range=1d',
      );
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        onSuccess(data);
      }
    } catch (_) {}
  }

  Future<void> veriCek() async {
    await _tekVeriCek('XU100.IS', (data) {
      final meta = data['chart']['result'][0]['meta'];
      final f = (meta['regularMarketPrice'] as num).toDouble();
      final k = (meta['chartPreviousClose'] as num).toDouble();
      if (mounted) setState(() { bist100 = f; bist100Degisim = ((f - k) / k) * 100; });
    });
    await _tekVeriCek('USDTRY=X', (data) {
      final f = (data['chart']['result'][0]['meta']['regularMarketPrice'] as num).toDouble();
      if (mounted) setState(() => usdTry = f);
    });
    await _tekVeriCek('EURTRY=X', (data) {
      final f = (data['chart']['result'][0]['meta']['regularMarketPrice'] as num).toDouble();
      if (mounted) setState(() => eurTry = f);
    });

    for (var hisse in hisseler) {
      try {
        final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${hisse.kod}?interval=1d&range=1d',
        );
        final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final meta = data['chart']['result'][0]['meta'];
          final fiyat = (meta['regularMarketPrice'] as num).toDouble();
          final kapanis = (meta['chartPreviousClose'] as num).toDouble();
          if (mounted) {
            setState(() {
              hisse.fiyat = fiyat;
              hisse.degisim = ((fiyat - kapanis) / kapanis) * 100;
            });
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => yukleniyor = false);
  }

  List<Map<String, dynamic>> _sinyaller(HisseModel h) {
    List<Map<String, dynamic>> sinyaller = [];
    if (h.gecmisFiyatlar.length < 15) return sinyaller;
    double rsi = _rsi(h.gecmisFiyatlar);
    if (rsi < 30) {
      sinyaller.add({'ikon': '🟢', 'mesaj': 'RSI Aşırı Satım', 'renk': const Color(0xFF00D4AA)});
    } else if (rsi > 70) {
      sinyaller.add({'ikon': '🔴', 'mesaj': 'RSI Aşırı Alım', 'renk': Colors.redAccent});
    }
    if (h.gecmisFiyatlar.length >= 26) {
      double macd = _macd(h.gecmisFiyatlar);
      if (macd > 0) {
        sinyaller.add({'ikon': '⚡', 'mesaj': 'MACD Pozitif', 'renk': const Color(0xFF00D4AA)});
      } else {
        sinyaller.add({'ikon': '⚠️', 'mesaj': 'MACD Negatif', 'renk': Colors.orange});
      }
    }
    return sinyaller;
  }

  double _rsi(List<double> p) {
    if (p.length < 15) return 50;
    double gain = 0, loss = 0;
    for (int i = p.length - 14; i < p.length; i++) {
      final d = p[i] - p[i - 1];
      if (d > 0) { gain += d; } else { loss += d.abs(); }
    }
    gain /= 14; loss /= 14;
    if (loss == 0) return 100;
    return 100 - (100 / (1 + gain / loss));
  }

  double _ema(List<double> p, int period) {
    if (p.length < period) return p.last;
    double k = 2 / (period + 1);
    double ema = p.take(period).reduce((a, b) => a + b) / period;
    for (int i = period; i < p.length; i++) { ema = p[i] * k + ema * (1 - k); }
    return ema;
  }

  double _macd(List<double> p) => _ema(p, 12) - _ema(p, 26);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('📈 BIST Radar',
            style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(sadeceFavori ? Icons.star : Icons.star_border,
                color: sadeceFavori ? Colors.amber : Colors.white38),
            onPressed: () => setState(() => sadeceFavori = !sadeceFavori),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
      body: Column(children: [
        _piyasaSeridi(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: (v) => setState(() => aramaMetni = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Hisse ara...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4AA)),
              filled: true,
              fillColor: const Color(0xFF2A2A3E),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1),
              ),
            ),
          ),
        ),
        Expanded(
          child: yukleniyor
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
              : filtrelenmis.isEmpty
                  ? Center(child: Text(
                      sadeceFavori
                          ? 'Favori hisse yok\nHisse kartına ⭐ basın'
                          : 'Hisse bulunamadı',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38)))
                  : RefreshIndicator(
                      onRefresh: veriCek,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtrelenmis.length,
                        itemBuilder: (context, i) {
                          final h = filtrelenmis[i];
                          final pozitif = (h.degisim ?? 0) >= 0;
                          final renk = pozitif
                              ? const Color(0xFF00D4AA)
                              : Colors.redAccent;
                          final sinyaller = _sinyaller(h);
                          return GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => DetailScreen(hisse: h))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A3E),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Text(h.kod.replaceAll('.IS', ''),
                                          style: const TextStyle(color: Colors.white,
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => setState(() => h.favori = !h.favori),
                                        child: Icon(
                                            h.favori ? Icons.star : Icons.star_border,
                                            color: h.favori ? Colors.amber : Colors.white24,
                                            size: 16),
                                      ),
                                    ]),
                                    Text(h.ad,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ]),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text(
                                      h.fiyat != null ? '₺${h.fiyat!.toStringAsFixed(2)}' : '--',
                                      style: const TextStyle(color: Colors.white,
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Row(children: [
                                      Icon(pozitif ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: renk, size: 12),
                                      Text(
                                        h.degisim != null
                                            ? '${h.degisim!.abs().toStringAsFixed(2)}%'
                                            : '--',
                                        style: TextStyle(color: renk,
                                            fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ]),
                                  ]),
                                ]),
                                if (sinyaller.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    ...sinyaller.take(2).map((s) => Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (s['renk'] as Color).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('${s['ikon']} ${s['mesaj']}',
                                          style: TextStyle(
                                              color: s['renk'],
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold)),
                                    )),
                                  ]),
                                ],
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _piyasaSeridi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF16162A),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _seritItem('BIST 100',
            bist100 != null ? bist100!.toStringAsFixed(0) : '--', bist100Degisim),
        Container(width: 1, height: 30, color: Colors.white12),
        _seritItem('USD/TRY', usdTry != null ? usdTry!.toStringAsFixed(2) : '--', null),
        Container(width: 1, height: 30, color: Colors.white12),
        _seritItem('EUR/TRY', eurTry != null ? eurTry!.toStringAsFixed(2) : '--', null),
      ]),
    );
  }

  Widget _seritItem(String baslik, String deger, double? degisim) {
    final pozitif = (degisim ?? 0) >= 0;
    final renk = degisim == null
        ? Colors.white
        : pozitif ? const Color(0xFF00D4AA) : Colors.redAccent;
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(baslik, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(height: 2),
      Text(deger, style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 13)),
      if (degisim != null)
        Text('${pozitif ? '+' : ''}${degisim.toStringAsFixed(2)}%',
            style: TextStyle(color: renk, fontSize: 10)),
    ]);
  }
}