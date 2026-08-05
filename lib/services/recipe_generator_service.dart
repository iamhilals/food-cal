import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/default_ingredients.dart';
import '../models/recipe.dart';

class RecipeGeneratorService {
  /// Generates a recipe using Google Gemini API.
  /// Receives [selectedIngredients] and the user's [apiKey].
  Future<Recipe> generateRecipe({
    required List<String> selectedIngredients,
    required String apiKey,
    String dietProfile = '',
    List<String> allergens = const [],
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API Anahtarı eksik. Lütfen ayarlardan bir API anahtarı ekleyin.');
    }

    // List of active models in order of priority
    final List<String> modelCandidates = [
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3.5-flash-lite',
    ];

    final prompt = _buildPrompt(selectedIngredients, dietProfile, allergens);
    Exception? lastException;

    for (var model in modelCandidates) {
      final String url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      try {
        debugPrint('Trying Gemini model: $model...');
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
            }
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final String? textResponse =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];

          if (textResponse != null) {
            final cleanedJson = _cleanResponseText(textResponse);
            final Map<String, dynamic> recipeJson = json.decode(cleanedJson);
            debugPrint('Successfully generated recipe using model: $model');
            return Recipe.fromJson(recipeJson);
          }
        } else {
          final errorJson = json.decode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'API Hatası';
          debugPrint('Model $model failed with status ${response.statusCode}: $errorMessage');
          lastException = Exception('Gemini API Hatası (${response.statusCode}): $errorMessage');
        }
      } catch (e) {
        debugPrint('Model $model threw exception: $e');
        lastException = Exception('Tarif oluşturulurken bir sorun oluştu: $e');
      }
    }

    throw lastException ?? Exception('Tüm yapay zeka modelleri başarısız oldu.');
  }

  /// Builds the prompt with explicit instruction to return a JSON matching the Recipe schema.
  String _buildPrompt(List<String> selectedIngredients, String dietProfile, List<String> allergens) {
    final String dietRules = dietProfile.isNotEmpty 
        ? '\n- KULLANICININ DİYETİ: $dietProfile. Tarif kesinlikle bu diyete/beslenme profiline %100 UYGUN OLMAK zorundadır.' 
        : '';
    final String allergenRules = allergens.isNotEmpty 
        ? '\n- KULLANICININ ALERJİLERİ: ${allergens.join(", ")}. Tarif kesinlikle bu alerjenleri ve bunları içeren veya bunlardan üretilen hiçbir malzemeyi İÇERMEMELİDİR.' 
        : '';

    return '''
Sen profesyonel bir şefsin. Sana verilen seçili malzemeler ve temel mutfak malzemeleri (varsayılan olarak el altında bulunan) listesini kullanarak Türkçe bir yemek tarifi oluşturmalısın.
$dietRules$allergenRules

Seçilen Malzemeler: ${selectedIngredients.join(', ')}
Varsayılan Temel Taş Malzemeler (El altında olduğu varsayılır, seçilmemiş olsalar bile kullanılabilir): ${kImplicitIngredients.join(', ')}

Kurallar:
1. Seçilen malzemeler ve temel taş malzemeler birlikte mantıklı ve lezzetli bir yemek yapmaya YETİYORSA:
   - "is_sufficient" alanını true yap.
   - "missing_ingredients" listesini boş bırak [].
   - Tarifin adımlarını, süresini ve adını oluştur.
2. Seçilen malzemeler tek başına (temel taşlar dahil) bir yemek yapmaya YETMİYORSA:
   - En yakın uyumlu tarifi belirle.
   - Bu tarifi yapabilmek için gereken 1 veya 2 adet "Kritik Ek Malzeme" tespit et (Örn: Seçilenler mercimek ve patates ise, mercimek çorbası için et suyu veya tereyağı eksik olabilir veya sebze yemeği için tavuk gerekebilir).
   - Tespit ettiğin eksik malzemeleri "missing_ingredients" listesine ekle.
   - "is_sufficient" alanını false yap.
   - Tarifin adını, adımlarını ve süresini eksik malzemeler de varmış gibi oluştur (kullanıcıya bu yemeği nasıl yapacağını göstermek için).
3. Tarifin malzemelerini net miktarlarıyla birlikte "ingredients" listesine ekle (Örn: "2 adet yumurta", "1.5 su bardağı süt", "100g un").
4. Tarifte kullanılan malzemelerin porsiyon miktarlarına göre toplam besin değerlerini (Kalori kcal, Protein g, Yağ g, Karbonhidrat g) hesapla.
5. Tarif veya kullanılan malzemeler hakkında eğlenceli, esprili, iştah kabartan ve motive edici bir şef yorumu ("chef_comment") yaz. (Örn: "Mercimeğin patatesle olan muhteşem aşkı! Şef der ki: Yanına bol köpüklü bir ayran ve taze naneli salata çok yakışır!")
6. Yanıtı MUTLAKA aşağıdaki JSON şemasına uygun olarak döndür. Yanıt sadece ham JSON olmalıdır, markdown kod blokları (```json vb.) içermemelidir:

{
  "recipe_name": "Tarif Adı",
  "prep_time": "30 dakika",
  "ingredients": [
    "2 su bardağı kırmızı mercimek",
    "1 adet kuru soğan",
    "1 yemek kaşığı tereyağı"
  ],
  "steps": [
    "Adım 1: ...",
    "Adım 2: ..."
  ],
  "calories": 350.0,
  "protein": 15.0,
  "fat": 10.0,
  "carbohydrates": 45.0,
  "is_sufficient": true veya false,
  "missing_ingredients": ["Malzeme 1", "Malzeme 2"],
  "chef_comment": "Şefin esprili ve eğlenceli mutfak notu"
}
''';
  }

  /// Helper to remove potential markdown JSON wrappers from the response.
  String _cleanResponseText(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```json\s*', caseSensitive: false), '');
      cleaned = cleaned.replaceAll(RegExp(r'^```\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\s*```$'), '');
    }
    return cleaned.trim();
  }

  /// Analyzes a base64-encoded image and returns a list of detected food ingredients.
  Future<List<String>> detectIngredientsFromImage({
    required String base64Image,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API Anahtarı eksik. Lütfen ayarlardan bir API anahtarı ekleyin.');
    }

    final List<String> modelCandidates = [
      'gemini-3.5-flash',
      'gemini-3.6-flash',
    ];

    Exception? lastException;

    for (var model in modelCandidates) {
      try {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [
              {
                'parts': [
                  {
                    'text': 'Bu görseldeki veya fotoğraftaki yiyecek/yemek malzemelerini tespit et ve sadece Türkçe isimlerini ham bir JSON listesi olarak döndür. Örnek çıktı formatı: ["domates", "biber", "yumurta"]. Yanıtta markdown kod bloğu (```json gibi) veya açıklama bulunmamalıdır, sadece ham JSON listesi döndür.'
                  },
                  {
                    'inlineData': {
                      'mimeType': 'image/jpeg',
                      'data': base64Image
                    }
                  }
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final text = candidates[0]['content']['parts'][0]['text'] as String?;
            if (text != null) {
              final cleaned = _cleanResponseText(text);
              final List decoded = json.decode(cleaned);
              return decoded.map((e) => e.toString().trim()).toList();
            }
          }
        } else {
          final errorJson = json.decode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'API Hatası';
          debugPrint('Multimodal model $model failed with status ${response.statusCode}: $errorMessage');
          lastException = Exception('Gemini API Hatası (${response.statusCode}): $errorMessage');
        }
      } catch (e) {
        debugPrint('Multimodal model $model threw exception: $e');
        lastException = Exception('Fotoğraf analiz edilirken sorun oluştu: $e');
      }
    }

    throw lastException ?? Exception('Tüm yapay zeka modelleri görsel analizinde başarısız oldu.');
  }

  /// Simplifies a commercial product name into a general ingredient name using Gemini.
  Future<String> simplifyProductName({
    required String productName,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty || productName.isEmpty) return productName;

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Ticari gıda ürünü ismi: "$productName". Bu gıdanın genel, sade ve markasız Türkçe karşılığını tek veya en fazla iki kelimeyle döndür. Örn: "Pınar Süzme Süzme Peynir 500g" -> "Peynir", "Filiz Burgu Makarna" -> "Makarna", "Tat Domates Salçası 830g" -> "Salça". Yanıt sadece sade isimden oluşmalı, başka hiçbir açıklama veya markdown içermemelidir.'
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String?;
          if (text != null) {
            return text.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Error simplifying product name: $e');
    }
    return productName; // fallback
  }

  /// HTML temizleme yardimcisi (Script, style ve tagleri temizler)
  String _extractTextFromHtml(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  /// URL uzerinden tarifi ceker (Extract), temizler, Gemini ile yapilandirir (Transform) ve Recipe nesnesi doner.
  Future<Recipe> importRecipeFromUrl({
    required String url,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API Anahtarı eksik. Lütfen ayarlardan bir API anahtarı ekleyin.');
    }

    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      throw Exception('Lütfen geçerli bir internet bağlantısı girin.');
    }

    // 1. EXTRACT (Veri Çekme)
    String pageHtml;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        pageHtml = response.body;
      } else {
        throw Exception('Sayfa yüklenemedi (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Web sayfası çekilirken hata oluştu: $e');
    }

    final cleanedText = _extractTextFromHtml(pageHtml);
    final truncatedText = cleanedText.length > 12000 ? cleanedText.substring(0, 12000) : cleanedText;

    // 2. TRANSFORM (Dönüştürme)
    final List<String> modelCandidates = [
      'gemini-3.5-flash',
      'gemini-3.6-flash',
    ];

    Exception? lastException;

    for (var model in modelCandidates) {
      try {
        final apiUri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
        
        final prompt = '''
Sana ham ve kazınmış bir web sayfasının metin içeriği verilecek. Bu metinden yemek tarifini analiz et ve aşağıdaki bilgileri Türkçe olarak çıkartarak bir JSON yapısı oluştur.

Yemek Tarifi Metni:
"""
$truncatedText
"""

Kurallar:
1. "recipe_name" alanına yemeğin adını yaz.
2. "prep_time" alanına hazırlama ve pişirme süresini yaz (Örn: "45 dakika").
3. "ingredients" listesine tarifte kullanılan tüm malzemeleri ve net miktarlarını ekle (Örn: "2 adet yumurta", "1.5 su bardağı süt", "100g un").
4. "steps" listesine tarifin yapılış adımlarını sırasıyla ekle.
5. Tarifin porsiyon bazlı yaklaşık besin değerlerini hesapla (Kalori kcal, Protein g, Yağ g, Karbonhidrat g). Eğer metinde yazmıyorsa malzemelere göre şef bilgisiyle tahmin et.
6. "is_sufficient" alanını true yap.
7. "missing_ingredients" listesini boş bırak [].
8. Tarif için eğlenceli ve samimi bir şef yorumu ("chef_comment") yaz.
9. Yanıtı MUTLAKA aşağıdaki JSON şemasına uygun olarak döndür. Yanıt sadece ham JSON olmalıdır, markdown kod blokları (```json vb.) içermemelidir:

{
  "recipe_name": "Tarif Adı",
  "prep_time": "30 dakika",
  "ingredients": [
    "Malzeme 1 (Örn: 2 adet yumurta)",
    "Malzeme 2 (Örn: 100g un)"
  ],
  "steps": [
    "Adım 1: ...",
    "Adım 2: ..."
  ],
  "calories": 350.0,
  "protein": 15.0,
  "fat": 10.0,
  "carbohydrates": 45.0,
  "is_sufficient": true,
  "missing_ingredients": [],
  "chef_comment": "Şefin esprili ve eğlenceli mutfak notu"
}
''';

        final response = await http.post(
          apiUri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final text = candidates[0]['content']['parts'][0]['text'] as String?;
            if (text != null) {
              final cleaned = _cleanResponseText(text);
              final decoded = json.decode(cleaned);
              return Recipe.fromJson(decoded);
            }
          }
        } else {
          final errorJson = json.decode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'API Hatası';
          debugPrint('Model $model failed with status ${response.statusCode}: $errorMessage');
          lastException = Exception('Gemini API Hatası (${response.statusCode}): $errorMessage');
        }
      } catch (e) {
        debugPrint('Model $model threw exception: $e');
        lastException = Exception('Tarif dönüştürülürken hata oluştu: $e');
      }
    }

    throw lastException ?? Exception('Tarif dönüştürme işlemi başarısız oldu.');
  }
}
