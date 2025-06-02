import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fp_ppb/Model/model.dart';

class APIservices {
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  late final String nowShowingApi =
      "https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey";
  late final String upComingApi =
      "https://api.themoviedb.org/3/movie/upcoming?api_key=$apiKey";
  late final String popularApi =
      "https://api.themoviedb.org/3/movie/popular?api_key=$apiKey";

  Future<List<Movie>> getNowShowing() async {
    final url = Uri.parse(nowShowingApi);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      return data.map((movie) => Movie.fromMap(movie)).toList();
    } else {
      throw Exception("Failed to load now showing movies");
    }
  }

  Future<List<Movie>> getUpComing() async {
    final url = Uri.parse(upComingApi);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      return data.map((movie) => Movie.fromMap(movie)).toList();
    } else {
      throw Exception("Failed to load upcoming movies");
    }
  }

  Future<List<Movie>> getPopular() async {
    final url = Uri.parse(popularApi);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      return data.map((movie) => Movie.fromMap(movie)).toList();
    } else {
      throw Exception("Failed to load popular movies");
    }
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey"
    );
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load movie details");
    }
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    final url = Uri.parse(
      "https://api.themoviedb.org/3/movie/$movieId/credits?api_key=$apiKey"
    );
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load movie details");
    }
  }
}
