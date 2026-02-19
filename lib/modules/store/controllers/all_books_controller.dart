import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:get/get.dart';

class GetAllBooksController extends GetxController {
  final RxnInt authorId = RxnInt(null);
  final RxList<Book> books = <Book>[].obs;
  final RxInt currentPage = 1.obs;
  final RxString errorMessage = ''.obs;
  final RxnBool finished = RxnBool(null);
  final RxnInt genreId = RxnInt(null);
  final RxBool hasMore = true.obs;
  var isGridView = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnBool myBooks = RxnBool(null);
  final RxInt pageSize = 20.obs;
  final RxnBool recentOpened = RxnBool(null);
  final RxnBool recommended = RxnBool(null);
  final RxString searchQuery = ''.obs;
  var selectedBooks = <String>[].obs;
  final RxnBool topOfTheWeek = RxnBool(null);
  final RxInt totalCount = 0.obs;
  final RxnString wantsTo = RxnString(null);
  final RxnBool withAudio = RxnBool(null);

  final NetworkManager _networkManager = Get.find<NetworkManager>();

  @override
  @override
  void onClose() {
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchBooks({
    String? search,
    int? authorIdFilter,
    int? genreIdFilter,
    bool? topOfTheWeekFilter,
    bool? recommendedFilter,
    String? wantsToFilter,
    bool? recentOpenedFilter,
    bool? myBooksFilter,
    bool? finishedFilter,
    bool? withAudioFilter,
    bool resetPagination = true,
  }) async {
    try {
      if (resetPagination) {
        currentPage.value = 1;
        hasMore.value = true;
        isLoading.value = true;
        books.clear();

        searchQuery.value = search ?? '';
        authorId.value = authorIdFilter;
        genreId.value = genreIdFilter;
        topOfTheWeek.value = topOfTheWeekFilter;
        recommended.value = recommendedFilter;
        wantsTo.value = wantsToFilter;
        recentOpened.value = recentOpenedFilter;
        myBooks.value = myBooksFilter;
        myBooks.value = myBooksFilter;
        finished.value = finishedFilter;
        withAudio.value = withAudioFilter;
      } else {
        isLoadingMore.value = true;
      }

      errorMessage.value = '';

      final Map<String, String> queryParameters = {
        'page': currentPage.value.toString(),
        'size': pageSize.value.toString(),
      };

      if (searchQuery.value.isNotEmpty) {
        queryParameters['search'] = searchQuery.value;
      }
      if (authorId.value != null) {
        queryParameters['author_id'] = authorId.value.toString();
      }
      if (genreId.value != null) {
        queryParameters['genre_id'] = genreId.value.toString();
      }
      if (topOfTheWeek.value != null) {
        queryParameters['top_of_the_week'] = topOfTheWeek.value.toString();
      }
      if (recommended.value != null) {
        queryParameters['recommended'] = recommended.value.toString();
      }
      if (wantsTo.value != null && wantsTo.value!.isNotEmpty) {
        queryParameters['wants_to'] = wantsTo.value!;
      }
      if (recentOpened.value != null) {
        queryParameters['recent_opened'] = recentOpened.value.toString();
      }

      if (finished.value != null) {
        queryParameters['finished'] = finished.value.toString();
      }
      if (withAudio.value != null) {
        queryParameters['with_audio'] = withAudio.value.toString();
      }

      final response = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: queryParameters,
      );

      if (response['success']) {
        final data = response['data'];
        if (data != null && data is Map<String, dynamic>) {
          final List<dynamic> items = data['items'] ?? [];
          final int total = data['totalCount'] ?? 0;
          final int page = data['page'] ?? 1;

          totalCount.value = total;

          final newBooks = items.map((json) => Book.fromJson(json)).toList();

          if (topOfTheWeek.value == true) {}

          if (recommended.value == true) {}

          if (resetPagination) {
            books.value = newBooks;
          } else {
            books.addAll(newBooks);
          }

          hasMore.value = (page * pageSize.value) < total;
        } else {
          errorMessage.value = 'Invalid response format';
        }
      } else {
        errorMessage.value = response['error'] ?? 'Failed to fetch books';
      }
    } catch (e) {
      Future.microtask(() {
        errorMessage.value = 'An error occurred: $e';
      });
    } finally {
      Future.microtask(() {
        isLoading.value = false;
        isLoadingMore.value = false;
      });
    }
  }

  Future<void> loadMoreBooks() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) {
      return;
    }

    currentPage.value++;
    await fetchBooks(
      search: searchQuery.value.isEmpty ? null : searchQuery.value,
      authorIdFilter: authorId.value,
      genreIdFilter: genreId.value,
      topOfTheWeekFilter: topOfTheWeek.value,
      recommendedFilter: recommended.value,
      wantsToFilter: wantsTo.value,
      recentOpenedFilter: recentOpened.value,
      myBooksFilter: myBooks.value,
      finishedFilter: finished.value,
      resetPagination: false,
    );
  }

  Future<void> getAllBooks() async {
    await fetchBooks(
      search: null,
      authorIdFilter: null,
      genreIdFilter: null,
      topOfTheWeekFilter: null,
      recommendedFilter: null,
      wantsToFilter: null,
      recentOpenedFilter: null,
      myBooksFilter: null,
      finishedFilter: null,
      withAudioFilter: null,
      resetPagination: true,
    );
  }

  Future<void> getBooksByGenre(int genreIdParam) async {
    await fetchBooks(
      genreIdFilter: genreIdParam,
      resetPagination: true,
    );
  }

  Future<void> getBooksByAuthor(int authorIdParam) async {
    await fetchBooks(
      authorIdFilter: authorIdParam,
      resetPagination: true,
    );
  }

  Future<void> searchBooks(String query) async {
    await fetchBooks(
      search: query,
      resetPagination: true,
    );
  }

  Future<void> getTopOfTheWeekBooks() async {
    await fetchBooks(
      topOfTheWeekFilter: true,
      resetPagination: true,
    );
  }

  Future<void> getRecommendedBooks() async {
    await fetchBooks(
      recommendedFilter: true,
      resetPagination: true,
    );
  }

  Future<void> getBooksWantToRead() async {
    await fetchBooks(
      wantsToFilter: 'read',
      resetPagination: true,
    );
  }

  Future<void> getBooksWantToListen() async {
    await fetchBooks(
      wantsToFilter: 'listen',
      resetPagination: true,
    );
  }

  Future<void> getFinishedBooks() async {
    await fetchBooks(
      wantsToFilter: 'finished',
      resetPagination: true,
    );
  }

  Future<void> getAudioBooks() async {
    await fetchBooks(
      withAudioFilter: true,
      resetPagination: true,
    );
  }

  Future<void> getRecentlyOpenedBooks() async {
    await fetchBooks(
      recentOpenedFilter: true,
      resetPagination: true,
    );
  }

  Future<void> getMyBooks() async {
    await fetchBooks(
      myBooksFilter: true,
      resetPagination: true,
    );
  }

  Future<void> searchBooksWithFilters({
    String? search,
    int? authorIdFilter,
    int? genreIdFilter,
    bool? topOfTheWeekFilter,
    bool? recommendedFilter,
    String? wantsToFilter,
    bool? recentOpenedFilter,
    bool? myBooksFilter,
    bool? finishedFilter,
    bool? withAudioFilter,
  }) async {
    await fetchBooks(
      search: search,
      authorIdFilter: authorIdFilter,
      genreIdFilter: genreIdFilter,
      topOfTheWeekFilter: topOfTheWeekFilter,
      recommendedFilter: recommendedFilter,
      wantsToFilter: wantsToFilter,
      recentOpenedFilter: recentOpenedFilter,
      myBooksFilter: myBooksFilter,
      finishedFilter: finishedFilter,
      withAudioFilter: withAudioFilter,
      resetPagination: true,
    );
  }

  void clearFilters() {
    searchQuery.value = '';
    authorId.value = null;
    genreId.value = null;
    topOfTheWeek.value = null;
    recommended.value = null;
    wantsTo.value = null;
    recentOpened.value = null;
    myBooks.value = null;
    finished.value = null;
    withAudio.value = null;
  }

  Future<void> refreshBooks() async {
    await fetchBooks(
      search: searchQuery.value.isEmpty ? null : searchQuery.value,
      authorIdFilter: authorId.value,
      genreIdFilter: genreId.value,
      topOfTheWeekFilter: topOfTheWeek.value,
      recommendedFilter: recommended.value,
      wantsToFilter: wantsTo.value,
      recentOpenedFilter: recentOpened.value,
      myBooksFilter: myBooks.value,
      finishedFilter: finished.value,
      withAudioFilter: withAudio.value,
      resetPagination: true,
    );
  }

  int getActiveFiltersCount() {
    int count = 0;
    if (searchQuery.value.isNotEmpty) count++;
    if (authorId.value != null) count++;
    if (genreId.value != null) count++;
    if (topOfTheWeek.value != null) count++;
    if (recommended.value != null) count++;
    if (wantsTo.value != null && wantsTo.value!.isNotEmpty) count++;
    if (recentOpened.value != null) count++;
    if (myBooks.value != null) count++;
    if (finished.value != null) count++;
    if (withAudio.value != null) count++;
    return count;
  }

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      authorId.value != null ||
      genreId.value != null ||
      topOfTheWeek.value != null ||
      recommended.value != null ||
      (wantsTo.value != null && wantsTo.value!.isNotEmpty) ||
      recentOpened.value != null ||
      myBooks.value != null ||
      finished.value != null ||
      withAudio.value != null;

  Book? getBookById(int id) {
    try {
      return books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }
}
