import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:predictions/data/matches_bloc.dart';
import 'package:predictions/data/model/football_match.dart';
import 'package:predictions/matches/predictions/btts_no_checker.dart';
import 'package:predictions/matches/predictions/btts_yes_checker.dart';
import 'package:predictions/matches/predictions/over_2_checker.dart';
import 'package:predictions/matches/predictions/under_3_checker.dart';
import 'package:predictions/matches/predictions/win_lose_draw_checker.dart';

class PredictionStat {
  final String type;
  final double percentage;
  final String summary;

  PredictionStat(
      {@required this.type, @required this.percentage, @required this.summary});

  @override
  String toString() => "$type - ${percentage.toStringAsFixed(2)}";
}

class StatsBloc {
  final StreamController<Map<String, List<PredictionStat>>> stats =
      StreamController<Map<String, List<PredictionStat>>>();

  void dispose() {
    stats.close();
  }

  StatsBloc({@required MatchesBloc matchesBloc}) {
    matchesBloc.matches.listen(_loadStats);
  }

  void _loadStats(Matches matches) async {
    final statsList = await compute(_getStats, matches);
    stats.add(statsList);
  }

  static Map<String, List<PredictionStat>> _getStats(Matches matches) {
    final groupedMatches = groupBy(matches.allMatches, (m) => m.league);
    return groupedMatches
        .map((key, value) => MapEntry(key, _getLeagueStats(value)));
  }

  static List<PredictionStat> _getLeagueStats(List<FootballMatch> matches) {
    final winLoseDrawStats = _getWinLoseDrawStats(matches);
    final under3Stats = _getUnder3Stats(matches);
    final over2Stats = _getOver2Stats(matches);
    final bttsNoStats = _getBttsNoStats(matches);
    final bttsYesStats = _getBttsYesStats(matches);
    return [
      winLoseDrawStats,
      under3Stats,
      over2Stats,
      bttsNoStats,
      bttsYesStats,
    ]..sort((left, right) => right.percentage.compareTo(left.percentage));
  }

  static PredictionStat _getWinLoseDrawStats(List<FootballMatch> matches) {
    final predictedMatches =
        matches.where((m) => m.hasFinalScore() && m.isBeforeToday());
    final predictedCorrectly = matches.where((m) {
      final checker = WinLoseDrawChecker(match: m);
      return checker.isPredictionCorrect();
    });

    final percentage = predictedCorrectly.length == 0
        ? 0.0
        : predictedCorrectly.length / predictedMatches.length * 100;
    final summary =
        "${predictedCorrectly.length} predicted correctly out of ${predictedMatches.length} matches that matched this prediction method.";

    return PredictionStat(
      type: "1X2",
      percentage: percentage,
      summary: summary,
    );
  }

  static PredictionStat _getUnder3Stats(List<FootballMatch> matches) {
    final predictedMatches = matches.where((m) {
      if (!m.hasFinalScore() || !m.isBeforeToday()) {
        return false;
      }

      final checker = Under3Checker(match: m);
      return checker.getPrediction();
    });
    final predictedCorrectly = predictedMatches.where((m) {
      final checker = Under3Checker(match: m);
      return checker.isPredictionCorrect();
    });

    final percentage = predictedCorrectly.length == 0
        ? 0.0
        : predictedCorrectly.length / predictedMatches.length * 100;
    final summary =
        "${predictedCorrectly.length} predicted correctly out of ${predictedMatches.length} matches that matched this prediction method.";

    return PredictionStat(
      type: "Under 2.5",
      percentage: percentage,
      summary: summary,
    );
  }

  static PredictionStat _getOver2Stats(List<FootballMatch> matches) {
    final predictedMatches = matches.where((m) {
      if (!m.hasFinalScore() || !m.isBeforeToday()) {
        return false;
      }

      final checker = Over2Checker(match: m);
      return checker.getPrediction();
    });
    final predictedCorrectly = predictedMatches.where((m) {
      final checker = Over2Checker(match: m);
      return checker.isPredictionCorrect();
    });

    final percentage = predictedCorrectly.length == 0
        ? 0.0
        : predictedCorrectly.length / predictedMatches.length * 100;
    final summary =
        "${predictedCorrectly.length} predicted correctly out of ${predictedMatches.length} matches that matched this prediction method.";

    return PredictionStat(
      type: "Over 2.5",
      percentage: percentage,
      summary: summary,
    );
  }

  static PredictionStat _getBttsNoStats(List<FootballMatch> matches) {
    final predictedMatches = matches.where((m) {
      if (!m.hasFinalScore() || !m.isBeforeToday()) {
        return false;
      }

      final checker = BttsNoChecker(match: m);
      return checker.getPrediction();
    });
    final predictedCorrectly = predictedMatches.where((m) {
      final checker = BttsNoChecker(match: m);
      return checker.isPredictionCorrect();
    });

    final percentage = predictedCorrectly.length == 0
        ? 0.0
        : predictedCorrectly.length / predictedMatches.length * 100;
    final summary =
        "${predictedCorrectly.length} predicted correctly out of ${predictedMatches.length} matches that matched this prediction method.";

    return PredictionStat(
      type: "BTTS No",
      percentage: percentage,
      summary: summary,
    );
  }

  static PredictionStat _getBttsYesStats(List<FootballMatch> matches) {
    final predictedMatches = matches.where((m) {
      if (!m.hasFinalScore() || !m.isBeforeToday()) {
        return false;
      }

      final checker = BttsYesChecker(match: m);
      return checker.getPrediction();
    });
    final predictedCorrectly = predictedMatches.where((m) {
      final checker = BttsYesChecker(match: m);
      return checker.isPredictionCorrect();
    });

    final percentage = predictedCorrectly.length == 0
        ? 0.0
        : predictedCorrectly.length / predictedMatches.length * 100;
    final summary =
        "${predictedCorrectly.length} predicted correctly out of ${predictedMatches.length} matches that matched this prediction method.";

    return PredictionStat(
      type: "BTTS Yes",
      percentage: percentage,
      summary: summary,
    );
  }
}
