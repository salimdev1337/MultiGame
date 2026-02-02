## 🎯 Features

- 🧩 **Multiple Game Modes**: Image puzzle, Number puzzle, Memory game (coming soon)
- 🏆 **Achievement System**: Unlock achievements as you complete puzzles
- 📊 **Statistics Tracking**: Track your best times and moves
- 🎨 **Beautiful UI**: Modern dark theme with smooth animations
- 📱 **Cross-Platform**: Android, iOS, Windows, Web
- 🌐 **Play Online**: [Play now on GitHub Pages](https://salimdev1337.github.io/MultiGame)

## 🚀 Live Demo

**Play online:** (https://salimdev1337.github.io/MultiGame)
## 📥 Download

### Latest Release
Download the latest version for your platform:

- **Android**: [Download APK](https://github.com/salimdev1337/MultiGame/releases/latest)
- **Windows**: [Download ZIP](https://github.com/salimdev1337/MultiGame/releases/latest)
- **Web**: [Play Online](https://salimdev1337.github.io/MultiGame)

## 🎮 Game Modes

### Image Puzzle (Available)
Classic sliding puzzle with beautiful images from Unsplash. Choose from 3x3, 4x4, or 5x5 grids.

### Number Puzzle (Coming Soon)
Traditional 15-puzzle with numbers.

### Memory Game (Coming Soon)
Match pairs of cards to win.

## 🏆 Achievements

Unlock achievements by completing challenges:
- 🎉 **First Victory**: Complete your first puzzle
- 🎮 **Puzzle Fan**: Complete 5 puzzles
- 🏆 **Puzzle Master**: Complete 10 puzzles
- ⭐ **3x3 Expert**: Complete a 3x3 in under 100 moves
- 💎 **4x4 Pro**: Complete a 4x4 in under 200 moves
- ⚡ **Speed Demon**: Complete any puzzle in under 60 seconds

## 🏗️ Architecture

MultiGame follows a **clean, layered architecture** with:
- **Dependency Injection** via GetIt for loose coupling
- **Repository Pattern** for data persistence abstraction
- **Provider Pattern** for reactive state management
- **Feature-First Structure** for scalability
- **Separation of Concerns** between UI, business logic, and data layers

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed documentation.

### Security Features

- 🔒 **Encrypted local storage** for sensitive data (Flutter Secure Storage)
- ✅ **Input validation** on all user inputs
- 🛡️ **Secure logging** that prevents credential leakage
- 🔥 **Firestore security rules** to protect database access
- 🔑 **API key protection** through build-time configuration

See [docs/SECURITY.md](docs/SECURITY.md) for security best practices.

## 🛠️ Built With

- [Flutter](https://flutter.dev/) - UI Framework
- [Provider](https://pub.dev/packages/provider) - State management
- [GetIt](https://pub.dev/packages/get_it) - Dependency injection
- [Firebase](https://firebase.google.com/) - Backend services
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) - Encrypted storage
- [Flame](https://flame-engine.org/) - Game engine (Infinite Runner)
- [Shared Preferences](https://pub.dev/packages/shared_preferences) - Local storage
- [Carousel Slider](https://pub.dev/packages/carousel_slider) - Game carousel
- [HTTP](https://pub.dev/packages/http) - Image fetching

## 🚀 CI/CD

This project uses GitHub Actions for automated testing, building, and deployment:

- ✅ **Continuous Integration**: Automated tests on every commit
- 🔨 **Multi-Platform Builds**: Automatic builds for Android, Windows, and Web
- 🌐 **Auto Deployment**: Web version deploys to GitHub Pages automatically
- 📦 **Releases**: Automated release creation with downloadable builds

**Learn more**: Check out our [CI/CD Learning Guide](.github/CI_CD_GUIDE.md)

## 📱 Getting Started for Developers

### Prerequisites

- Flutter SDK (3.27.1 or higher)
- Dart SDK (3.10.4 or higher)
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/salimdev1337/puzzle.git
cd puzzle
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase (required for score tracking):
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (generates lib/config/firebase_options.dart)
flutterfire configure

# Follow the prompts to select/create a Firebase project
# See docs/FIREBASE_SETUP_GUIDE.md for detailed instructions
```

**Important:** Add `lib/config/firebase_options.dart` to your `.gitignore` (already configured).

4. Configure API keys (optional):
```bash
# See docs/API_CONFIGURATION.md for detailed instructions
# The app will work with fallback images without API configuration
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

5. Run the app:
```bash
# Android/iOS
flutter run

# Windows
flutter run -d windows

# Web
flutter run -d chrome
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point, DI setup
│
├── config/                        # Configuration
│   ├── service_locator.dart      # Dependency injection setup
│   ├── api_config.dart           # API key management
│   └── firebase_options.dart     # Firebase config (gitignored)
│
├── core/                          # Core interfaces
│   ├── game_interface.dart       # Game registration interface
│   └── game_registry.dart        # Game registry system
│
├── games/                         # Feature-based game modules
│   ├── puzzle/                   # Image Puzzle
│   ├── game_2048/                # 2048 Game
│   ├── snake/                    # Snake Game
│   └── infinite_runner/          # Infinite Runner (Flame)
│
├── models/                        # Shared data models
│   ├── game_model.dart
│   ├── achievement_model.dart
│   └── user_stats_model.dart
│
├── providers/                     # State management
│   ├── user_auth_provider.dart
│   └── mixins/
│       └── game_stats_mixin.dart
│
├── repositories/                  # Data access layer
│   ├── secure_storage_repository.dart
│   ├── user_repository.dart
│   └── stats_repository.dart
│
├── services/                      # Business logic
│   ├── auth/                     # Authentication
│   ├── data/                     # Firebase operations
│   ├── game/                     # Game services
│   └── storage/                  # Persistence
│
├── screens/                       # UI screens
│   ├── main_navigation.dart
│   ├── home_page.dart
│   └── [game]_page.dart
│
├── widgets/                       # Reusable widgets
│   ├── game_carousel.dart
│   ├── achievement_card.dart
│   └── dialogs/
│
└── utils/                         # Utilities
    ├── input_validator.dart
    ├── secure_logger.dart
    └── dialog_utils.dart

docs/                              # Documentation
├── ARCHITECTURE.md                # Architecture guide
├── SECURITY.md                    # Security best practices
├── ADDING_GAMES.md                # Game integration guide
├── API_CONFIGURATION.md           # API setup
├── FIREBASE_SETUP_GUIDE.md        # Firebase setup
└── INFINITE_RUNNER_ARCHITECTURE.md

assets/
├── images/                        # Game images and sprites
└── (audio, fonts coming soon)
```

**See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.**

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Note**: All pull requests trigger automated tests. Make sure tests pass before requesting review.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Author

**Your Name**
- GitHub: [@ME](https://github.com/salimdev1337)

## 🙏 Acknowledgments

- Images from [Unsplash](https://unsplash.com/)
- Flutter team for the amazing framework
- All contributors who help improve this project

## 📞 Support

If you encounter any issues or have questions:
- Open an [issue](https://github.com/salimdev1337/puzzle/issues)
- Check the [CI/CD Guide](.github/CI_CD_GUIDE.md)
- Browse documentation in the [docs/](docs/) folder

## 📚 Documentation

### For Developers
- **[Architecture Guide](docs/ARCHITECTURE.md)** - Application architecture, patterns, and design decisions
- **[Security Best Practices](docs/SECURITY.md)** - Security guidelines and implementation
- **[Adding Games](docs/ADDING_GAMES.md)** - Step-by-step guide for adding new games

### Setup & Configuration
- [API Configuration](docs/API_CONFIGURATION.md) - Unsplash API setup
- [Firebase Setup](docs/FIREBASE_SETUP_GUIDE.md) - Firebase configuration guide
- [CI/CD Setup](docs/CI_CD_SETUP_COMPLETE.md) - GitHub Actions workflows

### Technical Details
- [Infinite Runner Architecture](docs/INFINITE_RUNNER_ARCHITECTURE.md) - Flame engine architecture
- [Security Improvements](docs/SECURITY_IMPROVEMENTS.md) - Security changelog

### Sudoku Game (NEW)
- **[Sudoku Quick Reference](docs/SUDOKU_QUICK_REFERENCE.md)** - API reference and usage examples
- **[Sudoku Phase 1 Analysis](docs/SUDOKU_PHASE1_ANALYSIS.md)** - Complete implementation analysis and test coverage

## 🔒 Security

This project implements industry-standard security practices:
- All sensitive data is encrypted using Flutter Secure Storage
- API keys are never committed to version control
- Input validation prevents injection attacks
- Secure logging prevents credential leakage
- Firebase security rules protect user data

**Report security issues:** Do not open public issues. Email security concerns privately.

See [docs/SECURITY.md](docs/SECURITY.md) for complete security documentation.


