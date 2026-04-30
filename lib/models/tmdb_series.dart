class TmdbSeason {
  final int seasonNumber;
  final String name;
  final int episodeCount;

  TmdbSeason({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
  });

  factory TmdbSeason.fromJson(Map<String, dynamic> json) {
    return TmdbSeason(
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'] ?? 'Unknown Season',
      episodeCount: json['episode_count'] ?? 0,
    );
  }
}

class TmdbEpisode {
  final int episodeNumber;
  final String name;
  final String overview;
  final String? stillPath;
  final double voteAverage;
  final int? runtime;

  TmdbEpisode({
    required this.episodeNumber,
    required this.name,
    required this.overview,
    this.stillPath,
    required this.voteAverage,
    this.runtime,
  });

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) {
    return TmdbEpisode(
      episodeNumber: json['episode_number'] ?? 0,
      name: json['name'] ?? 'Unknown Episode',
      overview: json['overview'] ?? '',
      stillPath: json['still_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      runtime: json['runtime'],
    );
  }

  String get stillUrl => stillPath != null 
      ? 'https://image.tmdb.org/t/p/w500$stillPath' 
      : '';
}
