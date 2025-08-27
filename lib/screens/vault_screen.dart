import 'package:flutter/material.dart';

class VaultScreen extends StatefulWidget {
  final String userName;
  
  const VaultScreen({super.key, required this.userName});

  @override
  _VaultScreenState createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late AnimationController _headerController;
  late AnimationController _microController;
  late List<Animation<Offset>> _cardAnimations;
  late List<Animation<double>> _scaleAnimations;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final List<Map<String, dynamic>> vaultCollections = [
    {
      'title': 'Book Collection',
      'icon': Icons.menu_book_rounded,
      'color': Colors.blue,
      'description': 'Track your reading journey',
      'count': '12 books',
      'progress': 0.75,
      'gradient': [Colors.blue.shade400, Colors.blue.shade600]
    },
    {
      'title': 'Recipe Keeper',
      'icon': Icons.restaurant_rounded,
      'color': Colors.orange,
      'description': 'Save your favorite recipes',
      'count': '8 recipes',
      'progress': 0.60,
      'gradient': [Colors.orange.shade400, Colors.orange.shade600]
    },
    {
      'title': 'Movie Tracker',
      'icon': Icons.movie_rounded,
      'color': Colors.red,
      'description': 'Keep track of entertainment',
      'count': '25 items',
      'progress': 0.85,
      'gradient': [Colors.red.shade400, Colors.red.shade600]
    },
    {
      'title': 'Favorite Quotes',
      'icon': Icons.format_quote_rounded,
      'color': Colors.purple,
      'description': 'Inspiring words collection',
      'count': '15 quotes',
      'progress': 0.45,
      'gradient': [Colors.purple.shade400, Colors.purple.shade600]
    },
    {
      'title': 'Pet Favorites',
      'icon': Icons.pets_rounded,
      'color': Colors.green,
      'description': 'Your beloved companions',
      'count': '3 pets',
      'progress': 0.90,
      'gradient': [Colors.green.shade400, Colors.green.shade600]
    },
    {
      'title': 'Travel Memories',
      'icon': Icons.flight_takeoff_rounded,
      'color': Colors.teal,
      'description': 'Adventures around the world',
      'count': '7 places',
      'progress': 0.55,
      'gradient': [Colors.teal.shade400, Colors.teal.shade600]
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _microController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    
    _headerSlide = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.elasticOut));
    
    // Create staggered animations for cards
    _cardAnimations = List.generate(
      vaultCollections.length,
      (index) => Tween<Offset>(
        begin: Offset(1.2, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.12,
            0.6 + index * 0.12,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
    
    _scaleAnimations = List.generate(
      vaultCollections.length,
      (index) => Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.12,
            0.6 + index * 0.12,
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );
    
    _headerController.forward();
    Future.delayed(Duration(milliseconds: 400), () {
      _controller.forward();
    });
  }

  void _onCardTap(int index) {
    _microController.forward().then((_) {
      _microController.reverse();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.white),
            SizedBox(width: 10),
            Text('${vaultCollections[index]['title']} - Coming Soon!'),
          ],
        ),
        backgroundColor: vaultCollections[index]['color'][600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(milliseconds: 2000),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _headerController.dispose();
    _microController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          
          // Header with animation
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple[600]!, Colors.deepPurple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_special_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                    SizedBox(height: 15),
                    Text(
                      '${widget.userName}\'s Vault',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your personal collections await',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 30),
          
          // Collections List with enhanced animations
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: vaultCollections.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SlideTransition(
                    position: _cardAnimations[index],
                    child: ScaleTransition(
                      scale: _scaleAnimations[index],
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: _buildEnhancedVaultCard(vaultCollections[index], index),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEnhancedVaultCard(Map<String, dynamic> collection, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (collection['color'] as MaterialColor).withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: (collection['color'] as MaterialColor)[100]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onCardTap(index),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon Container with gradient
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: collection['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (collection['color'] as MaterialColor).withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        collection['icon'],
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    
                    SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            collection['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (collection['color'] as MaterialColor)[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: (collection['color'] as MaterialColor)[200]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              collection['count'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: collection['color'][700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow with micro-interaction
                    AnimatedBuilder(
                      animation: _microController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_microController.value * 4, 0),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Progress indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Collection Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(collection['progress'] * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: collection['color'][600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: collection['progress'],
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: collection['gradient'],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
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
}