import '../models/exercise_session.dart';
import '../models/game_result.dart';
import '../models/mindtalk_emotion_event.dart';

enum CognitiveDomain {
  memory,
  attention,
  executiveFunction,
  language,
  visuospatial,
  socialCognition,
}

enum CognitiveTimeScale { hour, day, week, month }

class CognitiveDomainStatistics {
  const CognitiveDomainStatistics({
    required this.scale,
    required this.periodStart,
    required this.labels,
    required this.scores,
  });

  final CognitiveTimeScale scale;
  final DateTime periodStart;
  final List<String> labels;
  final Map<CognitiveDomain, List<double?>> scores;

  bool get hasData =>
      scores.values.any((values) => values.any((value) => value != null));

  factory CognitiveDomainStatistics.from({
    required Iterable<GameResult> games,
    required Iterable<MindTalkEmotionEvent> mindTalkEvents,
    required Iterable<ExerciseSession> exerciseSessions,
    required CognitiveTimeScale scale,
    required DateTime anchor,
  }) {
    final period = _Period.forScale(scale, anchor);
    final totals = <CognitiveDomain, List<double>>{
      for (final domain in CognitiveDomain.values)
        domain: List.filled(period.bucketCount, 0),
    };
    final counts = <CognitiveDomain, List<int>>{
      for (final domain in CognitiveDomain.values)
        domain: List.filled(period.bucketCount, 0),
    };

    void add(CognitiveDomain domain, DateTime time, double score) {
      final index = period.indexOf(time);
      if (index == null) return;
      totals[domain]![index] += score.clamp(0, 100);
      counts[domain]![index]++;
    }

    for (final result in games) {
      final domain = domainForGame(result.game);
      if (domain != null) add(domain, result.playedAt, result.accuracy);
    }

    for (final session in exerciseSessions) {
      final completion = session.totalPoses == 0
          ? 0.0
          : session.completedPoses / session.totalPoses * 100;
      add(CognitiveDomain.attention, session.performedAt, completion);
      add(CognitiveDomain.executiveFunction, session.performedAt, completion);
    }

    final conversationCounts = List<int>.filled(period.bucketCount, 0);
    final emotionSignalCounts = List<int>.filled(period.bucketCount, 0);
    for (final event in mindTalkEvents) {
      final index = period.indexOf(event.recordedAt);
      if (index == null) continue;
      emotionSignalCounts[index]++;
      if (event.sourceValue == MindTalkEmotionSource.conversation) {
        conversationCounts[index]++;
      }
    }
    for (var index = 0; index < period.bucketCount; index++) {
      if (conversationCounts[index] > 0) {
        totals[CognitiveDomain.language]![index] =
            (conversationCounts[index] * 25).clamp(0, 100).toDouble();
        counts[CognitiveDomain.language]![index] = 1;
      }
      if (emotionSignalCounts[index] > 0) {
        totals[CognitiveDomain.socialCognition]![index] =
            (emotionSignalCounts[index] * 20).clamp(0, 100).toDouble();
        counts[CognitiveDomain.socialCognition]![index] = 1;
      }
    }

    final scores = <CognitiveDomain, List<double?>>{};
    for (final domain in CognitiveDomain.values) {
      scores[domain] = List.generate(period.bucketCount, (index) {
        final count = counts[domain]![index];
        return count == 0 ? null : totals[domain]![index] / count;
      });
    }

    return CognitiveDomainStatistics(
      scale: scale,
      periodStart: period.start,
      labels: period.labels,
      scores: scores,
    );
  }

  static CognitiveDomain? domainForGame(String game) {
    return switch (game.toLowerCase()) {
      'supermarket' => CognitiveDomain.memory,
      'catpaw' => CognitiveDomain.attention,
      'dicedash' => CognitiveDomain.executiveFunction,
      'drawvis' => CognitiveDomain.visuospatial,
      _ => null,
    };
  }
}

class _Period {
  const _Period({
    required this.scale,
    required this.start,
    required this.end,
    required this.labels,
  });

  final CognitiveTimeScale scale;
  final DateTime start;
  final DateTime end;
  final List<String> labels;

  int get bucketCount => labels.length;

  factory _Period.forScale(CognitiveTimeScale scale, DateTime anchor) {
    switch (scale) {
      case CognitiveTimeScale.hour:
        final start = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          anchor.hour,
        );
        return _Period(
          scale: scale,
          start: start,
          end: start.add(const Duration(hours: 1)),
          labels: List.generate(60, (minute) => minute.toString()),
        );
      case CognitiveTimeScale.day:
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        return _Period(
          scale: scale,
          start: start,
          end: start.add(const Duration(days: 1)),
          labels: List.generate(24, (hour) => hour.toString().padLeft(2, '0')),
        );
      case CognitiveTimeScale.week:
        final day = DateTime(anchor.year, anchor.month, anchor.day);
        final start = day.subtract(Duration(days: day.weekday - 1));
        return _Period(
          scale: scale,
          start: start,
          end: start.add(const Duration(days: 7)),
          labels: List.generate(7, (index) {
            final date = start.add(Duration(days: index));
            return '${date.day}/${date.month}';
          }),
        );
      case CognitiveTimeScale.month:
        final start = DateTime(anchor.year, anchor.month);
        final end = DateTime(anchor.year, anchor.month + 1);
        final days = end.difference(start).inDays;
        return _Period(
          scale: scale,
          start: start,
          end: end,
          labels: List.generate(days, (index) => '${index + 1}'),
        );
    }
  }

  int? indexOf(DateTime time) {
    if (time.isBefore(start) || !time.isBefore(end)) return null;
    return switch (scale) {
      CognitiveTimeScale.hour => time.difference(start).inMinutes,
      CognitiveTimeScale.day => time.difference(start).inHours,
      CognitiveTimeScale.week ||
      CognitiveTimeScale.month => time.difference(start).inDays,
    };
  }
}
