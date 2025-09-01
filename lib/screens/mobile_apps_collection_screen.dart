import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';

class MobileApp {
  final String id;
  final String appName;
  final String platform;
  final String category;
  final String reason;
  final String userId;

  MobileApp({
    required this.id,
    required this.appName,
    required this.platform,
    required this.category,
    required this.reason,
    required this.userId,
  });

  factory MobileApp.fromJson(Map<String, dynamic> json) {
    return MobileApp(
      id: json['id']?.toString() ?? '',
      appName: json['appName']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'platform': platform,
      'category': category,
      'reason': reason,
      'userId': userId,
    };
  }
}

class MobileAppsCollectionScreen extends StatefulWidget {
  final String userName;

  const MobileAppsCollectionScreen({super.key, required this.userName});

  @override
  State<MobileAppsCollectionScreen> createState() => _MobileAppsCollectionScreenState();
}

class _MobileAppsCollectionScreenState extends State<MobileAppsCollectionScreen>
    with TickerProviderStateMixin {
  List<MobileApp> mobileApps = [];
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
      _fetchMobileApps();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchMobileApps() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthubdotnet.onrender.com/api/MobileApps/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            mobileApps = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            mobileApps = [];
          });
          return;
        }

        if (jsonData['success'] == true && jsonData['data'] is List) {
          setState(() {
            mobileApps = (jsonData['data'] as List)
                .map((json) => MobileApp.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            mobileApps = [];
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          mobileApps = [];
        });
      } else {
        _showMessage('Error fetching mobile apps: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        mobileApps = [];
      });
      _showMessage('Error fetching mobile apps: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addMobileApp(String appName, String platform, String category, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'userId': userId,
        'appName': appName,
        'platform': platform,
        'category': category,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('https://collecthubdotnet.onrender.com/api/MobileApps'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Mobile app added successfully! 📱', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMobileApps();
        } else {
          _showMessage('Error adding mobile app: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        _showMessage('Error adding mobile app: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error adding mobile app: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateMobileApp(
      MobileApp app, String appName, String platform, String category, String reason) async {
    setState(() => isLoading = true);

    try {
      final requestBody = {
        'appName': appName,
        'platform': platform,
        'category': category,
        'reason': reason,
      };

      final response = await http.put(
        Uri.parse('https://collecthubdotnet.onrender.com/api/MobileApps/${app.id}/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Mobile app updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMobileApps();
        } else {
          _showMessage('Mobile app may have been updated, refreshing list...');
          _fetchMobileApps();
        }
      } else {
        _showMessage('Error updating mobile app: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error updating mobile app: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteMobileApp(MobileApp app) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthubdotnet.onrender.com/api/MobileApps/${app.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showMessage('Mobile app removed from vault! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchMobileApps();
        } else {
          _showMessage('Mobile app may have been deleted, refreshing list...');
          _fetchMobileApps();
        }
      } else {
        _showMessage('Error deleting mobile app: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error deleting mobile app: Please check your internet connection');
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

  void _showAddMobileAppDialog() {
    final appNameController = TextEditingController();
    final categoryController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedPlatform = 'Android';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo.shade50, Colors.white],
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
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mobile_friendly, color: Colors.indigo, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Mobile App',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(appNameController, 'App Name', Icons.apps),
                const SizedBox(height: 16),
                _buildTextField(categoryController, 'Category', Icons.category),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_android, color: Colors.indigo, size: 20),
                          const SizedBox(width: 8),
                          const Text('Platform', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Android',
                            groupValue: selectedPlatform,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPlatform = value!;
                              });
                            },
                          ),
                          const Text('Android'),
                          Radio<String>(
                            value: 'iOS',
                            groupValue: selectedPlatform,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPlatform = value!;
                              });
                            },
                          ),
                          const Text('iOS'),
                        ],
                      ),
                    ],
                  ),
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
                          if (appNameController.text.trim().isNotEmpty &&
                              categoryController.text.trim().isNotEmpty &&
                              reasonController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _addMobileApp(
                              appNameController.text.trim(),
                              selectedPlatform,
                              categoryController.text.trim(),
                              reasonController.text.trim(),
                            );
                          } else {
                            _showMessage('Please fill all fields');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add App', style: TextStyle(fontSize: 16)),
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

  void _showUpdateMobileAppDialog(MobileApp app) {
    final appNameController = TextEditingController(text: app.appName);
    final categoryController = TextEditingController(text: app.category);
    final reasonController = TextEditingController(text: app.reason);
    String selectedPlatform = app.platform;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                      'Update Mobile App',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(appNameController, 'App Name', Icons.apps),
                const SizedBox(height: 16),
                _buildTextField(categoryController, 'Category', Icons.category),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_android, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text('Platform', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Android',
                            groupValue: selectedPlatform,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPlatform = value!;
                              });
                            },
                          ),
                          const Text('Android'),
                          Radio<String>(
                            value: 'iOS',
                            groupValue: selectedPlatform,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPlatform = value!;
                              });
                            },
                          ),
                          const Text('iOS'),
                        ],
                      ),
                    ],
                  ),
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
                          if (appNameController.text.trim().isNotEmpty &&
                              categoryController.text.trim().isNotEmpty &&
                              reasonController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _updateMobileApp(
                              app,
                              appNameController.text.trim(),
                              selectedPlatform,
                              categoryController.text.trim(),
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

  void _showDeleteConfirmation(MobileApp app) {
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
            const Text('Remove Mobile App'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${app.appName.isNotEmpty ? app.appName : 'this mobile app'}" from your AppVault?',
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
              _deleteMobileApp(app);
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
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildMobileAppCard(MobileApp app) {
    return Dismissible(
      key: Key(app.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (e.g., to delete)
          _showDeleteConfirmation(app);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (e.g., to update)
          _showUpdateMobileAppDialog(app);
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
          color: Colors.orange.shade400,
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
                  colors: [Colors.white, Colors.indigo.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.shade100.withOpacity(0.5),
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
                        color: app.platform.toLowerCase() == 'android' 
                            ? Colors.green.shade600 
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        app.platform.toLowerCase() == 'android' 
                            ? Icons.android 
                            : Icons.apple,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName.isNotEmpty
                                ? app.appName
                                : 'Untitled App',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: app.platform.toLowerCase() == 'android' 
                                      ? Colors.green.shade100 
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  app.platform,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: app.platform.toLowerCase() == 'android' 
                                        ? Colors.green.shade700 
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                app.category.isNotEmpty
                                    ? app.category
                                    : 'No Category',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app.reason.isNotEmpty
                                ? app.reason
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
        title: Text("${widget.userName}'s Mobile Apps 📱"),
        backgroundColor: Colors.indigo,
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
                colors: [Colors.indigo, Colors.indigo.shade700],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AppVault 📱',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddMobileAppDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Mobile Apps List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your mobile apps...'),
                      ],
                    ),
                  )
                : mobileApps.isEmpty
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
                                Icons.mobile_friendly,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your AppVault is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first mobile app',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMobileApps,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: mobileApps.length,
                          itemBuilder: (context, index) {
                            return _buildMobileAppCard(mobileApps[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}