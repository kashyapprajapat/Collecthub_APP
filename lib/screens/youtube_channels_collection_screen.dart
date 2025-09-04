import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';

class YouTubeChannel {
  final String id;
  final String channelName;
  final String creatorName;
  final String genre;
  final String reason;
  final String userId;

  YouTubeChannel({
    required this.id,
    required this.channelName,
    required this.creatorName,
    required this.genre,
    required this.reason,
    required this.userId,
  });

  factory YouTubeChannel.fromJson(Map<String, dynamic> json) {
    return YouTubeChannel(
      id: json['id']?.toString() ?? '',
      channelName: json['channelName']?.toString() ?? '',
      creatorName: json['creatorName']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelName': channelName,
      'creatorName': creatorName,
      'genre': genre,
      'reason': reason,
    };
  }
}

class YouTubeChannelsCollectionScreen extends StatefulWidget {
  final String userName;

  const YouTubeChannelsCollectionScreen({super.key, required this.userName});

  @override
  State<YouTubeChannelsCollectionScreen> createState() => _YouTubeChannelsCollectionScreenState();
}

class _YouTubeChannelsCollectionScreenState extends State<YouTubeChannelsCollectionScreen>
    with TickerProviderStateMixin {
  List<YouTubeChannel> channels = [];
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
      _fetchChannels();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchChannels() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthubdotnet.onrender.com/api/YouTubeChannels?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            channels = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            channels = [];
          });
          return;
        }

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> channelsList = jsonData['data'] as List<dynamic>;
          setState(() {
            channels = channelsList
                .map((json) => YouTubeChannel.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            channels = [];
          });
          _showMessage(jsonData['message'] ?? 'Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        setState(() {
          channels = [];
        });
      } else {
        _showMessage('Error fetching channels: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        channels = [];
      });
      _showMessage('Error fetching channels: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addChannel(String channelName, String creatorName, String genre, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'userId': userId,
        'channelName': channelName,
        'creatorName': creatorName,
        'genre': genre,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('https://collecthubdotnet.onrender.com/api/YouTubeChannels'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Channel added successfully! 🎬', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchChannels();
        } else {
          _showMessage(responseData['message'] ?? 'Error adding channel');
        }
      } else {
        _showMessage('Error adding channel: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error adding channel: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateChannel(
      YouTubeChannel channel, String channelName, String creatorName, String genre, String reason) async {
    setState(() => isLoading = true);

    try {
      final requestBody = {
        'channelName': channelName,
        'creatorName': creatorName,
        'genre': genre,
        'reason': reason,
      };

      final response = await http.put(
        Uri.parse('https://collecthubdotnet.onrender.com/api/YouTubeChannels/${channel.id}?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Channel updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchChannels();
        } else {
          _showMessage(responseData['message'] ?? 'Error updating channel');
        }
      } else {
        _showMessage('Error updating channel: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error updating channel: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteChannel(YouTubeChannel channel) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthubdotnet.onrender.com/api/YouTubeChannels/${channel.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Channel removed from vault! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchChannels();
        } else {
          _showMessage(responseData['message'] ?? 'Error deleting channel');
        }
      } else {
        _showMessage('Error deleting channel: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error deleting channel: Please check your internet connection');
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

  void _showAddChannelDialog() {
    final channelNameController = TextEditingController();
    final creatorNameController = TextEditingController();
    final genreController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade50, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
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
                      child: const Icon(Icons.video_camera_front, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Channel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(channelNameController, 'Channel Name', Icons.subscriptions),
                const SizedBox(height: 16),
                _buildTextField(creatorNameController, 'Creator Name', Icons.account_circle),
                const SizedBox(height: 16),
                _buildTextField(genreController, 'Genre', Icons.local_movies),
                const SizedBox(height: 16),
                _buildTextField(reasonController, 'Reason', Icons.thumb_up,
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
                          if (channelNameController.text.trim().isNotEmpty &&
                              creatorNameController.text.trim().isNotEmpty &&
                              genreController.text.trim().isNotEmpty &&
                              reasonController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _addChannel(
                              channelNameController.text.trim(),
                              creatorNameController.text.trim(),
                              genreController.text.trim(),
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
                        child: const Text('Add Channel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateChannelDialog(YouTubeChannel channel) {
    final channelNameController = TextEditingController(text: channel.channelName);
    final creatorNameController = TextEditingController(text: channel.creatorName);
    final genreController = TextEditingController(text: channel.genre);
    final reasonController = TextEditingController(text: channel.reason);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
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
                      child: const Icon(Icons.edit_note, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Update Channel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(channelNameController, 'Channel Name', Icons.subscriptions),
                const SizedBox(height: 16),
                _buildTextField(creatorNameController, 'Creator Name', Icons.account_circle),
                const SizedBox(height: 16),
                _buildTextField(genreController, 'Genre', Icons.local_movies),
                const SizedBox(height: 16),
                _buildTextField(reasonController, 'Reason', Icons.thumb_up,
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
                          if (channelNameController.text.trim().isNotEmpty &&
                              creatorNameController.text.trim().isNotEmpty &&
                              genreController.text.trim().isNotEmpty &&
                              reasonController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _updateChannel(
                              channel,
                              channelNameController.text.trim(),
                              creatorNameController.text.trim(),
                              genreController.text.trim(),
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
      ),
    );
  }

  void _showDeleteConfirmation(YouTubeChannel channel) {
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
              child: const Icon(Icons.warning_amber, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Remove Channel'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${channel.channelName.isNotEmpty ? channel.channelName : 'this channel'}" from your ChannelVault?',
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
              _deleteChannel(channel);
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

  Widget _buildChannelCard(YouTubeChannel channel) {
    return Dismissible(
      key: Key(channel.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (e.g., to delete)
          _showDeleteConfirmation(channel);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (e.g., to update)
          _showUpdateChannelDialog(channel);
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
            Icon(Icons.delete_forever, color: Colors.white, size: 28),
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
            Icon(Icons.edit_note, color: Colors.white, size: 28),
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
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.channelName.isNotEmpty
                                ? channel.channelName
                                : 'Untitled Channel',
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
                            channel.creatorName.isNotEmpty
                                ? 'by ${channel.creatorName}'
                                : 'Unknown Creator',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            channel.genre.isNotEmpty
                                ? '🎬 ${channel.genre}'
                                : 'Unknown Genre',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            channel.reason.isNotEmpty
                                ? channel.reason
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
        title: Text("${widget.userName}'s Channels 🎥"),
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
                  'ChannelVault 🎬',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddChannelDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Channels List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your channels...'),
                      ],
                    ),
                  )
                : channels.isEmpty
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
                                Icons.video_library,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your ChannelVault is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first channel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchChannels,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: channels.length,
                          itemBuilder: (context, index) {
                            return _buildChannelCard(channels[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}