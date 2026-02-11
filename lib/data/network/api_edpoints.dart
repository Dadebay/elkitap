class ApiEndpoints {
  static const String baseUrl = 'https://api.elkitap.com.tm';
  static const String imageBaseUrl = 'https://storage.elkitap.com.tm';

  // Auth endpoints
  static const String sendCode = '/users/send-code';
  static const String verifyCode = '/users/verify-login';
  static const String getMe = '/users/me';
  static const String updateUser = '/users';
  static const String updateFcmToken = '/users/fcm-token';
  static const String contacts = '/contacts';

  // Geners endpoints
  static const String geners = '/genres/all';

  // Authors endpoints
  static const String searchAuthors = '/authors/search';
  static String authorDetail(int id) => '/authors/$id';

  // Book endpoints
  static const String allBooks = '/books/all';
  static const String allCollections = '/collections/all';
  static const String wantsToCount = '/books/wants-to-count';
  static const String suggests = '/suggests';
  static const String mySuggestions = '/suggests/my';

  // Book detail
  static String bookDetail(int bookId) => '/books/$bookId';
  static String bookProgress(int bookId) => '/books/$bookId/progress';
  static String audioHlsKey(int bookTranslateId) =>
      '/books/audio-hls-key/$bookTranslateId';

  // Like a book
  static String bookLike(int id) => '/books/$id/like';
  static String bookUnlike(int likedBookId) => '/books/unlike/$likedBookId';

  // Notes endpoints
  static const String addNote = '/users/notes';
  static const String getNotes = '/users/notes';
  static const String deleteNote = '/users/notes';

  // Problems endpoint
  static const String reportProblem = '/problems';

  // Promo codes endpoint
  static const String promoCodes = '/users/promo-codes';

  // Tariffs endpoint
  static const String tariffs = '/payments/tariffs';

  // Banks endpoint
  static const String banks = '/payments/banks';

  // Orders endpoint
  static const String orders = '/payments/orders';

  // Payment history endpoint
  static const String paymentHistory = '/payments/my';

  // Check payment status endpoint
  static const String paymentIsActive = '/payments/is-active';

  // Get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
