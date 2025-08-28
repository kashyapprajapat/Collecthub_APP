import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class Movie {
  final String id;
  final String title;
  final String type;
  final String reason;
  final String userId;

  Movie({
    required this.id,
    required this.title,
    required this.type,
    required this.reason,
    required this.userId,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'reason': reason,
      'user_id': userId,
    };
  }
}

class MovieCollectionScreen extends StatefulWidget {
  final String userName;

  const MovieCollectionScreen({super.key, required this.userName});

  @override
  State<MovieCollectionScreen> createState() => _MovieCollectionScreenState();
}

class _MovieCollectionScreenState extends State<MovieCollectionScreen>
    with TickerProviderStateMixin {
  List<Movie> movies = [];
  bool isLoading = false;
  String? userId;
  late AnimationController _dragController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _dragController, curve: Curves.easeInOut),
    );
    _loadUserId();
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    userId = await StorageService.getUserId();
    if (userId != null && userId!.isNotEmpty) {
      _fetchMovies();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchMovies() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthub-c1la.onrender.com/api/movies/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            movies = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            movies = [];
          });
          return;
        }

        if (jsonData is List) {
          setState(() {
            movies = jsonData
                .map((json) => Movie.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            movies = [];
          });
          _showMessage('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        setState(() {
          movies = [];
        });
      } else {
        _showMessage('Error fetching movies: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        movies = [];
      });
      _showMessage('Error fetching movies: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addMovie(String title, String type, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'title': title,
        'type': type,
        'reason': reason,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse('https://collecthub-c1la.onrender.com/api/movies'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('InsertedID') ||
            responseData.containsKey('insertedId')) {
          _showMessage('Movie added successfully! 🎬', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMovies();
        } else {
          // If the backend doesn't return an ID, but status is success,
          // assume it worked and refresh.
          _showMessage('Movie may have been added, refreshing list...');
          _fetchMovies();
        }
      } else {
        _showMessage('Error adding movie: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error adding movie: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateMovie(
      Movie movie, String title, String type, String reason) async {
    setState(() => isLoading = true);

    try {
      final requestBody = {
        'title': title,
        'type': type,
        'reason': reason,
      };

      final response = await http.put(
        Uri.parse('https://collecthub-c1la.onrender.com/api/movies/${movie.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message']?.toString().contains('updated') == true) {
          _showMessage('Movie updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMovies();
        } else {
          _showMessage('Movie may have been updated, refreshing list...');
          _fetchMovies();
        }
      } else {
        _showMessage('Error updating movie: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error updating movie: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteMovie(Movie movie) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthub-c1la.onrender.com/api/movies/${movie.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if ((responseData['deleted_count'] ?? 0) > 0 ||
            responseData['message']?.toString().contains('deleted') == true) {
          _showMessage('Movie removed from theater! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMovies();
        } else {
          _showMessage('Movie may have been deleted, refreshing list...');
          _fetchMovies();
        }
      } else {
        _showMessage('Error deleting movie: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error deleting movie: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddMovieDialog() {
    final titleController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedType = 'Movie'; // Default selection

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade50, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.movie, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add New Movie/Series',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(titleController, 'Title', Icons.movie),
                  const SizedBox(height: 16),
                  // Type selection with radio buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Movie'),
                                value: 'Movie',
                                groupValue: selectedType,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedType = value!;
                                  });
                                },
                                activeColor: Colors.red,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Series'),
                                value: 'Series',
                                groupValue: selectedType,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedType = value!;
                                  });
                                },
                                activeColor: Colors.red,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(reasonController, 'Reason', Icons.lightbulb,
                      maxLines: 3),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isNotEmpty &&
                                reasonController.text.trim().isNotEmpty) {
                              Navigator.pop(context);
                              _addMovie(
                                titleController.text.trim(),
                                selectedType,
                                reasonController.text.trim(),
                              );
                            } else {
                              _showMessage('Please fill all fields');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add Movie', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateMovieDialog(Movie movie) {
    final titleController = TextEditingController(text: movie.title);
    final reasonController = TextEditingController(text: movie.reason);
    String selectedType = movie.type.isNotEmpty ? movie.type : 'Movie';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.deepOrange.shade50, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.deepOrange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Update Movie/Series',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(titleController, 'Title', Icons.movie),
                  const SizedBox(height: 16),
                  // Type selection with radio buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Movie'),
                                value: 'Movie',
                                groupValue: selectedType,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedType = value!;
                                  });
                                },
                                activeColor: Colors.red,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Series'),
                                value: 'Series',
                                groupValue: selectedType,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedType = value!;
                                  });
                                },
                                activeColor: Colors.red,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(reasonController, 'Reason', Icons.lightbulb,
                      maxLines: 3),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isNotEmpty &&
                                reasonController.text.trim().isNotEmpty) {
                              Navigator.pop(context);
                              _updateMovie(
                                movie,
                                titleController.text.trim(),
                                selectedType,
                                reasonController.text.trim(),
                              );
                            } else {
                              _showMessage('Please fill all fields');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Update', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Remove Movie'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${movie.title.isNotEmpty ? movie.title : 'this movie'}" from your Movie Theater?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMovie(movie);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return Dismissible(
      key: Key(movie.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (e.g., to delete)
          _showDeleteConfirmation(movie);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (e.g., to update)
          _showUpdateMovieDialog(movie);
        }
        return false; // Prevent actual dismissal here, we handle actions in dialogs
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400, // Background for delete
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade400, // Background for update
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Update',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            SizedBox(width: 8),
            Icon(Icons.edit, color: Colors.white, size: 28),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.red.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: movie.type.toLowerCase() == 'series' 
                          ? Colors.purple.shade600 
                          : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        movie.type.toLowerCase() == 'series' ? Icons.tv : Icons.movie,
                        color: Colors.white, 
                        size: 24
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title.isNotEmpty
                                ? movie.title
                                : 'Untitled Movie',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: movie.type.toLowerCase() == 'series'
                                  ? Colors.purple.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              movie.type.isNotEmpty ? movie.type : 'Unknown Type',
                              style: TextStyle(
                                fontSize: 12,
                                color: movie.type.toLowerCase() == 'series'
                                    ? Colors.purple.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            movie.reason.isNotEmpty
                                ? movie.reason
                                : 'No reason provided',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName}'s Movies 🎬"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red, Colors.red.shade700],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Movie Theater 🎬',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddMovieDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Movies List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your movies...'),
                      ],
                    ),
                  )
                : movies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.movie,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your Movie Theater is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first movie',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMovies,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            return _buildMovieCard(movies[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}