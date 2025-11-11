class FeedbackItem {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final int rating;
  final String feedback;
  final DateTime timestamp;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.feedback,
    required this.timestamp,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory FeedbackItem.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackItem(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userEmail: map['userEmail'] ?? '',
      rating: map['rating'] ?? 0,
      feedback: map['feedback'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}