# 🌱 HortikulturaApp - Smart Plant Care with Chatbot

<p align="center">
  <img src="https://i.ibb.co.com/q3JtK37L/Screenshot-1746122151.png" alt="Hortikultura App" width="400" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen" alt="Version" />
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License" />
</p>

## 📋 Overview

HortikulturaApp is a comprehensive mobile application developed in Flutter to assist users in managing their gardening needs with smart features and expert advice. This project is part of a Sarjana's Thesis focused on improving horticulture knowledge and practices through technology.

The application leverages Firebase for backend services and integrates with Google's Gemini AI to provide intelligent plant care recommendations and answers to user queries.

## ✨ Features

### 🤖 AI-Powered Chatbot
- Get instant answers to your horticulture questions
- Receive personalized plant care advice
- Learn about optimal growing conditions for different plants
- Troubleshoot plant diseases and pest problems

### 📚 Comprehensive Plant Database
- Detailed information on a wide variety of plants
- Categorized by type (vegetables, fruits, ornamentals, spices)
- Growth requirements and care instructions
- Step-by-step planting guides

### 📝 Insightful Articles
- Latest gardening tips and techniques
- Seasonal planting guides
- Organic pest control methods
- Sustainable gardening practices

### 👤 User Management
- Personalized user profiles
- Save favorite plants and articles
- Track your plant care history
- Customize notifications and preferences

## 🛠️ Technology Stack

- **Frontend**: Flutter & Dart
- **Backend**: Firebase (Authentication, Cloud Firestore, Storage)
- **AI Integration**: Google Gemini API
- **State Management**: Provider
- **Networking**: HTTP Package
- **UI Components**: Custom-themed Material Design
- **Image Handling**: Cached Network Image
- **Markdown Rendering**: Flutter Markdown

## 📱 Screenshots

<!-- Add actual screenshots here when available -->
<p align="center">
  <i>Screenshots coming soon</i>
</p>

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Google Gemini API key

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/hortikultura_app.git
cd hortikultura_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
   - Create a Firebase project
   - Add Android/iOS apps in Firebase console
   - Download and place the `google-services.json` file in the appropriate directory
   - Enable Authentication, Cloud Firestore, and Storage services

4. Configure Gemini API
   - Obtain a Gemini API key from [Google AI Studio](https://ai.google.dev/)
   - Create a `.env` file in the project root and add your API key:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```

5. Run the app
```bash
flutter run
```

## 📂 Project Structure

```
lib/
├── app/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_constants.dart
├── data/
│   ├── models/
│   │   ├── article_model.dart
│   │   ├── chat_message_model.dart
│   │   ├── plant_model.dart
│   │   └── user_model.dart
│   ├── providers/
│   │   ├── article_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── chat_provider.dart
│   │   └── plant_provider.dart
│   └── repositories/
│       ├── article_repository.dart
│       ├── chat_repository.dart
│       └── plant_repository.dart
├── services/
│   ├── auth_service.dart
│   ├── firebase_service.dart
│   └── gemini_service.dart
├── ui/
│   ├── screens/
│   │   ├── articles/
│   │   ├── auth/
│   │   ├── chatbot/
│   │   ├── home/
│   │   ├── plants/
│   │   └── splash/
│   ├── themes/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── articles/
│       ├── chatbot/
│       └── plants/
└── main.dart
```

## 🧪 Development and Testing

### Running Tests
```bash
flutter test
```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Future Development Plans

- Plant disease detection using camera
- Community forum for sharing gardening experiences
- Weather integration for location-based planting advice
- Plant growth tracking and reminders
- Marketplace for seeds and gardening supplies

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Firebase** - For backend services
- **Google Gemini API** - For AI capabilities
- **Unsplash & Pixabay** - For sample plant images

## 📬 Contact

Have feedback or need support? Please reach out at [me@pras.ari69@gmail.com](mailto:me@pras.ari69@gmail.com).

---

<p align="center">
  Made with ❤️ for plants and plant lovers
</p>
