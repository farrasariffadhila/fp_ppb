class Movie {
  final int id;
  final String title;
  final String backDropPath;
  final String? posterPath;

  Movie({
     required this.id,
    required this.title,
    required this.backDropPath,
    this.posterPath,
  });

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      backDropPath: map['backdrop_path'] ?? '',
      posterPath: map['poster_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'backDropPath': backDropPath,
      'posterPath': posterPath, 
    };
  }
}
