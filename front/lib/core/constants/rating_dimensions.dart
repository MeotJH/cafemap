const Map<String, List<String>> categoryRatingDimensions = {
  'coffee': [
    'coffee_quality',
    'acidity_balance',
    'body',
    'aftertaste',
    'temperature',
    'value',
  ],
  'latte': [
    'coffee_quality',
    'milk_balance',
    'texture',
    'sweetness',
    'temperature',
    'value',
  ],
  'cold_brew': [
    'coffee_quality',
    'clean_finish',
    'body',
    'refreshing',
    'ice_balance',
    'value',
  ],
  'hand_drip': [
    'coffee_quality',
    'aroma',
    'acidity_balance',
    'clarity',
    'aftertaste',
    'value',
  ],
  'tea': [
    'flavor_balance',
    'sweetness',
    'texture',
    'visuals',
    'portion',
    'value',
  ],
  'dessert': [
    'flavor_balance',
    'sweetness',
    'texture',
    'visuals',
    'portion',
    'value',
  ],
};

const Map<String, String> ratingCategoryAliases = {
  'coffee': 'coffee',
  '커피': 'coffee',
  'latte': 'latte',
  '라떼': 'latte',
  'cold_brew': 'cold_brew',
  'coldbrew': 'cold_brew',
  '콜드브루': 'cold_brew',
  'hand_drip': 'hand_drip',
  'handdrip': 'hand_drip',
  '핸드드립': 'hand_drip',
  'tea': 'tea',
  '차': 'tea',
  'signature': 'coffee',
  '시그니처': 'coffee',
  'dessert': 'dessert',
  '디저트': 'dessert',
  '디저트음료': 'dessert',
};

const Map<String, String> ratingCategoryLabels = {
  'coffee': '커피',
  'latte': '라떼',
  'cold_brew': '콜드브루',
  'hand_drip': '핸드드립',
  'tea': '차',
  'dessert': '디저트',
};

const String fallbackRatingCategory = 'coffee';

const Set<String> temperatureSelectableCategories = {
  'coffee',
  'latte',
  'tea',
  'hand_drip',
};

const List<String> storeExperienceDimensions = [
  'atmosphere',
  'work_friendly',
  'quietness',
  'seat_comfort',
  'outlet_access',
  'wifi_quality',
  'service',
  'revisit_intent',
];

const Map<String, String> ratingDimensionLabels = {
  'coffee_quality': '원두 품질',
  'acidity_balance': '산미 밸런스',
  'body': '바디감',
  'aftertaste': '여운',
  'temperature': '온도 만족도',
  'value': '가성비',
  'milk_balance': '우유 밸런스',
  'texture': '질감',
  'sweetness': '단맛 밸런스',
  'clean_finish': '깔끔함',
  'refreshing': '청량감',
  'ice_balance': '얼음 비율',
  'aroma': '향',
  'clarity': '클린컵',
  'signature_balance': '시그니처 완성도',
  'visuals': '비주얼',
  'flavor_balance': '맛 조화',
  'portion': '양',
  'atmosphere': '분위기',
  'work_friendly': '작업하기 좋음',
  'quietness': '조용함',
  'seat_comfort': '좌석 편안함',
  'outlet_access': '콘센트 접근성',
  'wifi_quality': '와이파이',
  'service': '응대',
  'revisit_intent': '재방문 의사',
};

String normalizeRatingCategory(String? category) {
  final value = (category ?? '').trim();
  if (categoryRatingDimensions.containsKey(value)) return value;
  final alias = ratingCategoryAliases[value];
  if (alias != null && categoryRatingDimensions.containsKey(alias)) {
    return alias;
  }
  return fallbackRatingCategory;
}

List<String> dimensionsForCategory(String? category) {
  return categoryRatingDimensions[normalizeRatingCategory(category)]!;
}

String ratingCategoryLabel(String? category) {
  final normalized = normalizeRatingCategory(category);
  return ratingCategoryLabels[normalized] ?? normalized;
}

String ratingLabel(String key) {
  return ratingDimensionLabels[key] ?? key;
}
