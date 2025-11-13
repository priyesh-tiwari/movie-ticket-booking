import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MovieSearchWidget extends StatefulWidget {
  final Function(String movieId, String movieTitle, String posterUrl)?
      onMovieSelected;
  final Function(Map<String, dynamic> movie)? onMovieTap;
  final bool showSelectionIndicator;
  final String? selectedMovieId;

  const MovieSearchWidget({
    Key? key,
    this.onMovieSelected,
    this.onMovieTap,
    this.showSelectionIndicator = true,
    this.selectedMovieId,
  }) : super(key: key);

  @override
  State<MovieSearchWidget> createState() => _MovieSearchWidgetState();
}

class _MovieSearchWidgetState extends State<MovieSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final String apikey = '2d24410';
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  String? _localSelectedMovieId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final url = Uri.parse(
          'https://www.omdbapi.com/?s=${query.trim()}&apikey=$apikey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['Response'] == 'True' && data['Search'] != null) {
          if (mounted) {
            setState(() {
              searchResults = List<Map<String, dynamic>>.from(data['Search']);
              isSearching = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              searchResults = [];
              isSearching = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No movies found for "$query"'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print('Error searching movies: $e');
      if (mounted) {
        setState(() {
          searchResults = [];
          isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching movies. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMovieSelection(Map<String, dynamic> movie) {
    setState(() {
      _localSelectedMovieId = movie['imdbID'];
    });

    // Call the selection callback if provided
    if (widget.onMovieSelected != null) {
      widget.onMovieSelected!(
        movie['imdbID'] ?? '',
        movie['Title'] ?? '',
        movie['Poster'] ?? '',
      );
    }

    // Call the tap callback if provided
    if (widget.onMovieTap != null) {
      widget.onMovieTap!(movie);
    }
  }

  String get _currentSelectedId {
    return widget.selectedMovieId ?? _localSelectedMovieId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search movies...',
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.search, color: Colors.tealAccent),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        searchResults = [];
                        _localSelectedMovieId = null;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to show/hide clear button
          },
          onSubmitted: (value) => searchMovies(value),
        ),

        SizedBox(height: 16),

        // Loading Indicator
        if (isSearching)
          Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
          )

        // Search Results
        else if (searchResults.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                var movie = searchResults[index];
                bool isSelected = _currentSelectedId == movie['imdbID'];

                return GestureDetector(
                  onTap: () => _handleMovieSelection(movie),
                  child: Container(
                    width: 130,
                    height: 220,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: widget.showSelectionIndicator && isSelected
                          ? Border.all(color: Colors.tealAccent, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Movie Poster
                          Image.network(
                            movie['Poster'] ?? '',
                            height: 160,
                            width: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 160,
                              width: 130,
                              color: Colors.grey[800],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.movie,
                                      size: 40, color: Colors.grey[600]),
                                  SizedBox(height: 4),
                                  Text(
                                    'No Image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 160,
                                width: 130,
                                color: Colors.grey[850],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.tealAccent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Movie Info
                          Expanded(
                            child: Container(
                              width: 130,
                              padding: EdgeInsets.all(6),
                              color: Colors.grey[900],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    movie['Title'] ?? 'Unknown',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    movie['Year'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )

        // Empty State
        else if (_searchController.text.isNotEmpty && !isSearching)
          Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No results found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Try a different search term',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
