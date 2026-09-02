import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../models/educational_resource.dart';
import '../providers/education_provider.dart';
import 'resource_detail_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final lang = context.read<LanguageProvider>().locale.languageCode;
    final provider = context.read<EducationProvider>();
    provider.loadResources(language: lang);
    provider.loadCategories(language: lang);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryTap(String? category) {
    final provider = context.read<EducationProvider>();
    if (category == provider.selectedCategory) {
      provider.clearCategory();
    } else {
      provider.setCategory(category);
    }
  }

  void _onSearch(String term) {
    context.read<EducationProvider>().search(term);
  }

  void _openDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResourceDetailScreen(resourceId: id),
      ),
    );
  }

  String _categoryLabel(AppLocalizations loc, String id) {
    switch (id) {
      case 'nutrition':
        return loc.eduCategoryNutrition;
      case 'glycemic_index':
        return loc.eduCategoryGlycemicIndex;
      case 'fasting':
        return loc.eduCategoryFasting;
      case 'recipes':
        return loc.eduCategoryRecipes;
      case 'health_tips':
        return loc.eduCategoryHealthTips;
      case 'exercise':
        return loc.eduCategoryExercise;
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resourceHub),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
            onPressed: () => context.read<EducationProvider>().refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.searchResources,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _onSearch,
            ),
          ),
          Consumer<EducationProvider>(
            builder: (ctx, provider, _) {
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _categoryChip(loc, null, provider.selectedCategory == null),
                    _buildCategoryChip(loc, 'nutrition', provider.selectedCategory, Icons.restaurant_menu),
                    _buildCategoryChip(loc, 'glycemic_index', provider.selectedCategory, Icons.analytics),
                    _buildCategoryChip(loc, 'fasting', provider.selectedCategory, Icons.schedule),
                    _buildCategoryChip(loc, 'recipes', provider.selectedCategory, Icons.menu_book),
                    _buildCategoryChip(loc, 'health_tips', provider.selectedCategory, Icons.lightbulb),
                    _buildCategoryChip(loc, 'exercise', provider.selectedCategory, Icons.fitness_center),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<EducationProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(loc.errorOccurred,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: Text(loc.retry),
                        ),
                      ],
                    ),
                  );
                }
                if (provider.resources.isEmpty) {
                  return Center(
                    child: Text(
                      provider.searchQuery != null
                          ? loc.noSearchResults
                          : loc.noResources,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: provider.resources.length,
                    itemBuilder: (ctx, index) {
                      final resource = provider.resources[index];
                      return _resourceCard(resource, loc);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(AppLocalizations loc, String? id, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(loc.filterAll),
        selected: selected,
        selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
        onSelected: (_) => _onCategoryTap(null),
      ),
    );
  }

  Widget _buildCategoryChip(
    AppLocalizations loc,
    String id,
    String? selected,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(_categoryLabel(loc, id)),
          ],
        ),
        selected: selected == id,
        selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.2),
        onSelected: (_) => _onCategoryTap(id),
      ),
    );
  }

  Widget _resourceCard(EducationalResource resource, AppLocalizations loc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDetail(resource.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (resource.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loc.featured,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _categoryLabel(loc, resource.category),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                resource.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (resource.summary != null) ...[
                const SizedBox(height: 6),
                Text(
                  resource.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${resource.viewCount} ${loc.views}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const Spacer(),
                  if (resource.hasVideo)
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          loc.video,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
