import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tmdb_movie.dart';

final myListProvider = StateNotifierProvider<MyListNotifier, List<TmdbMovie>>((ref) {
  return MyListNotifier();
});

class MyListNotifier extends StateNotifier<List<TmdbMovie>> {
  MyListNotifier() : super([]) {
    _loadList();
  }

  Future<void> _loadList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('my_list');
    if (data != null) {
      final List decoded = jsonDecode(data);
      final List<TmdbMovie> movies = decoded.map((e) => TmdbMovie.fromJson(e)).toList();
      state = movies;
    }
  }

  Future<void> _saveList() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(state.map((m) => {
      'id': m.id,
      'title': m.title,
      'poster_path': m.posterPath,
      'backdrop_path': m.backdropPath,
      'vote_average': m.voteAverage,
      'overview': m.overview,
      'media_type': m.isTvShow ? 'tv' : 'movie',
    }).toList());
    await prefs.setString('my_list', data);
  }

  void toggleMovie(TmdbMovie movie) {
    if (state.any((m) => m.id == movie.id)) {
      state = state.where((m) => m.id != movie.id).toList();
    } else {
      state = [...state, movie];
    }
    _saveList();
  }

  bool isInList(int id) {
    return state.any((m) => m.id == id);
  }
}
