# 🍳 Smart Ingredients & Recipe Generator Mobile & Web App

[![Live Demo](https://img.shields.io/badge/demo-live%20web-teal?style=for-the-badge&logo=flutter)](https://iamhilals.github.io/food-cal/)

Smart Ingredients & Recipe Generator, dolabınızda bulunan malzemeleri seçerek, kamera ile çoklu rafları tarayarak veya yeni malzemeleri barkod/veri tabanı doğrulamasıyla ekleyerek kişiselleştirilmiş, yapay zeka destekli yemek tarifleri oluşturmanızı sağlayan modern, zengin özellikli ve premium tasarımlı bir **Flutter** mobil ve web uygulamasıdır.

🔗 **Canlı Web Demosunu Hemen Deneyin:** [https://iamhilals.github.io/food-cal/](https://iamhilals.github.io/food-cal/)

---

## ✨ Özellikler (Features)

*   **📸 AI Vision Çoklu Fotoğraf Analizi (Multi-Image Scan):** Dolabınızın veya malzemelerinizin birden fazla fotoğrafını arka arkaya çekebilir ya da galeriden çoklu görseller seçebilirsiniz. Toplanan tüm görseller Gemini Vision API'ye tek istekte gönderilerek tüm malzemeler ortaklaşa saptanıp sepetinize otomatik seçili olarak eklenir.
*   **🔌 Web-Scraping ETL Tarif İçe Aktarıcı (ETL Importer):** Herhangi bir yemek tarifi web sayfasının bağlantısını (URL) yapıştırarak içeriğini kazıyabilir (scraping), regex ile temizleyebilir (transform) ve Gemini API aracılığıyla yapısal model nesnemize dönüştürerek (load) tarif defterinize ekleyebilirsiniz.
*   **📅 Haftalık Menü Planlayıcı & Birleşik Alışveriş Sepeti:** 7 günlük (Pazartesi-Pazar) yatay planlama takvimi ile defterinizdeki tarifleri günlere atayabilirsiniz. Tek tıkla takvimdeki tüm tariflerin malzemeleri regex süzgeciyle porsiyon ve miktarlardan arındırılarak (örn. *"2 adet yumurta"* ve *"3 adet yumurta"* -> *"Yumurta"*) akıllıca birleştirilir ve çift kayıt oluşmadan tek sepet halinde alışveriş listenize yüklenir.
*   **🛒 Alışveriş Listesi Akıllı Gruplama (Reyon Kategorileri):** Market listenizdeki ürünler isimlerine göre otomatik olarak market reyonlarına (*Manav 🍎*, *Süt Ürünleri 🥛*, *Kasap & Şarküteri 🥩*, *Kuru Gıda & Baharat 🌾*, *Diğer*) ayrıştırılır ve reyon başlıkları altında düzenli bir şekilde listelenir.
*   **🗣️ Sesli Asistan Hız ve Ton Kontrolü (Speech Settings):** Mutfakta eller serbest kullanım sağlayan sesli asistan ekranına yerleştirilen *"Asistan Ses Ayarları"* panelinden konuşma hızını (`0.3x` - `1.2x`) ve ses tonu perdesini slider çubuklarıyla anlık değiştirebilirsiniz.
*   **⏱️ Adım İçi Akıllı Zamanlayıcı (Step Timer):** Tarif adımlarında geçen süre ifadeleri (örn: *"15 dakika"*, *"30 saniye"*) regex motoru tarafından otomatik olarak yakalanır. Adımın yanındaki kronometre simgesine tıklandığında durdurulabilir/başlatılabilir şık bir dairesel geri sayım zamanlayıcısı açılır.
*   **👥 Porsiyon Ayarlayıcı / Tarif Ölçekleyici:** Tarif detay ekranında porsiyon sayısını değiştirdiğinizde (`[-] X Porsiyon [+]`), malzemelerin miktarları ve tarifin toplam kalori/makro besin değerleri matematiksel olarak anlık olarak yeniden ölçeklenir.
*   **🍊 Şefin Atık Önleme Tavsiyesi (Zero-Waste Tips):** Üretilen her tarifin altında şefin o tarife özel artan malzemeleri nasıl saklayabileceğinizi veya değerlendirebileceğinizi açıklayan yeşil kart tasarımlı *"Şefin Sıfır Atık Tavsiyesi 🌿"* yer alır.
*   **📖 Mini Mutfak Terimleri Sözlüğü (Culinary Tooltips):** Tarif adımlarında geçen aşçılık terimleri (örn: *"sotelemek"*, *"benmari"*, *"jülyen"*) tespit edilerek renkli vurgulanır. Vurgulu kelimeye dokunulduğunda o terimin profesyonel mutfak tanımını sunan bir tooltip penceresi gösterilir.
*   **Besin Doğrulama Motoru (Validation Engine):** Serbest metinle yeni bir malzeme eklendiğinde, **Open Food Facts API** üzerinden gerçek zamanlı doğrulama yapılarak gıda dışı maddeler (örn. "Masa", "Kalem") engellenir.
*   **Görsel Makro Grafik Kartı (MacroChart):** Toplam kalori ve protein, yağ, karbonhidrat oranlarını dairesel ilerleme çubukları ile sunan premium kart tasarımı.

---

## 🛠️ Teknik Mimari (Architecture)

Proje, genişletilebilir ve modüler (Layered & Feature-focused hybrid) bir temiz mimari yapısında kurulmuştur:

*   **Front-End:** Flutter (Dart Web & Mobile)
*   **State Management (Durum Yönetimi):** MultiProvider (`provider` paketi)
*   **Besin Doğrulama:** Open Food Facts API (REST JSON search endpoint)
*   **Yapay Zeka Tarif Motoru:** Google Gemini API (`gemini-3.6-flash` ve `gemini-3.5-flash` modelleri arasında hata durumunda otomatik geçiş yapan **Fallback** altyapısı)
*   **Tasarım Sistemi:** Slate 50 arka planı, yumuşak gölgeli koyu/açık kartlar, teal/indigo marka vurguları ve Google Fonts (Outfit) tipografisi.

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
│   ├── ingredient.dart            # Malzeme veri modeli (kategori, durumlar)
│   └── recipe.dart                # Tarif ve besin değerleri veri modeli (ingredients, wasteTip)
├── services/
│   ├── food_validation_service.dart # Open Food Facts besin sorgulama servisi
│   └── recipe_generator_service.dart # Gemini API prompt kurgusu, scraping ve model geçiş servisi
├── providers/
│   ├── ingredient_provider.dart    # Malzeme seçimi, doğrulama ve vision durum yönetimi
│   └── recipe_provider.dart        # API Key, geçmiş tarifler ve haftalık plan yönetimi
└── views/
    ├── ingredient_selection_screen.dart # Kategori bazlı seçim, çoklu fotoğraf tarama ekranı
    ├── recipe_history_screen.dart       # Tarif defteri, URL içe aktarma ve haftalık takvim görünümü
    ├── recipe_detail_screen.dart        # Adım zamanlayıcı, porsiyon ölçekleyici detay ekranı
    ├── voice_cooking_screen.dart        # Sesli asistan ve ses ayar sliderları paneli
    ├── shopping_list_screen.dart        # Akıllı gruplanmış reyon bazlı alışveriş listesi
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
    git clone https://github.com/iamhilals/food-cal.git
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

Uygulamada girilen Gemini API anahtarı hiçbir uzak sunucuya kaydedilmez, doğrudan uygulamanın çalıştığı cihazın hafızasında (veya tarayıcının `localStorage` alanında) tutularak Google API uç noktalarına güvenli HTTPS kanalıyla iletilir. Projenizi GitHub'a yüklerken API anahtarınızı kod içerisine sabit (hardcoded) olarak **yazmamanız** önerilir.
