import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tmdb_movie.dart';

class WatchHistoryItem {
  final TmdbMovie movie;
  final DateTime watchedAt;

  WatchHistoryItem({required this.movie, required this.watchedAt});

  Map<String, dynamic> toJson() => {
    'id': movie.id,
    'title': movie.title,
    'poster_path': movie.posterPath,
    'backdrop_path': movie.backdropPath,
    'vote_average': movie.voteAverage,
    'overview': movie.overview,
    'media_type': movie.isTvShow ? 'tv' : 'movie',
    'watched_at': watchedAt.toIso8601String(),
  };

  static WatchHistoryItem fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      movie: TmdbMovie.fromJson(json),
      watchedAt: DateTime.tryParse(json['watched_at'] ?? '') ?? DateTime.now(),
    );
  }
}

final watchHistoryProvider =
    StateNotifierProvider<WatchHistoryNotifier, List<WatchHistoryItem>>((ref) {
  return WatchHistoryNotifier();
});

class WatchHistoryNotifier extends StateNotifier<List<WatchHistoryItem>> {
  WatchHistoryNotifier() : super([]) {
    _load();
  }

  static const _key = 'watch_history';
  static const _maxItems = 20;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final List decoded = jsonDecode(data);
        state = decoded.map((e) => WatchHistoryItem.fromJson(e)).toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_key, data);
  }

  /// Adds or bumps a movie to the top of the history list.
  Future<void> addToHistory(TmdbMovie movie) async {
    // Remove existing entry for this movie (to move it to top)
    final updated = state.where((e) => e.movie.id != movie.id).toList();
    updated.insert(
      0,
      WatchHistoryItem(movie: movie, watchedAt: DateTime.now()),
    );
    // Keep only most recent _maxItems
    state = updated.take(_maxItems).toList();
    await _save();
  }

  Future<void> removeFromHistory(int movieId) async {
    state = state.where((e) => e.movie.id != movieId).toList();
    await _save();
  }

  bool isWatched(int movieId) => state.any((e) => e.movie.id == movieId);
}
