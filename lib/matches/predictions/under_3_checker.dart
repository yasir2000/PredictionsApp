import 'package:meta/meta.dart';
import 'package:predictions/data/model/football_match.dart';
import 'package:predictions/data/teams.dart';
import 'package:predictions/util/utils.dart';

class Under3Checker {
  final FootballMatch match;

  Under3Checker({@required this.match});

  bool getPrediction() {
    final roundedHomeGoals =
        Utils.roundProjectedGoals(match.homeProjectedGoals);
    final roundedAwayGoals =
        Utils.roundProjectedGoals(match.awayProjectedGoals);
    return roundedHomeGoals + roundedAwayGoals < 3;
  }

  bool getPredictionIncludingPerformance() {
    final prediction = getPrediction();
    if (!prediction) {
      return false;
    }

    return underPerformingTeams.contains("(H) ${match.homeTeam}") &&
        underPerformingTeams.contains("(A) ${match.awayTeam}");
  }

  bool isPredictionCorrect() {
    if (!match.hasFinalScore() || !getPrediction()) {
      return false;
    }

    return match.homeFinalScore + match.awayFinalScore < 3;
  }
}
