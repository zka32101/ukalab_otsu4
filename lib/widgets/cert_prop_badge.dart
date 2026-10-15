import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart' show UkalabCertProp, UkalabProps;

/// 乙種第4類危険物取扱者の資格小物。赤いガソリン携行缶（gascan）のイラストを使う。
/// 第4類は引火性液体（ガソリン等）を扱う資格で、キャップを閉じた缶の絵は
/// 火や漏れを連想させず、「推奨・操作方法」とも読まれにくい。
/// 装飾のみ（読み上げ・タップ対象外）。画像の読み込みに失敗したら何も出さない。
class CertPropBadge extends StatelessWidget {
  const CertPropBadge({super.key, this.size = 44, this.prop = UkalabCertProp.gascan});

  final double size;
  final UkalabCertProp prop;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Image(
          image: UkalabProps.certImage(prop),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
