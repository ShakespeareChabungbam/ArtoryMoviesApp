import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tmdb_movie.dart';
import '../models/tmdb_series.dart';
class TmdbService {
  static const String _apiKey = '57240db50c2008e78c261e1a934627e4';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Future<List<TmdbMovie>> _fetch(String endpoint, [Map<String, String>? queryParams]) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: {
      'api_key': _apiKey,
      ...?queryParams,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        
        final parsedMovies = <TmdbMovie>[];
        for (var item in results) {
          if (item['poster_path'] != null) {
            try {
              parsedMovies.add(TmdbMovie.fromJson(item));
            } catch (e) {
              debugPrint('TMDB Parse Error (Movie): $e');
            }
          }
        }
        return parsedMovies;
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Error: $e');
      return [];
    }
  }

  static Future<List<TmdbMovie>> getTrending() => _fetch('/trending/all/day');
  static Future<List<TmdbMovie>> getAction() => _fetch('/discover/movie', {'with_genres': '28'});
  static Future<List<TmdbMovie>> getDrama() => _fetch('/discover/movie', {'with_genres': '18'});
  static Future<List<TmdbMovie>> getSciFi() => _fetch('/discover/movie', {'with_genres': '878'});
  static Future<List<TmdbMovie>> getHorror() => _fetch('/discover/movie', {'with_genres': '27'});
  static Future<List<TmdbMovie>> getComedy() => _fetch('/discover/movie', {'with_genres': '35'});
  
  // Generic Fetch by Genre
  static Future<List<TmdbMovie>> getByGenre(String genreId, {bool isTv = false}) => 
      _fetch(isTv ? '/discover/tv' : '/discover/movie', {'with_genres': genreId});

  // TV Series
  static Future<List<TmdbMovie>> getPopularSeries() => _fetch('/tv/popular');
  static Future<List<TmdbMovie>> getActionSeries() => _fetch('/discover/tv', {'with_genres': '10759'}); // Action & Adventure
  static Future<List<TmdbMovie>> getSciFiSeries() => _fetch('/discover/tv', {'with_genres': '10765'}); // Sci-Fi & Fantasy
  static Future<List<TmdbMovie>> getCrimeSeries() => _fetch('/discover/tv', {'with_genres': '80'}); // Crime (Money Heist)
  
  static Future<List<TmdbMovie>> search(String query) => _fetch('/search/multi', {'query': query});

  // Series Details
  static Future<List<TmdbSeason>> getTvSeasons(int tvId) async {
    final uri = Uri.parse('$_baseUrl/tv/$tvId').replace(queryParameters: {'api_key': _apiKey});
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List seasons = data['seasons'] ?? [];
        
        final parsedSeasons = <TmdbSeason>[];
        for (var item in seasons) {
          try {
            final season = TmdbSeason.fromJson(item);
            if (season.seasonNumber > 0) {
              parsedSeasons.add(season);
            }
          } catch (e) {
            debugPrint('TMDB Parse Error (Season): $e');
          }
        }
        return parsedSeasons;
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Error (Seasons): $e');
      return [];
    }
  }

  static Future<List<TmdbEpisode>> getTvEpisodes(int tvId, int seasonNumber) async {
    final uri = Uri.parse('$_baseUrl/tv/$tvId/season/$seasonNumber').replace(queryParameters: {'api_key': _apiKey});
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List episodes = data['episodes'] ?? [];
        
        final parsedEpisodes = <TmdbEpisode>[];
        for (var item in episodes) {
          try {
            parsedEpisodes.add(TmdbEpisode.fromJson(item));
          } catch (e) {
            debugPrint('TMDB Parse Error (Episode): $e');
          }
        }
        return parsedEpisodes;
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Error (Episodes): $e');
      return [];
    }
  }
}
