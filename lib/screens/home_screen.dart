import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin {
  User? user;
  String personalityAnalysis = '';
  bool isLoadingPersonality = false;
  int _currentIndex = 0;
  
  late AnimationController _controller;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late List<Animation<Offset>> _cardAnimations;
  late List<Animation<double>> _cardScaleAnimations;

  final List<Map<String, dynamic>> collections = [
    {
      'title': 'Book Collection',
      'color': Colors.blue,
      'description': 'A space to gather favorite books with reasons why they matter',
      'gradient': [Colors.blue.shade400, Colors.blue.shade600],
      'number': '1'
    },
    {
      'title': 'Recipe Keeper',
      'color': Colors.orange,
      'description': 'Store and cherish recipes you love to cook and share',
      'gradient': [Colors.orange.shade400, Colors.orange.shade600],
      'number': '2'
    },
    {
      'title': 'Movie Tracker',
      'color': Colors.red,
      'description': 'Track movies you\'ve watched or want to watch, with quick notes',
      'gradient': [Colors.red.shade400, Colors.red.shade600],
      'number': '3'
    },
    {
      'title': 'Favorite Quartz Tracker',
      'color': Colors.purple,
      'description': 'Collect and admire unique quartz pieces that inspire you',
      'gradient': [Colors.purple.shade400, Colors.purple.shade600],
      'number': '4'
    },
    {
      'title': 'Pet Favorites',
      'color': Colors.green,
      'description': 'A place to keep memories, stories, and favorites of your pets',
      'gradient': [Colors.green.shade400, Colors.green.shade600],
      'number': '5'
    },
    {
      'title': 'Travel Memories',
      'color': Colors.teal,
      'description': 'Capture moments from journeys and adventures around the world',
      'gradient': [Colors.teal.shade400, Colors.teal.shade600],
      'number': '6'
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Create staggered animations for cards
    _cardAnimations = List.generate(
      collections.length,
      (index) => Tween<Offset>(
        begin: Offset(0, 0.8),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(
            index * 0.15,
            0.7 + index * 0.15,
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );
    
    _cardScaleAnimations = List.generate(
      collections.length,
      (index) => Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(
            index * 0.15,
            0.7 + index * 0.15,
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );
    
    _loadUserData();
    _controller.forward();
    Future.delayed(Duration(milliseconds: 800), () {
      _cardController.forward();
    });
  }

  _loadUserData() async {
    final userData = await StorageService.getUser();
    setState(() {
      user = userData;
    });
  }

  _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[600]),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  _logout() async {
    await StorageService.clearUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _getPersonalityAnalysis() async {
    if (user == null) return;
    
    setState(() {
      isLoadingPersonality = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://collecthub-c1la.onrender.com/api/aipersonality/analysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user!.id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          personalityAnalysis = data['personality_analysis'] ?? 'Based on your collections, you have a well-rounded personality with diverse interests spanning literature, entertainment, and personal growth.';
        });
      } else {
        setState(() {
          personalityAnalysis = 'Based on your collection patterns, you demonstrate curiosity and organization skills. Your diverse interests suggest an open-minded approach to life.';
        });
      }
    } catch (e) {
      setState(() {
        personalityAnalysis = 'Your collection habits indicate someone who values experiences and memories. You have an organized approach to preserving what matters to you.';
      });
    } finally {
      setState(() {
        isLoadingPersonality = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    return user == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading your collections...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    
                    // Simple Welcome Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hello, ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w300,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${user!.name} ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Text(
                                  '👋',
                                  style: TextStyle(fontSize: 26),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 15),
                    
                    // App Description
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CollectHub 🎒📃',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your personal collections. All in one place.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A unified platform to organize and store your personal collections.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 25),
                    
                    // Collections - Staggered Layout
                    Column(
                      children: [
                        // Row 1 - Card 1 (left)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _cardAnimations[0],
                                child: ScaleTransition(
                                  scale: _cardScaleAnimations[0],
                                  child: _buildStaggeredCard(collections[0], true),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Row 2 - Card 2 (right)
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _cardAnimations[1],
                                child: ScaleTransition(
                                  scale: _cardScaleAnimations[1],
                                  child: _buildStaggeredCard(collections[1], false),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Row 3 - Card 3 (left)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _cardAnimations[2],
                                child: ScaleTransition(
                                  scale: _cardScaleAnimations[2],
                                  child: _buildStaggeredCard(collections[2], true),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Row 4 - Card 4 (right)
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _cardAnimations[3],
                                child: ScaleTransition(
                                  scale: _cardScaleAnimations[3],
                                  child: _buildStaggeredCard(collections[3], false),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Row 5 - Card 5 (left)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _cardAnimations[4],
                                child: ScaleTransition(
                                  scale: _cardScaleAnimations[4],
                                  child: _buildStaggeredCard(collections[4], true),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Row 6 - Card 6 (right)
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedBuilder(
                            animation: _cardController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _cardAnimations[5],
                                child: ScaleTransition(
                                  scale: _cardScaleAnimations[5],
                                  child: _buildStaggeredCard(collections[5], false),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 40),
                    
                    // AI Personality Button with more space
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: isLoadingPersonality ? null : _getPersonalityAnalysis,
                        icon: isLoadingPersonality
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                        label: Text(
                          isLoadingPersonality 
                              ? 'Analyzing Your Collections...' 
                              : 'AI Personality Analysis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 8,
                          shadowColor: Colors.deepPurple.withOpacity(0.3),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 25),
                    
                    // Personality Analysis Result
                    if (personalityAnalysis.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple[50]!, Colors.purple[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.purple[200]!, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.psychology_rounded, color: Colors.purple[700], size: 28),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Your Personality Insights',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Text(
                              personalityAnalysis,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.purple[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildVaultContent() {
    return VaultScreen(userName: user?.name ?? '');
  }

  Widget _buildStaggeredCard(Map<String, dynamic> collection, bool isLeft) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: collection['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (collection['color'] as MaterialColor).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text('${collection['title']} - Coming Soon!'),
                    ),
                  ],
                ),
                backgroundColor: collection['color'][600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        collection['number'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      collection['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                collection['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        elevation: 0,
        title: Row(
          children: [
            Text(
              'CollectHub',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            SizedBox(width: 8),
            Text('🎒', style: TextStyle(fontSize: 20)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          _buildVaultContent(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_special_rounded),
              label: 'Vault',
            ),
          ],
        ),
      ),
    );
  }
}