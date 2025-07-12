# 🤝 Contributing to HortiKita

First off, thank you for considering contributing to HortiKita! It's people like you that make HortiKita such a great tool for the Indonesian gardening community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Style Guidelines](#style-guidelines)
- [Development Workflow](#development-workflow)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

## 📜 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

### Our Pledge
- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.7.0+
- Dart SDK
- Git
- A GitHub account
- Basic knowledge of Flutter/Dart

### Development Setup
```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/prassaaa/hortikultura_app.git
cd HortiKita

# 3. Add upstream remote
git remote add upstream https://github.com/prassaaa/hortikultura_app.git

# 4. Install dependencies
flutter pub get

# 5. Set up environment
cp .env.example .env
# Edit .env with your API keys

# 6. Run the app
flutter run
```

## 🤝 How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one.

**How to submit a good bug report:**

1. **Use a clear and descriptive title**
2. **Describe the exact steps to reproduce the problem**
3. **Provide specific examples**
4. **Include screenshots or GIFs if applicable**
5. **Describe the behavior you observed and what behavior you expected**
6. **Include your environment details:**
   - OS version
   - Flutter version
   - Device model (if mobile)

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

1. **Use a clear and descriptive title**
2. **Provide a detailed description of the suggested enhancement**
3. **Explain why this enhancement would be useful**
4. **Include mockups or examples if applicable**

### 🔧 Pull Requests

1. **Follow the development workflow**
2. **Include tests for new functionality**
3. **Update documentation as needed**
4. **Follow the style guidelines**
5. **Write a good commit message**

## 🎨 Style Guidelines

### Dart/Flutter Code Style

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// ✅ Good
class PlantModel {
  final String name;
  final String scientificName;
  
  PlantModel({
    required this.name,
    required this.scientificName,
  });
}

// ❌ Bad  
class plant_model {
  String Name;
  String scientific_name;
}
```

### Code Organization

```dart
// File organization order:
// 1. Imports (dart: first, then package:, then relative)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant_model.dart';
import '../services/plant_service.dart';

// 2. Class declaration
class PlantScreen extends StatefulWidget {
  // 3. Constants
  static const routeName = '/plants';
  
  // 4. Fields
  final String title;
  
  // 5. Constructor
  const PlantScreen({
    super.key,
    required this.title,
  });
  
  // 6. Methods
  @override
  State<PlantScreen> createState() => _PlantScreenState();
}
```

### Naming Conventions

```dart
// Classes: PascalCase
class PlantProvider extends ChangeNotifier {}

// Variables and functions: camelCase
String plantName = 'Tomato';
void fetchPlantData() {}

// Constants: lowerCamelCase with const
const int maxRetryAttempts = 3;

// Private members: prefix with underscore
String _privateField;
void _privateMethod() {}

// Files: snake_case
plant_detail_screen.dart
user_model.dart
```

### Widget Structure

```dart
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    this.onTap,
  });

  final Plant plant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlantImage(),
              const SizedBox(height: 8),
              _buildPlantName(),
              _buildPlantDescription(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantImage() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(plant.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  
  // Additional private methods...
}
```

## 🔄 Development Workflow

### Branch Naming
```bash
# Feature branches
feature/plant-disease-detection
feature/user-profile-settings

# Bug fix branches  
bugfix/chat-message-loading
hotfix/security-vulnerability

# Documentation
docs/api-documentation
docs/setup-guide
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: type(scope): description

# Examples:
feat(plants): add disease detection feature
fix(auth): resolve email verification issue
docs(readme): update installation instructions
style(ui): improve button component spacing
refactor(services): extract common API logic
test(plants): add unit tests for plant model
chore(deps): update flutter dependencies
```

### Git Workflow

```bash
# 1. Ensure you're on main and up to date
git checkout main
git pull upstream main

# 2. Create a new branch
git checkout -b feature/your-feature-name

# 3. Make your changes and commit
git add .
git commit -m "feat(scope): your feature description"

# 4. Push to your fork
git push origin feature/your-feature-name

# 5. Create a Pull Request on GitHub
```

## 🧪 Testing Guidelines

### Writing Tests

```dart
// Unit Test Example
import 'package:flutter_test/flutter_test.dart';
import 'package:hortikita/models/plant_model.dart';

void main() {
  group('PlantModel', () {
    test('should create plant from valid data', () {
      // Arrange
      final plantData = {
        'name': 'Tomato',
        'scientificName': 'Solanum lycopersicum',
        'category': 'Vegetable',
      };

      // Act
      final plant = PlantModel.fromMap(plantData);

      // Assert
      expect(plant.name, equals('Tomato'));
      expect(plant.scientificName, equals('Solanum lycopersicum'));
      expect(plant.category, equals('Vegetable'));
    });

    test('should throw exception for invalid data', () {
      // Arrange
      final invalidData = <String, dynamic>{};

      // Act & Assert
      expect(
        () => PlantModel.fromMap(invalidData),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### Widget Testing

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hortikita/ui/widgets/plant_card.dart';
import 'package:hortikita/models/plant_model.dart';

void main() {
  testWidgets('PlantCard displays plant information', (tester) async {
    // Arrange
    final plant = PlantModel(
      id: '1',
      name: 'Tomato',
      scientificName: 'Solanum lycopersicum',
      imageUrl: 'https://example.com/image.jpg',
      category: 'Vegetable',
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlantCard(plant: plant),
        ),
      ),
    );

    // Assert
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Solanum lycopersicum'), findsOneWidget);
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/plant_model_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## 📚 Documentation

### Code Documentation

```dart
/// A model representing a plant in the hortikultura database.
///
/// This class contains all the essential information about a plant
/// including its botanical details, care instructions, and growth requirements.
class PlantModel {
  /// The unique identifier for this plant.
  final String id;
  
  /// The common name of the plant (e.g., "Tomato").
  final String name;
  
  /// The scientific/botanical name (e.g., "Solanum lycopersicum").
  final String scientificName;
  
  /// Creates a new [PlantModel] instance.
  ///
  /// All parameters are required except [photoUrl] which can be null
  /// if no image is available for the plant.
  ///
  /// Example:
  /// ```dart
  /// final plant = PlantModel(
  ///   id: '1',
  ///   name: 'Tomato',
  ///   scientificName: 'Solanum lycopersicum',
  /// );
  /// ```
  PlantModel({
    required this.id,
    required this.name,
    required this.scientificName,
  });
  
  /// Creates a [PlantModel] from a Firestore document.
  ///
  /// Throws [ArgumentError] if required fields are missing.
  factory PlantModel.fromFirestore(DocumentSnapshot doc) {
    // Implementation...
  }
}
```

### README Updates

When adding new features, update the relevant sections:
- Features list
- Installation instructions (if needed)
- API documentation links
- Screenshots (if UI changes)

## 🎯 Areas for Contribution

### High Priority
- 🐛 Bug fixes and performance improvements
- 🧪 Test coverage improvements
- 📱 UI/UX enhancements
- 🌐 Internationalization (i18n)

### Medium Priority
- 📊 Analytics and monitoring
- 🔍 Search functionality improvements
- 📝 Content management features
- 🎨 Design system refinements

### Future Features
- 🤖 AI model improvements
- 📱 Mobile-specific optimizations
- 🌦️ Weather integration
- 🛒 E-commerce features

## ❓ Questions?

Don't hesitate to ask questions by:
- Opening a [GitHub Discussion](https://github.com/prassaaa/HortiKita/discussions)
- Creating an issue with the "question" label
- Reaching out to maintainers directly

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Special mentions in the app's about section

Thank you for contributing to HortiKita! 🌱
