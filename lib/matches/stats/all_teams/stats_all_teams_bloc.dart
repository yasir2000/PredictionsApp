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
import 'package:predictions/matches/stats/prediction_stat.dart';

class StatsAllTeamsBloc {
  final StreamController<Map<String, List<PredictionStat>>> stats =
      StreamController<Map<String, List<PredictionStat>>>();
  Map<String, List<PredictionStat>> _cachedStatsMap;

  void dispose() {
    stats.close();
  }

  StatsAllTeamsBloc({@required MatchesBloc matchesBloc}) {
    matchesBloc.matches.listen(_loadStats);
  }

  void _loadStats(Matches matches) async {
    _cachedStatsMap = await compute(_getStats, matches);

//    final winLoseDrawTeams = [];
//    final under3Teams = [];
//    final over2Teams = [];
//    final bttsNoTeams = [];
//    final bttsYesTeams = [];
//    _cachedStatsMap.forEach((key, value) {
//      value.forEach((s) {
//        if (s.type == "1X2" && s.percentage > 80 && s.total > 2) {
//          winLoseDrawTeams.add(key);
//        } else if (s.type == "Under 2.5" && s.percentage > 90 && s.total > 1) {
//          under3Teams.add(key);
//        } else if (s.type == "Over 2.5" && s.percentage > 90 && s.total > 1) {
//          over2Teams.add(key);
//        } else if (s.type == "BTTS No" && s.percentage > 90 && s.total > 1) {
//          bttsNoTeams.add(key);
//        } else if (s.type == "BTTS Yes" && s.percentage > 90 && s.total > 1) {
//          bttsYesTeams.add(key);
//        }
//      });
//    });

//    print("---- 1X2");
//    winLoseDrawTeams.forEach((s) => print(s));
//    print("---- U2.5");
//    under3Teams.forEach((s) => print(s));
//    print("---- O2.5");
//    over2Teams.forEach((s) => print(s));
//    print("---- BTTS No");
//    bttsNoTeams.forEach((s) => print(s));
//    print("---- BTTS Yes");
//    bttsYesTeams.forEach((s) => print(s));

    stats.add(_cachedStatsMap);
  }

  static Map<String, List<PredictionStat>> _getStats(Matches matches) {
    final groupedHomeMatches =
        groupBy(matches.thisSeasonsMatches, (m) => m.homeTeam);
    final groupedHomeMatchesStats = groupedHomeMatches
        .map((key, value) => MapEntry("(H) $key", _getLeagueStats(value)));

    final groupedAwayMatches =
        groupBy(matches.thisSeasonsMatches, (m) => m.awayTeam);
    final groupedAwayMatchesStats = groupedAwayMatches
        .map((key, value) => MapEntry("(A) $key", _getLeagueStats(value)));

    return Map()
      ..addAll(groupedHomeMatchesStats)
      ..addAll(groupedAwayMatchesStats);
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
    return PredictionStat(
      type: "1X2",
      percentage: percentage,
      total: predictedMatches.length,
      totalCorrect: predictedCorrectly.length,
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
    return PredictionStat(
      type: "Under 2.5",
      percentage: percentage,
      total: predictedMatches.length,
      totalCorrect: predictedCorrectly.length,
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
    return PredictionStat(
      type: "Over 2.5",
      percentage: percentage,
      total: predictedMatches.length,
      totalCorrect: predictedCorrectly.length,
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
    return PredictionStat(
      type: "BTTS No",
      percentage: percentage,
      total: predictedMatches.length,
      totalCorrect: predictedCorrectly.length,
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
    return PredictionStat(
      type: "BTTS Yes",
      percentage: percentage,
      total: predictedMatches.length,
      totalCorrect: predictedCorrectly.length,
    );
  }

  void search(String searchTerm) {
    final filteredKeys = _cachedStatsMap.keys
        .where((key) => key.toLowerCase().contains(searchTerm.toLowerCase()));
    final filteredResults = Map.fromEntries(
        filteredKeys.map((key) => MapEntry(key, _cachedStatsMap[key])));
    stats.add(filteredResults);
  }
}