import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../models/educational_resource.dart';
import '../providers/education_provider.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  EducationalResource? _resource;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResource();
  }

  Future<void> _loadResource() async {
    final provider = context.read<EducationProvider>();
    final resource = await provider.loadResourceById(widget.resourceId);
    if (mounted) {
      setState(() {
        _resource = resource;
        _isLoading = provider.isLoadingDetail;
        _error = provider.error;
      });
    }
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

  void _openVideo(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.resourceHub)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _resource == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.resourceHub)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? loc.resourceNotFound),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResource,
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
      );
    }

    final resource = _resource!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryLabel(loc, resource.category)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.isFeatured)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.featured,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            Text(
              resource.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${resource.viewCount} ${loc.views}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${resource.createdAt.year}-${resource.createdAt.month.toString().padLeft(2, '0')}-${resource.createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (resource.summary != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                ),
                child: Text(
                  resource.summary!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            if (resource.summary != null) const SizedBox(height: 20),
            if (resource.contentBody != null)
              _renderMarkdown(resource.contentBody!),
            if (resource.hasVideo) const SizedBox(height: 24),
            if (resource.hasVideo)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.videoTutorial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (resource.formattedDuration != null)
                            Text(
                              resource.formattedDuration!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openVideo(resource.videoUrl!),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: Text(loc.watch),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(loc.back),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a simple markdown-like view of the content body.
  /// Handles headings (##, ###), bullet points (-), and paragraphs.
  Widget _renderMarkdown(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            trimmed.substring(4),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            trimmed.substring(3),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ));
      } else if (trimmed.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(trimmed.substring(2), style: const TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(trimmed, style: const TextStyle(fontSize: 15, height: 1.5)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
