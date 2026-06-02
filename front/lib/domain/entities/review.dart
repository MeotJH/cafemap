class ReviewMediaItem {
  final String type;
  final String url;
  final String thumbnailUrl;
  final int? durationMs;

  const ReviewMediaItem({
    required this.type,
    required this.url,
    this.thumbnailUrl = '',
    this.durationMs,
  });

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'durationMs': durationMs,
      };
}

class Review {
  final String id;
  final String storeName;
  final String address;
  final String placeId;
  final String link;
  final double? lat;
  final double? lng;
  final String brandId;
  final String temperatureOption;
  final String brandName;
  final String menuName;
  final String menuCategory;
  final String userEmail;
  final String reviewerType;
  final int ratingSchemaVersion;
  final Map<String, double> scores;
  final Map<String, String> attributes;
  final double overall;
  final String comment;
  final List<String> imageUrls;
  final List<ReviewMediaItem> mediaItems;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.storeName,
    required this.address,
    required this.placeId,
    required this.link,
    this.lat,
    this.lng,
    required this.brandId,
    required this.temperatureOption,
    required this.brandName,
    required this.menuName,
    required this.menuCategory,
    required this.userEmail,
    required this.reviewerType,
    required this.ratingSchemaVersion,
    required this.scores,
    required this.attributes,
    required this.overall,
    required this.comment,
    required this.imageUrls,
    required this.mediaItems,
    required this.createdAt,
  });
}
