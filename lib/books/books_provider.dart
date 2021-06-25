import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:leaf/books/books_service.dart';

import 'models/book.dart';

class BooksProvider with ChangeNotifier{
  late BooksService booksService;
  final int _pageSize;

  BooksProvider(this.booksService, [this._pageSize = 10]);

  factory BooksProvider.basic(){
    return BooksProvider(BooksService(FirebaseFirestore.instance));
  }

  List<Book> _books = [];
  List<Book> _cachedBooks = [];
  Map<String, dynamic> _bookTitles = {};
  var _isLoading = true;
  var _isError = false;
  var _isSearch = false;
  late StreamSubscription _booksSubscription;
  StreamSubscription? _bookTitlesSubscription;

  // getters
  List<Book> get books => [..._books];
  Map<String, dynamic> get bookTitles => {..._bookTitles};
  bool get isLoading => _isLoading;
  bool get isError => _isError;
  bool get isSearch => _isSearch;

  
  /// Subsbribe to the book stream, Should be called in the [init state] method of the page
  /// from where it is called, stores the result in [books] then calls [fetchBookTitles]
  /// if an error accours the stream will be canceled, and we will set [isError]
  void fetchBooks() {
    // get original first batch of books
    final stream = booksService.fetchBooks(_pageSize);
    _booksSubscription = stream.listen(
      (books) {
        _books = books;
        fetchBookTitles();
      },
      onError: (error) {
        print('Error fetching books $error');
        _isError = true;
        _isLoading = false;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  /// refetch books when an error occurs, reset [loading] and [error]
  /// then call [fetchBooks] again to remake the stream 
  void reFetchBooks() async{
    _isLoading = true;
    _isError = false;
    notifyListeners();
    fetchBooks();
  }

  /// fetch more books, starts with setting a [silent loader] so that the method does 
  /// not get called again. Check if [books] is empty or [isError] or [isSearch] is set
  /// add fetched books at the end of [books], catch errors if any and return
  Future<void> fetchMoreBooks() async {
    // only get called one time and not on error or in a search
    // Aslo if no lastBook to start from, needs to return
    if (_books.isEmpty || _isError || _isSearch) {
      return;
    }

    List<Book> moreBooks;
    try{
      moreBooks = await booksService.fetchMoreBooks(_pageSize);
    } catch (error){
      print('Failed to fetch more books: $error');
      return;
    }
    // add them the end of the messages list
    _books.addAll(moreBooks);
    notifyListeners();
  }

  /// Subscbribe to the book titles stream, should only be called from [fetchBooks]
  /// store the result in [bookTitles] and stop [loading] if an error accours 
  /// the stream will be canceled, and we will set [isError]
  void fetchBookTitles() {
    // get book titles
    final stream = booksService.fetchBookTitles();
    _bookTitlesSubscription = stream.listen(
      (bookTitles) {
        _bookTitles = bookTitles;
        _isError = false;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error feteching book titles $error');
        _isError = true;
        _isLoading = false;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  
  /// Searches for all books matching a certain title from [firebase] and sets [isSearch] flag
  /// if successfull lists the found books in [books] and cashe prevoius books in [cashedBooks]
  /// to be restored when search is cleared, do not store prevoius searches
  /// if an error occurs sets [isError]
  Future<void> fetchSearchedBook(String title) async {
    // only store the loaded books, when not searching
    // else on double search you get the previous search
    if (!_isSearch){
      _cachedBooks = _books;
    }
    // get books that fits a cetain title
    _isSearch = true;
    _isLoading = true;
    notifyListeners();
    try{
      _books = await booksService.searchBooksByTitle(title);
    } catch (error){
      print('Failed to fetch books: $error');
      _isError = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Restores the [chashed books], when a search is called
  /// and turns off [isSearch] flag
  void clearSearch(){
    _isLoading = true;
    _isSearch = false;
    notifyListeners();
    _books = _cachedBooks;
    _isLoading = false;
    notifyListeners();
  }

  /// Dispose when the provider is destroyed, cancel the book subscription
  @override
  void dispose() async {
    super.dispose();
    await _booksSubscription.cancel();
    await _bookTitlesSubscription?.cancel();
  }
}