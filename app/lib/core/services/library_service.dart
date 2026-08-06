// lib/core/services/library_service.dart

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import '../constants/app_constants.dart';
import '../data/repositories.dart';

export '../../models/document_model.dart';

class LibraryService {
  LibraryService._();

  /// Cache daftar dokumen tanpa filter — dipakai beberapa layar sekaligus
  /// (pustaka, bookmark, kartu peraturan di dashboard).
  static List<Document>? _cachedDocs;

  static void clearCache() => _cachedDocs = null;

  static Future<List<DocCategory>> getCategories() =>
      Repos.library.getCategories();

  static Future<List<Document>> getDocuments({
    String? query,
    String? categoryId,
    String? type,
  }) async {
    final unfiltered = query == null && categoryId == null && type == null;
    if (unfiltered && _cachedDocs != null) return _cachedDocs!;

    final docs = await Repos.library.getDocuments(
      query: query,
      categoryId: categoryId,
      type: type,
    );
    if (unfiltered) _cachedDocs = docs;
    return docs;
  }

  static Future<Document?> getDocument(String id) =>
      Repos.library.getDocument(id);

  // ── Bookmark — selalu lokal, tidak ikut backend ─────────────────────────────

  static Future<bool> isBookmarked(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(StorageKeys.bookmarks) ?? []).contains(docId);
  }

  static Future<void> setBookmark(String docId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(StorageKeys.bookmarks) ?? [];
    if (value) {
      if (!bookmarks.contains(docId)) bookmarks.add(docId);
    } else {
      bookmarks.remove(docId);
    }
    await prefs.setStringList(StorageKeys.bookmarks, bookmarks);
  }

  static Future<List<Document>> getBookmarkedDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(StorageKeys.bookmarks) ?? [];
    if (ids.isEmpty) return [];
    final allDocs = await getDocuments();
    return allDocs.where((d) => ids.contains(d.id)).toList();
  }
}
