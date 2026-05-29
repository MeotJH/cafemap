const int legacyRatingSchemaVersion = 1;
const int currentRatingSchemaVersion = 2;

const Map<String, List<String>> v1CategoryRatingDimensions = {
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

const List<String> v2CoffeeDimensions = [
  'taste_satisfaction',
  'aroma',
  'body',
  'clean_finish',
  'aftertaste',
  'value',
];

const List<String> v2LatteDimensions = [
  'taste_satisfaction',
  'coffee_presence',
  'milk_balance',
  'texture',
  'aftertaste',
  'value',
];

const Map<String, List<String>> v2CategoryRatingDimensions = {
  'coffee': v2CoffeeDimensions,
  'latte': v2LatteDimensions,
  'cold_brew': v2CoffeeDimensions,
  'hand_drip': [
    'taste_satisfaction',
    'aroma',
    'clean_finish',
    'aftertaste',
    'body',
    'value',
  ],
  'tea': [
    'taste_satisfaction',
    'aroma',
    'clean_finish',
    'aftertaste',
    'portion',
    'value',
  ],
  'dessert': [
    'taste_satisfaction',
    'texture',
    'visuals',
    'portion',
    'value',
  ],
};

const Map<String, List<String>> categoryRatingDimensions =
    v1CategoryRatingDimensions;

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
  'cold_brew',
  'tea',
  'hand_drip',
};

const List<String> v1StoreExperienceDimensions = [
  'atmosphere',
  'work_friendly',
  'quietness',
  'seat_comfort',
  'outlet_access',
  'wifi_quality',
  'service',
  'revisit_intent',
];

const List<String> v2StoreExperienceDimensions = [
  'atmosphere',
  'quietness',
  'seat_comfort',
  'restroom_cleanliness',
  'service',
  'revisit_intent',
];

const List<String> storeExperienceDimensions = v1StoreExperienceDimensions;

const Map<String, String> v1RatingDimensionLabels = {
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

final Map<String, String> v2RatingDimensionLabels = {
  ...v1RatingDimensionLabels,
  'taste_satisfaction': '맛 만족도',
  'value': '가격 만족도',
  'coffee_presence': '커피 맛',
  'restroom_cleanliness': '화장실 청결',
};

const Map<String, String> ratingDimensionLabels = v1RatingDimensionLabels;

const Map<String, List<String>> v2MenuAttributeKeys = {
  'coffee': ['flavor_profile', 'roast_level', 'temperature_option'],
  'latte': ['temperature_option', 'sweetness_level'],
  'cold_brew': ['flavor_profile', 'roast_level', 'temperature_option'],
  'hand_drip': ['flavor_profile', 'roast_level', 'temperature_option'],
  'tea': ['temperature_option', 'sweetness_level'],
  'dessert': ['sweetness_level'],
};

const List<String> v2StoreAttributeKeys = [
  'outlet_available',
  'wifi_usable',
];

const Map<String, String> ratingAttributeLabels = {
  'flavor_profile': '맛 성향',
  'roast_level': '로스팅',
  'sweetness_level': '단맛 정도',
  'temperature_option': '온도',
  'outlet_available': '콘센트',
  'wifi_usable': '와이파이',
};

const Map<String, Map<String, String>> ratingAttributeValueLabels = {
  'flavor_profile': {
    'acidic': '산미',
    'balanced': '균형',
    'nutty': '고소',
    'unknown': '잘 모르겠음',
  },
  'roast_level': {
    'light': '라이트',
    'medium': '미디엄',
    'dark': '다크',
    'unknown': '잘 모르겠음',
  },
  'sweetness_level': {
    'low': '덜 달게',
    'medium': '적당히 달게',
    'high': '달게',
    'unknown': '잘 모르겠음',
  },
  'temperature_option': {
    'hot': 'HOT',
    'ice': 'ICE',
    'unspecified': '미선택',
  },
  'outlet_available': {
    'yes': '콘센트 있음',
    'no': '콘센트 없음',
    'unknown': '잘 모르겠음',
  },
  'wifi_usable': {
    'good': '와이파이 좋음',
    'bad': '와이파이 아쉬움',
    'not_used': '안 써봄',
    'unknown': '잘 모르겠음',
  },
};

int normalizeRatingSchemaVersion(int? schemaVersion) {
  if ((schemaVersion ?? legacyRatingSchemaVersion) >=
      currentRatingSchemaVersion) {
    return currentRatingSchemaVersion;
  }
  return legacyRatingSchemaVersion;
}

String normalizeRatingCategory(String? category) {
  final value = (category ?? '').trim();
  if (v1CategoryRatingDimensions.containsKey(value)) return value;
  final alias = ratingCategoryAliases[value];
  if (alias != null && v1CategoryRatingDimensions.containsKey(alias)) {
    return alias;
  }
  return fallbackRatingCategory;
}

Map<String, List<String>> _categoryDimensionsForSchema(int schemaVersion) {
  return normalizeRatingSchemaVersion(schemaVersion) == currentRatingSchemaVersion
      ? v2CategoryRatingDimensions
      : v1CategoryRatingDimensions;
}

List<String> dimensionsForCategory(String? category) {
  return dimensionsForCategoryForSchema(category, legacyRatingSchemaVersion);
}

List<String> dimensionsForCategoryForSchema(
  String? category,
  int schemaVersion,
) {
  final normalized = normalizeRatingCategory(category);
  return _categoryDimensionsForSchema(schemaVersion)[normalized]!;
}

List<String> storeDimensionsForSchema(
  int schemaVersion, {
  bool includeOptional = false,
}) {
  final _ = includeOptional;
  if (normalizeRatingSchemaVersion(schemaVersion) != currentRatingSchemaVersion) {
    return v1StoreExperienceDimensions;
  }
  return v2StoreExperienceDimensions;
}

List<String> menuAttributeKeysForCategory(String? category) {
  final normalized = normalizeRatingCategory(category);
  return v2MenuAttributeKeys[normalized] ?? const [];
}

List<String> visibleMenuAttributeKeysForCategory(String? category) {
  return menuAttributeKeysForCategory(category)
      .where((key) => key != 'temperature_option')
      .toList();
}

String ratingCategoryLabel(String? category) {
  final normalized = normalizeRatingCategory(category);
  return ratingCategoryLabels[normalized] ?? normalized;
}

String ratingLabel(String key) {
  return ratingLabelForSchema(key, legacyRatingSchemaVersion);
}

String ratingLabelForSchema(String key, int schemaVersion) {
  final labels =
      normalizeRatingSchemaVersion(schemaVersion) == currentRatingSchemaVersion
          ? v2RatingDimensionLabels
          : v1RatingDimensionLabels;
  return labels[key] ?? key;
}

String attributeLabel(String key) {
  return ratingAttributeLabels[key] ?? key;
}

String attributeValueLabel(String key, String value) {
  return ratingAttributeValueLabels[key]?[value] ?? value;
}

String defaultAttributeValue(String key) {
  if (key == 'temperature_option') return 'unspecified';
  if (key == 'wifi_usable') return 'not_used';
  return 'unknown';
}
