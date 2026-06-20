class CourseContent {
  static const Map<String, Map<String, dynamic>> data = {
    'basics of forex': {
      'description':
          'This comprehensive beginner-friendly course is designed to help you understand the Forex market from the ground up. Whether you are completely new to trading or looking to strengthen your fundamentals, this course covers everything from currency pairs and market mechanics to technical analysis, risk management, and trading psychology.',
      'outcomes': [
        'Total currency pairs',
        'Crypto market basics',
        'News and fundamental analysis',
      ],
    },
    'candlestick & chart': {
      'description':
          'Master the art of reading candlestick charts and understanding market price action. This course teaches you how to analyze charts, identify trends, spot trading opportunities, and make informed trading decisions using candlestick patterns and technical analysis.',
      'outcomes': [
        'Basics of candlestick patterns',
        'Bullish candlesticks',
        'Bearish candlesticks',
        'Basics of chart patterns',
        'Bullish chart patterns',
        'Bearish chart patterns',
        'Support and resistance',
        'Trend identification and market structure',
      ],
    },
    'smart money concept': {
      'description':
          'Learn how institutional traders and banks move the market using Smart Money Concepts. This course covers market structure, order blocks, liquidity, fair value gaps, and high-probability entry models used by professional traders.',
      'outcomes': [
        'Basics of SMC',
        'Break of structure',
        'Change of character (CHoCH)',
        'Order blocks',
        'Fair value gaps (FVG)',
        'Mitigation blocks',
        'Premium and discount zones',
        'Liquidity zones',
        'Institutional trading logic',
        '4 SMC entry setups',
      ],
    },
    'candle range theory': {
      'description':
          'Master Candle Range Theory and learn how to identify high-probability trading setups by understanding candle behavior, market manipulation, and price delivery concepts.',
      'outcomes': [
        'Fundamentals of Candle Range Theory',
        'CRT Candle Identification',
        'Manipulation, Expansion & Distribution Phases',
        'High-Probability Entry Setups',
        'Market Structure Alignment',
        'Liquidity Sweeps',
        'Target Selection Techniques',
        'Risk-to-Reward Planning',
        'Trade Execution Rules',
        'Live Chart Examples',
      ],
    },
    'liquidity concept': {
      'description':
          'Understand how liquidity drives the Forex market and learn how smart money targets liquidity pools to create trading opportunities. This course teaches you to identify liquidity zones and trade with institutional logic.',
      'outcomes': [
        'What is Liquidity?',
        'Buy-Side & Sell-Side Liquidity',
        'Equal Highs & Equal Lows',
        'Liquidity Sweeps & Grabs',
        'Stop Hunts Explained',
        'Internal vs External Liquidity',
        'Market Manipulation Concepts',
        'Liquidity-Based Trade Entries',
        'Risk Management',
        'Real Market Examples',
      ],
    },
    'money factory indicator': {
      'description':
          'The Money Factory Indicator package contains two powerful indicators:\n1. Money Factory Indicator\n2. Money Factory Liquidity Indicator\n\nThe first provides buy and sell signals, while the second identifies liquidity pools. Combined, these entry setups provide a 70-75% accuracy rate.',
      'outcomes': [
        'The Buy/Sell Signal: You are going to learn how to interpret the buy and sell signals. You will learn how to execute high-accuracy trades based on these signals.',
        'The Liquidity Pool: You are going to learn how to identify which liquidity pools are likely to be tapped and how institutional operators use liquidity to make a profit.',
      ],
    },
  };

  static const Map<String, List<String>> aliases = {
    'basics of forex': ['forex trading for beginners', 'basics of forex'],
    'candlestick & chart': ['candle & chart analysis', 'candle chart analysis', 'candlestick'],
    'smart money concept': ['smc', 'smart money concepts'],
    'candle range theory': ['crt', 'cycle range theory'],
    'liquidity concept': ['liquidity mastery'],
    'money factory indicator': [],
  };

  static String _findKey(String title) {
    final t = title.toLowerCase().trim();
    for (final key in data.keys) {
      if (t.contains(key)) return key;
      if (aliases.containsKey(key)) {
        for (final alias in aliases[key]!) {
          if (t.contains(alias)) return key;
        }
      }
    }
    return '';
  }

  static String getDescription(String title, String fallback) {
    final key = _findKey(title);
    if (key.isNotEmpty) return data[key]!['description'];
    return fallback;
  }

  static List<dynamic> getOutcomes(String title, List<dynamic> fallback) {
    final key = _findKey(title);
    if (key.isNotEmpty) return data[key]!['outcomes'];
    return fallback;
  }
}
