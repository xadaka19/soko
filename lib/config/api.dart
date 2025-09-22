import 'environment.dart';

class Api {
  static String get baseUrl => Environment.apiBaseUrl;

  // Check if baseUrl already contains /api to avoid duplication
  static bool get _baseUrlHasApi => baseUrl.endsWith('/api');

  // API endpoints - dynamically adjust based on baseUrl
  static String get loginEndpoint =>
      _baseUrlHasApi ? '/login.php' : '/api/login.php';
  static String get registerEndpoint =>
      _baseUrlHasApi ? '/register.php' : '/api/register.php';
  static String get getListingsEndpoint =>
      _baseUrlHasApi ? '/get-listings.php' : '/api/get-listings.php';
  static String get getListingEndpoint =>
      _baseUrlHasApi ? '/get-listing.php' : '/api/get-listing.php';
  static String get getCategoriesEndpoint =>
      _baseUrlHasApi ? '/get-categories.php' : '/api/get-categories.php';
  static String get createListingEndpoint =>
      _baseUrlHasApi ? '/create-listing.php' : '/api/create-listing.php';
  static String get getMessagesEndpoint =>
      _baseUrlHasApi ? '/get-messages.php' : '/api/get-messages.php';
  static String get getMessageThreadEndpoint => _baseUrlHasApi
      ? '/get-message-thread.php'
      : '/api/get-message-thread.php';
  static String get sendMessageEndpoint =>
      _baseUrlHasApi ? '/send-message.php' : '/api/send-message.php';
  static String get markUnavailableEndpoint =>
      _baseUrlHasApi ? '/mark-unavailable.php' : '/api/mark-unavailable.php';
  static String get reportAbuseEndpoint =>
      _baseUrlHasApi ? '/report-abuse.php' : '/api/report-abuse.php';
  static String get callbackRequestEndpoint =>
      _baseUrlHasApi ? '/callback-request.php' : '/api/callback-request.php';
  static String get getPlansEndpoint =>
      _baseUrlHasApi ? '/get-plans.php' : '/api/get-plans.php';
  static String get googleAuthEndpoint =>
      _baseUrlHasApi ? '/google-auth.php' : '/api/google-auth.php';
  static String get registerWithGoogleEndpoint =>
      _baseUrlHasApi ? '/register-google.php' : '/api/register-google.php';
  static String get getProfileEndpoint =>
      _baseUrlHasApi ? '/get-profile.php' : '/api/get-profile.php';
  static String get updateProfileEndpoint =>
      _baseUrlHasApi ? '/update-profile.php' : '/api/update-profile.php';
  static String get getReviewsEndpoint =>
      _baseUrlHasApi ? '/get-reviews.php' : '/api/get-reviews.php';
  static String get submitReviewEndpoint =>
      _baseUrlHasApi ? '/submit-review.php' : '/api/submit-review.php';
  static String get likeReviewEndpoint =>
      _baseUrlHasApi ? '/like-review.php' : '/api/like-review.php';
  static String get reviewCommentsEndpoint =>
      _baseUrlHasApi ? '/review-comments.php' : '/api/review-comments.php';
  static String get uploadProfilePictureEndpoint => _baseUrlHasApi
      ? '/update-profile-picture.php'
      : '/api/update-profile-picture.php';
  static String get getSellerListingsEndpoint => _baseUrlHasApi
      ? '/get-seller-listings.php'
      : '/api/get-seller-listings.php';

  // Search endpoints
  static String get searchEndpoint =>
      _baseUrlHasApi ? '/search.php' : '/api/search.php';
  static String get smartSearchEndpoint => _baseUrlHasApi
      ? '/search/smart-search.php'
      : '/api/search/smart-search.php';
  static String get autocompleteEndpoint => _baseUrlHasApi
      ? '/search/autocomplete.php'
      : '/api/search/autocomplete.php';
  static String get searchHistoryEndpoint =>
      _baseUrlHasApi ? '/search/history.php' : '/api/search/history.php';
  static String get trendingSearchEndpoint =>
      _baseUrlHasApi ? '/search/trending.php' : '/api/search/trending.php';
  static String get categorySuggestionsEndpoint => _baseUrlHasApi
      ? '/search/category-suggestions.php'
      : '/api/search/category-suggestions.php';
  static String get saveSearchHistoryEndpoint => _baseUrlHasApi
      ? '/search/save-history.php'
      : '/api/search/save-history.php';
  static String get getSearchHistoryEndpoint => _baseUrlHasApi
      ? '/search/get-history.php'
      : '/api/search/get-history.php';
  static String get popularCategoriesEndpoint => _baseUrlHasApi
      ? '/search/popular-categories.php'
      : '/api/search/popular-categories.php';
  static String get trackInteractionEndpoint => _baseUrlHasApi
      ? '/search/track-interaction.php'
      : '/api/search/track-interaction.php';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get multipartHeaders => {
    'Accept': 'application/json',
  };
}
