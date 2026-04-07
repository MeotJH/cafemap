// 항목별 평점 분해 데이터를 표현하는 엔티티다.
class RatingBreakdown {
  final Map<String, double> scores;
  final double overall;

  const RatingBreakdown({
    required this.scores,
    required this.overall,
  });
}
