import 'dart:collection';
import 'dart:core';
import 'dart:developer' as developer;

import 'package:tuple/tuple.dart';

/// Reads in results from an instantaneous audio recognition model and smoothes them over time.
class RecognizeCommands {
  // Configuration settings.
  late List<String> labels;
  late int averageWindowDurationMs;
  late double detectionThreshold;
  late int suppressionMs;
  late int minimumCount;
  late int minimumTimeBetweenSamplesMs;

  // Working variables.
  var previousResults = Queue<Tuple2<int, List<double>>>();
  String? previousTopLabel;
  late int labelsCount;
  int? previousTopLabelTime;
  double? previousTopLabelScore;

  static const String SILENCE_LABEL = "_silence_";
  static const int MINIMUM_TIME_FRACTION = 4;

  RecognizeCommands(
      List<String> inLabels,
      int inAverageWindowDurationMs,
      double inDetectionThreshold,
      int inSuppressionMS,
      int inMinimumCount,
      int inMinimumTimeBetweenSamplesMS) {
    labels = inLabels;
    averageWindowDurationMs = inAverageWindowDurationMs;
    detectionThreshold = inDetectionThreshold;
    suppressionMs = inSuppressionMS;
    minimumCount = inMinimumCount;
    labelsCount = inLabels.length;
    previousTopLabel = SILENCE_LABEL;
    previousTopLabelTime = -0x8000000000000000;
    previousTopLabelScore = 0;
    minimumTimeBetweenSamplesMs = inMinimumTimeBetweenSamplesMS;
  }

  RecognitionResult processLatestResults(
      List<double> currentResults, int currentTimeMS) {
    if (currentResults.length != labelsCount) {
      throw Exception(
          "The results for recognition should contain $labelsCount elements, "
          "but there are ${currentResults.length}");
    }

    if ((previousResults.isNotEmpty) &&
        (currentTimeMS < previousResults.first.item1)) {
      throw Exception(
          "You must feed results in increasing time order, but received a "
          "timestamp of $currentTimeMS that was earlier than the previous "
          "one of ${previousResults.first.item1}");
    }

    int howManyResults = previousResults.length;
    // Ignore any results that are coming in too frequently.
    if (howManyResults > 1) {
      final timeSinceMostRecent = currentTimeMS - previousResults.last.item1;
      if (timeSinceMostRecent < minimumTimeBetweenSamplesMs) {
        return new RecognitionResult(
            previousTopLabel, previousTopLabelScore, false);
      }
    }

    // Add the latest results to the head of the queue.
    previousResults.addLast(Tuple2(currentTimeMS, currentResults));

    // Prune any earlier results that are too old for the averaging window.
    final timeLimit = currentTimeMS - averageWindowDurationMs;
    while (previousResults.first.item1 < timeLimit) {
      previousResults.removeFirst();
    }

    howManyResults = previousResults.length;

    // If there are too few results, assume the result will be unreliable and
    // bail.
    final earliestTime = previousResults.first.item1;
    final samplesDuration = currentTimeMS - earliestTime;

    developer.log('$howManyResults', name: 'Number of Results: ');

    developer.log(
        '${(samplesDuration < (averageWindowDurationMs / MINIMUM_TIME_FRACTION))}',
        name: 'Duration < WD/FRAC?');

    if ((howManyResults < minimumCount)
        //        || (samplesDuration < (averageWindowDurationMs / MINIMUM_TIME_FRACTION))
        ) {
      developer.log('Too few results', name: 'RecognizeResult');
      return RecognitionResult(previousTopLabel, 0, false);
    }

    // Calculate the average score across all the results in the window.
    var averageScores = List<double?>.filled(labelsCount, null);
    previousResults.forEach((previousResult) {
      final scoresTensor = previousResult.item2;
      int i = 0;
      while (i < scoresTensor.length) {
        averageScores[i] = scoresTensor[i] / howManyResults;
        ++i;
      }
    });

    // Sort the averaged results in descending score order.
    var sortedAverageScores = List<ScoreForSorting?>.filled(labelsCount, null);
    for (int i = 0; i < labelsCount; ++i) {
      sortedAverageScores[i] = new ScoreForSorting(averageScores[i], i);
    }
    sortedAverageScores.sort();

    // See if the latest top score is enough to trigger a detection.
    final currentTopIndex = sortedAverageScores[0]!.index;
    final currentTopLabel = labels[currentTopIndex];
    final currentTopScore = sortedAverageScores[0]!.score!;
    // If we've recently had another label trigger, assume one that occurs too
    // soon afterwards is a bad result.
    int timeSinceLastTop;
    if (previousTopLabel == SILENCE_LABEL ||
        (previousTopLabelTime == -0x8000000000000000)) {
      timeSinceLastTop = 0x7FFFFFFFFFFFFFFF;
    } else {
      timeSinceLastTop = currentTimeMS - previousTopLabelTime!;
    }
    bool isNewCommand;
    if (currentTopScore > detectionThreshold &&
        timeSinceLastTop > suppressionMs) {
      previousTopLabel = currentTopLabel;
      previousTopLabelTime = currentTimeMS;
      previousTopLabelScore = currentTopScore;
      isNewCommand = true;
    } else {
      isNewCommand = false;
    }
    return RecognitionResult(currentTopLabel, currentTopScore, isNewCommand);
  }
}

/// Holds information about what's been recognized.
class RecognitionResult {
  final String? foundCommand;
  final double? score;
  final bool isNewCommand;

  RecognitionResult(this.foundCommand, this.score, this.isNewCommand);
}

class ScoreForSorting implements Comparable<ScoreForSorting> {
  double? score;
  int index;

  ScoreForSorting(this.score, this.index);

  @override
  int compareTo(ScoreForSorting other) {
    if (this.score! > other.score!) {
      return -1;
    } else if (this.score! < other.score!) {
      return 1;
    } else {
      return 0;
    }
  }
}
