import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart'; 

class Travel {
  final String id;
  final String placeName;
  final DateTime? dateVisited;
  final String reason;
  final String userId;

  Travel({
    required this.id,
    required this.placeName,
    this.dateVisited,
    required this.reason,
    required this.userId,
  });

  factory Travel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    String? dateStringFromApi;

    try {
      dateStringFromApi =
          json['date_visited']?.toString() ?? json['visited_date']?.toString();

      if (dateStringFromApi != null &&
          dateStringFromApi.isNotEmpty &&
          dateStringFromApi != '0001-01-01T00:00:00Z') {
        // Attempt to parse. DateTime.parse is robust for various ISO 8601 forms.
        // It can handle 'Z' or '+00:00' and various millisecond precisions.
        parsedDate = DateTime.parse(dateStringFromApi);
      }
    } catch (e) {
      print('Error parsing date from API: "$dateStringFromApi", Error: $e');
      parsedDate = null;
    }

    return Travel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      placeName:
          json['place_name']?.toString() ?? json['place']?.toString() ?? '',
      dateVisited: parsedDate,
      reason: json['reason']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
    );
  }

  // Helper to format date for backend as YYYY-MM-DDTHH:MM:SS.000+00:00
  String _formatDateForBackend(DateTime date) {
    // Format the date part as YYYY-MM-DD
    final String year = date.year.toString();
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    // Combine with the fixed time and timezone offset
    return '$year-$month-$day' 'T10:30:00.000+00:00';
  }

  // Used for adding new travels (POST request)
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'place_name': placeName.trim(), // Confirmed by backend error
      'reason': reason.trim(),
      'user_id': userId.trim(),
    };

    if (dateVisited != null) {
      // Use the custom formatter for fixed time component
      data['date_visited'] = _formatDateForBackend(dateVisited!);
    }
    return data;
  }

  // Used for updating existing travels (PUT request)
  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{
      'place_name': placeName.trim(),
      'reason': reason.trim(),
    };

    if (dateVisited != null) {
      // Use the custom formatter for fixed time component
      data['date_visited'] = _formatDateForBackend(dateVisited!);
    } else {
      // Explicitly send null if date is cleared in UI, safer than empty string
      data['date_visited'] = null;
    }
    return data;
  }
}

class TravelCollectionScreen extends StatefulWidget {
  final String userName;

  const TravelCollectionScreen({super.key, required this.userName});

  @override
  State<TravelCollectionScreen> createState() => _TravelCollectionScreenState();
}

class _TravelCollectionScreenState extends State<TravelCollectionScreen>
    with TickerProviderStateMixin {
  List<Travel> travels = [];
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
      _fetchTravels();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchTravels() async {
    if (userId == null || userId!.isEmpty) {
      setState(() {
        travels = []; // Clear travels if userId is invalid
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthub-c1la.onrender.com/api/travels/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            travels = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            travels = [];
          });
          return;
        }

        if (jsonData is List) {
          setState(() {
            travels = jsonData
                .map((json) => Travel.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            travels = [];
          });
          _showMessage('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        // 404 can mean no travels for this user
        setState(() {
          travels = [];
        });
      } else {
        _showMessage('Error fetching travels: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        travels = [];
      });
      _showMessage('Error fetching travels: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addTravel(String place, DateTime? visitedDate, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final newTravel = Travel(
        id: '', // ID not needed for creation
        placeName: place,
        dateVisited: visitedDate, // Pass the date as is (without time from picker)
        reason: reason,
        userId: userId!,
      );

      final String jsonBody = json.encode(newTravel.toJson());
      print('JSON being sent to POST: $jsonBody');

      final response = await http.post(
        Uri.parse('https://collecthub-c1la.onrender.com/api/travels'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonBody,
      );

      print('Response status for POST: ${response.statusCode}');
      print('Response body for POST: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Travel added successfully! 🎉', isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 500));
        _fetchTravels();
      } else {
        _showMessage(
            'Error adding travel: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network Error adding travel: $e');
      _showMessage('Network error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateTravel(
      Travel travel, String place, DateTime? visitedDate, String reason) async {
    setState(() => isLoading = true);

    try {
      final updatedTravel = Travel(
        id: travel.id,
        placeName: place,
        dateVisited: visitedDate, // Pass the date as is (without time from picker)
        reason: reason,
        userId: travel.userId,
      );

      final String jsonBody = json.encode(updatedTravel.toUpdateJson());
      print('JSON being sent to PUT: $jsonBody');

      final response = await http.put(
        Uri.parse('https://collecthub-c1la.onrender.com/api/travels/${travel.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonBody,
      );

      print('Response status for PUT: ${response.statusCode}');
      print('Response body for PUT: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message']?.toString().contains('updated') == true) {
          _showMessage('Travel updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchTravels();
        } else {
          _showMessage('Travel may have been updated, refreshing list...');
          _fetchTravels();
        }
      } else {
        _showMessage(
            'Error updating travel: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network Error updating travel: $e');
      _showMessage('Error updating travel: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTravel(Travel travel) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthub-c1la.onrender.com/api/travels/${travel.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status for DELETE: ${response.statusCode}');
      print('Response body for DELETE: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if ((responseData['deleted_count'] ?? 0) > 0 ||
            responseData['message']?.toString().contains('deleted') == true) {
          _showMessage('Travel removed from vault! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchTravels();
        } else {
          _showMessage('Travel may have been deleted, refreshing list...');
          _fetchTravels();
        }
      } else {
        _showMessage(
            'Error deleting travel: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network Error deleting travel: $e');
      _showMessage('Error deleting travel: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- Only Date Picker Logic ---
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal, // Color for "CANCEL", "OK"
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    return picked; // This DateTime will have time components set to midnight (00:00:00)
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

  void _showAddTravelDialog() {
    final placeController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime? selectedDate; // Will store only the date part (time will be midnight)

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade50, Colors.white],
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
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flight_takeoff, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Travel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(placeController, 'Place Name', Icons.location_on),
                const SizedBox(height: 16),
                _buildDateField(
                  'Visited Date', // Simplified label
                  selectedDate,
                  () async {
                    final date = await _selectDate(context, selectedDate);
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(reasonController, 'Reason', Icons.favorite,
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
                          if (placeController.text.trim().isNotEmpty &&
                              reasonController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _addTravel(
                              placeController.text.trim(),
                              selectedDate, // Pass date only
                              reasonController.text.trim(),
                            );
                          } else {
                            _showMessage('Please fill place name and reason fields');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Travel', style: TextStyle(fontSize: 16)),
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

  void _showUpdateTravelDialog(Travel travel) {
    final placeController = TextEditingController(text: travel.placeName);
    final reasonController = TextEditingController(text: travel.reason);
    DateTime? selectedDate = travel.dateVisited; // Will hold date only

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                      'Update Travel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(placeController, 'Place Name', Icons.location_on),
                const SizedBox(height: 16),
                _buildDateField(
                  'Visited Date', // Simplified label
                  selectedDate,
                  () async {
                    final date = await _selectDate(context, selectedDate);
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(reasonController, 'Reason', Icons.favorite,
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
                          if (placeController.text.trim().isNotEmpty &&
                              reasonController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _updateTravel(
                              travel,
                              placeController.text.trim(),
                              selectedDate, // Pass date only
                              reasonController.text.trim(),
                            );
                          } else {
                            _showMessage('Please fill place name and reason fields');
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

  void _showDeleteConfirmation(Travel travel) {
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
            const Text('Remove Travel'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${travel.placeName.isNotEmpty ? travel.placeName : 'this travel'}" from your TravelVault?',
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
              _deleteTravel(travel);
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
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? selectedDate, VoidCallback onTap) {
    String displayString;
    if (selectedDate != null) {
      // Format to "DD/MM/YYYY"
      final String month = selectedDate.month.toString().padLeft(2, '0');
      final String day = selectedDate.day.toString().padLeft(2, '0');
      displayString = '$day/$month/${selectedDate.year}';
    } else {
      displayString = label;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.teal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayString,
                style: TextStyle(
                  fontSize: 16,
                  color: selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelCard(Travel travel) {
    String formattedDate;
    if (travel.dateVisited != null) {
      final String month = travel.dateVisited!.month.toString().padLeft(2, '0');
      final String day = travel.dateVisited!.day.toString().padLeft(2, '0');
      formattedDate = '$day/$month/${travel.dateVisited!.year}';
    } else {
      formattedDate = 'Date not specified';
    }

    return Dismissible(
      key: Key(travel.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (to delete)
          _showDeleteConfirmation(travel);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (to update)
          _showUpdateTravelDialog(travel);
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
                  colors: [Colors.white, Colors.teal.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade100.withOpacity(0.5),
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
                        color: Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            travel.placeName.isNotEmpty
                                ? travel.placeName
                                : 'Unknown Place',
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
                              Icon(Icons.calendar_today,
                                  color: Colors.teal.shade400, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate, // Use formattedDate
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
                            travel.reason.isNotEmpty
                                ? travel.reason
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
        title: Text("${widget.userName}'s Travel ✈️"),
        backgroundColor: Colors.teal,
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
                colors: [Colors.teal, Colors.teal.shade700],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TravelVault ✈️',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddTravelDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal,
                  mini: true,
                  heroTag: 'addTravel', // Add a unique heroTag
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Travels List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 16),
                        Text('Loading your travels...'),
                      ],
                    ),
                  )
                : travels.isEmpty
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
                                Icons.flight_takeoff,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your TravelVault is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first travel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTravels,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: travels.length,
                          itemBuilder: (context, index) {
                            return _buildTravelCard(travels[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}