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
3. Tarifte kullanılan malzemelerin porsiyon miktarlarına göre toplam besin değerlerini (Kalori kcal, Protein g, Yağ g, Karbonhidrat g) hesapla.
4. Tarif veya kullanılan malzemeler hakkında eğlenceli, esprili, iştah kabartan ve motive edici bir şef yorumu ("chef_comment") yaz. (Örn: "Mercimeğin patatesle olan muhteşem aşkı! Şef der ki: Yanına bol köpüklü bir ayran ve taze naneli salata çok yakışır!")
5. Yanıtı MUTLAKA aşağıdaki JSON şemasına uygun olarak döndür. Yanıt sadece ham JSON olmalıdır, markdown kod blokları (```json vb.) içermemelidir:

{
  "recipe_name": "Tarif Adı",
  "prep_time": "30 dakika",
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
}
