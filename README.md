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

- **Android**: [Download APK](https://github.com/yourusername/MultiGame/releases/latest)
- **Windows**: [Download ZIP](https://github.com/yourusername/MultiGame/releases/latest)
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

## 🛠️ Built With

- [Flutter](https://flutter.dev/) - UI Framework
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
git clone https://github.com/yourusername/puzzle.git
cd puzzle
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API keys (optional):
```bash
# See docs/API_CONFIGURATION.md for detailed instructions
# The app will work with fallback images without API configuration
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

4. Run the app:
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
├── main.dart                      # App entry point
├── puzzle_game_logic.dart         # Puzzle game logic
├── screens/
│   ├── main_navigation.dart       # Bottom navigation
│   ├── home_page.dart            # Home with carousel
│   ├── puzzle.dart               # Image puzzle game
│   └── profile_screen.dart       # User profile & stats
├── models/
│   ├── game_model.dart           # Game definitions
│   ├── achievement_model.dart    # Achievement system
│   └── puzzle_piece.dart         # Puzzle piece model
├── services/
│   ├── achievement_service.dart  # Achievement logic
│   ├── image_puzzle_generator.dart
│   └── unsplash_service.dart
├── widgets/
│   ├── game_carousel.dart        # Game selection carousel
│   ├── achievement_card.dart     # Achievement display
│   └── image_puzzle_piece.dart   # Puzzle tile widget
├── providers/
│   ├── puzzle_game_provider.dart # Puzzle state management
│   ├── game_2048_provider.dart   # 2048 game provider
│   └── snake_game_provider.dart  # Snake game provider
├── infinite_runner/               # Infinite runner game module
│   ├── components/
│   ├── state/
│   ├── systems/
│   └── ui/
└── config/
    └── api_config.dart           # API configuration

docs/                              # Documentation
├── API_CONFIGURATION.md
├── FIREBASE_SETUP_GUIDE.md
├── INFINITE_RUNNER_ARCHITECTURE.md
└── ...more documentation files

assets/
├── images/                        # Game images and sprites
├── audio/                         # Sound effects (coming soon)
└── fonts/                         # Custom fonts (coming soon)
```

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

For detailed guides and documentation, see:
- [API Configuration](docs/API_CONFIGURATION.md)
- [Firebase Setup](docs/FIREBASE_SETUP_GUIDE.md)
- [Infinite Runner Architecture](docs/INFINITE_RUNNER_ARCHITECTURE.md)
- [CI/CD Setup](docs/CI_CD_SETUP_COMPLETE.md)
- [Security Improvements](docs/SECURITY_IMPROVEMENTS.md)


