import '../../models/feedback_item.dart';
import '../../models/mock_user.dart';

class MockDataStore {
  static MockUser? currentUser;
  static List<FeedbackItem> feedbacks = [];
  
  static double getAverageRating() {
    if (feedbacks.isEmpty) return 0.0;
    double sum = feedbacks.fold(0, (prev, item) => prev + item.rating);
    return sum / feedbacks.length;
  }
  
  static int getTotalReviews() {
    return feedbacks.length;
  }
  
  static void addFeedback(FeedbackItem item) {
    feedbacks.insert(0, item);
  }
}