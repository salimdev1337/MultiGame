/// Model for FAQ (Frequently Asked Questions) items
class FaqItem {
  final String question;
  final String answer;
  final String category;
  final List<String>? relatedQuestions;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    this.relatedQuestions,
  });

  /// Default FAQ items for MultiGame
  static List<FaqItem> get defaultFaqs => [
    // General
    const FaqItem(
      question: 'What is MultiGame?',
      answer:
          'MultiGame is a collection of 5+ exciting games in one app, including Sudoku, Snake, 2048, Image Puzzle, and Infinite Runner. Track your progress, compete on leaderboards, and unlock achievements!',
      category: 'General',
    ),
    const FaqItem(
      question: 'Is MultiGame free to use?',
      answer:
          'Yes! MultiGame is completely free to download and play. All games and features are available at no cost.',
      category: 'General',
    ),
    const FaqItem(
      question: 'How do I change my nickname?',
      answer:
          'Go to your Profile page by tapping the profile icon in the bottom navigation. Tap on your current nickname to edit it. Your new nickname will be displayed on leaderboards.',
      category: 'General',
    ),

    // Sudoku
    const FaqItem(
      question: 'How do I play Sudoku online with friends?',
      answer:
          'From the Sudoku game, select "1v1 Online" mode. You can either create a room and share the 6-digit code with a friend, or join an existing room using their code. Both players compete to solve the same puzzle!',
      category: 'Sudoku',
      relatedQuestions: ['How do Sudoku hints work?'],
    ),
    const FaqItem(
      question: 'How do Sudoku hints work?',
      answer:
          'You get 3 hints per game. Tap the hint button to reveal the correct number for a selected cell. In online mode, both players share the same hint limit, so use them wisely!',
      category: 'Sudoku',
    ),
    const FaqItem(
      question: 'What are the Sudoku difficulty levels?',
      answer:
          'Sudoku offers 4 difficulty levels: Easy (40-45 clues), Medium (32-37 clues), Hard (28-32 clues), and Expert (22-27 clues). Higher difficulties have fewer starting numbers.',
      category: 'Sudoku',
    ),

    // Achievements
    const FaqItem(
      question: 'How do I unlock achievements?',
      answer:
          'Achievements are unlocked by completing specific challenges in games. Check the Achievements page to see all available achievements and track your progress. New achievements are celebrated with confetti!',
      category: 'Achievements',
    ),
    const FaqItem(
      question: 'What are achievement tiers?',
      answer:
          'Achievements have different rarity tiers based on difficulty: Common (easy to get), Rare (requires skill), Epic (challenging), and Legendary (very difficult). Rarer achievements have special visual effects!',
      category: 'Achievements',
    ),

    // Leaderboards
    const FaqItem(
      question: 'How do leaderboards work?',
      answer:
          'Leaderboards show the top players globally for each game. Your rank is calculated based on your best score. Tap the Leaderboard icon in the bottom navigation to see rankings. You can filter by time period (Today, This Week, All Time).',
      category: 'Leaderboards',
    ),
    const FaqItem(
      question: 'How is my score calculated?',
      answer:
          'Each game has its own scoring system:\n• Sudoku: Based on time and difficulty\n• Snake: Points per food eaten\n• 2048: Tile values\n• Puzzle: Time to complete\n• Infinite Runner: Distance traveled',
      category: 'Leaderboards',
    ),

    // Technical
    const FaqItem(
      question: 'My game progress was lost. What happened?',
      answer:
          'Game progress is saved automatically to your device. If you logged in with a different account or reinstalled the app, your local saves may have been reset. Make sure you\'re logged in to sync your data to the cloud (coming soon).',
      category: 'Technical',
    ),
    const FaqItem(
      question: 'The app is running slowly. How can I fix it?',
      answer:
          'Try these steps:\n1. Close other apps running in the background\n2. Restart the MultiGame app\n3. Clear app cache in your device settings\n4. Make sure you have the latest version installed',
      category: 'Technical',
    ),
    const FaqItem(
      question: 'How do I report a bug?',
      answer:
          'If you encounter a bug, please contact our support team through the "Contact Support" button below. Include details about what happened and your device model.',
      category: 'Technical',
    ),
  ];

  /// Get FAQs by category
  static List<FaqItem> getByCategory(String category) {
    return defaultFaqs.where((faq) => faq.category == category).toList();
  }

  /// Get all categories
  static List<String> get categories {
    return defaultFaqs.map((faq) => faq.category).toSet().toList();
  }
}
