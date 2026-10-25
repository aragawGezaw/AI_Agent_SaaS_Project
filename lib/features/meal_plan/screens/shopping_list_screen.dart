import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_plan_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _checkedItems = {};

  // Clinical reference mapping for Ethiopian staples & target protein yields (~30g protein target)
  final List<Map<String, String>> _clinicalStaples = [
    {
      'category': 'Animal Proteins (Non-Fasting Days)',
      'item': 'Lean Beef (Key Sega)',
      'portion': '115g per meal',
      'yield': 'Yields ~30.0g Protein (Low GL)',
    },
    {
      'category': 'Animal Proteins (Non-Fasting Days)',
      'item': 'Whole Eggs',
      'portion': '5 large eggs (or combined with Ayib)',
      'yield': 'Yields ~30.0g Protein',
    },
    {
      'category': 'Plant Proteins & Legumes (Fasting Compliant)',
      'item': 'Red Lentils (Misir Kik)',
      'portion': '90g dry weight per meal',
      'yield': 'Yields ~22.5g Protein + High Fiber (Low GL)',
    },
    {
      'category': 'Plant Proteins & Legumes (Fasting Compliant)',
      'item': 'Shiro Powder (Chickpea Flour)',
      'portion': '80g powder per meal',
      'yield': 'Yields ~17.5g Protein + Plant Fiber',
    },
    {
      'category': 'Plant Proteins & Legumes (Fasting Compliant)',
      'item': 'Cottage Cheese (Ayib)',
      'portion': '120g per serving',
      'yield': 'Yields ~22.0g High-Value Dairy Protein',
    },
    {
      'category': 'Grains & Complex Carbs',
      'item': 'Teff Flour (Brown/White for Injera)',
      'portion': '100g dry batter equivalent',
      'yield': 'Low Glycemic Index Staple (<10 GL)',
    },
    {
      'category': 'Spices, Aromatics & Healthy Fats',
      'item': 'Berbere Spice Blend',
      'portion': '15g per recipe batch',
      'yield': 'Enhances Thermogenesis & Insulin Sensitivity',
    },
    {
      'category': 'Spices, Aromatics & Healthy Fats',
      'item': 'Niter Kibbeh / Vegetable Oil',
      'portion': '10ml (1 tablespoon)',
      'yield': 'Healthy Lipid & Satiety Control',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Grocery & Portion Checklist'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Target & Portion Guidance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Each grocery item below outlines exact portion sizes calibrated to hit your ~30g per-meal protein target while keeping Glycemic Load (GL) low and ensuring Orthodox fasting compliance.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._clinicalStaples.map((staple) {
                final itemName = staple['item']!;
                final isChecked = _checkedItems.contains(itemName);

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      itemName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: isChecked ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Portion Size: ${staple['portion']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Yield Target: ${staple['yield']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Category: ${staple['category']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    value: isChecked,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _checkedItems.add(itemName);
                        } else {
                          _checkedItems.remove(itemName);
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
