class CourseContent {
  static const Map<String, Map<String, dynamic>> data = {
    'basics of forex': {
      'description':
          'This comprehensive beginner-friendly course is designed to help you understand the Forex market from the ground up. Whether you are completely new to trading or looking to strengthen your fundamentals, this course covers everything from currency pairs and market mechanics to technical analysis, risk management, and trading psychology.',
      'outcomes': [
        'Forex market basics',
        'Currency pairs and pips',
        'Leverage and margin',
        'Buy and sell trades',
        'Chart reading and analysis',
        'Support and resistance',
        'Technical indicators (RSI, MACD, Moving Averages)',
        'Risk management',
        'Trading psychology',
        'Creating a trading plan',
        'Common trading mistakes to avoid',
        'Practical market analysis skills',
      ],
    },
    'candlestick & chart': {
      'description':
          'Master the art of reading candlestick charts and understanding market price action. This course teaches you how to analyze charts, identify trends, spot trading opportunities, and make informed trading decisions using candlestick patterns and technical analysis.',
      'outcomes': [
        'Basics of candlestick charts',
        'Candlestick structure (Open, High, Low, Close)',
        'Bullish and bearish candlestick patterns',
        'Support and resistance levels',
        'Trend identification and market structure',
        'Chart patterns (Head & Shoulders, Double Top/Bottom, Triangles, etc.)',
        'Entry and exit strategies',
        'Risk management techniques',
        'Price action trading concepts',
        'Real-market chart analysis',
      ],
    },
    'smart money concept': {
      'description':
          'Learn how institutional traders and banks move the market using Smart Money Concepts. This course covers market structure, order blocks, liquidity, fair value gaps, and high-probability entry models used by professional traders.',
      'outcomes': [
        'Market structure (BOS & CHoCH)',
        'Order Blocks',
        'Fair Value Gaps (FVG)',
        'Premium & Discount Zones',
        'Liquidity Concepts',
        'Institutional Trading Logic',
        'Entry & Exit Models',
        'Risk Management using SMC',
        'Multi-Timeframe Analysis',
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
          'Stop chasing lagging indicators. The Money Factory system reads the market\'s true DNA—Structure and Liquidity—making it an absolute weapon for trading Gold (XAU/USD).',
      'outcomes': [
        'money factory indicator (The Trigger): Tracks market structure and behavior to strike with precise BUY/SELL signals right as the trend shifts.',
        'Money factory Liquidity Indicator (The Magnet): Reveals "Liquidity Pools"—hidden institutional zones that pull the price toward them like a powerful magnet.',
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
