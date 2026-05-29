enum RankingAudience { couple, wife, husband, user }

enum StoreRankingSort { rating, recent, revisit }

enum RankingMode { stores, menus }

enum ProfileMenuAction { myRecord, login, logout }

enum RankingPurpose { date, conversation, photo, coffee, longStay }

extension RankingPurposeX on RankingPurpose {
  String get queryValue {
    return switch (this) {
      RankingPurpose.date => 'date',
      RankingPurpose.conversation => 'conversation',
      RankingPurpose.photo => 'photo',
      RankingPurpose.coffee => 'coffee',
      RankingPurpose.longStay => 'long_stay',
    };
  }

  String get label {
    return switch (this) {
      RankingPurpose.date => '데이트',
      RankingPurpose.conversation => '대화',
      RankingPurpose.photo => '사진',
      RankingPurpose.coffee => '커피맛',
      RankingPurpose.longStay => '오래 앉기',
    };
  }

  String get homeDescription {
    return switch (this) {
      RankingPurpose.date => '분위기와 맛이 좋은 카페',
      RankingPurpose.conversation => '조용하고 대화하기 편한 카페',
      RankingPurpose.photo => '분위기와 비주얼이 좋은 카페',
      RankingPurpose.coffee => '커피 만족도가 높은 카페',
      RankingPurpose.longStay => '좌석과 실용성이 좋은 카페',
    };
  }

  String title(String districtLabel) {
    final prefix = districtLabel == '전국' ? '' : '$districtLabel ';
    return switch (this) {
      RankingPurpose.date => '$prefix데이트에 좋은 카페',
      RankingPurpose.conversation => '$prefix대화하기 좋은 카페',
      RankingPurpose.photo => '$prefix사진 찍기 좋은 카페',
      RankingPurpose.coffee => '$prefix커피맛 좋은 카페',
      RankingPurpose.longStay => '$prefix오래 앉기 좋은 카페',
    };
  }

  String get rankingDescription {
    return switch (this) {
      RankingPurpose.date => '분위기, 맛 만족도, 다시 가고 싶은 마음을 함께 봅니다.',
      RankingPurpose.conversation => '조용함, 좌석 편안함, 응대 만족도를 함께 봅니다.',
      RankingPurpose.photo => '분위기, 비주얼, 공간 상태를 함께 봅니다.',
      RankingPurpose.coffee => '커피 맛 평가가 좋은 카페부터 보여줍니다.',
      RankingPurpose.longStay => '좌석, 와이파이, 콘센트, 응대 신호를 함께 봅니다.',
    };
  }
}

RankingPurpose? rankingPurposeFromQuery(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'date' => RankingPurpose.date,
    'conversation' => RankingPurpose.conversation,
    'photo' => RankingPurpose.photo,
    'coffee' => RankingPurpose.coffee,
    'long_stay' => RankingPurpose.longStay,
    _ => null,
  };
}

class StoreRankingQuery {
  final RankingAudience audience;
  final RankingPurpose? purpose;

  const StoreRankingQuery({required this.audience, this.purpose});

  @override
  bool operator ==(Object other) {
    return other is StoreRankingQuery &&
        other.audience == audience &&
        other.purpose == purpose;
  }

  @override
  int get hashCode => Object.hash(audience, purpose);
}
