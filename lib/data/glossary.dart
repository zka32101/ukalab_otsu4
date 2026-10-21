import 'dart:math';

import 'package:ukalab_core/ui.dart';

/// 乙4の頻出用語（暗記カードで使用）。
///
/// 既存の確認済みデータ（`substance.dart`・`extinguisher.dart`・問題データの
/// 解説文）に基づく基礎用語の定義。新たな一次資料の収集は行っていない。
class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.subjectId,
    this.note,
    this.aiDraft = false,
  });

  final String term;
  final String definition;

  /// 分野別フィルタで使う科目ID（`assets/exam/hazmat4_exam.json` と同じ
  /// law/physics_chem/property_extinguish）。
  final String subjectId;

  /// 補足（他の用語との対比・覚え方のヒントなど）。
  final String? note;

  /// AIが下書きした用語で、専門家（危険物取扱者・指導経験者）の確認前であることを
  /// 示す。確認が済んだら true を外す（問題データの `ai-draft` タグと同じ運用）。
  final bool aiDraft;
}

const glossaryTerms = <GlossaryTerm>[
  GlossaryTerm(
    term: '引火点',
    definition: '可燃性蒸気を発生し、点火源があれば燃焼を始める最低の液温。',
    subjectId: 'physics_chem',
    note: '温度の実験室の代表6物質では二硫化炭素（-30℃）が最も低い。',
  ),
  GlossaryTerm(
    term: '発火点',
    definition: '点火源が無くても、空気中で自然に燃え始める最低の温度。',
    subjectId: 'physics_chem',
    note: '引火点より高い温度になることが多い（例: ガソリンは引火点-40℃・発火点約300℃）。',
  ),
  GlossaryTerm(
    term: '比重',
    definition: '水（＝1）を基準にした物質の重さの比。1未満なら水に浮く。',
    subjectId: 'property_extinguish',
    note: '第四類危険物のほとんどは比重1未満（水に浮く）。二硫化炭素（1.26）は水より重い代表例。',
  ),
  GlossaryTerm(
    term: '水溶性・非水溶性',
    definition: '水に溶けるかどうか。消火剤の選び方に直結する重要な性質。',
    subjectId: 'property_extinguish',
    note: '一般の泡消火薬剤は水溶性液体に溶けてしまい効果が無いため、耐アルコール泡を使う。',
  ),
  GlossaryTerm(
    term: '指定数量',
    definition: '危険物の規制の基準となる数量。品名・性質ごとに政令別表第三で定める。',
    subjectId: 'law',
    note: '指定数量以上の貯蔵・取扱いには許可、未満には届出等の規制がかかる。',
  ),
  GlossaryTerm(
    term: '商の和',
    definition: '2種類以上の危険物を同時に貯蔵・取扱う場合、各物質の貯蔵量を指定数量で割った'
        '値（倍数）の合計。1以上になると指定数量以上とみなす。',
    subjectId: 'law',
    note: '根拠は消防法第10条（貯蔵）・政令第30条（運搬）。貯蔵所パズルの判定ロジック。',
  ),
  GlossaryTerm(
    term: '特殊引火物',
    definition: '発火点100℃以下、または引火点-20℃以下かつ沸点40℃以下の、第四類の中でも'
        '特に危険性が高い品名。',
    subjectId: 'property_extinguish',
    note: '代表例は二硫化炭素・ジエチルエーテル。指定数量は50Lと少ない。',
  ),
  GlossaryTerm(
    term: '保安距離',
    definition: '製造所等が、学校・病院・住宅等の保護対象物から確保しなければならない距離。',
    subjectId: 'law',
    note: '火災・爆発時の被害が周囲に及ばないようにするための規制。',
  ),
  GlossaryTerm(
    term: '保有空地',
    definition: '製造所等の周囲に確保しなければならない、何も置かない空地。',
    subjectId: 'law',
    note: '延焼の防止・消火活動のための通路確保が目的。',
  ),
  GlossaryTerm(
    term: '免状の書換え',
    definition: '氏名・本籍地等の記載事項に変更があったときに行う手続き。',
    subjectId: 'law',
    note: '紛失・汚損・破損による「再交付」とは別の手続き（規則第52条）。',
  ),
  GlossaryTerm(
    term: '保安講習',
    definition: '危険物取扱作業に従事する危険物取扱者が、一定期間ごとに受講する講習。',
    subjectId: 'law',
    note: '取扱作業に従事していない危険物取扱者は受講対象外（消防法第13条の23）。',
  ),
  GlossaryTerm(
    term: '消火の3要素',
    definition: '燃焼を止める3つの方法。除去（可燃物を取り除く）・窒息（酸素を断つ）・'
        '冷却（温度を下げる）。',
    subjectId: 'property_extinguish',
    note: '二酸化炭素消火剤は窒息効果、水は主に冷却効果。',
  ),
  GlossaryTerm(
    term: '第四類危険物の共通性質',
    definition: '引火性の液体で、蒸気は空気より重く低所に溜まりやすい。多くは水より軽く'
        '（比重1未満）、電気の不良導体で静電気を帯びやすい。',
    subjectId: 'property_extinguish',
    note: '蒸気が低所に溜まる性質は、換気・排気設備の必要性につながる。',
  ),
  // ---- 以下は AI 下書き（aiDraft: true）。専門家の確認前。確認後に aiDraft を外す ----
  GlossaryTerm(
    term: '燃焼範囲',
    definition: '空気中の可燃性蒸気の濃度が、燃焼できる下限から上限までの範囲。',
    subjectId: 'physics_chem',
    note: '範囲が広いほど、また下限が低いほど、危険性が高いと考える。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '蒸気比重',
    definition: '蒸気の重さを、同じ体積の空気の重さと比べた値。1より大きいと蒸気は空気より重い。',
    subjectId: 'physics_chem',
    note: '第四類の蒸気は低所に滞留しやすい。換気や排気の考え方につながる。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '沸点',
    definition: '液体が沸騰して気体になる温度。',
    subjectId: 'physics_chem',
    note: '沸点が低い物質ほど蒸発しやすい傾向がある。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '可燃性蒸気',
    definition: '液体の表面から発生する、燃える性質をもった蒸気。',
    subjectId: 'physics_chem',
    note: '第四類では、液体そのものではなく蒸気が燃える。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '静電気',
    definition: '物質どうしの摩擦や流動で生じる電気。放電の火花が点火源になることがある。',
    subjectId: 'physics_chem',
    note: '電気を通しにくい液体は、流れたりかき混ぜたりすると帯電しやすい。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '自然発火',
    definition: '外部の火源がなくても、物質が酸化して熱がたまり、自ら燃え出す現象。',
    subjectId: 'physics_chem',
    note: '油のしみた布などを積み重ねて放置する場面を例に考える。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '蒸発燃焼',
    definition: '液体の表面から出た蒸気が空気と混ざって燃える形の燃焼。',
    subjectId: 'physics_chem',
    note: '第四類の液体の燃え方の基本形。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '気化熱',
    definition: '液体が蒸発するときに、周囲から奪う熱。',
    subjectId: 'physics_chem',
    note: '蒸発が盛んなほど周囲の温度は下がりやすい。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '燃焼の3要素',
    definition: '燃焼に必要な3つの条件。可燃物・酸素供給源・点火源。',
    subjectId: 'physics_chem',
    note: 'どれか1つを欠けば燃焼は続かない。消火の3要素と対にして整理する。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '第一石油類',
    definition: '第四類の品名の1つ。引火点が低い部類の石油類で、アセトンやガソリンが代表例。',
    subjectId: 'property_extinguish',
    note: '品名は引火点などの性状で区分される。区分の境目は教材で確認すること。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '第二石油類',
    definition: '第四類の品名の1つ。第一石油類より引火点が高い部類で、灯油や軽油が代表例。',
    subjectId: 'property_extinguish',
    note: '水溶性かどうかで消火剤の選び方が変わる点も合わせて整理する。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '第三石油類',
    definition: '第四類の品名の1つ。第二石油類より引火点が高い部類で、重油などが代表例。',
    subjectId: 'property_extinguish',
    note: '常温では引火しにくくても、加熱すると危険性が高まる。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '第四石油類',
    definition: '第四類の品名の1つ。石油類の中で引火点が高い部類で、潤滑油などが代表例。',
    subjectId: 'property_extinguish',
    note: '引火点が高くても、霧状になったり加熱されたりすると燃えやすくなる。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: 'アルコール類',
    definition: '第四類の品名の1つ。炭素数の少ない飽和1価アルコールが対象で、メタノールやエタノールが代表例。',
    subjectId: 'property_extinguish',
    note: '水によく溶けるため、泡消火剤は耐アルコール泡を選ぶ。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '動植物油類',
    definition: '第四類の品名の1つ。動物の脂肉や植物の種子などから得た油。',
    subjectId: 'property_extinguish',
    note: '乾きやすい油がしみた布は、自然発火の例として扱われる。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '泡消火剤',
    definition: '泡で燃焼面を覆い、空気を遮って窒息させる消火剤。冷却の効果もある。',
    subjectId: 'property_extinguish',
    note: '水に溶ける液体の火災には、通常の泡は不向き。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '耐アルコール泡',
    definition: '水に溶ける液体の火災でも泡が壊れにくいように作られた泡消火剤。',
    subjectId: 'property_extinguish',
    note: 'アルコール類など水溶性の危険物に使う。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '粉末消火剤',
    definition: '微細な粉を放射して燃焼を抑える消火剤。窒息の効果も働く。',
    subjectId: 'property_extinguish',
    note: '第四類の火災に使える消火剤の1つ。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '二酸化炭素消火剤',
    definition: '二酸化炭素で酸素濃度を下げて窒息させる消火剤。',
    subjectId: 'property_extinguish',
    note: '密閉された場所で使うと、人が酸欠になるおそれがある。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '危険物',
    definition: '消防法の別表で品名や性質が示された、火災の危険が大きい物品。',
    subjectId: 'law',
    note: '消防法でいう危険物は、日常語の「危ない物」より範囲が決まっている。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '製造所等',
    definition: '製造所・貯蔵所・取扱所をまとめた呼び方。',
    subjectId: 'law',
    note: '危険物を扱う施設の総称として法令に出てくる。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '貯蔵所',
    definition: '危険物を貯蔵する施設。貯蔵の形態により、屋内貯蔵所や屋外タンク貯蔵所などに分かれる。',
    subjectId: 'law',
    note: '種類ごとの基準は教材で確認すること。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '取扱所',
    definition: '危険物を取り扱う施設で、貯蔵や製造を除くもの。給油取扱所や移送取扱所などがある。',
    subjectId: 'law',
    note: '施設の区分は法令の分類にそって覚える。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '危険物取扱者',
    definition: '危険物の取扱いに必要な免状を持つ人。免状の種類で、取り扱える範囲が異なる。',
    subjectId: 'law',
    note: '乙種は、免状に指定された類の危険物を取り扱える。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '危険物保安監督者',
    definition: '一定の製造所等で、所有者等が選任し、保安の監督を行う人。',
    subjectId: 'law',
    note: '選任の対象施設や資格の条件は、法令で定められている。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '予防規程',
    definition: '製造所等の所有者等が、火災を防ぐために自主的に定める保安のための規程。',
    subjectId: 'law',
    note: '対象となる施設は法令で定められ、行政の認可を受ける。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '仮貯蔵・仮取扱い',
    definition: '承認を受けて、一時的に、指定数量以上の危険物を貯蔵または取り扱うこと。',
    subjectId: 'law',
    note: '期間や承認の相手先は法令で定められている。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '完成検査',
    definition: '製造所等の設置や変更の工事が終わったあと、使用を始める前に受ける検査。',
    subjectId: 'law',
    note: '基準に適合していることが確認されて、使用を始められる。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '標識・掲示板',
    definition: '製造所等に設ける、危険物の施設であることや注意事項を示す表示。',
    subjectId: 'law',
    note: '第四類の掲示板には、火気厳禁の注意が示される。',
    aiDraft: true,
  ),
  GlossaryTerm(
    term: '運搬容器の表示',
    definition: '危険物を運ぶ容器の外部に、品名・数量・注意事項などを表示すること。',
    subjectId: 'law',
    note: '第四類の注意事項は火気厳禁。表示項目は教材で確認すること。',
    aiDraft: true,
  ),
];

/// [subjectId] の用語だけを返す（`glossaryTerms` と同じ順序）。
List<GlossaryTerm> glossaryTermsBySubject(String subjectId) =>
    [for (final t in glossaryTerms) if (t.subjectId == subjectId) t];

/// 分野・お気に入り・未習得の条件で用語集を絞り込む。[subjectId] が null
/// なら分野で絞り込まない。[favoritesOnly] がtrueなら、[favoriteTerms] に
/// 含まれる用語だけに絞り込む。[unmasteredOnly] がtrueなら、
/// [masteredTerms]（「覚えた」フラグが付いた用語）に含まれない用語だけに
/// 絞り込む。
List<GlossaryTerm> filterGlossaryTerms({
  String? subjectId,
  required bool favoritesOnly,
  required Set<String> favoriteTerms,
  bool unmasteredOnly = false,
  Set<String> masteredTerms = const {},
}) {
  final bySubject = subjectId == null ? glossaryTerms : glossaryTermsBySubject(subjectId);
  final byFavorite =
      favoritesOnly ? [for (final t in bySubject) if (favoriteTerms.contains(t.term)) t] : bySubject;
  if (!unmasteredOnly) return byFavorite;
  return [for (final t in byFavorite) if (!masteredTerms.contains(t.term)) t];
}

/// [keyword] が用語または定義に含まれる用語を返す（大文字小文字は区別しない）。
/// 空のキーワードでは何も返さない（検索前の一覧表示を避けるため）。
List<GlossaryTerm> searchGlossaryTerms(String keyword) {
  final kw = keyword.trim().toLowerCase();
  if (kw.isEmpty) return [];
  return [
    for (final t in glossaryTerms)
      if (t.term.toLowerCase().contains(kw) || t.definition.toLowerCase().contains(kw)) t,
  ];
}

/// [terms] をランダムな順序に並べ替えて返す（暗記カードのシャッフルモード）。
/// [random] を渡すとテストで結果を固定できる。
List<GlossaryTerm> shuffledGlossaryTerms(List<GlossaryTerm> terms, {Random? random}) =>
    [...terms]..shuffle(random);

/// [terms] を用語名の文字コード順（五十音順。日本語の場合は読み仮名ではなく
/// 文字コード順になる点に注意）に並べ替えて返す（暗記カードの五十音順モード）。
List<GlossaryTerm> sortedGlossaryTermsAlphabetically(List<GlossaryTerm> terms) =>
    [...terms]..sort((a, b) => a.term.compareTo(b.term));

/// [text] 内に出現する用語集の用語を [TermReference] のリストにして返す。
/// 解説文中の用語をタップ可能にする（`TappableTermText`。app_common_kit）ために使う。
List<TermReference> termReferencesIn(String text) => [
      for (final t in glossaryTerms)
        if (text.contains(t.term)) TermReference(termId: t.term, matchText: t.term),
    ];

/// [date] の「今日の一語」（ホーム画面でのピックアップ用）。[terms] が空なら
/// null。同じ日付なら常に同じ用語を返す（エポックからの経過日数を
/// [terms] の件数で割った余りで決める。保存は行わず、呼び出すたびに算出する）。
GlossaryTerm? glossaryTermOfDay(List<GlossaryTerm> terms, DateTime date) {
  if (terms.isEmpty) return null;
  final daysSinceEpoch = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return terms[daysSinceEpoch % terms.length];
}
