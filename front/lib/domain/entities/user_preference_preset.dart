class UserPreferencePreset {
  final String id;
  final String label;
  final String description;
  final int iconCodePoint;
  final List<String> scoreKeys;
  final List<String> reasonLabels;
  final String matchMode;
  final bool enabled;

  const UserPreferencePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.iconCodePoint,
    required this.scoreKeys,
    required this.reasonLabels,
    this.matchMode = 'average',
    this.enabled = true,
  });
}

const List<UserPreferencePreset> defaultUserPreferencePresets = [
  UserPreferencePreset(
    id: 'quiet_place',
    label: '조용한 곳',
    description: '소음이 적고 차분한 카페',
    iconCodePoint: 0xe050,
    scoreKeys: ['quietness'],
    reasonLabels: ['조용함'],
  ),
  UserPreferencePreset(
    id: 'work_friendly',
    label: '작업하기 좋은 곳',
    description: '오래 머물며 작업하기 편한 카페',
    iconCodePoint: 0xe31f,
    scoreKeys: ['work_friendly'],
    reasonLabels: ['작업 적합성'],
  ),
  UserPreferencePreset(
    id: 'good_atmosphere',
    label: '분위기가 좋은 곳',
    description: '공간 분위기와 무드가 좋은 카페',
    iconCodePoint: 0xe57f,
    scoreKeys: ['atmosphere'],
    reasonLabels: ['분위기'],
  ),
  UserPreferencePreset(
    id: 'good_coffee',
    label: '커피 맛이 좋은 곳',
    description: '기본적인 커피 완성도가 좋은 카페',
    iconCodePoint: 0xe541,
    scoreKeys: ['coffee_quality'],
    reasonLabels: ['커피 맛'],
  ),
  UserPreferencePreset(
    id: 'good_value',
    label: '가성비가 좋은 곳',
    description: '가격 대비 만족도가 높은 카페',
    iconCodePoint: 0xe227,
    scoreKeys: ['value'],
    reasonLabels: ['가성비'],
  ),
  UserPreferencePreset(
    id: 'kind_service',
    label: '응대가 친절한 곳',
    description: '서비스와 응대 만족도가 높은 카페',
    iconCodePoint: 0xe7fd,
    scoreKeys: ['service'],
    reasonLabels: ['응대'],
  ),
  UserPreferencePreset(
    id: 'seat_comfortable',
    label: '좌석이 편안한 곳',
    description: '오래 앉아 있어도 불편하지 않은 카페',
    iconCodePoint: 0xe637,
    scoreKeys: ['seat_comfort'],
    reasonLabels: ['좌석 편안함'],
  ),
];
