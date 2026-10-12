import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/glossary.dart';
import 'package:otsu4/data/question_repository.dart';
import 'package:otsu4/data/reading_repository.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  test('読み物データ（assets/readings.jsonl）は配信前チェックを通る', () async {
    final exam = ExamConfig.fromJson(
      jsonDecode(await File('assets/exam/hazmat4_exam.json').readAsString())
          as Map<String, dynamic>,
    );
    final parsed =
        parseChapterReadingsJsonl(await File(ReadingRepository.assetPath).readAsString());
    expect(parsed.issues, isEmpty, reason: parsed.issues.map((i) => i.toString()).join('\n'));
    expect(parsed.items.length, greaterThanOrEqualTo(10));

    final qids = <String>[];
    for (final path in QuestionRepository.assetPaths) {
      qids.addAll(parseQuestionsJsonl(await File(path).readAsString()).questions.map((q) => q.qid));
    }
    final issues = validateChapterReadings(
      parsed.items,
      exam: exam,
      termIds: [for (final t in glossaryTerms) t.term],
      questionIds: qids,
    );
    expect(issues, isEmpty, reason: issues.map((i) => i.toString()).join('\n'));
  });
}
