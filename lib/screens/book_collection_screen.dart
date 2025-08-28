import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../utils/constants.dart'; // Ensure this path is correct for your project

class Book {
  final String id;
  final String bookName;
  final String author;
  final String reason;
  final String userId;

  Book({
    required this.id,
    required this.bookName,
    required this.author,
    required this.reason,
    required this.userId,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      bookName: json['book_name']?.toString() ?? json['name']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_name': bookName,
      'author': author,
      'reason': reason,
      'user_id': userId,
    };
  }
}

class BookCollectionScreen extends StatefulWidget {
  final String userName;

  const BookCollectionScreen({super.key, required this.userName});

  @override
  State<BookCollectionScreen> createState() => _BookCollectionScreenState();
}

class _BookCollectionScreenState extends State<BookCollectionScreen>
    with TickerProviderStateMixin {
  List<Book> books = [];
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
      _fetchBooks();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchBooks() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthub-c1la.onrender.com/api/books/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            books = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            books = [];
          });
          return;
        }

        if (jsonData is List) {
          setState(() {
            books = jsonData
                .map((json) => Book.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            books = [];
          });
          _showMessage('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        setState(() {
          books = [];
        });
      } else {
        _showMessage('Error fetching books: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        books = [];
      });
      _showMessage('Error fetching books: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addBook(String name, String author, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'book_name': name,
        'author': author,
        'reason': reason,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse('https://collecthub-c1la.onrender.com/api/books'),
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
          _showMessage('Book added successfully! 📚', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchBooks();
        } else {
          // If the backend doesn't return an ID, but status is success,
          // assume it worked and refresh.
          _showMessage('Book may have been added, refreshing list...');
          _fetchBooks();
        }
      } else {
        _showMessage('Error adding book: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error adding book: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateBook(
      Book book, String name, String author, String reason) async {
    setState(() => isLoading = true);

    try {
      final requestBody = {
        'book_name': name,
        'author': author,
        'reason': reason,
      };

      final response = await http.put(
        Uri.parse('https://collecthub-c1la.onrender.com/api/books/${book.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message']?.toString().contains('updated') == true) {
          _showMessage('Book updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchBooks();
        } else {
          _showMessage('Book may have been updated, refreshing list...');
          _fetchBooks();
        }
      } else {
        _showMessage('Error updating book: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error updating book: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteBook(Book book) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthub-c1la.onrender.com/api/books/${book.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if ((responseData['deleted_count'] ?? 0) > 0 ||
            responseData['message']?.toString().contains('deleted') == true) {
          _showMessage('Book removed from vault! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchBooks();
        } else {
          _showMessage('Book may have been deleted, refreshing list...');
          _fetchBooks();
        }
      } else {
        _showMessage('Error deleting book: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error deleting book: Please check your internet connection');
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

  void _showAddBookDialog() {
    final nameController = TextEditingController();
    final authorController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.book, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Book',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Book Name', Icons.menu_book),
              const SizedBox(height: 16),
              _buildTextField(authorController, 'Author', Icons.person),
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
                        if (nameController.text.trim().isNotEmpty &&
                            authorController.text.trim().isNotEmpty &&
                            reasonController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _addBook(
                            nameController.text.trim(),
                            authorController.text.trim(),
                            reasonController.text.trim(),
                          );
                        } else {
                          _showMessage('Please fill all fields');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Book', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateBookDialog(Book book) {
    final nameController = TextEditingController(text: book.bookName);
    final authorController = TextEditingController(text: book.author);
    final reasonController = TextEditingController(text: book.reason);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Update Book',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Book Name', Icons.menu_book),
              const SizedBox(height: 16),
              _buildTextField(authorController, 'Author', Icons.person),
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
                        if (nameController.text.trim().isNotEmpty &&
                            authorController.text.trim().isNotEmpty &&
                            reasonController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _updateBook(
                            book,
                            nameController.text.trim(),
                            authorController.text.trim(),
                            reasonController.text.trim(),
                          );
                        } else {
                          _showMessage('Please fill all fields');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
    );
  }

  void _showDeleteConfirmation(Book book) {
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
            const Text('Remove Book'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${book.bookName.isNotEmpty ? book.bookName : 'this book'}" from your BookVault?',
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
              _deleteBook(book);
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
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Dismissible(
      key: Key(book.id),
      direction: DismissDirection.horizontal, // Allow both left and right swipe
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (e.g., to delete)
          _showDeleteConfirmation(book);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (e.g., to update)
          _showUpdateBookDialog(book);
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
                  colors: [Colors.white, Colors.blue.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
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
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.bookName.isNotEmpty
                                ? book.bookName
                                : 'Untitled Book',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author.isNotEmpty
                                ? 'by ${book.author}'
                                : 'Unknown Author',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.reason.isNotEmpty
                                ? book.reason
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
                    // Removed the drag handle icon, as Dismissible handles the drag itself
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
        title: Text("${widget.userName}'s Books 📚"),
        backgroundColor: Colors.blue,
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
                colors: [Colors.blue, Colors.blue.shade700],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BookVault 📚',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddBookDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Books List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your books...'),
                      ],
                    ),
                  )
                : books.isEmpty
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
                                Icons.menu_book,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your BookVault is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first book',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBooks,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            return _buildBookCard(books[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}