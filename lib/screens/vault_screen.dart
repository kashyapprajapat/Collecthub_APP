import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'book_collection_screen.dart';
import 'recipe_collection_screen.dart';
import 'movie_collection_screen.dart';
import 'quote_collection_screen.dart';
import 'pet_collection_screen.dart';
import 'travel_collection_screen.dart';
import 'mobile_apps_collection_screen.dart';
import 'music_collection_screen.dart';
import 'vehicle_collection_screen.dart';
import 'youtube_channels_collection_screen.dart';

class VaultScreen extends StatefulWidget {
  final String userName;

  const VaultScreen({super.key, required this.userName});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _staggerController;
  int? _tappedIndex;

  final List<Map<String, dynamic>> vaultItems = [
    {
      "title": "Books", 
      "icon": Icons.menu_book_rounded, 
      "primaryColor": const Color(0xFF2196F3),
      "secondaryColor": const Color(0xFF64B5F6),
      "shadowColor": const Color(0xFF1976D2),
    },
    {
      "title": "Recipes", 
      "icon": Icons.restaurant_menu_rounded, 
      "primaryColor": const Color(0xFFFF9800),
      "secondaryColor": const Color(0xFFFFB74D),
      "shadowColor": const Color(0xFFF57C00),
    },
    {
      "title": "Movies", 
      "icon": Icons.movie_rounded, 
      "primaryColor": const Color(0xFFF44336),
      "secondaryColor": const Color(0xFFE57373),
      "shadowColor": const Color(0xFFD32F2F),
    },
    {
      "title": "Quotes", 
      "icon": Icons.format_quote_rounded, 
      "primaryColor": const Color(0xFF9C27B0),
      "secondaryColor": const Color(0xFFBA68C8),
      "shadowColor": const Color(0xFF7B1FA2),
    },
    {
      "title": "Pets", 
      "icon": Icons.pets_rounded, 
      "primaryColor": const Color(0xFF4CAF50),
      "secondaryColor": const Color(0xFF81C784),
      "shadowColor": const Color(0xFF388E3C),
    },
    {
      "title": "Travel", 
      "icon": Icons.flight_takeoff_rounded, 
      "primaryColor": const Color(0xFF009688),
      "secondaryColor": const Color(0xFF4DB6AC),
      "shadowColor": const Color(0xFF00695C),
    },
    {
      "title": "Mobile Apps", 
      "icon": Icons.smartphone_rounded, 
      "primaryColor": const Color(0xFF3F51B5),
      "secondaryColor": const Color(0xFF7986CB),
      "shadowColor": const Color(0xFF303F9F),
    },
    {
      "title": "Music", 
      "icon": Icons.music_note_rounded, 
      "primaryColor": const Color(0xFFE91E63),
      "secondaryColor": const Color(0xFFF06292),
      "shadowColor": const Color(0xFFC2185B),
    },
    {
      "title": "Vehicles", 
      "icon": Icons.directions_car_rounded, 
      "primaryColor": const Color(0xFFFFC107),
      "secondaryColor": const Color(0xFFFFD54F),
      "shadowColor": const Color(0xFFFFA000),
    },
    {
      "title": "YouTube", 
      "icon": Icons.play_circle_filled_rounded, 
      "primaryColor": const Color(0xFFFF5722),
      "secondaryColor": const Color(0xFFFF8A65),
      "shadowColor": const Color(0xFFE64A19),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _staggerController.forward();
  }

  void _onCardTap(String title, int index) {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _tappedIndex = index;
    });

    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _tappedIndex = null;
          });
        }
      });
    });

    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;

      Widget destinationScreen;

      switch (title) {
        case "Books":
          destinationScreen = BookCollectionScreen(userName: widget.userName);
          break;
        case "Recipes":
          destinationScreen = RecipeCollectionScreen(userName: widget.userName);
          break;
        case "Movies":
          destinationScreen = MovieCollectionScreen(userName: widget.userName);
          break;
        case "Quotes":
          destinationScreen = QuoteCollectionScreen(userName: widget.userName);
          break;
        case "Pets":
          destinationScreen = PetCollectionScreen(userName: widget.userName);
          break;
        case "Travel":
          destinationScreen = TravelCollectionScreen(userName: widget.userName);
          break;
        case "Mobile Apps":
          destinationScreen = MobileAppsCollectionScreen(userName: widget.userName);
          break;
        case "Music":
          destinationScreen = MusicCollectionScreen(userName: widget.userName);
          break;
        case "Vehicles":
          destinationScreen = VehicleCollectionScreen(userName: widget.userName);
          break;
        case "YouTube":
          destinationScreen = YouTubeChannelsCollectionScreen(userName: widget.userName);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title - Coming Soon! 🚀'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
          return;
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  Widget _build3DIcon(Map<String, dynamic> item, bool isPressed) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPressed 
              ? [
                  item["secondaryColor"].withOpacity(0.8),
                  item["primaryColor"],
                ]
              : [
                  item["secondaryColor"],
                  item["primaryColor"],
                ],
          stops: const [0.3, 1.0],
        ),
        boxShadow: [
          // Main 3D shadow
          BoxShadow(
            color: item["shadowColor"].withOpacity(0.3),
            offset: const Offset(0, 6),
            blurRadius: 15,
            spreadRadius: 0,
          ),
          // Inner shadow for depth
          BoxShadow(
            color: item["primaryColor"].withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 8,
            spreadRadius: -2,
          ),
          // Top highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            offset: const Offset(-1, -1),
            blurRadius: 3,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
              item["shadowColor"].withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Icon(
          item["icon"],
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVaultCard(Map<String, dynamic> item, int index) {
    final animationDelay = index * 0.08;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(animationDelay, animationDelay + 0.4, curve: Curves.easeOutBack),
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(animationDelay, animationDelay + 0.4, curve: Curves.easeOut),
    ));

    final scaleAnimation = _tappedIndex == index
        ? Tween<double>(begin: 1.0, end: 0.92).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          )
        : Tween<double>(begin: 1.0, end: 1.0).animate(_controller);

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: GestureDetector(
            onTap: () => _onCardTap(item["title"], index),
            onTapDown: (_) => HapticFeedback.selectionClick(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // Primary card shadow
                  BoxShadow(
                    color: item["primaryColor"].withOpacity(0.12),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                  // Subtle depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 3D Icon
                    _build3DIcon(item, _tappedIndex == index),
                    
                    const SizedBox(height: 16),
                    
                    // Title with better typography
                    Text(
                      item["title"],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: item["primaryColor"],
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Subtle accent line
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      height: 2,
                      width: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item["primaryColor"].withOpacity(0.3),
                            item["primaryColor"],
                            item["primaryColor"].withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Enhanced header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      "${widget.userName}'s Vault 🎒",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B2C87),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your collections in one place",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 4,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // Grid with better spacing
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: vaultItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    return _buildVaultCard(vaultItems[index], index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}