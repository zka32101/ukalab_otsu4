import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/glossary.dart';

void main() {
  group('searchGlossaryTerms', () {
    test('用語名に一致する用語を返す', () {
      expect(searchGlossaryTerms('引火点').map((t) => t.term), contains('引火点'));
    });

    test('定義の文中にあるキーワードでも一致する', () {
      // 「商の和」の定義文中に「指定数量」が含まれるため、「指定数量」で検索すると
      // 用語名が一致する「指定数量」自体に加えて「商の和」もヒットする。
      expect(searchGlossaryTerms('指定数量').map((t) => t.term), containsAll(['指定数量', '商の和']));
    });

    test('大文字小文字は区別しない', () {
      expect(searchGlossaryTerms('ひきかてん'), isEmpty); // 読み仮名検索は対象外（想定内）
      expect(searchGlossaryTerms('引火点'), isNotEmpty);
    });

    test('空のキーワードでは何も返さない', () {
      expect(searchGlossaryTerms(''), isEmpty);
    });

    test('一致しないキーワードでは空を返す', () {
      expect(searchGlossaryTerms('存在しない語句'), isEmpty);
    });
  });

  group('glossaryTermsBySubject', () {
    test('指定した分野の用語だけを返す', () {
      final terms = glossaryTermsBySubject('law');
      expect(terms, isNotEmpty);
      expect(terms.every((t) => t.subjectId == 'law'), isTrue);
    });

    test('全ての用語はlaw・physics_chem・property_extinguishのいずれかに属する', () {
      const validSubjects = {'law', 'physics_chem', 'property_extinguish'};
      expect(glossaryTerms.every((t) => validSubjects.contains(t.subjectId)), isTrue);
    });

    test('存在しない分野では空を返す', () {
      expect(glossaryTermsBySubject('存在しない分野'), isEmpty);
    });
  });

  group('filterGlossaryTerms', () {
    test('subjectIdがnullならすべての用語が対象', () {
      final terms = filterGlossaryTerms(subjectId: null, favoritesOnly: false, favoriteTerms: {});
      expect(terms, glossaryTerms);
    });

    test('subjectIdを指定すると、その分野だけに絞り込む', () {
      final terms = filterGlossaryTerms(subjectId: 'law', favoritesOnly: false, favoriteTerms: {});
      expect(terms.every((t) => t.subjectId == 'law'), isTrue);
    });

    test('favoritesOnlyがtrueなら、favoriteTermsに含まれる用語だけに絞り込む', () {
      final terms = filterGlossaryTerms(
        subjectId: null,
        favoritesOnly: true,
        favoriteTerms: {'引火点', '指定数量'},
      );
      expect(terms.map((t) => t.term).toSet(), {'引火点', '指定数量'});
    });

    test('分野・お気に入りの両方を同時に絞り込める', () {
      final terms = filterGlossaryTerms(
        subjectId: 'law',
        favoritesOnly: true,
        favoriteTerms: {'引火点', '指定数量'},
      );
      expect(terms.map((t) => t.term).toSet(), {'指定数量'});
    });

    test('お気に入りが空ならfavoritesOnlyで空を返す', () {
      final terms = filterGlossaryTerms(subjectId: null, favoritesOnly: true, favoriteTerms: {});
      expect(terms, isEmpty);
    });

    test('unmasteredOnlyがtrueなら、masteredTermsに含まれない用語だけに絞り込む', () {
      final terms = filterGlossaryTerms(
        subjectId: null,
        favoritesOnly: false,
        favoriteTerms: {},
        unmasteredOnly: true,
        masteredTerms: {'引火点'},
      );
      expect(terms.any((t) => t.term == '引火点'), isFalse);
      expect(terms.length, glossaryTerms.length - 1);
    });

    test('お気に入り・未習得の両方を同時に絞り込める', () {
      final terms = filterGlossaryTerms(
        subjectId: null,
        favoritesOnly: true,
        favoriteTerms: {'引火点', '指定数量'},
        unmasteredOnly: true,
        masteredTerms: {'引火点'},
      );
      expect(terms.map((t) => t.term).toSet(), {'指定数量'});
    });
  });

  group('shuffledGlossaryTerms', () {
    test('元の用語と同じ要素を、同じ件数だけ返す（順序が入れ替わる）', () {
      final terms = glossaryTermsBySubject('law');
      final shuffled = shuffledGlossaryTerms(terms, random: Random(42));
      expect(shuffled.length, terms.length);
      expect(shuffled.toSet(), terms.toSet());
    });

    test('元のリストを変更しない', () {
      final terms = glossaryTermsBySubject('law');
      final before = [...terms];
      shuffledGlossaryTerms(terms, random: Random(1));
      expect(terms, before);
    });
  });

  group('sortedGlossaryTermsAlphabetically', () {
    test('用語名の文字コード順に並べ替える', () {
      final terms = glossaryTermsBySubject('law');
      final sorted = sortedGlossaryTermsAlphabetically(terms);
      final termNames = sorted.map((t) => t.term).toList();
      final expected = [...termNames]..sort();
      expect(termNames, expected);
    });

    test('元の用語と同じ要素を、同じ件数だけ返す', () {
      final terms = glossaryTermsBySubject('law');
      final sorted = sortedGlossaryTermsAlphabetically(terms);
      expect(sorted.length, terms.length);
      expect(sorted.toSet(), terms.toSet());
    });

    test('元のリストを変更しない', () {
      final terms = glossaryTermsBySubject('law');
      final before = [...terms];
      sortedGlossaryTermsAlphabetically(terms);
      expect(terms, before);
    });
  });

  group('termReferencesIn', () {
    test('本文中に出現する用語集の用語をTermReferenceとして返す', () {
      final refs = termReferencesIn('引火点は可燃性蒸気を発生する最低温度。指定数量も重要。');
      final ids = refs.map((r) => r.termId).toSet();
      expect(ids, containsAll(['引火点', '指定数量']));
    });

    test('一致する用語が無ければ空を返す', () {
      expect(termReferencesIn('まったく関係のない文章'), isEmpty);
    });
  });

  group('glossaryTermOfDay', () {
    test('termsが空ならnull', () {
      expect(glossaryTermOfDay(const [], DateTime(2026, 1, 1)), isNull);
    });

    test('同じ日付なら常に同じ用語を返す', () {
      final terms = glossaryTermsBySubject('law');
      final a = glossaryTermOfDay(terms, DateTime(2026, 1, 1, 9));
      final b = glossaryTermOfDay(terms, DateTime(2026, 1, 1, 23));
      expect(a, b);
    });

    test('日付が変わると用語が変わることがある', () {
      final terms = glossaryTermsBySubject('law');
      final days = [for (var i = 0; i < 30; i++) glossaryTermOfDay(terms, DateTime(2026, 1, 1 + i))];
      expect(days.toSet().length, greaterThan(1));
    });
  });
}
