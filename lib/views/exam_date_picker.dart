import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exam_date_store.dart';

/// 試験日の日付ピッカーを開いて保存する。設定タブとホームのカウントダウンで共用。
/// 試験日が過去（昨日より前）でも落ちないよう、初期表示日を選択可能範囲に収める。
Future<void> pickExamDate(BuildContext context, WidgetRef ref) async {
  final now = DateTime.now();
  final first = now.subtract(const Duration(days: 1));
  final last = now.add(const Duration(days: 730));
  var initial = ref.read(examDateProvider) ?? now;
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked != null) {
    await ref.read(examDateProvider.notifier).setDate(picked);
  }
}
