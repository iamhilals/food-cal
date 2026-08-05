import '../../models/ingredient.dart';

const List<String> kImplicitIngredients = [
  'Tuz',
  'Karabiber',
  'Pul Biber',
  'Zeytinyağı',
  'Ayçiçek Yağı',
  'Su',
  'Un',
  'Sarımsak',
  'Kuru Soğan',
  'Salça',
];

final List<Ingredient> kInitialIngredients = [
  // Sebzeler
  Ingredient(id: 'domates', name: 'Domates', category: 'Sebzeler'),
  Ingredient(id: 'patates', name: 'Patates', category: 'Sebzeler'),
  Ingredient(id: 'biber', name: 'Biber', category: 'Sebzeler'),
  Ingredient(id: 'havuc', name: 'Havuç', category: 'Sebzeler'),
  Ingredient(id: 'ispanak', name: 'Ispanak', category: 'Sebzeler'),
  Ingredient(id: 'patlican', name: 'Patlıcan', category: 'Sebzeler'),
  Ingredient(id: 'kabak', name: 'Kabak', category: 'Sebzeler'),
  
  // Bakliyatlar
  Ingredient(id: 'kirmizi_mercimek', name: 'Kırmızı Mercimek', category: 'Bakliyatlar'),
  Ingredient(id: 'nohut', name: 'Nohut', category: 'Bakliyatlar'),
  Ingredient(id: 'kuru_fasulye', name: 'Kuru Fasulye', category: 'Bakliyatlar'),
  Ingredient(id: 'pirinc', name: 'Pirinç', category: 'Bakliyatlar'),
  Ingredient(id: 'bulgur', name: 'Bulgur', category: 'Bakliyatlar'),

  // Et & Balık Ürünleri
  Ingredient(id: 'tavuk_gogsu', name: 'Tavuk Göğsü', category: 'Et & Balık Ürünleri'),
  Ingredient(id: 'dana_kiyma', name: 'Dana Kıyma', category: 'Et & Balık Ürünleri'),
  Ingredient(id: 'kusbasi_et', name: 'Kuşbaşı Dana Eti', category: 'Et & Balık Ürünleri'),
  Ingredient(id: 'ton_baligi', name: 'Ton Balığı', category: 'Et & Balık Ürünleri'),

  // Süt Ürünleri
  Ingredient(id: 'sut', name: 'Süt', category: 'Süt Ürünleri'),
  Ingredient(id: 'yogurt', name: 'Yoğurt', category: 'Süt Ürünleri'),
  Ingredient(id: 'beyaz_peynir', name: 'Beyaz Peynir', category: 'Süt Ürünleri'),
  Ingredient(id: 'kasar_peyniri', name: 'Kaşar Peyniri', category: 'Süt Ürünleri'),
  Ingredient(id: 'tereyagi', name: 'Tereyağı', category: 'Süt Ürünleri'),

  // Diğer
  Ingredient(id: 'yumurta', name: 'Yumurta', category: 'Diğer'),
  Ingredient(id: 'makarna', name: 'Makarna', category: 'Diğer'),
  Ingredient(id: 'mantar', name: 'Mantar', category: 'Diğer'),
  Ingredient(id: 'limon', name: 'Limon', category: 'Diğer'),
];
