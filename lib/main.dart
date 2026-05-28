import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MealApp());
}

class MealApp extends StatelessWidget {
  const MealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8572A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      home: const HomePage(),
    );
  }
}

// ─── MODEL ───────────────────────────────────────────────────────────────────

class Meal {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbnail;
  final List<String> ingredients;
  final List<String> measures;

  Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbnail,
    required this.ingredients,
    required this.measures,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    final measures = <String>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString().trim());
        measures.add(measure?.toString().trim() ?? '');
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'] ?? '',
      area: json['strArea'] ?? '',
      instructions: json['strInstructions'] ?? '',
      thumbnail: json['strMealThumb'] ?? '',
      ingredients: ingredients,
      measures: measures,
    );
  }
}

// ─── API SERVICE ──────────────────────────────────────────────────────────────

class MealService {
  static Future<List<Meal>> searchMeals(String query) async {
    final url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(query)}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) return [];
      return (data['meals'] as List).map((m) => Meal.fromJson(m)).toList();
    }
    throw Exception('Failed to load meals');
  }
}

// ─── HOME PAGE ────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  List<Meal> _meals = [];
  bool _loading = false;
  bool _searched = false;
  String _error = '';

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = true;
      _error = '';
      _meals = [];
    });

    try {
      final results = await MealService.searchMeals(query);
      setState(() {
        _meals = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFE8572A);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🍽️ Recipe Finder',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search for any meal to discover recipes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _search(),
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'e.g. chicken, pasta, salad...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _search,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: orange,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE8572A),
                      ),
                    )
                  : _error.isNotEmpty
                      ? Center(
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : !_searched
                          ? _buildWelcome()
                          : _meals.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No recipes found 😕\nTry a different word!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🥗', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'What are you craving today?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C3D2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try: chicken  •  pasta  •  salad  •  beef',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: _meals.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final meal = _meals[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPage(meal: meal),
              ),
            ),
            child: _MealCard(meal: meal),
          );
        },
      ),
    );
  }
}

// ─── MEAL CARD ────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.network(
              meal.thumbnail,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 130,
                color: Colors.grey[200],
                child:
                    const Icon(Icons.restaurant, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D1B0E),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 12, color: Color(0xFFE8572A)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        meal.area,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meal.category,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE8572A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DETAIL PAGE ──────────────────────────────────────────────────────────────

class DetailPage extends StatelessWidget {
  final Meal meal;
  const DetailPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFE8572A);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      body: CustomScrollView(
        slivers: [
          // ── App Bar with image ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: orange,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    meal.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _chip(meal.category, Icons.category_rounded),
                            const SizedBox(width: 8),
                            _chip(meal.area, Icons.public_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredients
                  _sectionTitle('Ingredients', Icons.shopping_basket_rounded),
                  const SizedBox(height: 12),
                  ...List.generate(meal.ingredients.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              meal.ingredients[i],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2D1B0E),
                              ),
                            ),
                          ),
                          Text(
                            meal.measures[i],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  // Instructions
                  _sectionTitle('Instructions', Icons.menu_book_rounded),
                  const SizedBox(height: 12),
                  Text(
                    meal.instructions,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Color(0xFF4A3728),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE8572A), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1B0E),
          ),
        ),
      ],
    );
  }
}
