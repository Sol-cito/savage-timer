import 'dart:math';

import '../models/timer_settings.dart';

enum QuoteSituation { roundStart, roundMid, roundFinal, restTime }

class MotivationQuotes {
  static final _random = Random();

  static const Map<SavageLevel, Map<QuoteSituation, List<String>>> _quotes = {
    SavageLevel.level1: {
      QuoteSituation.roundStart: [
        "You got this!",
        "Let's go!",
        "New round, fresh start!",
        "Here we go!",
        "Time to shine!",
      ],
      QuoteSituation.roundMid: [
        "Keep going!",
        "Stay strong!",
        "You're doing great!",
        "Nice work!",
        "Keep it up!",
        "Looking good!",
      ],
      QuoteSituation.roundFinal: [
        "Almost there!",
        "Finish strong!",
        "Just a bit more!",
        "You can do it!",
        "Push through!",
        "Last stretch!",
      ],
      QuoteSituation.restTime: [
        "Good job!",
        "Well done!",
        "Take a breath.",
        "Nice round!",
        "Rest up!",
      ],
    },
    SavageLevel.level2: {
      QuoteSituation.roundStart: [
        "Focus!",
        "Let's work!",
        "Show me what you got!",
        "Time to grind!",
        "Get after it!",
      ],
      QuoteSituation.roundMid: [
        "Don't slow down!",
        "Keep the pace!",
        "Stay focused!",
        "Don't give up!",
        "Keep moving!",
        "Dig deeper!",
      ],
      QuoteSituation.roundFinal: [
        "Push harder!",
        "No quitting now!",
        "Give it everything!",
        "Empty the tank!",
        "Finish it!",
        "Now or never!",
      ],
      QuoteSituation.restTime: [
        "Catch your breath.",
        "Recover quick!",
        "Next round will be harder.",
        "Don't get comfortable.",
        "Stay ready!",
      ],
    },
    SavageLevel.level3: {
      QuoteSituation.roundStart: [
        "Is that all you got?",
        "Time to suffer!",
        "Pain is weakness leaving!",
        "No excuses!",
        "Beast mode!",
      ],
      QuoteSituation.roundMid: [
        "Weak dies here!",
        "More! More! More!",
        "Stop being soft!",
        "Your opponent isn't resting!",
        "Harder!",
        "That's nothing!",
      ],
      QuoteSituation.roundFinal: [
        "Don't you dare quit!",
        "Winners don't stop!",
        "Prove yourself!",
        "This is where champions are made!",
        "Break through!",
        "Destroy it!",
      ],
      QuoteSituation.restTime: [
        "You call that effort?",
        "Next round, double down!",
        "That was weak!",
        "Do better!",
        "Rest is for the weak!",
      ],
    },
  };

  static String getRandomQuote(SavageLevel level, QuoteSituation situation) {
    final quotes = _quotes[level]?[situation];
    if (quotes == null || quotes.isEmpty) {
      return "Keep going!";
    }
    return quotes[_random.nextInt(quotes.length)];
  }

  static List<String> getQuotes(SavageLevel level, QuoteSituation situation) {
    return _quotes[level]?[situation] ?? [];
  }
}
