import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hortikita/ui/widgets/plants/plant_card_widget.dart';
import 'package:hortikita/data/models/plant_model.dart';

void main() {
  group('PlantCard Widget Tests', () {
    late Plant testPlant;

    setUp(() {
      testPlant = Plant(
        id: 'test-plant-1',
        name: 'Test Plant',
        scientificName: 'Testus plantus',
        category: 'Sayuran',
        difficulty: 'Mudah',
        description: 'This is a test plant description that might be quite long to test text overflow behavior.',
        imageUrl: 'https://example.com/test-plant.jpg',
        careInstructions: [],
        growthDuration: 30,
        wateringFrequency: 'Daily',
        sunlightRequirement: 'Full sun',
        soilType: 'Well-drained',
        harvestTime: '30 days',
        benefits: 'Nutritious and healthy',
        plantingSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('PlantCard displays plant information correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: PlantCard(
                plant: testPlant,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify plant name is displayed
      expect(find.text('Test Plant'), findsOneWidget);
      
      // Verify scientific name is displayed
      expect(find.text('Testus plantus'), findsOneWidget);
      
      // Verify category tag is displayed
      expect(find.text('Sayuran'), findsOneWidget);
      
      // Verify difficulty tag is displayed
      expect(find.text('Mudah'), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(PlantCard));
      expect(tapped, isTrue);
    });

    testWidgets('PlantCard handles long text with ellipsis', (WidgetTester tester) async {
      final longNamePlant = Plant(
        id: 'test-plant-2',
        name: 'This is a very long plant name that should be truncated',
        scientificName: 'Very long scientific name that should also be truncated',
        category: 'Sayuran',
        difficulty: 'Mudah',
        description: 'This is a very long description that should be truncated after two lines to prevent overflow issues in the card layout.',
        imageUrl: 'https://example.com/test-plant.jpg',
        careInstructions: [],
        growthDuration: 30,
        wateringFrequency: 'Daily',
        sunlightRequirement: 'Full sun',
        soilType: 'Well-drained',
        harvestTime: '30 days',
        benefits: 'Nutritious and healthy',
        plantingSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: PlantCard(
                plant: longNamePlant,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify the widget renders without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('PlantCard works in GridView layout', (WidgetTester tester) async {
      final plants = List.generate(4, (index) => Plant(
        id: 'plant-$index',
        name: 'Plant $index',
        scientificName: 'Plantus $index',
        category: 'Sayuran',
        difficulty: 'Mudah',
        description: 'Description for plant $index',
        imageUrl: 'https://example.com/plant-$index.jpg',
        careInstructions: [],
        growthDuration: 30,
        wateringFrequency: 'Daily',
        sunlightRequirement: 'Full sun',
        soilType: 'Well-drained',
        harvestTime: '30 days',
        benefits: 'Nutritious and healthy',
        plantingSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  return PlantCard(
                    plant: plants[index],
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify cards are rendered (at least some should be visible)
      expect(find.byType(PlantCard), findsAtLeastNWidgets(1));

      // Verify no overflow exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
