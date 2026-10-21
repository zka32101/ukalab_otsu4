import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/glossary.dart';

void main() {
  group('用語集の整合性', () {
    test('用語名は重複しない', () {
      final names = [for (final t in glossaryTerms) t.term];
      expect(names.toSet().length, names.length);
    });

    test('定義と補足は空でなく、極端に長くない', () {
      for (final t in glossaryTerms) {
        expect(t.definition.trim(), isNotEmpty, reason: t.term);
        expect(t.definition.length, lessThanOrEqualTo(100), reason: t.term);
        expect((t.note ?? '').length, lessThanOrEqualTo(100), reason: t.term);
      }
    });

    test('AI下書きの用語に、確認済みと読める表記や断定的な宣伝表現がない', () {
      const banned = ['公式', '認定', '本試験相当', '合格保証', '必ず受かる', '確認済み'];
      for (final t in glossaryTerms.where((t) => t.aiDraft)) {
        final text = '${t.term}${t.definition}${t.note ?? ''}';
        for (final w in banned) {
          expect(text.contains(w), isFalse, reason: '${t.term}: $w');
        }
      }
    });
  });
}
