import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/hisse_model.dart';

class CandleData {
  final double open, high, low, close;
  CandleData({required this.open, required this.high, required this.low, required this.close});
}

class DetailScreen extends StatefulWidget {
  final HisseModel hisse;
  const DetailScreen({super.key, required this.hisse});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<double> fiyatlar = [];
  List<double> hacimler = [];
  List<CandleData> mumlar = [];
  List<double> bbUpper = [];
  List<double> bbMiddle = [];
  List<double> bbLower = [];
  double? rsi;
  double? macdDeger;
  double? haftalikYuksek;
  double? haftalikDusuk;
  bool yukleniyor = true;
  bool mumGrafik = true;
  bool bbGoster = true;

  // Crosshair
  int? seciliIndex;
  double? seciliFiyat;

  // Ortalama maliyet hesaplayıcı
  double ekstraAdet = 0;

  // Zaman dilimi
  String secilenAralik = '3mo';
  String secilenInterval = '1d';
  final List<Map<String, String>> araliklar = [
    {'label': '1G', 'range': '1d', 'interval': '5m'},
    {'label': '1H', 'range': '1mo', 'interval': '1d'},
    {'label': '3A', 'range': '3mo', 'interval': '1d'},
    {'label': '6A', 'range': '6mo', 'interval': '1d'},
    {'label': '1Y', 'range': '1y', 'interval': '1d'},
  ];

  @override
  void initState() {
    super.initState();
    veriCek();
    _52HaftaCek();
  }

  Future<void> _52HaftaCek() async {
    try {
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/${widget.hisse.kod}?interval=1d&range=1y',
      );
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final closes = (data['chart']['result'][0]['indicators']['quote'][0]['close'] as List)
            .whereType<num>().map((e) => e.toDouble()).toList();
        if (mounted && closes.isNotEmpty) {
          setState(() {
            haftalikYuksek = closes.reduce((a, b) => a > b ? a : b);
            haftalikDusuk = closes.reduce((a, b) => a < b ? a : b);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> veriCek() async {
    setState(() { yukleniyor = true; seciliIndex = null; seciliFiyat = null; });
    try {
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/${widget.hisse.kod}?interval=$secilenInterval&range=$secilenAralik',
      );
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final quote = data['chart']['result'][0]['indicators']['quote'][0];
        final closes = (quote['close'] as List).whereType<num>().map((e) => e.toDouble()).toList();
        final opens = (quote['open'] as List).whereType<num>().map((e) => e.toDouble()).toList();
        final highs = (quote['high'] as List).whereType<num>().map((e) => e.toDouble()).toList();
        final lows = (quote['low'] as List).whereType<num>().map((e) => e.toDouble()).toList();
        final vols = (quote['volume'] as List).map((e) => e != null ? (e as num).toDouble() : 0.0).toList();
        final len = [closes.length, opens.length, highs.length, lows.length]
            .reduce((a, b) => a < b ? a : b);
        setState(() {
          fiyatlar = closes;
          hacimler = vols;
          mumlar = List.generate(len, (i) => CandleData(
            open: opens[i], high: highs[i], low: lows[i], close: closes[i],
          ));
          bbUpper = []; bbMiddle = []; bbLower = [];
          if (closes.length >= 20) _hesaplaBollinger(closes);
          if (closes.length >= 15) rsi = _rsi(closes);
          if (closes.length >= 26) macdDeger = _macd(closes);
          yukleniyor = false;
        });
      }
    } catch (_) {
      setState(() => yukleniyor = false);
    }
  }

  void _hesaplaBollinger(List<double> p) {
    const period = 20;
    bbUpper = []; bbMiddle = []; bbLower = [];
    for (int i = period - 1; i < p.length; i++) {
      final slice = p.sublist(i - period + 1, i + 1);
      final sma = slice.reduce((a, b) => a + b) / period;
      final variance = slice.map((v) => (v - sma) * (v - sma)).reduce((a, b) => a + b) / period;
      final stdDev = variance > 0 ? _sqrt(variance) : 0.0;
      bbMiddle.add(sma);
      bbUpper.add(sma + 2 * stdDev);
      bbLower.add(sma - 2 * stdDev);
    }
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) r = (r + x / r) / 2;
    return r;
  }

  double _rsi(List<double> p) {
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
    double k = 2 / (period + 1);
    double ema = p.take(period).reduce((a, b) => a + b) / period;
    for (int i = period; i < p.length; i++) { ema = p[i] * k + ema * (1 - k); }
    return ema;
  }

  double _macd(List<double> p) => _ema(p, 12) - _ema(p, 26);

  Color get _renkDegisim =>
      (widget.hisse.degisim ?? 0) >= 0 ? const Color(0xFF00D4AA) : Colors.redAccent;

  // Akıllı sinyaller
  List<Map<String, dynamic>> get _sinyaller {
    List<Map<String, dynamic>> s = [];
    if (rsi != null) {
      if (rsi! < 30) s.add({'ikon': '🟢', 'mesaj': 'RSI Aşırı Satım (${rsi!.toStringAsFixed(1)})', 'renk': const Color(0xFF00D4AA)});
      else if (rsi! > 70) s.add({'ikon': '🔴', 'mesaj': 'RSI Aşırı Alım (${rsi!.toStringAsFixed(1)})', 'renk': Colors.redAccent});
    }
    if (macdDeger != null) {
      if (macdDeger! > 0) s.add({'ikon': '⚡', 'mesaj': 'MACD Pozitif Trend', 'renk': const Color(0xFF00D4AA)});
      else s.add({'ikon': '⚠️', 'mesaj': 'MACD Negatif Trend', 'renk': Colors.orange});
    }
    if (fiyatlar.isNotEmpty && bbLower.isNotEmpty) {
      final sonFiyat = fiyatlar.last;
      if (sonFiyat <= bbLower.last * 1.01) s.add({'ikon': '🎯', 'mesaj': 'BB Alt Bandı Teması', 'renk': Colors.blue});
      if (sonFiyat >= bbUpper.last * 0.99) s.add({'ikon': '🚧', 'mesaj': 'BB Üst Bandı Teması', 'renk': Colors.orange});
    }
    if (haftalikDusuk != null && fiyatlar.isNotEmpty) {
      if (fiyatlar.last <= haftalikDusuk! * 1.05) {
        s.add({'ikon': '📉', 'mesaj': '52 Hafta Dibine Yakın', 'renk': Colors.redAccent});
      }
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final pozitif = (widget.hisse.degisim ?? 0) >= 0;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3E),
        iconTheme: const IconThemeData(color: Color(0xFF00D4AA)),
        title: Text(widget.hisse.kod.replaceAll('.IS', ''),
            style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Fiyat başlık
          Text(widget.hisse.ad, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            Text(
              seciliFiyat != null
                  ? '₺${seciliFiyat!.toStringAsFixed(2)}'
                  : widget.hisse.fiyat != null ? '₺${widget.hisse.fiyat!.toStringAsFixed(2)}' : '--',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            if (seciliFiyat == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _renkDegisim.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.hisse.degisim != null
                      ? '${pozitif ? '+' : ''}${widget.hisse.degisim!.toStringAsFixed(2)}%'
                      : '--',
                  style: TextStyle(color: _renkDegisim, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('📌 ${seciliIndex! + 1}. gün',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 12),

          // 52 Hafta Band
          if (haftalikYuksek != null && haftalikDusuk != null && widget.hisse.fiyat != null)
            _52HaftaWidget(),

          const SizedBox(height: 16),

          // Zaman dilimi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: araliklar.map((a) {
              final aktif = secilenAralik == a['range'];
              return GestureDetector(
                onTap: () {
                  setState(() { secilenAralik = a['range']!; secilenInterval = a['interval']!; });
                  veriCek();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: aktif ? const Color(0xFF00D4AA) : const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(a['label']!,
                      style: TextStyle(
                          color: aktif ? Colors.black : Colors.white54,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 12),

          // Grafik toggle
          Row(children: [
            _toggleBtn('Mum', mumGrafik, () => setState(() => mumGrafik = true)),
            const SizedBox(width: 8),
            _toggleBtn('Çizgi', !mumGrafik, () => setState(() => mumGrafik = false)),
            const SizedBox(width: 16),
            if (!mumGrafik)
              GestureDetector(
                onTap: () => setState(() => bbGoster = !bbGoster),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: bbGoster ? Colors.purple.withOpacity(0.3) : const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: bbGoster ? Colors.purple : Colors.transparent),
                  ),
                  child: const Text('BB', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
          ]),
          const SizedBox(height: 12),

          // Grafik
          if (yukleniyor)
            const SizedBox(height: 220,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))))
          else ...[
            if (mumlar.isNotEmpty && mumGrafik) ...[
              const Text('Mum Grafik', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onPanUpdate: (d) {
                  if (mumlar.isEmpty) return;
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final w = box.size.width - 32;
                  final x = d.localPosition.dx.clamp(0, w);
                  final idx = ((x / w) * (mumlar.length - 1)).round().clamp(0, mumlar.length - 1);
                  setState(() { seciliIndex = idx; seciliFiyat = mumlar[idx].close; });
                },
                onPanEnd: (_) => setState(() { seciliIndex = null; seciliFiyat = null; }),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CustomPaint(painter: CandlePainter(mumlar: mumlar, seciliIndex: seciliIndex)),
                ),
              ),
            ],

            if (fiyatlar.isNotEmpty && !mumGrafik) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Fiyat Grafiği', style: TextStyle(color: Colors.white70, fontSize: 13)),
                if (bbGoster) Row(children: [
                  _bbLegend('Üst', Colors.purple),
                  const SizedBox(width: 6),
                  _bbLegend('Orta', Colors.orange),
                  const SizedBox(width: 6),
                  _bbLegend('Alt', Colors.blue),
                ]),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: LineChart(LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        '₺${s.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )).toList(),
                    ),
                    touchCallback: (event, response) {
                      if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                        setState(() {
                          seciliIndex = response.lineBarSpots![0].x.toInt();
                          seciliFiyat = response.lineBarSpots![0].y;
                        });
                      } else {
                        setState(() { seciliIndex = null; seciliFiyat = null; });
                      }
                    },
                  ),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: fiyatlar.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true, color: _renkDegisim, barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: _renkDegisim.withOpacity(0.08)),
                    ),
                    if (bbGoster && bbUpper.isNotEmpty)
                      LineChartBarData(
                        spots: bbUpper.asMap().entries.map((e) => FlSpot((e.key + 19).toDouble(), e.value)).toList(),
                        isCurved: true, color: Colors.purple.withOpacity(0.7),
                        barWidth: 1, dotData: const FlDotData(show: false),
                      ),
                    if (bbGoster && bbMiddle.isNotEmpty)
                      LineChartBarData(
                        spots: bbMiddle.asMap().entries.map((e) => FlSpot((e.key + 19).toDouble(), e.value)).toList(),
                        isCurved: true, color: Colors.orange.withOpacity(0.7),
                        barWidth: 1, dotData: const FlDotData(show: false),
                      ),
                    if (bbGoster && bbLower.isNotEmpty)
                      LineChartBarData(
                        spots: bbLower.asMap().entries.map((e) => FlSpot((e.key + 19).toDouble(), e.value)).toList(),
                        isCurved: true, color: Colors.blue.withOpacity(0.7),
                        barWidth: 1, dotData: const FlDotData(show: false),
                      ),
                  ],
                )),
              ),
            ],

            // Hacim
            if (hacimler.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Hacim', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(height: 60, width: double.infinity,
                  child: CustomPaint(painter: VolumePainter(hacimler: hacimler))),
            ],
          ],

          // Akıllı sinyaller
          if (_sinyaller.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('🧠 Akıllı Sinyaller', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            ..._sinyaller.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (s['renk'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (s['renk'] as Color).withOpacity(0.3)),
              ),
              child: Row(children: [
                Text(s['ikon'], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(s['mesaj'], style: TextStyle(color: s['renk'], fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
          ],

          // Teknik göstergeler
          const SizedBox(height: 20),
          const Text('Teknik Göstergeler', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _kart('RSI (14)', rsi?.toStringAsFixed(1) ?? '--', _rsiRenk(rsi))),
            const SizedBox(width: 12),
            Expanded(child: _kart('MACD', macdDeger?.toStringAsFixed(2) ?? '--',
                (macdDeger ?? 0) >= 0 ? const Color(0xFF00D4AA) : Colors.redAccent)),
          ]),

          // Ortalama maliyet hesaplayıcı
          const SizedBox(height: 20),
          _ortalamaHesaplayici(),
        ]),
      ),
    );
  }

  Widget _52HaftaWidget() {
    final fiyat = widget.hisse.fiyat!;
    final range = haftalikYuksek! - haftalikDusuk!;
    final pozisyon = range > 0 ? ((fiyat - haftalikDusuk!) / range).clamp(0.0, 1.0) : 0.5;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF2A2A3E), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('52 Hafta Bandı', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('₺${haftalikDusuk!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          Text('₺${haftalikYuksek!.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Stack(children: [
          Container(height: 6, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(colors: [Colors.redAccent, Colors.amber, Color(0xFF00D4AA)]),
          )),
          Positioned(
            left: (pozisyon * (MediaQuery.of(context).size.width - 76)).clamp(0, double.infinity),
            top: -3,
            child: Container(width: 12, height: 12,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ]),
        const SizedBox(height: 8),
        Center(child: Text(
          pozisyon < 0.2 ? '📉 52 Hafta Dibine Yakın' :
          pozisyon > 0.8 ? '🚀 52 Hafta Zirvesine Yakın' : '📊 Orta Bölgede',
          style: TextStyle(
            color: pozisyon < 0.2 ? Colors.redAccent : pozisyon > 0.8 ? const Color(0xFF00D4AA) : Colors.amber,
            fontSize: 12, fontWeight: FontWeight.bold,
          ),
        )),
      ]),
    );
  }

  Widget _ortalamaHesaplayici() {
    final mevcutFiyat = widget.hisse.fiyat ?? 0;
    final mevcutAdet = 20.0;
    final mevcutOrtalama = 47.0;
    final yeniOrtalama = ekstraAdet > 0
        ? ((mevcutAdet * mevcutOrtalama) + (ekstraAdet * mevcutFiyat)) / (mevcutAdet + ekstraAdet)
        : mevcutOrtalama;
    final fark = yeniOrtalama - mevcutOrtalama;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2A2A3E), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🧮 Ortalama Maliyet Hesaplayıcı',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Ekstra Alım:', style: TextStyle(color: Colors.white54, fontSize: 13)),
          Text('${ekstraAdet.toInt()} adet @ ₺${mevcutFiyat.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        Slider(
          value: ekstraAdet,
          min: 0, max: 100,
          divisions: 100,
          activeColor: const Color(0xFF00D4AA),
          inactiveColor: Colors.white12,
          onChanged: (v) => setState(() => ekstraAdet = v),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fark < 0 ? const Color(0xFF00D4AA).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mevcut Ort.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('₺${mevcutOrtalama.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
            const Icon(Icons.arrow_forward, color: Colors.white38, size: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Yeni Ort.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('₺${yeniOrtalama.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: fark < 0 ? const Color(0xFF00D4AA) : Colors.orange,
                    fontWeight: FontWeight.bold,
                  )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _bbLegend(String label, Color renk) => Row(children: [
    Container(width: 10, height: 2, color: renk),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(color: renk, fontSize: 10)),
  ]);

  Widget _toggleBtn(String label, bool aktif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF00D4AA) : const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: aktif ? Colors.black : Colors.white54,
          fontWeight: FontWeight.bold, fontSize: 12,
        )),
      ),
    );
  }

  Color _rsiRenk(double? r) {
    if (r == null) return Colors.white54;
    if (r < 30) return const Color(0xFF00D4AA);
    if (r > 70) return Colors.redAccent;
    return Colors.white;
  }

  Widget _kart(String baslik, String deger, Color renk) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF2A2A3E), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(baslik, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 8),
      Text(deger, style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 22)),
    ]),
  );
}

class CandlePainter extends CustomPainter {
  final List<CandleData> mumlar;
  final int? seciliIndex;
  CandlePainter({required this.mumlar, this.seciliIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (mumlar.isEmpty) return;
    final son = mumlar.length > 60 ? mumlar.sublist(mumlar.length - 60) : mumlar;
    final minVal = son.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final maxVal = son.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;
    final w = size.width / son.length;

    // Crosshair
    if (seciliIndex != null && seciliIndex! < son.length) {
      final x = seciliIndex! * w + w / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          Paint()..color = Colors.white24..strokeWidth = 1);
    }

    for (int i = 0; i < son.length; i++) {
      final c = son[i];
      final bull = c.close >= c.open;
      final renk = bull ? const Color(0xFF00D4AA) : Colors.redAccent;
      final x = i * w + w / 2;
      final yHigh = size.height - ((c.high - minVal) / range) * size.height;
      final yLow = size.height - ((c.low - minVal) / range) * size.height;
      final yOpen = size.height - ((c.open - minVal) / range) * size.height;
      final yClose = size.height - ((c.close - minVal) / range) * size.height;
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow),
          Paint()..color = renk..strokeWidth = 1);
      final top = bull ? yClose : yOpen;
      final bottom = bull ? yOpen : yClose;
      final bodyH = (bottom - top).abs().clamp(1.0, double.infinity);
      canvas.drawRect(Rect.fromLTWH(x - w * 0.3, top, w * 0.6, bodyH),
          Paint()..color = seciliIndex == i ? Colors.white : renk);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class VolumePainter extends CustomPainter {
  final List<double> hacimler;
  VolumePainter({required this.hacimler});

  @override
  void paint(Canvas canvas, Size size) {
    if (hacimler.isEmpty) return;
    final son = hacimler.length > 60 ? hacimler.sublist(hacimler.length - 60) : hacimler;
    final maxVol = son.reduce((a, b) => a > b ? a : b);
    if (maxVol == 0) return;
    final w = size.width / son.length;
    for (int i = 0; i < son.length; i++) {
      final h = (son[i] / maxVol) * size.height;
      canvas.drawRect(Rect.fromLTWH(i * w + 1, size.height - h, w - 2, h),
          Paint()..color = const Color(0xFF00D4AA).withOpacity(0.4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}