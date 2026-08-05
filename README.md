# 🍳 Smart Ingredients & Recipe Generator Mobile App

Smart Ingredients & Recipe Generator, dolabınızda bulunan malzemeleri seçerek veya yeni malzemeleri barkod/veri tabanı doğrulamasıyla ekleyerek kişiselleştirilmiş, yapay zeka destekli yemek tarifleri oluşturmanızı sağlayan modern ve premium tasarımlı bir **Flutter** mobil uygulamasıdır.

Uygulama, malzemelerin yeterlilik durumunu analiz ederek tam tarif üretir; eğer malzemeler yetersizse, en yakın tarifi belirleyip kullanıcıya **1 veya 2 "Kritik Ek Malzeme"** önerisinde bulunur. Ayrıca üretilen tariflerin toplam kalori, protein, yağ ve karbonhidrat makro değerlerini görselleştirilmiş grafiklerle sunar.

---

## ✨ Özellikler (Features)

*   **Malzeme Seçim Paneli:** Sebze, bakliyat, et ürünleri ve süt ürünleri gibi kategorilere ayrılmış modern Chip seçim arayüzü.
*   **Temel Taş Malzemeler (Implicit Defaults):** Tuz, karabiber, pul biber, zeytinyağı, ayçiçek yağı, su, un vb. temel mutfak gereçleri sistemde varsayılan olarak el altında kabul edilir ve tarife otomatik eklenir.
*   **Besin Doğrulama Motoru (Validation Engine):** Serbest metinle yeni bir malzeme eklendiğinde, ücretsiz **Open Food Facts API** üzerinden gerçek zamanlı doğrulama yapılır. Gıda dışı maddeler (Örn: "Masa", "Kalem") elenir ve kullanıcıya uyarı gösterilir.
*   **Yapay Zeka Destekli Tarif & Makro Motoru:** Google Gemini API entegrasyonu ile seçilen malzemelere göre ham JSON şemasında (Structured Output) tarif adımları, hazırlanma süresi ve kalori/makro besin değerleri üretilir.
*   **Eksik Malzeme Öneri Modalı:** Malzemelerin yetersiz olduğu durumlarda ("is_sufficient = false") açılan modal ile kritik eksik malzemeler listelenir ve tek tıkla listeye eklenip tarif yeniden üretilebilir.
*   **Premium Mikro-Animasyonlar:** Tarif hazırlanırken asenkron süreci dinamik olarak gösteren ve her 2 saniyede bir durumu güncelleyen geçişli yüklenme ekranı.
*   **Görsel Makro Grafik Kartı (MacroChart):** Toplam kalori göstergesi ve protein, yağ, karbonhidrat oranlarını dairesel ilerleme çubukları ile sunan premium kart tasarımı.
*   **Modern Light Tema:** Slate 50 arka planı, yumuşak gölgeli beyaz kartlar, teal/indigo marka vurguları ve Outfit tipografisi içeren modern arayüz.

---

## 🛠️ Teknik Mimari (Architecture)

Proje, genişletilebilir ve modüler (Layered & Feature-focused hybrid) bir temiz mimari yapısında kurulmuştur:

*   **Front-End:** Flutter (Dart)
*   **State Management (Durum Yönetimi):** MultiProvider (`provider` paketi)
*   **Besin Doğrulama:** Open Food Facts API (REST JSON search endpoint)
*   **Yapay Zeka Tarif Motoru:** Google Gemini API (`gemini-3.6-flash`, `gemini-3.5-flash` ve `gemini-3.5-flash-lite` modelleri arasında hata durumunda otomatik geçiş yapan **Fallback** altyapısı)
*   **Tasarım Sistemi:** Google Fonts (Outfit) & Flutter Spinkit & Özel Circular Painter oranları

---

## 📂 Proje Klasör Yapısı (Directory Structure)

```
lib/
├── main.dart                      # Uygulama giriş noktası ve Provider tanımlamaları
├── core/
│   ├── constants/
│   │   └── default_ingredients.dart # Temel Taş ve başlangıç malzemeleri
│   ├── theme/
│   │   └── app_theme.dart         # Modern premium Light tema tanımlamaları
│   └── services/
│       └── http_client.dart       # Open Food Facts uyumlu ortak HTTP istemcisi (User-Agent)
├── models/
│   ├── ingredient.dart            # Malzeme veri modeli (kategori, default/custom durumu)
│   └── recipe.dart                # Tarif ve besin değerleri veri modeli
├── services/
│   ├── food_validation_service.dart # Open Food Facts besin sorgulama servisi
│   └── recipe_generator_service.dart # Gemini API prompt kurgusu ve model geçiş servisi
├── providers/
│   ├── ingredient_provider.dart    # Malzeme seçimi ve doğrulama durum yönetimi
│   └── recipe_provider.dart        # API Key ve asenkron tarif oluşturma durum yönetimi
└── views/
    ├── ingredient_selection_screen.dart # Kategori bazlı seçim, arama ve ekleme ekranı
    ├── recipe_detail_screen.dart        # Tarif yapılış adımları ve yüklenme ekranı
    └── widgets/
        ├── macro_chart.dart             # Makro oranlarını gösteren dairesel grafik
        ├── missing_ingredients_modal.dart # Kritik eksik malzemeleri gösteren bottom sheet
        └── settings_dialog.dart         # Gemini API anahtarı kurulum penceresi
```

---

## 🚀 Kurulum ve Çalıştırma (Setup & Run)

Projeyi bilgisayarınızda veya emulatorünüzde çalıştırmak için:

1.  **Depoyu Klonlayın:**
    ```bash
    git clone https://github.com/KULLANICI_ADINIZ/food-cal.git
    cd food-cal
    ```
2.  **Bağımlılıkları Yükleyin:**
    ```bash
    flutter pub get
    ```
3.  **API Anahtarıyla Çalıştırın:**
    Uygulama içerisindeki Tarif Motoru'nun çalışabilmesi için bir Google Gemini API anahtarına ihtiyaç vardır. Anahtarı [Google AI Studio](https://aistudio.google.com/) üzerinden ücretsiz olarak alabilirsiniz.
    
    Uygulamayı çalıştırırken API anahtarını tanımlamak için:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=API_ANAHTARINIZ
    ```
    *Alternatif olarak*, uygulamayı doğrudan `flutter run` ile açıp, sağ üstteki **Ayarlar (Dişli çark)** simgesine tıklayarak API anahtarınızı arayüz üzerinden de kaydedebilirsiniz.

---

## 🔒 Güvenlik (Security Notice)

Uygulamada girilen Gemini API anahtarı hiçbir uzak sunucuya kaydedilmez, doğrudan uygulamanın çalıştığı cihazın hafızasında tutularak Google API uç noktalarına güvenli HTTPS kanalıyla iletilir. Projenizi GitHub'a yüklerken API anahtarınızı kod içerisine sabit (hardcoded) olarak **yazmamanız** önerilir.
