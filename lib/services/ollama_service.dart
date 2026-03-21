import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ollama_response.dart';
import '../models/ai_analysis.dart';

class OllamaService {
  String _baseUrl;
  String _model;
  String _language;
  final Duration _timeout;

  OllamaService({
    String baseUrl = 'http://10.0.2.2:11434',
    String model = 'mistral',
    String language = 'tr',
  })  : _baseUrl = baseUrl,
        _model = model,
        _language = language,
        _timeout = const Duration(seconds: 120);

  void updateBaseUrl(String baseUrl) => _baseUrl = baseUrl;
  void updateModel(String model) => _model = model;
  void updateLanguage(String language) => _language = language;

  String get baseUrl => _baseUrl;
  String get model => _model;
  String get language => _language;

  /// Ollama sunucusunun erişilebilir olup olmadığını kontrol eder.
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sunucudaki mevcut modellerin listesini döner.
  Future<List<String>> getAvailableModels() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/tags'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Model listesi alınamadı: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final models = data['models'] as List<dynamic>? ?? [];
    return models
        .map((m) => (m as Map<String, dynamic>)['name'] as String)
        .toList();
  }

  /// Tek seferde (stream:false) yanıt alır.
  Future<OllamaResponse> generate({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? options,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'prompt': prompt,
      'system': ?systemPrompt,
      'stream': false,
      'options': ?options,
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/generate'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Yanıt alınamadı: ${response.statusCode}');
    }

    return OllamaResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Token token yanıt alır, her token'ı `Stream<String>` olarak yayınlar.
  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? options,
  }) async* {
    final body = jsonEncode({
      'model': _model,
      'prompt': prompt,
      'system': ?systemPrompt,
      'stream': true,
      'options': ?options,
    });

    final request = http.Request('POST', Uri.parse('$_baseUrl/api/generate'))
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    final streamedResponse =
        await request.send().timeout(_timeout);

    if (streamedResponse.statusCode != 200) {
      throw Exception('Stream başlatılamadı: ${streamedResponse.statusCode}');
    }

    await for (final chunk
        in streamedResponse.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final token = json['response'] as String? ?? '';
          if (token.isNotEmpty) yield token;
          if (json['done'] == true) return;
        } catch (_) {
          // Yarım chunk, sonraki parçayla birleşecek — atla
        }
      }
    }
  }

  /// Seçili dile göre hisse analizi system prompt'unu döner.
  String buildStockSystemPrompt() {
    if (_language == 'en') {
      return '''
You are an experienced BIST (Borsa Istanbul) technical analyst and investment advisor.
Analyze the given technical indicators and provide a clear, professional evaluation in English.
You MUST write everything in English. Do NOT use Turkish words.
Be concise: maximum 10 sentences.
Give ONLY ONE recommendation: either BUY, SELL, or HOLD. Never give multiple recommendations.
Always end your analysis with exactly these lines:
RECOMMENDATION: BUY | SELL | HOLD
RISK LEVEL: Low | Medium | High
''';
    }
    return '''
Sen 15 yıllık deneyime sahip bir BIST teknik analiz uzmanısın. Yatırımcılara profesyonel teknik analiz raporu hazırlıyorsun. MUTLAKA Türkçe yaz, İngilizce terim kullanma.

Şu formatta analiz yaz:

GENEL GÖRÜNÜM:
Hissenin güncel fiyat seviyesini ve son durumunu 2-3 cümleyle özetle.

TEKNİK İNDİKATÖRLER:

1) RSI Analizi:
- RSI değerini ver ve hangi bölgede olduğunu belirt (0-30 aşırı satım, 30-50 zayıf, 50-70 güçlü, 70-100 aşırı alım)
- Trendin yönünü yorumla

2) MACD Analizi:
- MACD değerini ve sinyal çizgisini karşılaştır
- MACD sinyal çizgisinin üstünde mi altında mı belirt
- Eğer MACD sinyal çizgisini yukarı kesiyorsa bu alım sinyali, aşağı kesiyorsa satım sinyali olduğunu belirt
- Histogram yönünü yorumla (MACD - Sinyal farkı pozitifse momentum yukarı, negatifse aşağı)

3) Bollinger Bantları Analizi:
- Orta bandı hesapla (üst+alt)/2 ve fiyatın orta banda göre konumunu belirt
- Fiyat üst banda yakınsa aşırı alım baskısı, alt banda yakınsa aşırı satım baskısı, ortadaysa kararsız bölge
- Bant genişliğini yorumla (dar bant: sert hareket beklentisi, geniş bant: volatilite yüksek)

SONUÇ VE ÖNERİ:
- Tüm indikatörleri birlikte değerlendir, birbiriyle çelişen sinyalleri belirt
- Tek bir öneri ver: AL, SAT veya BEKLE
- Kısa vadeli (1-5 gün) ve orta vadeli (1-4 hafta) ayrı yorum yap
- Destek ve direnç seviyelerini Bollinger bantlarına göre belirt

RİSK DEĞERLENDİRMESİ:
- Risk seviyesini belirt: Düşük / Orta / Yüksek
- Zarar kes (stop-loss) seviyesi mutlaka öner. Bollinger alt bandını veya en yakın destek seviyesini referans al. Asla "stop-loss önerilmez" deme.

Yanıtının en sonuna tam olarak şu iki satırı ekle:
ÖNERİ: AL | SAT | BEKLE
RİSK SEVİYESİ: Düşük | Orta | Yüksek
''';
  }

  /// Seçili dile göre hisse analizi kullanıcı prompt'unu döner.
  String buildStockUserPrompt({
    required String symbol,
    required double currentPrice,
    required double rsiValue,
    required double macdValue,
    required double macdSignal,
    required double bollingerUpper,
    required double bollingerLower,
  }) {
    if (_language == 'en') {
      return '''
Analyze the $symbol stock based on the following technical data:

- Current Price: ${currentPrice.toStringAsFixed(2)} TRY
- RSI (14): ${rsiValue.toStringAsFixed(2)}
- MACD: ${macdValue.toStringAsFixed(4)}
- MACD Signal: ${macdSignal.toStringAsFixed(4)}
- Bollinger Upper Band: ${bollingerUpper.toStringAsFixed(2)} TRY
- Bollinger Lower Band: ${bollingerLower.toStringAsFixed(2)} TRY

Evaluate: RSI overbought/oversold, MACD trend, Bollinger position, short-term outlook.
End with RECOMMENDATION and RISK LEVEL lines.
''';
    }
    // RSI bölgesi
    final String rsiZone;
    if (rsiValue < 30) {
      rsiZone = 'AŞIRI SATIM bölgesinde (${rsiValue.toStringAsFixed(2)})';
    } else if (rsiValue < 50) {
      rsiZone = 'ZAYIF/NÖTR bölgesinde (${rsiValue.toStringAsFixed(2)})';
    } else if (rsiValue < 70) {
      rsiZone = 'GÜÇLÜ bölgesinde (${rsiValue.toStringAsFixed(2)})';
    } else {
      rsiZone = 'AŞIRI ALIM bölgesinde (${rsiValue.toStringAsFixed(2)})';
    }

    // MACD sinyali
    final String macdSignalComment;
    if (macdValue > macdSignal) {
      macdSignalComment =
          'ALIM SİNYALİ — MACD (${macdValue.toStringAsFixed(4)}) sinyal çizgisini (${macdSignal.toStringAsFixed(4)}) yukarı kesiyor';
    } else {
      macdSignalComment =
          'SATIM SİNYALİ — MACD (${macdValue.toStringAsFixed(4)}) sinyal çizgisinin (${macdSignal.toStringAsFixed(4)}) altında';
    }
    final double macdHistogram = macdValue - macdSignal;
    final String histogramComment = macdHistogram >= 0
        ? 'Histogram pozitif (${macdHistogram.toStringAsFixed(4)}): yukarı momentum'
        : 'Histogram negatif (${macdHistogram.toStringAsFixed(4)}): aşağı momentum';

    // Bollinger pozisyonu
    final double bbMid = (bollingerUpper + bollingerLower) / 2;
    final double bbRange = bollingerUpper - bollingerLower;
    final String bbComment;
    if (bbRange == 0) {
      bbComment = 'Bollinger verileri yetersiz';
    } else {
      final double posRatio = (currentPrice - bollingerLower) / bbRange;
      if (currentPrice > bbMid) {
        if (posRatio >= 0.8) {
          bbComment =
              'Fiyat (${currentPrice.toStringAsFixed(2)} TL) üst banda çok yakın — AŞIRI ALIM baskısı';
        } else {
          bbComment =
              'Fiyat (${currentPrice.toStringAsFixed(2)} TL) orta bandın üstünde — güçlü bölge';
        }
      } else {
        if (posRatio <= 0.2) {
          bbComment =
              'Fiyat (${currentPrice.toStringAsFixed(2)} TL) alt banda çok yakın — AŞIRI SATIM baskısı';
        } else {
          bbComment =
              'Fiyat (${currentPrice.toStringAsFixed(2)} TL) orta bandın altında — zayıf bölge';
        }
      }
    }

    return '''
$symbol hissesini aşağıdaki teknik verilere göre analiz et:

FIYAT: ${currentPrice.toStringAsFixed(2)} TL

RSI (14): $rsiZone

MACD Durumu: $macdSignalComment
$histogramComment

Bollinger Bantları:
- Üst Bant: ${bollingerUpper.toStringAsFixed(2)} TL
- Orta Bant: ${bbMid.toStringAsFixed(2)} TL
- Alt Bant: ${bollingerLower.toStringAsFixed(2)} TL
- Durum: $bbComment

Yukarıdaki hazır yorumları doğrudan kullan. Rakamları yeniden yorumlamana gerek yok; analizini bu sinyaller üzerine inşa et.
ÖNERİ ve RİSK SEVİYESİ satırlarıyla bitir.
''';
  }

  /// Teknik analiz yorumlarını tamamen Dart'ta hesaplar, modele hazır metin gönderir.
  Future<AiAnalysis> analyzeStock({
    required String symbol,
    required double currentPrice,
    required double rsiValue,
    required double macdValue,
    required double macdSignal,
    required double bollingerUpper,
    required double bollingerLower,
  }) async {
    // ── RSI yorumu ──────────────────────────────────────────────────────────
    final String rsiComment;
    if (rsiValue < 30) {
      rsiComment =
          'RSI ${rsiValue.toStringAsFixed(1)} — AŞIRI SATIM bölgesinde, güçlü dip sinyali';
    } else if (rsiValue < 40) {
      rsiComment =
          'RSI ${rsiValue.toStringAsFixed(1)} — Zayıf bölgede, satış baskısı devam ediyor';
    } else if (rsiValue < 50) {
      rsiComment =
          'RSI ${rsiValue.toStringAsFixed(1)} — Nötr-zayıf bölgede, momentum yetersiz';
    } else if (rsiValue < 60) {
      rsiComment =
          'RSI ${rsiValue.toStringAsFixed(1)} — Nötr-güçlü bölgede, toparlanma sinyali';
    } else if (rsiValue < 70) {
      rsiComment =
          'RSI ${rsiValue.toStringAsFixed(1)} — Güçlü bölgede, alım momentumu var';
    } else {
      rsiComment =
          'RSI ${rsiValue.toStringAsFixed(1)} — AŞIRI ALIM bölgesinde, düzeltme riski yüksek';
    }

    // ── MACD yorumu ─────────────────────────────────────────────────────────
    final String macdComment;
    if (macdValue > macdSignal) {
      macdComment =
          'ALIM SİNYALİ — MACD sinyal çizgisinin üstünde, yukarı momentum';
    } else {
      macdComment =
          'SATIM SİNYALİ — MACD sinyal çizgisinin altında, aşağı momentum';
    }
    final double histogram = macdValue - macdSignal;
    final String histogramComment = histogram >= 0
        ? 'Histogram: +${histogram.toStringAsFixed(4)} — momentum güçleniyor'
        : 'Histogram: ${histogram.toStringAsFixed(4)} — momentum zayıflıyor';

    // ── Bollinger yorumu ─────────────────────────────────────────────────────
    final double bbMid = (bollingerUpper + bollingerLower) / 2;
    final double bbRange = bollingerUpper - bollingerLower;

    final String bbPositionComment;
    if (bbRange == 0) {
      bbPositionComment = 'Bollinger verileri yetersiz';
    } else {
      final double upperThreshold = bbMid + (bollingerUpper - bbMid) * 0.8;
      final double lowerThreshold = bbMid - (bbMid - bollingerLower) * 0.8;
      if (currentPrice > upperThreshold) {
        bbPositionComment =
            'Fiyat üst banda çok yakın (${currentPrice.toStringAsFixed(2)} TL / üst: ${bollingerUpper.toStringAsFixed(2)} TL) — aşırı alım baskısı';
      } else if (currentPrice > bbMid) {
        bbPositionComment =
            'Fiyat orta bandın üstünde (${currentPrice.toStringAsFixed(2)} TL / orta: ${bbMid.toStringAsFixed(2)} TL) — pozitif bölge';
      } else if (currentPrice > lowerThreshold) {
        bbPositionComment =
            'Fiyat orta bandın altında ama henüz alt banda uzak (${currentPrice.toStringAsFixed(2)} TL / orta: ${bbMid.toStringAsFixed(2)} TL)';
      } else {
        bbPositionComment =
            'Fiyat alt banda çok yakın (${currentPrice.toStringAsFixed(2)} TL / alt: ${bollingerLower.toStringAsFixed(2)} TL) — aşırı satım baskısı';
      }
    }

    final String bbVolatilityComment;
    if (bbRange > currentPrice * 0.15) {
      bbVolatilityComment =
          'Bant genişliği: ${bbRange.toStringAsFixed(2)} TL — volatilite yüksek';
    } else if (bbRange > currentPrice * 0.08) {
      bbVolatilityComment =
          'Bant genişliği: ${bbRange.toStringAsFixed(2)} TL — volatilite normal';
    } else {
      bbVolatilityComment =
          'Bant genişliği: ${bbRange.toStringAsFixed(2)} TL — volatilite düşük, sert hareket beklenir';
    }

    // ── Genel öneri sayacı ───────────────────────────────────────────────────
    int buyCount = 0;
    int sellCount = 0;

    if (rsiValue > 50) buyCount++;
    if (rsiValue < 40) sellCount++;
    if (macdValue > macdSignal) { buyCount++; } else { sellCount++; }
    if (currentPrice > bbMid) { buyCount++; } else { sellCount++; }

    final String generalRecommendation;
    if (buyCount >= 2) {
      generalRecommendation = 'AL';
    } else if (sellCount >= 2) {
      generalRecommendation = 'SAT';
    } else {
      generalRecommendation = 'BEKLE';
    }

    // ── Stop-loss: Bollinger alt bandının %1 altı ────────────────────────────
    final double stopLoss = bollingerLower * 0.99;

    // ── Modele gönderilecek hazır analiz notu ───────────────────────────────
    final String analysisNotes = '''
$symbol Hisse Teknik Analiz Notu

Güncel Fiyat: ${currentPrice.toStringAsFixed(2)} TL

RSI Durumu:
$rsiComment

MACD Durumu:
$macdComment
$histogramComment

Bollinger Bantları Durumu:
$bbPositionComment
$bbVolatilityComment
Üst Bant: ${bollingerUpper.toStringAsFixed(2)} TL | Orta Bant: ${bbMid.toStringAsFixed(2)} TL | Alt Bant: ${bollingerLower.toStringAsFixed(2)} TL

Sinyal Özeti:
Alım sinyali sayısı: $buyCount/3 | Satım sinyali sayısı: $sellCount/3

Hesaplanan Öneri: $generalRecommendation
Stop-Loss Seviyesi: ${stopLoss.toStringAsFixed(2)} TL (Bollinger alt bandının %1 altı)
''';

    final String editorSystemPrompt =
        'Sen finansal rapor editörüsün. Sana verilen teknik analiz notlarını '
        'profesyonel, akıcı Türkçe ile yeniden yaz. '
        'Verileri DEĞİŞTİRME, sadece daha okunur ve profesyonel hale getir. '
        'Kendi yorumunu EKLEME, sadece verilen bilgileri düzenle. '
        'Yanıtının en sonuna tam olarak şu iki satırı ekle:\n'
        'ÖNERİ: $generalRecommendation\n'
        'RİSK SEVİYESİ: Düşük | Orta | Yüksek';

    final ollamaResponse = await generate(
      prompt: analysisNotes,
      systemPrompt: editorSystemPrompt,
      options: {
        'num_predict': 1024,
        'num_ctx': 2048,
        'temperature': 0.3,
      },
    );

    return AiAnalysis.fromRawResponse(
      stockSymbol: symbol,
      rawText: ollamaResponse.response,
    );
  }

  /// Portföy genelinde analiz yapar, AiAnalysis döner.
  Future<AiAnalysis> analyzePortfolio({
    required List<Map<String, dynamic>> holdings,
  }) async {
    const systemPrompt = '''
Sen deneyimli bir BIST portföy yöneticisi ve risk analisti­sin.
Verilen portföyü bütünsel olarak değerlendirip Türkçe, net bir analiz sunarsın.
Analizinin sonunda mutlaka şu formatta bir öneri verirsin:
ÖNERİ: AL | SAT | BEKLE
RİSK SEVİYESİ: Düşük | Orta | Yüksek
''';

    final holdingLines = holdings.map((h) {
      final symbol = h['symbol'] ?? '-';
      final quantity = h['quantity'] ?? 0;
      final avgCost = h['averageCost'] ?? 0.0;
      final currentPrice = h['currentPrice'] ?? 0.0;
      final profitLoss = ((currentPrice - avgCost) / avgCost * 100).toStringAsFixed(2);
      return '  - $symbol: $quantity adet, Ort. Maliyet: $avgCost TL, Güncel: $currentPrice TL ($profitLoss%)';
    }).join('\n');

    final prompt = '''
Aşağıdaki BIST portföyünü analiz et:

$holdingLines

Lütfen şunları değerlendir:
1. Portföy çeşitlendirmesi ve sektörel dağılım
2. Kâr/zarar durumu ve momentum
3. Yüksek riskli ve güçlü pozisyonlar
4. Genel portföy sağlığı ve önerilen aksiyon

Analizini tamamladıktan sonra ÖNERİ ve RİSK SEVİYESİ satırlarını ekle.
''';

    final ollamaResponse =
        await generate(prompt: prompt, systemPrompt: systemPrompt);

    return AiAnalysis.fromRawResponse(
      stockSymbol: 'PORTFÖY',
      rawText: ollamaResponse.response,
    );
  }
}
