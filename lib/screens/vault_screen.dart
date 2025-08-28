import 'package:flutter/material.dart';
// Import all the new collection screens
import 'book_collection_screen.dart';
import 'recipe_collection_screen.dart';
import 'movie_collection_screen.dart';
import 'quote_collection_screen.dart';
import 'pet_collection_screen.dart';
import 'travel_collection_screen.dart';

class VaultScreen extends StatefulWidget {
  final String userName;

  const VaultScreen({super.key, required this.userName});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  final List<Map<String, dynamic>> vaultItems = [
    {"title": "Books", "icon": Icons.menu_book_rounded, "color": Colors.blue},
    {"title": "Recipes", "icon": Icons.restaurant_menu, "color": Colors.orange},
    {"title": "Movies", "icon": Icons.movie_rounded, "color": Colors.red},
    {"title": "Quotes", "icon": Icons.format_quote_rounded, "color": Colors.purple},
    {"title": "Pets", "icon": Icons.pets_rounded, "color": Colors.green},
    {"title": "Travel", "icon": Icons.flight_takeoff_rounded, "color": Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  void _onCardTap(String title) {
    _controller.forward().then((_) {
      _controller.reverse();
    });

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Determine which screen to navigate to based on the card title
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
      default:
        // If the title doesn't match any known screens, show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title - Coming Soon!'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black87,
          ),
        );
        return; // Exit the function if no valid destination is found
    }

    // Navigate to the chosen destination screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildVaultCard(Map<String, dynamic> item) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
      ),
      child: GestureDetector(
        onTap: () => _onCardTap(item["title"]),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (item["color"] as Color).withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: (item["color"] as Color).withOpacity(0.12),
                child: Icon(item["icon"], color: item["color"], size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item["title"],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item["color"],
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "${widget.userName}'s Vault 🎒📦",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Your collections in one place",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grid Layout
              Expanded(
                child: GridView.builder(
                  itemCount: vaultItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 per row
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1.05, // smaller white boxes
                  ),
                  itemBuilder: (context, index) {
                    return _buildVaultCard(vaultItems[index]);
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