# 📈 BIST Radar

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active%20Development-00D4AA?style=for-the-badge)

**Borsa İstanbul için gerçek zamanlı hisse takip ve teknik analiz uygulaması**

*Real-time stock tracking & technical analysis app for Borsa Istanbul (BIST)*

</div>

---

## 📱 Ekran Görüntüleri / Screenshots

| Splash | Piyasa | Hisse Detay | Portföy |
|:---:|:---:|:---:|:---:|
| Animasyonlu açılış | Canlı fiyatlar + sinyaller | Grafik + Teknik analiz | Gerçek zamanlı K/Z |

---

## ✨ Özellikler / Features

### 📊 Piyasa Ekranı
- **5 saniyelik otomatik güncelleme** — gerçek zamanlı fiyat akışı
- **BIST 100 endeksi** — anlık değer ve günlük değişim
- **Döviz kurları** — USD/TRY ve EUR/TRY canlı takip
- **Hisse arama** — listede olmayan hisseleri de ara, detaya git veya listeye ekle
- **Favori listesi** — ⭐ ile işaretle, tek tıkla filtrele
- **Akıllı sinyal etiketleri** — RSI aşırı satım/alım, MACD pozitif/negatif

### 📉 Teknik Analiz (Hisse Detay)
- **Mum grafiği (Candlestick)** — dokunmatik crosshair ile fiyat okuma
- **Çizgi grafiği** — trend takibi
- **Bollinger Bands** — açılıp kapanabilir volatilite bantları
- **Hacim grafiği** — işlem hacmi analizi
- **RSI (14)** — otomatik yorum ile aşırı alım/satım tespiti
- **MACD** — trend yönü göstergesi
- **Zaman dilimi seçimi** — 1G / 1H / 3A / 6A / 1Y
- **52 Hafta Bandı** — fiyatın yıllık konumunu gösteren progress bar
- **Akıllı sinyal sistemi** — RSI, MACD, BB ve 52 hafta sinyalleri
- **Grafik dokunma (Crosshair)** — parmakla dokunarak fiyat okuma
- **Ortalama maliyet hesaplayıcı** — slider ile ekstra alım simülasyonu

### 💼 Portföy Yönetimi
- Hisse ekleme, düzenleme ve silme
- **Gerçek zamanlı kâr/zarar** — anlık fiyat bazlı hesaplama
- **Toplam portföy değeri** ve maliyet karşılaştırması
- **Pasta grafik** — portföy dağılımı (2+ hisse için)
- Dokunmatik pasta grafik etkileşimi

### 🎨 Tasarım & UX
- **Dark theme** — göz yormayan koyu tema
- **Animasyonlu splash screen** — scale + fade animasyonu
- **Material Design 3** — modern Android arayüzü
- **Alt navigasyon** — Piyasa ve Portföy sekmeleri
- **Pull-to-refresh** — aşağı çekerek yenile

---

## 🛠️ Teknolojiler / Tech Stack

| Teknoloji | Kullanım |
|---|---|
| **Flutter 3.41** | Cross-platform UI framework |
| **Dart** | Programlama dili |
| **Yahoo Finance API** | Gerçek zamanlı borsa verisi |
| **http** | API istekleri |
| **fl_chart** | Çizgi, pasta ve grafik kütüphanesi |
| **CustomPainter** | Mum grafiği, hacim grafiği |

---

## 🚀 Kurulum / Installation

### Gereksinimler
- Flutter SDK 3.x
- Android Studio (emülatör / SDK için)
- VS Code + Flutter & Dart eklentileri

### Adımlar

```bash
# Repoyu klonla
git clone https://github.com/ckaem/bist_radar.git

# Proje klasörüne gir
cd bist_radar

# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  fl_chart: ^0.68.0
```

---

## 📁 Proje Yapısı / Project Structure

```
lib/
├── main.dart                  # Uygulama girişi + ana navigasyon
├── models/
│   └── hisse_model.dart       # Hisse veri modeli
└── screens/
    ├── splash_screen.dart     # Animasyonlu açılış ekranı
    ├── home_screen.dart       # Piyasa ekranı
    ├── detail_screen.dart     # Teknik analiz ekranı
    └── portfolio_screen.dart  # Portföy yönetimi
```

---

## 📡 Veri Kaynağı / Data Source

Uygulama **Yahoo Finance API**'sini kullanmaktadır:

```
https://query1.finance.yahoo.com/v8/finance/chart/{SEMBOL}.IS
```

BIST hisseleri için `.IS` suffix'i kullanılmaktadır.
Örnek: `ISMEN.IS`, `THYAO.IS`, `GARAN.IS`, `KOZAL.IS`

> ⚠️ Yahoo Finance API resmi olarak belgelenmemiş üçüncü taraf kullanım içindir.
> Üretim ortamında lisanslı bir veri sağlayıcı kullanılması önerilir.

---

## 🗺️ Yol Haritası / Roadmap

### ✅ Tamamlanan
- [x] Anlık fiyat güncelleme (5 saniye)
- [x] BIST 100 + USD/TRY + EUR/TRY şeridi
- [x] Hisse arama (listede olmayan hisseler dahil)
- [x] Favori hisseler listesi
- [x] Mum + çizgi grafik
- [x] Bollinger Bands
- [x] Hacim grafiği
- [x] RSI + MACD göstergeleri
- [x] Zaman dilimi seçimi (1G / 1H / 3A / 6A / 1Y)
- [x] 52 Hafta bandı göstergesi
- [x] Akıllı sinyal sistemi (RSI / MACD / BB / 52H)
- [x] Grafik dokunma (crosshair)
- [x] Ortalama maliyet hesaplayıcı
- [x] Portföy gerçek zamanlı kâr/zarar
- [x] Portföy pasta grafik dağılımı
- [x] Portföy düzenleme & silme
- [x] Animasyonlu splash screen

### 🔜 Planlanan
- [ ] Fiyat alarmları ve bildirimler
- [ ] Hisse screener (RSI < 30, 52H dibi filtresi)
- [ ] KAP haber entegrasyonu
- [ ] Hisse karşılaştırma (2 hisseyi aynı grafikte)
- [ ] Stochastic RSI + ATR göstergeleri
- [ ] Portföy geçmiş işlem defteri
- [ ] Ekonomik takvim
- [ ] Google Play yayını

---

## 🤝 Katkı / Contributing

Pull request'ler memnuniyetle karşılanır.

1. Fork'layın
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit'leyin (`git commit -m 'feat: yeni özellik eklendi'`)
4. Push'layın (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

---

## 📄 Lisans / License

Bu proje [MIT](LICENSE) lisansı altında dağıtılmaktadır.

---

## 👨‍💻 Geliştirici / Developer

**Cemil Koca**
- 3. Sınıf Bilgisayar Mühendisliği Öğrencisi
- GitHub: [@ckaem](https://github.com/ckaem)

---

<div align="center">

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

*Built with ❤️ using Flutter*

</div>
