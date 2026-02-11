import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';

class LibraryMainController extends GetxController {
  final GetStorage _box = GetStorage();
  final String _lastOpenedBookKey = 'lastOpenedBook';

  Rx<Book?> lastOpenedBook = Rx<Book?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadLastOpenedBook();
  }

  void _loadLastOpenedBook() {
    final bookData = _box.read<Map<String, dynamic>>(_lastOpenedBookKey);
    if (bookData != null) {
      lastOpenedBook.value = Book.fromJson(bookData);
    }
  }

  void setLastOpenedBook(Book book) {
    lastOpenedBook.value = book;
    _box.write(_lastOpenedBookKey, book.toJson());
  }

  void clearLastOpenedBook() {
    lastOpenedBook.value = null;
    _box.remove(_lastOpenedBookKey);
  }

  @override
  void onClose() {
    // Clear last opened book reference
    lastOpenedBook.value = null;

    super.onClose();
  }
}
