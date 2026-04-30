class TmdbMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String overview;
  final bool isTvShow;

  TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.overview,
    this.isTvShow = false,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    // Robust detection for TV Shows
    final bool isTv = json['media_type'] == 'tv' || 
                      json.containsKey('name') || 
                      json.containsKey('first_air_date') || 
                      json.containsKey('original_name');
                      
    return TmdbMovie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      overview: json['overview'] ?? '',
      isTvShow: isTv,
    );
  }

  String get posterUrl => posterPath != null 
      ? 'https://image.tmdb.org/t/p/w500$posterPath' 
      : '';
      
  String get backdropUrl => backdropPath != null 
      ? 'https://image.tmdb.org/t/p/original$backdropPath' 
      : posterUrl;
}
