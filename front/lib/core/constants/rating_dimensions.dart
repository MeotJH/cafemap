const Map<String, List<String>> categoryRatingDimensions = {
  '커피': [
    'coffee_quality',
    'acidity_balance',
    'body',
    'aftertaste',
    'temperature',
    'value',
  ],
  '라떼': [
    'coffee_quality',
    'milk_balance',
    'texture',
    'sweetness',
    'temperature',
    'value',
  ],
  '콜드브루': [
    'coffee_quality',
    'clean_finish',
    'body',
    'refreshing',
    'ice_balance',
    'value',
  ],
  '핸드드립': [
    'coffee_quality',
    'aroma',
    'acidity_balance',
    'clarity',
    'aftertaste',
    'value',
  ],
  '시그니처': [
    'signature_balance',
    'coffee_quality',
    'sweetness',
    'texture',
    'visuals',
    'value',
  ],
  '디저트음료': [
    'flavor_balance',
    'sweetness',
    'texture',
    'visuals',
    'portion',
    'value',
  ],
};

const String fallbackRatingCategory = '커피';

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
  return fallbackRatingCategory;
}

List<String> dimensionsForCategory(String? category) {
  return categoryRatingDimensions[normalizeRatingCategory(category)]!;
}

String ratingLabel(String key) {
  return ratingDimensionLabels[key] ?? key;
}
