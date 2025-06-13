class Movie {
  final int id;
  final String title;
  final String backDropPath;
  final String? posterPath;
  final String overview;

  Movie({
     required this.id,
    required this.title,
    required this.backDropPath,
    this.posterPath,
    required this.overview,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      backDropPath: json['backdrop_path'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'backDropPath': backDropPath,
      'posterPath': posterPath, 
      'overview': overview,
    };
  }
}
