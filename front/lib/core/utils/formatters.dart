// 점수 표현 포맷을 담당한다.
class RatingFormatter {
  // 점수를 소수점 1자리 문자열로 변환한다.
  static String score(double value) => value.toStringAsFixed(1);
}
