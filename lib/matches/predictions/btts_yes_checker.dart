import 'package:meta/meta.dart';
import 'package:predictions/data/model/football_match.dart';
import 'package:predictions/data/teams.dart';

class BttsYesChecker {
  final FootballMatch match;

  BttsYesChecker({@required this.match});

  bool getPrediction() {
    return match.homeProjectedGoals > 1.2 && match.awayProjectedGoals > 1.2;
  }

  bool getPredictionIncludingPerformance() {
    final prediction = getPrediction();
    if (!prediction) {
      return false;
    }

    return overPerformingTeams.contains("(H) ${match.homeTeam}") &&
        overPerformingTeams.contains("(A) ${match.awayTeam}");
  }

  bool isPredictionCorrect() {
    if (!match.hasFinalScore() || !getPrediction()) {
      return false;
    }

    return match.homeFinalScore >= 1 && match.awayFinalScore >= 1;
  }
}
