import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// 章ごとの解説読み物（教科書的なまとめページ）の読み込み。
class ReadingRepository {
  const ReadingRepository();

  static const assetPath = 'assets/readings.jsonl';

  Future<List<ChapterReading>> load() async {
    final text = await rootBundle.loadString(assetPath);
    return parseChapterReadingsJsonl(text).items;
  }
}

final chapterReadingsProvider =
    FutureProvider<List<ChapterReading>>((ref) => const ReadingRepository().load());
