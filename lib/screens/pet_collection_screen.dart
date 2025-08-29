import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';

class Pet {
  final String id;
  final String name;
  final String reason;
  final String userId;

  Pet({
    required this.id,
    required this.name,
    required this.reason,
    required this.userId,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'user_id': userId,
    };
  }
}

class PetCollectionScreen extends StatefulWidget {
  final String userName;

  const PetCollectionScreen({super.key, required this.userName});

  @override
  State<PetCollectionScreen> createState() => _PetCollectionScreenState();
}

class _PetCollectionScreenState extends State<PetCollectionScreen>
    with TickerProviderStateMixin {
  List<Pet> pets = [];
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
      _fetchPets();
    } else {
      _showMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _fetchPets() async {
    if (userId == null || userId!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://collecthub-c1la.onrender.com/api/pets/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            pets = [];
          });
          return;
        }

        final dynamic jsonData = json.decode(responseBody);

        if (jsonData == null) {
          setState(() {
            pets = [];
          });
          return;
        }

        if (jsonData is List) {
          setState(() {
            pets = jsonData
                .map((json) => Pet.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        } else {
          setState(() {
            pets = [];
          });
          _showMessage('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        setState(() {
          pets = [];
        });
      } else {
        _showMessage('Error fetching pets: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        pets = [];
      });
      _showMessage('Error fetching pets: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addPet(String name, String reason) async {
    if (userId == null || userId!.isEmpty) {
      _showMessage('User ID not found. Please login again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'name': name,
        'reason': reason,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse('https://collecthub-c1la.onrender.com/api/pets'),
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
          _showMessage('Pet added successfully! 🐾', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchPets();
        } else {
          _showMessage('Pet may have been added, refreshing list...');
          _fetchPets();
        }
      } else {
        _showMessage('Error adding pet: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error adding pet: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePet(Pet pet, String name, String reason) async {
    setState(() => isLoading = true);

    try {
      final requestBody = {
        'name': name,
        'reason': reason,
      };

      final response = await http.put(
        Uri.parse('https://collecthub-c1la.onrender.com/api/pets/${pet.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message']?.toString().contains('updated') == true) {
          _showMessage('Pet updated successfully! ✨', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchPets();
        } else {
          _showMessage('Pet may have been updated, refreshing list...');
          _fetchPets();
        }
      } else {
        _showMessage('Error updating pet: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error updating pet: Please check your internet connection');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deletePet(Pet pet) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('https://collecthub-c1la.onrender.com/api/pets/${pet.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if ((responseData['deleted_count'] ?? 0) > 0 ||
            responseData['message']?.toString().contains('deleted') == true) {
          _showMessage('Pet removed from vault! 🗑️', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 500));
          _fetchPets();
        } else {
          _showMessage('Pet may have been deleted, refreshing list...');
          _fetchPets();
        }
      } else {
        _showMessage('Error deleting pet: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Error deleting pet: Please check your internet connection');
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

  void _showAddPetDialog() {
    final nameController = TextEditingController();
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
              colors: [Colors.green.shade50, Colors.white],
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
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Pet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Pet Name', Icons.pets),
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
                        if (nameController.text.trim().isNotEmpty &&
                            reasonController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _addPet(
                            nameController.text.trim(),
                            reasonController.text.trim(),
                          );
                        } else {
                          _showMessage('Please fill all fields');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Pet', style: TextStyle(fontSize: 16)),
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

  void _showUpdatePetDialog(Pet pet) {
    final nameController = TextEditingController(text: pet.name);
    final reasonController = TextEditingController(text: pet.reason);

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
                    'Update Pet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Pet Name', Icons.pets),
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
                        if (nameController.text.trim().isNotEmpty &&
                            reasonController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _updatePet(
                            pet,
                            nameController.text.trim(),
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

  void _showDeleteConfirmation(Pet pet) {
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
            const Text('Remove Pet'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${pet.name.isNotEmpty ? pet.name : 'this pet'}" from your PetVault?',
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
              _deletePet(pet);
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
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Dismissible(
      key: Key(pet.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        // This won't be called if confirmDismiss returns false
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swiping from left to right (to delete)
          _showDeleteConfirmation(pet);
        } else if (direction == DismissDirection.endToStart) {
          // Swiping from right to left (to update)
          _showUpdatePetDialog(pet);
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
                  colors: [Colors.white, Colors.green.shade50],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100.withOpacity(0.5),
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
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name.isNotEmpty
                                ? pet.name
                                : 'Unnamed Pet',
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
                              Icon(Icons.favorite, 
                                   color: Colors.red.shade400, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'My beloved companion',
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
                            pet.reason.isNotEmpty
                                ? pet.reason
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
        title: Text("${widget.userName}'s Pets 🐾"),
        backgroundColor: Colors.green,
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
                colors: [Colors.green, Colors.green.shade700],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PetVault 🐾',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showAddPetDialog,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Pets List
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text('Loading your pets...'),
                      ],
                    ),
                  )
                : pets.isEmpty
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
                                Icons.pets,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your PetVault is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first pet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPets,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: pets.length,
                          itemBuilder: (context, index) {
                            return _buildPetCard(pets[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}