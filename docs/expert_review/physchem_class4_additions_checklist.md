# 物理化学・第4類(類別・性質)追加80問 確認用一覧

- 対象: `assets/questions/physics_chem.jsonl` の `hazmat4-pc-0173`〜`0212`(40問)と、`assets/questions/property_extinguish.jsonl` の `hazmat4-pe-0183`〜`0222`(40問)。いずれも `tags` に `ai-draft`、`contentVer: 2026.10.2`
- 必要な専門性: 危険物取扱者(乙4または甲種)・受験講習の指導経験者
- 判定・コメント欄は人が埋める。記録は確認日(年月)と確認者区分のみ。氏名・所属・連絡先は記録しない。
- 他の確認用一覧: `multi_angle_checklist.md`(新形式36問)、`review_priority.csv`(優先サンプル)

## 1. 目的と注意

監査で薄いと判明した領域(物理化学、第4類の類別・性質)の補強として AI が下書きした問題である。難易度1(基礎)を中心に、難易度は1が各30問、2が各10問。専門家の確認前であり、確認が済むまで `ai-draft` を外さない。本表は問題文を引用せず、qid・論点・確認の観点のみを記す。数値・法令に関わる箇所は、本表では正しい値を書かず「要確認」とだけ記す。

- 数値問題(単位換算・計算): 計算結果と選択肢の誤答が一意に誤りか、前提(原子量・水1L=1kg・円周率など)が問題文に明示されているか
- 品名・類別・指定数量区分の問題: 消防法別表第一・政令別表第三の記載との整合(条文番号は本表では示さない)
- 取扱い・火災予防の問題: 実務上の一般論として妥当か、誤答に「条件次第で正しい」ものが混ざっていないか
- 共通: 正答が1つに確定するか、正解だけ長くなっていないか、禁止語(合格保証・公式・絶対・本試験相当・過去問・試験に出る)が無いか
- 既存問題との重複: 同一論点の既存問題が無いか(作成時に論点・問題文の類似を機械的に確認済みだが、人の目でも確認する)

## 2. 確認の優先度つき一覧

優先度の基準: 高=数値・計算・法令(別表)に依存、中=表現の妥当性・一般論の例外、低=基礎知識で誤りの余地が小さい。

| qid | 分野 | topicId | 難易度 | 確認の観点 | 優先度 | 判定 | コメント |
|---|---|---|---|---|---|---|---|
| hazmat4-pc-0173 | 物理化学 | physical_vs_chemical_change | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0174 | 物理化学 | mass_number_definition | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0175 | 物理化学 | subatomic_particle_charge | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0176 | 物理化学 | kelvin_celsius_conversion | 1 | 0℃≒273Kの近似でよいか | 高 |  |  |
| hazmat4-pc-0177 | 物理化学 | unit_cubic_meter_to_liter | 1 | 単位換算の正誤 | 中 |  |  |
| hazmat4-pc-0178 | 物理化学 | unit_drum_to_kiloliter | 1 | 単位換算の正誤 | 中 |  |  |
| hazmat4-pc-0179 | 物理化学 | solute_solvent_terms | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0180 | 物理化学 | saturated_solution_definition | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0181 | 物理化学 | adiabatic_compression_heating | 2 | 出題範囲としての妥当性と表現 | 中 |  |  |
| hazmat4-pc-0182 | 物理化学 | oxygen_supports_combustion | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0183 | 物理化学 | nitrogen_air_inert | 1 | 「約8割」の表現の妥当性 | 中 |  |  |
| hazmat4-pc-0184 | 物理化学 | co2_gas_properties | 1 | 性質の記述(無色無臭・空気より重い・不燃) | 中 |  |  |
| hazmat4-pc-0185 | 物理化学 | evaporation_vs_boiling | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0186 | 物理化学 | element_symbol_names | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0187 | 物理化学 | co_co2_formula_names | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0188 | 物理化学 | methanol_molecular_weight | 2 | 原子量の与え方(H=1,C=12,O=16)と計算結果32 | 高 |  |  |
| hazmat4-pc-0189 | 物理化学 | propane_oxygen_volume_ratio | 2 | 反応式の係数(1:5:3:4)と体積比の考え方 | 高 |  |  |
| hazmat4-pc-0190 | 物理化学 | combustion_definition_heat_light | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0191 | 物理化学 | litmus_paper_acid_base | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0192 | 物理化学 | gas_diffusion_basics | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0193 | 物理化学 | unit_kilojoule_to_joule | 1 | 単位換算の正誤 | 低 |  |  |
| hazmat4-pc-0194 | 物理化学 | specific_gravity_mass_from_volume | 2 | 水1L=1kgの前提と計算(400kg) | 高 |  |  |
| hazmat4-pc-0195 | 物理化学 | noble_gas_stability | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0196 | 物理化学 | water_electrolysis_volume_ratio | 2 | 体積比2:1 | 中 |  |  |
| hazmat4-pc-0197 | 物理化学 | heat_balance_mixing_water | 2 | 熱量保存の計算(60℃)と前提の明示 | 高 |  |  |
| hazmat4-pc-0198 | 物理化学 | nitrogen_blanketing_purpose | 1 | 窒素封入の目的の表現 | 中 |  |  |
| hazmat4-pc-0199 | 物理化学 | liquid_pressure_depth | 1 | 液体の圧力の記述 | 低 |  |  |
| hazmat4-pc-0200 | 物理化学 | ignition_source_examples | 1 | 正答の一意性(誤答が点火源でないか) | 中 |  |  |
| hazmat4-pc-0201 | 物理化学 | non_sparking_tools | 2 | 非火花工具の材質表現(銅合金等) | 中 |  |  |
| hazmat4-pc-0202 | 物理化学 | phenolphthalein_indicator | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0203 | 物理化学 | acid_metal_hydrogen | 1 | 亜鉛と希塩酸の反応 | 低 |  |  |
| hazmat4-pc-0204 | 物理化学 | gas_liquefaction_conditions | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pc-0205 | 物理化学 | liquid_viscosity_temperature | 1 | 一般論としての妥当性(例外の有無) | 中 |  |  |
| hazmat4-pc-0206 | 物理化学 | rectangular_tank_volume | 1 | 容積計算(3,000L) | 高 |  |  |
| hazmat4-pc-0207 | 物理化学 | cylinder_tank_volume | 2 | 円周率3.14での計算(6,280L)と「最も近い」の妥当性 | 高 |  |  |
| hazmat4-pc-0208 | 物理化学 | temperature_difference_celsius_kelvin | 1 | 温度差の扱い | 低 |  |  |
| hazmat4-pc-0209 | 物理化学 | calorie_joule_relation | 1 | 1cal≒4.2Jの近似表現 | 中 |  |  |
| hazmat4-pc-0210 | 物理化学 | copper_heating_oxidation | 1 | 酸化銅(II)の色・反応式 | 低 |  |  |
| hazmat4-pc-0211 | 物理化学 | ppm_percent_conversion | 2 | 1%=10,000ppmと計算(500ppm) | 高 |  |  |
| hazmat4-pc-0212 | 物理化学 | carbon_combustion_mass_relation | 2 | 原子量と質量関係(12g→44g) | 高 |  |  |
| hazmat4-pe-0183 | 性質・消火(第4類) | liquid_only_classes | 1 | 各類の状態(固体/液体)の整理 | 高 |  |  |
| hazmat4-pe-0184 | 性質・消火(第4類) | hinmei_count_seven | 1 | 品名数7(別表第一) | 高 |  |  |
| hazmat4-pe-0185 | 性質・消火(第4類) | nonexistent_hinmei | 1 | 品名一覧(別表第一) | 高 |  |  |
| hazmat4-pe-0186 | 性質・消火(第4類) | non_petroleum_hinmei | 1 | 品名の呼称(別表第一) | 中 |  |  |
| hazmat4-pe-0187 | 性質・消火(第4類) | animal_vegetable_oil_definition | 2 | 動植物油類の定義の表現(別表第一) | 高 |  |  |
| hazmat4-pe-0188 | 性質・消火(第4類) | water_soluble_split_hinmei | 2 | 水溶性/非水溶性で指定数量が分かれる品名(政令別表第三) | 高 |  |  |
| hazmat4-pe-0189 | 性質・消火(第4類) | cool_dark_place_storage | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0190 | 性質・消火(第4類) | empty_container_vapor | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0191 | 性質・消火(第4類) | spill_response_basics | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0192 | 性質・消火(第4類) | vapor_inhalation_caution | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0193 | 性質・消火(第4類) | explosion_proof_equipment | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0194 | 性質・消火(第4類) | container_headspace_expansion | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0195 | 性質・消火(第4類) | class4_common_trait | 1 | 第4類の共通性状の表現 | 中 |  |  |
| hazmat4-pe-0196 | 性質・消火(第4類) | oxidizer_contact_danger | 1 | 酸化性物質との接触危険の記述 | 中 |  |  |
| hazmat4-pe-0197 | 性質・消火(第4類) | kerosene_use_pairs | 1 | 用途の記述 | 低 |  |  |
| hazmat4-pe-0198 | 性質・消火(第4類) | acetone_use_solvent | 1 | 用途・水溶性の記述 | 中 |  |  |
| hazmat4-pe-0199 | 性質・消火(第4類) | diethyl_ether_anesthetic | 1 | かつての麻酔用途の表現 | 中 |  |  |
| hazmat4-pe-0200 | 性質・消火(第4類) | boil_over_phenomenon | 2 | ボイルオーバーの定義と誤答語(BLEVE等)の明確な誤り | 高 |  |  |
| hazmat4-pe-0201 | 性質・消火(第4類) | minimum_ignition_energy_small | 2 | 最小着火エネルギーの一般的記述 | 中 |  |  |
| hazmat4-pe-0202 | 性質・消火(第4類) | fire_prevention_principles | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0203 | 性質・消火(第4類) | extinguisher_upwind | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0204 | 性質・消火(第4類) | extinguisher_aim_base | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0205 | 性質・消火(第4類) | reflash_after_extinguishing | 2 | 再燃の記述 | 中 |  |  |
| hazmat4-pe-0206 | 性質・消火(第4類) | class_representative_pairs | 1 | 各類の代表物質の類別 | 高 |  |  |
| hazmat4-pe-0207 | 性質・消火(第4類) | gasoline_washing_prohibition | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0208 | 性質・消火(第4類) | gasoline_in_kerosene_heater | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0209 | 性質・消火(第4類) | gasoline_kerosene_mixture_flash | 2 | 混合時の引火点の変化(定性) | 中 |  |  |
| hazmat4-pe-0210 | 性質・消火(第4類) | tempura_oil_water_danger | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0211 | 性質・消火(第4類) | high_flash_point_heating | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0212 | 性質・消火(第4類) | water_solubility_simple_check | 1 | 簡易判別の記述(二層に分かれる=水に溶けにくい) | 中 |  |  |
| hazmat4-pe-0213 | 性質・消火(第4類) | gas_detector_before_work | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0214 | 性質・消火(第4類) | tank_entry_hazard | 2 | 入槽作業の危険の記述 | 中 |  |  |
| hazmat4-pe-0215 | 性質・消火(第4類) | hot_work_vapor_removal | 2 | 火気作業前の措置の記述 | 中 |  |  |
| hazmat4-pe-0216 | 性質・消火(第4類) | co2_extinguisher_confined_space | 1 | 二酸化炭素消火の安全上の記述 | 中 |  |  |
| hazmat4-pe-0217 | 性質・消火(第4類) | volatility_definition | 1 | 揮発性の定義と引火点との関係の表現 | 中 |  |  |
| hazmat4-pe-0218 | 性質・消火(第4類) | alcohol_flame_visibility | 1 | 炎の見えにくさの記述(「ことがある」の妥当性) | 中 |  |  |
| hazmat4-pe-0219 | 性質・消火(第4類) | ether_peroxide_formation | 2 | 過酸化物生成の記述 | 高 |  |  |
| hazmat4-pe-0220 | 性質・消火(第4類) | carbon_disulfide_combustion_gas | 2 | 燃焼生成物の記述(二酸化硫黄) | 高 |  |  |
| hazmat4-pe-0221 | 性質・消火(第4類) | waste_liquid_disposal | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |
| hazmat4-pe-0222 | 性質・消火(第4類) | protective_gloves_solvents | 1 | 一般的な理科・取扱い知識として正誤・誤答の明確な誤りを確認 | 低 |  |  |

## 3. 確認後の手順

1. 判定が OK の問題について、`ai-draft` タグを外す PR を別に作る(修正・削除の判定は内容を直す別 PR)。
2. 変更した問題の `contentVer` を更新する。
3. 本 PR(追加80問)は専門確認前のため、マージせず、確認後に別 PR で `ai-draft` を外す。
