import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';

class Music {
  final String id;
  final String musicName;
  final String singer;
  final String reason;
  final String userId;

  Music({
    required this.id,
    required this.musicName,
    required this.singer,
    required this.reason,
    required this.userId,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id']?.toString() ?? '',
      musicName: json['musicName']?.toString() ?? '',
      singer: json['singer']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'musicName': musicName,
      'singer': singer,
      'reason': reason,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'userId': userId,
      'musicName': musicName,
      'singer': singer,
      'reason': reason,
    };
  }
}

class MusicCollectionScreen extends StatefulWidget {
  final String userName;

  const MusicCollectionScreen({super.key, required this.userName});

  @override
  State<MusicCollectionScreen> createState() => _MusicCollectionScreenState();
}

class _MusicCollectionScreenState extends State<MusicCollectionScreen>
    with TickerProviderStateMixin {
  List<Music> musicList = [];
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
      _fetchMusic();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchMusic() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthubdotnet.onrender.com/api/FavMusic?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/plain',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            musicList = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            musicList = [];
          });
          return;
        }

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> musicData = jsonData['data'] as List<dynamic>;
          setState(() {
            musicList = musicData
                .map((json) => Music.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            musicList = [];
          });
          if (jsonData['message'] != null) {
            _showMessage(jsonData['message']);
          }
        }
      } else if (response.statusCode == 404) {
        setState(() {
          musicList = [];
        });
      } else {
        _showMessage('Error fetching music: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        musicList = [];
      });
      _showMessage('Error fetching music: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addMusic(String name, String singer, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'userId': userId,
        'musicName': name,
        'singer': singer,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('https://collecthubdotnet.onrender.com/api/FavMusic'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/plain',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Music added successfully! 🎵', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMusic();
        } else {
          _showMessage(responseData['message'] ?? 'Error adding music');
        }
      } else {
        _showMessage('Error adding music: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error adding music: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateMusic(
      Music music, String name, String singer, String reason) async {
    setState(() => isLoading = true);

    try {
      final requestBody = {
        'id': music.id,
        'userId': music.userId,
        'musicName': name,
        'singer': singer,
        'reason': reason,
      };

      final response = await http.put(
        Uri.parse('https://collecthubdotnet.onrender.com/api/FavMusic/${music.id}?userId=${music.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/plain',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Music updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMusic();
        } else {
          _showMessage(responseData['message'] ?? 'Error updating music');
        }
      } else {
        _showMessage('Error updating music: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error updating music: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteMusic(Music music) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthubdotnet.onrender.com/api/FavMusic/${music.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/plain',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Music removed from collection! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMusic();
        } else {
          _showMessage(responseData['message'] ?? 'Error deleting music');
        }
      } else {
        _showMessage('Error deleting music: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error deleting music: Please check your internet connection');
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

  void _showAddMusicDialog() {
    final nameController = TextEditingController();
    final singerController = TextEditingController();
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
              colors: [Colors.pink.shade50, Colors.white],
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
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.pink, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Music',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Music Name', Icons.music_note),
              const SizedBox(height: 16),
              _buildTextField(singerController, 'Singer/Artist', Icons.person),
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
                            singerController.text.trim().isNotEmpty &&
                            reasonController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _addMusic(
                            nameController.text.trim(),
                            singerController.text.trim(),
                            reasonController.text.trim(),
                          );
                        } else {
                          _showMessage('Please fill all fields');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Music', style: TextStyle(fontSize: 16)),
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

  void _showUpdateMusicDialog(Music music) {
    final nameController = TextEditingController(text: music.musicName);
    final singerController = TextEditingController(text: music.singer);
    final reasonController = TextEditingController(text: music.reason);

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
              colors: [Colors.purple.shade50, Colors.white],
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
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Update Music',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Music Name', Icons.music_note),
              const SizedBox(height: 16),
              _buildTextField(singerController, 'Singer/Artist', Icons.person),
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
                            singerController.text.trim().isNotEmpty &&
                            reasonController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _updateMusic(
                            music,
                            nameController.text.trim(),
                            singerController.text.trim(),
                            reasonController.text.trim(),
                          );
                        } else {
                          _showMessage('Please fill all fields');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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

  void _showDeleteConfirmation(Music music) {
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
            const Text('Remove Music'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${music.musicName.isNotEmpty ? music.musicName : 'this music'}" from your MusicVault?',
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
              _deleteMusic(music);
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
        prefixIcon: Icon(icon, color: Colors.pink),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pink, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildMusicCard(Music music) {
    return Dismissible(
      key: Key(music.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (delete)
          _showDeleteConfirmation(music);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (update)
          _showUpdateMusicDialog(music);
        }
        return false; // Prevent actual dismissal here, we handle actions in dialogs
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
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
          color: Colors.purple.shade400,
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
                  colors: [Colors.white, Colors.pink.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade100.withOpacity(0.5),
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
                        color: Colors.pink.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            music.musicName.isNotEmpty
                                ? music.musicName
                                : 'Untitled Music',
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
                            music.singer.isNotEmpty
                                ? 'by ${music.singer}'
                                : 'Unknown Artist',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            music.reason.isNotEmpty
                                ? music.reason
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
        title: Text("${widget.userName}'s Music 🎵"),
        backgroundColor: Colors.pink,
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
                colors: [Colors.pink, Colors.pink.shade700],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MusicVault 🎵',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddMusicDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pink,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Music List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your music...'),
                      ],
                    ),
                  )
                : musicList.isEmpty
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
                                Icons.music_note,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your MusicVault is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first music',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMusic,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: musicList.length,
                          itemBuilder: (context, index) {
                            return _buildMusicCard(musicList[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}