import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tmdb_movie.dart';
import '../models/tmdb_series.dart';
class TmdbService {
  static const String _apiKey = '57240db50c2008e78c261e1a934627e4';
  static const String _baseUrl = 'https://api.tmdb.org/3';

  static Future<List<TmdbMovie>> _fetch(String endpoint, [Map<String, String>? queryParams]) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: {
      'api_key': _apiKey,
      ...?queryParams,
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
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
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('TMDB Error: $e');
      rethrow;
    }
  }

  static Future<List<TmdbMovie>> _fetchWithRetry(String endpoint, [Map<String, String>? queryParams, int retries = 3]) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        return await _fetch(endpoint, queryParams);
      } catch (e) {
        debugPrint('TMDB Attempt $attempt failed: $e');
        if (attempt == retries) rethrow;
        // Wait before retrying (1s, 2s, 3s...)
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return [];
  }

  static Future<List<TmdbMovie>> getTrending() => _fetchWithRetry('/trending/all/day');
  static Future<List<TmdbMovie>> getAction() => _fetchWithRetry('/discover/movie', {'with_genres': '28'});
  static Future<List<TmdbMovie>> getDrama() => _fetchWithRetry('/discover/movie', {'with_genres': '18'});
  static Future<List<TmdbMovie>> getSciFi() => _fetchWithRetry('/discover/movie', {'with_genres': '878'});
  static Future<List<TmdbMovie>> getHorror() => _fetchWithRetry('/discover/movie', {'with_genres': '27'});
  static Future<List<TmdbMovie>> getComedy() => _fetchWithRetry('/discover/movie', {'with_genres': '35'});
  
  // Generic Fetch by Genre
  static Future<List<TmdbMovie>> getByGenre(String genreId, {bool isTv = false}) => 
      _fetchWithRetry(isTv ? '/discover/tv' : '/discover/movie', {'with_genres': genreId});

  // TV Series
  static Future<List<TmdbMovie>> getPopularSeries() => _fetchWithRetry('/tv/popular');
  static Future<List<TmdbMovie>> getActionSeries() => _fetchWithRetry('/discover/tv', {'with_genres': '10759'});
  static Future<List<TmdbMovie>> getSciFiSeries() => _fetchWithRetry('/discover/tv', {'with_genres': '10765'});
  static Future<List<TmdbMovie>> getCrimeSeries() => _fetchWithRetry('/discover/tv', {'with_genres': '80'});
  
  static Future<List<TmdbMovie>> search(String query) => _fetchWithRetry('/search/multi', {'query': query});

  // Series Details
  static Future<List<TmdbSeason>> getTvSeasons(int tvId) async {
    final uri = Uri.parse('$_baseUrl/tv/$tvId').replace(queryParameters: {'api_key': _apiKey});
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
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
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
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
