import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/utils/motivation_quotes.dart';

void main() {
  group('MotivationQuotes', () {
    test('returns non-empty quote for all level/situation combinations', () {
      for (final level in SavageLevel.values) {
        for (final situation in QuoteSituation.values) {
          final quote = MotivationQuotes.getRandomQuote(level, situation);
          expect(quote, isNotEmpty);
        }
      }
    });

    test('getQuotes returns list for valid level and situation', () {
      final quotes = MotivationQuotes.getQuotes(
        SavageLevel.level1,
        QuoteSituation.roundStart,
      );
      expect(quotes, isNotEmpty);
      expect(quotes.length, greaterThan(0));
    });

    test('level1 quotes are encouraging', () {
      final quotes = MotivationQuotes.getQuotes(
        SavageLevel.level1,
        QuoteSituation.roundMid,
      );

      // Level 1 should have positive/encouraging language
      expect(
        quotes.any(
          (q) =>
              q.contains('great') || q.contains('good') || q.contains('Keep'),
        ),
        true,
      );
    });

    test('level3 quotes are harsh', () {
      final quotes = MotivationQuotes.getQuotes(
        SavageLevel.level3,
        QuoteSituation.roundMid,
      );

      // Level 3 should have intense language
      expect(
        quotes.any(
          (q) => q.contains('!') || q.contains('Weak') || q.contains('More'),
        ),
        true,
      );
    });

    test('getRandomQuote returns different quotes on multiple calls', () {
      final quotes = <String>{};

      // Call multiple times to increase chance of getting different quotes
      for (var i = 0; i < 20; i++) {
        quotes.add(
          MotivationQuotes.getRandomQuote(
            SavageLevel.level2,
            QuoteSituation.roundFinal,
          ),
        );
      }

      // Should get at least 2 different quotes (with 20 attempts)
      expect(quotes.length, greaterThan(1));
    });
  });
}
