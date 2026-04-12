import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/settings.dart';
//import 'package:sns_calculator/logger.dart';
import 'package:sns_calculator/widgets/attack_effect_settings.dart';
import 'package:sns_calculator/widgets/card_settings.dart';
import 'package:lpinyin/lpinyin.dart';

class AddActionDialog extends StatefulWidget {
  final List<String> characterList;
  final VoidCallback? onActionCompleted; 

  const AddActionDialog({
    Key? key, 
    required this.characterList,
    this.onActionCompleted,
  }) : super(key: key);

  @override
  _AddActionDialogState createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  // 第一个下拉菜单选项
  // final List<String> _actionTypes = ['行动', '技能', '特质'];
  
  // 各个下拉菜单的当前选中值
  String? _actionType;
  String? _source;
  String? _target;
  String? _selectedSkill;
  String? _selectedTrait;

  // 玩家数据
  //Character? _sourcePlayer;
  //Character? _targetPlayer;

  // 技能额外目标列表
  final List<String> _skillTargetList = [];

  // 特质额外目标列表
  final List<String> _traitTargetList = [];
  
  // 道具卡数据
  List<String>? cardTypes;

  // 技能数据
  Map<String, dynamic>? skillData;

  // 特质数据
  Map<String, dynamic>? traitData;

  // 标签数据
  Map<String, dynamic>? tagData;

  // 语言数据
  Map<String, dynamic>? langMap;
  // 资产是否已加载
  bool _assetsLoaded = false;
  
  // 道具卡表格数据
  final List<Map<String, dynamic>> _cardTableData = [];

  // 攻击特效表格数据
  final List<Map<String, dynamic>> _attackEffectTableData = [];
  
  // 防守特效表格数据
  final List<Map<String, dynamic>> _defenceEffectTableData = [];

  // 技能设置
  // 仁慈
  int _benevolenceChoice = 0;
  // 恐吓
  int _intimidationPoint = 1;
  // 奉献
  int _devotionPoint = 1;
  // 挑唆
  final Map<String, int> _instigationPoints = {};
  final Map<String, int> _isPlayerInstigated = {};
  // 斯威芬【造梦者】
  int _dreamWeaverChoice = 1;
  // 叶姬【须臾】
  String? _emphemeralStatus;
  // 科亚特尔【天启之庭】
  int _apocalypticPoint = 1;
  // 祝烨明【八寒之七】
  int _seventhFrostPoint = 1;
  String? _seventhFrostStatus;
  // 蓝文策【三仙归洞】
  int _threeImmortalsChoice = 0;
  // 卡拉卡【木头羊】
  int _timberSheepPoint = 1;

  // 特质设置
  // 幸运壁垒
  final Map<DamageRecord, int> _luckyShieldDamages = {};
  // 决心
  int _resolutionPoint = 2;
  // 耀光爆裂
  int _radiantBlastPoint = 1;
  // 咕了
  int _escapingPoint = 1;
  // 大预言
  int _prophecyChoice = 0;
  int _prophecyPoint = 1;
  // 希冀
  int _yearningPoint = 1;
  // 天霜封印
  int _arcticSealPoint = 2;
  // 轻捷妙手
  int _deftTouchPoint = 0;
  String? _deftTouchSkill;
  // 律令
  int _decreePoint = 0;
  // 云系祝乐
  int _celestialChoice = 0;
  int _celestialPoint = 1;
  // 挑拣
  int _discerningPoint = 1;
  // 心炎
  int _cardioBlazePoint = 1;
  // 梦的塑造
  int _craftingDreamChoice = 0;
  int _craftingDreamPoint = 1;
  // 烈焰之体
  int _conflagrationChoice = 1;
  int _conflagrationPoint = 1;
  // 永恒
  int _eternityPoint = 0;
  String? _eternityStatus;
  // 黯灭
  int _darkDissolutionChoice = 0;
  String? _darkDissolutionCard;
  // 禁忌知识
  int _tabooLoreChoice = 1;
  // 红莲业火
  int _lotusFlameChoice = 1;
  // 光耀
  int _radianceChoice = 0;
  final Map<DamageRecord, int> _radianceDamages = {};
  // 精神干扰
  int _mentalDisruptionPoint = 1;
  // 追猎的乌托邦
  int _utopiaOfCelerityChoice = 0;
  // 极寒环域
  int _glacialCirclePoint = 1;
  // 控水
  int _hydromancyChoice = 0;
  // 水之刑
  int _waterTortureChoice = 0;
  int _waterTorturePoint = 1;
  // <04>质能转换
  int _massEnergyChoice = 0;
  // 针锋相对
  int _titForTatSourcePoint = 1;
  int _titForTatTargetPoint = 1;
  // 探囊取物
  int _pluckingPouchChoice = 0;
  // 气象万千
  int _weathersUnfoldChoice = 0;
  // 冰与火之歌
  int _iceAndFireChoice = 0;
  String? _iceAndFireStatus;
  // 不容置疑的信任
  int _unquestioningTrustPoint = 1;
  int _unquestioningTrustChoice = 0;
  // 蹦蹦咒语
  int _boingSpellChoice = 0;

  // 日志系统
  static final Logger _logger = Logger();

  // 点数输入控制器
  final TextEditingController _pointController = TextEditingController();

  // 游戏数据读取
  Game game = GameManager().game;

  @override
  void initState() {
    super.initState();
    // 从全局 Provider 获取已加载的 Assets（在 main 中预加载）
    final assets = Provider.of<AssetsManager>(context, listen: false);
    cardTypes = assets.cardTypes;
    skillData = assets.skillData;
    traitData = assets.traitData;
    tagData = assets.tagData;
    langMap = assets.langMap;
    _assetsLoaded = true;
    // 限制只能输入数字
    _pointController.addListener(() {
      final text = _pointController.text;
      if (text.isNotEmpty && int.tryParse(text) == null) {
        _pointController.value = TextEditingValue(
          text: text.replaceAll(RegExp(r'[^0-9]'), ''),
          selection: TextSelection.fromPosition(
            TextPosition(offset: text.replaceAll(RegExp(r'[^0-9]'), '').length),
          ),
        );
      }
    });
    // 技能设置初始化
    for (var chara in game.players.values) {
      if (chara.id != 'empty') {
        _instigationPoints[chara.id] = 1;
        _isPlayerInstigated[chara.id] = 0;
      }      
    }
  }

  // 读取并解析JSON文件
  Future<void> _loadAssetsData() async {
    // 兼容性：如果某处调用此方法（例如菜单可能在极少数情况下调用），
    // 则从 Provider 获取资产并在必要时加载。
    final assets = Provider.of<AssetsManager>(context, listen: false);
    if (assets.langMap == null) {
      await assets.loadData();
    }
    setState(() {
      cardTypes = assets.cardTypes;
      skillData = assets.skillData;
      traitData = assets.traitData;
      tagData = assets.tagData;
      langMap = assets.langMap;
      _assetsLoaded = true;
    });
  }

  // 显示道具卡选择菜单
  Future<void> _showCardSelectionMenu() async {
    if (!_assetsLoaded || cardTypes == null) {
      // 尝试从 Provider 获取（通常 main 已预加载）
      final assets = Provider.of<AssetsManager>(context, listen: false);
      if (assets.cardTypes == null) {
        await _loadAssetsData();
        if (cardTypes == null) return;
      } else {
        setState(() {
          cardTypes = assets.cardTypes;
          skillData = assets.skillData;
          traitData = assets.traitData;
          tagData = assets.tagData;
          langMap = assets.langMap;
          _assetsLoaded = true;
        });
      }
    }

    // 构建按拼音首字母分组的数据结构
    final allCards = cardTypes ?? [];
    // 生成分组 map：首字母 -> list of card names
    Map<String, List<String>> groups = {};
    for (var name in allCards) {
      String initial;
      try {
        final short = PinyinHelper.getShortPinyin(name);
        initial = short.isNotEmpty ? short[0].toUpperCase() : name[0].toUpperCase();
      } catch (_) {
        initial = name.isNotEmpty ? name[0].toUpperCase() : '#';
      }
      if (!RegExp(r'[A-Z]').hasMatch(initial)) initial = '#';
      groups.putIfAbsent(initial, () => []).add(name);
    }

    // 组内按完整拼音排序
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) {
        final pa = PinyinHelper.getPinyinE(a, separator: '');
        final pb = PinyinHelper.getPinyinE(b, separator: '');
        return pa.compareTo(pb);
      });
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: LayoutBuilder(builder: (context, constraints) {
            final double maxW = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            return SizedBox(
              width: maxW,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('添加道具卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, idx) {
                          final key = sortedKeys[idx];
                          final names = groups[key]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                LayoutBuilder(builder: (context, box) {
                                  final double w = box.maxWidth;
                                  int columns = (w / 140).floor();
                                  if (columns < 3) columns = 3;
                                  if (columns > 6) columns = 6;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent: 40,
                                    ),
                                    itemCount: names.length,
                                    itemBuilder: (context, i) {
                                      final name = names[i];
                                      return ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            // 添加到表格数据（允许重复选择）
                                            _cardTableData.add({
                                              'cardName': name,
                                              'settings': <String, dynamic>{},
                                            });
                                          });
                                          // 添加到道具卡设置管理器
                                          final cardSettingManager = Provider.of<CardSettingsManager>(context, listen: false);
                                          cardSettingManager.addNewCard(name);
                                          // 初始化部分设置（沿用原逻辑）
                                          if (langMap != null && name == langMap!['redstone']) {
                                            RedstoneSetting setting = RedstoneSetting();
                                            setting.playerProlonged = _source!;
                                            setting.statusProlonged = game.players[_source!]!.status.isEmpty ? '' : game.players[_source!]!.status.keys.first;
                                            cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
                                          }
                                          else if (langMap != null && name == langMap!['ascension_stair']) {
                                            AscensionStairSetting setting = AscensionStairSetting();
                                            for (var chara in game.players.values) {
                                              if (chara.id != 'empty' && !chara.isDead) {
                                                setting.ascensionPoints[chara.id] = 1;
                                              }
                                            }
                                            cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
                                          }
                                          else if (langMap != null && name == langMap!['refreshment']) {
                                            RefreshmentSetting setting = RefreshmentSetting();
                                            String skill = game.players[_source!]!.skill.isEmpty ? '' : game.players[_source!]!.skill.keys.first;
                                            setting.refreshmentChoice = skill;
                                            cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
                                          }
                                          else if (langMap != null && name == langMap!['aurora_concussion']) {
                                            AuroraConcussionSetting setting = AuroraConcussionSetting();
                                            for (var chara in game.players.values) {
                                              if (game.isEnemy(_source!, chara.id) && !chara.isDead && chara.id != 'empty') {
                                                setting.auroraPoints[chara.id] = 1;
                                              }
                                            }
                                            cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
                                          }

                                        Navigator.of(ctx).pop();
                                        },
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                        child: Text(name, textAlign: TextAlign.center),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  // 显示技能选择对话框（单选，替换现有 _selectedSkill）
  Future<void> _showSkillSelectionDialog() async {
    if (!_assetsLoaded || skillData == null) {
      final assets = Provider.of<AssetsManager>(context, listen: false);
      if (assets.skillData == null) {
        await _loadAssetsData();
        if (skillData == null) return;
      } else {
        setState(() {
          cardTypes = assets.cardTypes;
          skillData = assets.skillData;
          traitData = assets.traitData;
          tagData = assets.tagData;
          langMap = assets.langMap;
          _assetsLoaded = true;
        });
      }
    }

    final allSkills = skillData!.keys.toList();
    // group by pinyin initial like card dialog
    Map<String, List<String>> groups = {};
    for (var name in allSkills) {
      String initial;
      try {
        final short = PinyinHelper.getShortPinyin(name);
        initial = short.isNotEmpty ? short[0].toUpperCase() : name[0].toUpperCase();
      } catch (_) {
        initial = name.isNotEmpty ? name[0].toUpperCase() : '#';
      }
      if (!RegExp(r'[A-Z]').hasMatch(initial)) initial = '#';
      groups.putIfAbsent(initial, () => []).add(name);
    }
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) {
        final pa = PinyinHelper.getPinyinE(a, separator: '');
        final pb = PinyinHelper.getPinyinE(b, separator: '');
        return pa.compareTo(pb);
      });
    }
    final sortedKeys = groups.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: LayoutBuilder(builder: (context, constraints) {
            final double maxW = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            return SizedBox(
              width: maxW,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('选择技能', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, idx) {
                          final key = sortedKeys[idx];
                          final names = groups[key]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                LayoutBuilder(builder: (context, box) {
                                  final double w = box.maxWidth;
                                  int columns = (w / 140).floor();
                                  if (columns < 3) columns = 3;
                                  if (columns > 6) columns = 6;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent: 40,
                                    ),
                                    itemCount: names.length,
                                    itemBuilder: (context, i) {
                                      final name = names[i];
                                      return ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedSkill = name;
                                          });
                                          Navigator.of(ctx).pop();
                                        },
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                        child: Text(name, textAlign: TextAlign.center),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  // 显示特质选择对话框（单选，替换现有 _selectedTrait）
  Future<void> _showTraitSelectionDialog() async {
    if (!_assetsLoaded || traitData == null) {
      final assets = Provider.of<AssetsManager>(context, listen: false);
      if (assets.traitData == null) {
        await _loadAssetsData();
        if (traitData == null) return;
      } else {
        setState(() {
          cardTypes = assets.cardTypes;
          skillData = assets.skillData;
          traitData = assets.traitData;
          tagData = assets.tagData;
          langMap = assets.langMap;
          _assetsLoaded = true;
        });
      }
    }

    final allTraits = traitData!.keys.toList();
    Map<String, List<String>> groups = {};
    for (var name in allTraits) {
      String initial;
      try {
        final short = PinyinHelper.getShortPinyin(name);
        initial = short.isNotEmpty ? short[0].toUpperCase() : name[0].toUpperCase();
      } catch (_) {
        initial = name.isNotEmpty ? name[0].toUpperCase() : '#';
      }
      if (!RegExp(r'[A-Z]').hasMatch(initial)) initial = '#';
      groups.putIfAbsent(initial, () => []).add(name);
    }
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) {
        final pa = PinyinHelper.getPinyinE(a, separator: '');
        final pb = PinyinHelper.getPinyinE(b, separator: '');
        return pa.compareTo(pb);
      });
    }
    final sortedKeys = groups.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: LayoutBuilder(builder: (context, constraints) {
            final double maxW = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            return SizedBox(
              width: maxW,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('选择特质', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, idx) {
                          final key = sortedKeys[idx];
                          final names = groups[key]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                LayoutBuilder(builder: (context, box) {
                                  final double w = box.maxWidth;
                                  int columns = (w / 140).floor();
                                  if (columns < 3) columns = 3;
                                  if (columns > 6) columns = 6;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent: 40,
                                    ),
                                    itemCount: names.length,
                                    itemBuilder: (context, i) {
                                      final name = names[i];
                                      return ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedTrait = name;
                                          });
                                          Navigator.of(ctx).pop();
                                        },
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                        child: Text(name, textAlign: TextAlign.center),
                                      );
                                    },
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  // 删除道具卡行
  void _deleteCardRow(int index) {
    setState(() {
      _cardTableData.removeAt(index);
    });
    final cardSettingManager = Provider.of<CardSettingsManager>(context, listen: false);
    cardSettingManager.removeCard(index);
  }

  // 显示道具卡设置窗口
  void _showCardSettingsDialog(int index, String cardName) {
    final cardSettingsManager = Provider.of<CardSettingsManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeNotifierProvider.value(
          value: cardSettingsManager,
          child: CardSettingsDialog(
            cardIndex: index,
            cardName: cardName, 
            source: _source,
            target: _target
          )
        );
      },
    );
  }

  // 显示攻击特效选择菜单
  void _showAttackEffectSelectionMenu() {
    final List<AttackEffect> attackEffects = AttackEffect.values;
  
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2),
          Offset.zero & MediaQuery.of(context).size,
      ),
      items: attackEffects.map((AttackEffect effect) {
        return PopupMenuItem(
          value: effect,
          child: Text(effect.effectId),
        );
      }).toList(),
    ).then((AttackEffect? selectedEffect) {
      if (selectedEffect != null) {
        setState(() {
          // 添加到攻击特效表格数据中
          _attackEffectTableData.add({
            'effect': selectedEffect,
            'settings': <String, dynamic>{}, // 可用于存储该行的设置
          });
        });
      }
    });
  }

  // 删除攻击特效行
  void _deleteAttackEffectRow(int index) {
    setState(() {
      _attackEffectTableData.removeAt(index);
    });
  }

  // 显示攻击特效设置窗口
  void _showAttackEffectSettingsDialog(int index, AttackEffect effect) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AttackEffectSettingsDialog(
          effect: effect,
          initialSettings: Map<String, dynamic>.from(_attackEffectTableData[index]['settings']),
          onSettingsChanged: (settings) {
            setState(() {
              _attackEffectTableData[index]['settings'] = settings;
            });
          },
        );
      },
    );
  }

  // 显示防守特效选择菜单
  void _showDefenceEffectSelectionMenu() {
    final List<DefenceEffect> defenceEffects = DefenceEffect.values;
  
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2),
          Offset.zero & MediaQuery.of(context).size,
      ),
      items: defenceEffects.map((DefenceEffect effect) {
        return PopupMenuItem(
          value: effect,
          child: Text(effect.effectId),
        );
      }).toList(),
    ).then((DefenceEffect? selectedEffect) {
      if (selectedEffect != null) {
        setState(() {
          // 添加到防守特效表格数据中
          _defenceEffectTableData.add({
            'effect': selectedEffect,
            'settings': <String, dynamic>{}, // 可用于存储该行的设置
          });
        });
      }
    });
  }

  // 删除防守特效行
  void _deleteDefenceEffectRow(int index) {
    setState(() {
      _defenceEffectTableData.removeAt(index);
    });
  }

  // 显示防守特效设置窗口
  void _showDefenceEffectSettingsDialog(int index, DefenceEffect effect) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefenceEffectSettingsDialog(
          effect: effect,
          initialSettings: Map<String, dynamic>.from(_defenceEffectTableData[index]['settings']),
          onSettingsChanged: (settings) {
            setState(() {
              _defenceEffectTableData[index]['settings'] = settings;
            });
          },
        );
      },
    );
  }

  // 添加技能目标
  void _addSkillTarget(String target) {
    setState(() {
      _skillTargetList.add(target);
    });
  }

  // 删除技能目标
  void _removeSkillTarget(int index) {
    setState(() {
      _skillTargetList.removeAt(index);
    });
  }

  // 显示技能目标选择菜单
  Future<void> _showSkillTargetSelectionMenu() async {
    if (!_assetsLoaded || langMap == null) {
      final assets = Provider.of<AssetsManager>(context, listen: false);
      if (assets.langMap == null) {
        await _loadAssetsData();
        if (langMap == null) return;
      } else {
        setState(() {
          cardTypes = assets.cardTypes;
          skillData = assets.skillData;
          traitData = assets.traitData;
          tagData = assets.tagData;
          langMap = assets.langMap;
          _assetsLoaded = true;
        });
      }
    }

    final skillTargetItems = widget.characterList
        .where((item) => item != _target && !game.players[item]!.isDead
            && !game.players[item]!.hasStatus(langMap!['gugu']))
        .map((String item) {
      return PopupMenuItem<String>(
        value: item,
        child: Text(item),
      );
    }).toList();

    if (skillTargetItems.isEmpty) return; // 避免 showMenu(items: []) 触发断言

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
      items: skillTargetItems,
    ).then((String? selectedValue) {
      if (!mounted) return;
      if (selectedValue != null) {
        _addSkillTarget(selectedValue);
      }
    });
  }

  void _addTraitTarget(String target) {
    setState(() {
      _traitTargetList.add(target);
    });
  }


  void _removeTraitTarget(int index) {
    setState(() {
      _traitTargetList.removeAt(index);
    });
  }

  Future<void> _showTraitTargetSelectionMenu() async {
    if (!_assetsLoaded || langMap == null) {
      final assets = Provider.of<AssetsManager>(context, listen: false);
      if (assets.langMap == null) {
        await _loadAssetsData();
        if (langMap == null) return;
      } else {
        setState(() {
          cardTypes = assets.cardTypes;
          skillData = assets.skillData;
          traitData = assets.traitData;
          tagData = assets.tagData;
          langMap = assets.langMap;
          _assetsLoaded = true;
        });
      }
    }

    final traitTargetItems = widget.characterList
        .where((item) => (item != _target && !game.players[item]!.isDead
            && !game.players[item]!.hasStatus(langMap!['gugu'])))
        .map((String item) {
      return PopupMenuItem<String>(
        value: item,
        child: Text(item),
      );
    }).toList();

    if (traitTargetItems.isEmpty) return; // 避免 showMenu(items: []) 触发断言

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
      items: traitTargetItems,
    ).then((String? selectedValue) {
      if (!mounted) return;
      if (selectedValue != null) {
        _addTraitTarget(selectedValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 如果资产尚未加载，显示加载提示，避免访问 langMap!/skillData! 导致空指针
    if (!_assetsLoaded) {
      return AlertDialog(
        title: Text('加载中'),
        content: SizedBox(
          height: 80,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('正在加载数据，请稍候...'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('取消'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('添加行动'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行动类型选择
              Text('行动类型', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 使用 ToggleButtons 实现按下后保持选中、切换时取消的行为
                  ToggleButtons(
                    isSelected: [
                      _actionType == '行动',
                      _actionType == '技能',
                      _actionType == '特质',
                    ],
                    onPressed: (int index) {
                      setState(() {
                        switch (index) {
                          case 0:
                            _actionType = '行动';
                            break;
                          case 1:
                            _actionType = '技能';
                            break;
                          case 2:
                            _actionType = '特质';
                            break;
                        }
                      });
                    },
                    constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
                    borderRadius: BorderRadius.circular(6),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).colorScheme.primary,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('行动')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('技能')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('特质')),
                    ],
                  ),
                ],
              ),
              Text('主动角色', style: TextStyle(fontWeight: FontWeight.bold)),
              LayoutBuilder(builder: (context, box) {
                // 按人数决定每行列数：<=4 每行2个，否则每行3个
                final candidates = widget.characterList.where((item) => !game.players[item]!.isDead && !game.players[item]!.hasStatus(langMap!['gugu'])).toList();
                final int columns = candidates.length <= 4 ? 2 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 40,
                  ),
                  itemCount: candidates.length,
                  itemBuilder: (context, i) {
                    final name = candidates[i];
                    final bool selected = _source == name;
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _source = name;
                          if (_target == name) _target = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: selected ? Theme.of(context).colorScheme.primary : null,
                        foregroundColor: selected ? Colors.white : null,
                      ),
                      child: Text(name, textAlign: TextAlign.center),
                    );
                  },
                );
              }),
              const SizedBox(height: 12),

              Text('被动角色', style: TextStyle(fontWeight: FontWeight.bold)),
              LayoutBuilder(builder: (context, box) {
                final candidates = widget.characterList.where((item) => !game.players[item]!.isDead && !game.players[item]!.hasStatus(langMap!['gugu'])).toList();
                final int columns = candidates.length <= 4 ? 2 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 40,
                  ),
                  itemCount: candidates.length,
                  itemBuilder: (context, i) {
                    final name = candidates[i];
                    final bool selected = _target == name;
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _target = name;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: selected ? Theme.of(context).colorScheme.primary : null,
                        foregroundColor: selected ? Colors.white : null,
                      ),
                      child: Text(name, textAlign: TextAlign.center),
                    );
                  },
                );
              }),
              const SizedBox(height: 16),
              
              // 条件性显示的道具卡选择区域（仅在选择"行动"时显示）
              if (_actionType == '行动') ...[
                Text('道具卡', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),

                // 点数输入框
                TextFormField(
                  controller: _pointController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '点数',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                      return '请输入有效数字';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _showCardSelectionMenu,
                  child: Text('添加道具卡'),
                ),
                
                // 道具卡表格
                if (_cardTableData.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: Wrap(
                      spacing: 8,
                      children: _cardTableData.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final Map<String, dynamic> rowData = entry.value;
                        final String cardName = rowData['cardName'];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(cardName),
                                const SizedBox(width: 12),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.settings, size: 18),
                                  onPressed: () => _showCardSettingsDialog(index, cardName),
                                  tooltip: '设置',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 18),
                                  onPressed: () => _deleteCardRow(index),
                                  tooltip: '删除',
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                SizedBox(height: 8),
                // 添加攻击特效按钮
                ElevatedButton(
                  onPressed: _showAttackEffectSelectionMenu,
                  child: Text('添加攻击特效'),
                ),
  
                // 攻击特效表格
                if (_attackEffectTableData.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      children: _attackEffectTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final AttackEffect effect = rowData['effect'];
            
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(effect.effectId),
                                  const SizedBox(width: 12),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.settings, size: 18),
                                    onPressed: () => _showAttackEffectSettingsDialog(index, effect),
                                    tooltip: '设置',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteAttackEffectRow(index),
                                    tooltip: '删除',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ),
                  ),
                ],
                SizedBox(height: 8),
                // 添加防守特效按钮
                ElevatedButton(
                  onPressed: _showDefenceEffectSelectionMenu,
                  child: Text('添加防守特效'),
                ),
  
                // 防守特效表格
                if (_defenceEffectTableData.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      children: _defenceEffectTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final DefenceEffect effect = rowData['effect'];
            
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(effect.effectId),
                                  const SizedBox(width: 12),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.settings, size: 18),
                                    onPressed: () => _showDefenceEffectSettingsDialog(index, effect),
                                    tooltip: '设置',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteDefenceEffectRow(index),
                                    tooltip: '删除',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ),
                  ),
                ],
              ] else if (_actionType == '技能') ...[
                Text('额外目标', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showSkillTargetSelectionMenu,
                  child: Text('添加技能目标')),
                SizedBox(height: 8),

                if(_skillTargetList.isNotEmpty) ...[
                 Container(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      children: _skillTargetList.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final String target = entry.value;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(target),
                                const SizedBox(width: 12),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 18),
                                  onPressed: () => _removeSkillTarget(index),
                                )                                    
                              ]
                            )
                          )
                        );
                      }).toList(),
                    ),
                  ),
                ],
                SizedBox(height: 16),

                Text('技能选择', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(child: Text(_selectedSkill ?? '未选择技能')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showSkillSelectionDialog,
                      child: Text(_selectedSkill == null ? '选择技能' : '更换技能'),
                    ),
                    if (_selectedSkill != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() { _selectedSkill = null; });
                        },
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),

                if(_selectedSkill != null) ...[
                  Text('技能设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if (_selectedSkill == langMap!['benevolence']) ... [
                    Text('仁慈', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _benevolenceChoice,
                      hint: Text('请选择仁慈的效果'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('回复20%生命值')),
                        DropdownMenuItem(value: 1, child: Text('抽2张牌')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _benevolenceChoice = newValue ?? 0;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['intimidation']) ...[
                    Text('恐吓', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _intimidationPoint,
                      hint: Text('请选择恐吓点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),                              
                      onChanged: (int? newValue) {
                        setState(() {
                          _intimidationPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['devotion']) ...[
                    Text('奉献', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _devotionPoint,
                      hint: Text('请选择奉献点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),                              
                      onChanged: (int? newValue) {
                        setState(() {
                          _devotionPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['instigation']) ...[
                    Text('挑唆', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ...game.gameSequence.where((playerId) => playerId != game.players[_source]!.id)
                    .map((playerId) {
                      final Character chara = game.players[playerId]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${chara.id} 是否被挑唆'),
                          DropdownButtonFormField<int>(
                            initialValue:_isPlayerInstigated[chara.id],
                            items: [
                              DropdownMenuItem(value: 0, child: Text('否')),
                              DropdownMenuItem(value: 1, child: Text('是')),
                            ], 
                            onChanged: (int? newValue) {
                              setState(() {
                                _isPlayerInstigated[chara.id] = newValue ?? 0;
                              });
                            },
                            isExpanded: true,
                          ),
                          SizedBox(height: 16),
                          Text('${chara.id} 挑唆点数'),
                          DropdownButtonFormField(
                            initialValue: _instigationPoints[chara.id],                            
                            items: List.generate(6, (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                              )).toList(),                              
                            onChanged: (int? newValue) {
                              setState(() {
                                _instigationPoints[chara.id] = newValue ?? 1;
                              });
                            }
                          ),
                          SizedBox(height: 16)
                        ]
                      );
                    })
                  ] else if (_selectedSkill == langMap!['dream_weaver']) ...[
                    Text('造梦者', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _dreamWeaverChoice,
                      hint: Text('请选择造梦点数'),
                      items: List.generate(3, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),                              
                      onChanged: (int? newValue) {
                        setState(() {
                          _dreamWeaverChoice = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['emphemeral']) ...[                     
                    Text('须臾', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      initialValue:_emphemeralStatus,
                      hint: Text('请选择须臾状态'),
                      items: _target != null && game.players[_target] != null 
                        ? game.players[_target]!.status.keys.map((String statusKey) {
                          return DropdownMenuItem(
                            value: statusKey,
                            child: Text(statusKey),
                          );
                        }).toList()
                        : [],
                      onChanged: (String? newValue) {
                        setState(() {
                          _emphemeralStatus = newValue ?? '';
                        });
                      }
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['apocalyptic_court']) ...[
                    Text('天启之庭', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _apocalypticPoint,
                      hint: Text('请选择天启点数'),
                      items: List.generate(4, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),                              
                      onChanged: (int? newValue) {
                        setState(() {
                          _apocalypticPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['seventh_frost']) ...[ 
                    Text('八寒之七', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_seventhFrostPoint,
                      hint: Text('请选择八寒点数'),
                      items: List.generate(10, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _seventhFrostPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    Text('状态', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      initialValue:_seventhFrostStatus,
                      hint: Text('请选择八寒状态'),
                      items: _target != null && game.players[_target] != null 
                        ? game.players[_target]!.status.keys.map((String statusKey) {
                          return DropdownMenuItem(
                            value: statusKey,
                            child: Text(statusKey),
                          );
                        }).toList()
                        : [],
                      onChanged: (String? newValue) {
                        setState(() {
                          _seventhFrostStatus = newValue ?? '';
                        });
                      }
                    )
                  ] else if (_selectedSkill == langMap!['three_immortals_return']) ... [
                    Text('三仙归洞', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _threeImmortalsChoice,
                      hint: Text('请选择三仙归洞效果'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('回MP随机弃牌')),
                        DropdownMenuItem(value: 1, child: Text('消耗MP摸牌')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _threeImmortalsChoice = newValue ?? 0;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] else if (_selectedSkill == langMap!['timber_sheep']) ...[
                    Text('奉献', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _timberSheepPoint,
                      hint: Text('请选择奉献点数'),
                      items: List.generate(3, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),                              
                      onChanged: (int? newValue) {
                        setState(() {
                          _timberSheepPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16)
                  ] 
                ]
              ]

              // 特质
              else if (_actionType == '特质') ...[
                Text('额外目标', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showTraitTargetSelectionMenu,
                  child: Text('添加特质目标')),
                SizedBox(height: 8),

                if(_traitTargetList.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      children: _traitTargetList.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final String target = entry.value;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(target),
                                const SizedBox(width: 12),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 18),
                                  onPressed: () => _removeTraitTarget(index),
                                )                                    
                              ]
                            )
                          )
                        );
                      }).toList(),
                    ),
                  ),
                ],
                SizedBox(height: 16),

                Text('特质选择', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(child: Text(_selectedTrait ?? '未选择特质')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showTraitSelectionDialog,
                      child: Text(_selectedTrait == null ? '选择特质' : '更换特质'),
                    ),
                    if (_selectedTrait != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() { _selectedTrait = null; });
                        },
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),

                if (_selectedTrait != null) ...[
                  Text('特质设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if(_selectedTrait == langMap!['lucky_shield']) ... [
                    Builder(
                      builder: (BuildContext context) {
                        final recordProvider = Provider.of<RecordProvider>(context);
                        final List<GameRecord> damageRecords = recordProvider.getFilteredRecords(target: _source, type: RecordType.damage,
                          startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                        if (_luckyShieldDamages.length != damageRecords.length) {
                          _luckyShieldDamages.clear();
                          for (var record in damageRecords) {
                            DamageRecord dmgRecord = record as DamageRecord;
                            _luckyShieldDamages[dmgRecord] = 1;
                          }
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('幸运壁垒', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            if (damageRecords.isNotEmpty) ...[
                              ...damageRecords.asMap().entries.map((entry) {
                                final int index = entry.key;
                                final DamageRecord dmgRecord = entry.value as DamageRecord;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('第${index + 1}次，来源：${dmgRecord.source}'),
                                    Text('伤害值：${dmgRecord.damage}'),
                                    DropdownButtonFormField<int>(
                                      initialValue: _luckyShieldDamages[dmgRecord],
                                      items: List.generate(6, (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text('${i + 1}'),
                                      )).toList(), 
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          _luckyShieldDamages[dmgRecord] = newValue ?? 1;
                                        });
                                      },
                                      isExpanded: true,
                                    ),
                                    SizedBox(height: 16),
                                  ],
                                );
                              })
                            ]
                          ],
                        );
                      }
                    )
                  ] else if (_selectedTrait == langMap!['resolution']) ...[ 
                    Text('决心', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_resolutionPoint,
                      hint: Text('请选择决心点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _resolutionPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['radiant_blast']) ...[ 
                    Text('耀光爆裂', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_radiantBlastPoint,
                      hint: Text('请选择耀光爆裂点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _radiantBlastPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['escaping']) ...[ 
                    Text('咕了', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_escapingPoint,
                      hint: Text('请选择咕了点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _escapingPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['grand_prophecy']) ...[ 
                    Text('大预言', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_prophecyChoice,
                      hint: Text('请选择大预言选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('不替换')),
                        DropdownMenuItem(value: 1, child: Text('替换')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _prophecyChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    Text('大预言点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_prophecyPoint,
                      hint: Text('请选择大预言点数'),
                      items: List.generate(10, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _prophecyPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['yearning']) ...[ 
                    Text('希冀', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_yearningPoint,
                      hint: Text('请选择希冀选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('攻击')),
                        DropdownMenuItem(value: 1, child: Text('防御')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _yearningPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['arctic_seal']) ...[ 
                    Text('天霜封印', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_arcticSealPoint,
                      hint: Text('请选择天霜点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _arcticSealPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['deft_touch']) ...[ 
                    Text('轻捷妙手', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_deftTouchPoint,
                      hint: Text('请选择妙手选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('抽一张牌')),
                        DropdownMenuItem(value: 1, child: Text('窃取技能')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _deftTouchPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_deftTouchPoint == 1) ...[
                      Text('技能', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        initialValue: _deftTouchSkill,
                        items: skillData!.keys.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),  
                        onChanged: (String? newValue) {
                          setState(() {
                            _deftTouchSkill = newValue;
                          });
                        },
                        isExpanded: true
                      ),
                      SizedBox(height: 16)
                    ]
                  ] else if (_selectedTrait == langMap!['decree']) ...[ 
                    Text('律令', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_decreePoint,
                      hint: Text('请选择律令选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('禁空')),
                        DropdownMenuItem(value: 1, child: Text('天锁')),
                        DropdownMenuItem(value: 2, child: Text('封魔')),
                        DropdownMenuItem(value: 3, child: Text('缚灵')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _decreePoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['celestial_joy']) ...[ 
                    Text('云系祝乐', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_celestialChoice,
                      hint: Text('请选择云系祝乐选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('进行d2判定')),
                        DropdownMenuItem(value: 1, child: Text('消耗MP抽牌')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _celestialChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_celestialChoice == 0) ...[
                      Text('云系点数', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField(
                        initialValue:_celestialPoint,
                        hint: Text('请选择云系点数'),
                        items: List.generate(2, (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                          )).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _celestialPoint = newValue ?? 1; 
                          });
                        },
                        isExpanded: true,
                      ),
                    ] 
                  ] else if (_selectedTrait == langMap!['discerning']) ...[ 
                    Text('挑拣', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_discerningPoint,
                      hint: Text('请选择挑拣点数'),
                      items: List.generate(10, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _discerningPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['cardio_blaze']) ...[ 
                    Text('心炎', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_cardioBlazePoint,
                      hint: Text('请选择心炎点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _cardioBlazePoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['crafting_of_dreams']) ...[ 
                    Text('梦的塑造', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_craftingDreamChoice,
                      hint: Text('请选择梦的塑造选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('入梦')),
                        DropdownMenuItem(value: 1, child: Text('归梦')),
                        DropdownMenuItem(value: 2, child: Text('造梦')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _craftingDreamChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_craftingDreamChoice == 2) ...[
                      Text('造梦点数', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField(
                        initialValue:_craftingDreamPoint,
                        hint: Text('请选择造梦点数'),
                        items: List.generate(6, (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                          )).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _craftingDreamPoint = newValue ?? 1; 
                          });
                        },
                        isExpanded: true,
                      ),
                    ] 
                  ] else if (_selectedTrait == langMap!['conflagration_avatar']) ...[ 
                    Text('烈焰之体', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_conflagrationChoice,
                      hint: Text('请选择烈焰之体选项'),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('攻击')),
                        DropdownMenuItem(value: 2, child: Text('受击')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _conflagrationChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    Text('烈焰点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_conflagrationPoint,
                      hint: Text('请选择烈焰点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _conflagrationPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['eternity']) ...[ 
                    Text('永恒', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_eternityPoint,
                      hint: Text('请选择永恒点数'),
                      items: List.generate(11, (index) => DropdownMenuItem(
                        value: index,
                        child: Text('$index'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _eternityPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    Text('状态', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      initialValue:_eternityStatus,
                      hint: Text('请选择永恒状态'),
                      items: _target != null && game.players[_target] != null 
                        ? game.players[_target]!.status.keys.map((String statusKey) {
                          return DropdownMenuItem(
                            value: statusKey,
                            child: Text(statusKey),
                          );
                        }).toList()
                        : [],
                      onChanged: (String? newValue) {
                        setState(() {
                          _eternityStatus = newValue ?? '';
                        });
                      }
                    )
                  ] else if (_selectedTrait == langMap!['dark_dissolution']) ...[ 
                    Text('黯灭', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_darkDissolutionChoice,
                      hint: Text('请选择黯灭选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('消耗行动点')),
                        DropdownMenuItem(value: 1, child: Text('消耗卡牌')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _darkDissolutionChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_darkDissolutionChoice == 1) ...[
                      Text('黯灭卡牌', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        initialValue:_darkDissolutionCard,
                        hint: Text('请选择黯灭卡牌'),
                        items:  cardTypes!.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(), 
                        onChanged: (String? newValue) {
                          setState(() {
                            _darkDissolutionCard = newValue ?? '';
                          });
                        }
                      )
                    ] 
                  ] else if (_selectedTrait == langMap!['taboo_lore']) ...[ 
                    Text('禁忌知识', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_tabooLoreChoice,
                      hint: Text('请选择禁忌选项'),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('攻击')),
                        DropdownMenuItem(value: 2, child: Text('受击')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _tabooLoreChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),                    
                  ] else if (_selectedTrait == langMap!['lotus_flame']) ...[ 
                    Text('红莲业火', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_lotusFlameChoice,
                      hint: Text('请选择业火封印标签'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('锋锐')),
                        DropdownMenuItem(value: 1, child: Text('铁御')),
                        DropdownMenuItem(value: 2, child: Text('生机')),
                        DropdownMenuItem(value: 3, child: Text('命运')),
                        DropdownMenuItem(value: 4, child: Text('秘法')),
                        DropdownMenuItem(value: 5, child: Text('幻相')),
                        DropdownMenuItem(value: 6, child: Text('魔能')),
                        DropdownMenuItem(value: 7, child: Text('诡术')),
                        DropdownMenuItem(value: 8, child: Text('失序')),
                        DropdownMenuItem(value: 9, child: Text('感知')),
                        DropdownMenuItem(value: 10, child: Text('灼热')),
                        DropdownMenuItem(value: 11, child: Text('霜寒')),                                                
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _lotusFlameChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),                    
                  ] else if (_selectedTrait == langMap!['radiance']) ...[ 
                    Text('光耀', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_radianceChoice,
                      hint: Text('请选择光耀选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('召唤光灵')),
                        DropdownMenuItem(value: 1, child: Text('免除伤害')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _radianceChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_radianceChoice == 1) ...[
                      Builder(
                        builder: (BuildContext context) {
                          final recordProvider = Provider.of<RecordProvider>(context);
                          final List<GameRecord> damageRecords = recordProvider.getFilteredRecords(target: _source, type: RecordType.damage,
                            startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                          if (_radianceDamages.length != damageRecords.length) {
                            _radianceDamages.clear();
                            for (var record in damageRecords) {
                              DamageRecord dmgRecord = record as DamageRecord;
                              _radianceDamages[dmgRecord] = 1;
                            }
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('伤害免除', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              if (damageRecords.isNotEmpty) ...[
                                ...damageRecords.asMap().entries.map((entry) {
                                  final int index = entry.key;
                                  final DamageRecord dmgRecord = entry.value as DamageRecord;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('第${index + 1}次，来源：${dmgRecord.source}'),
                                      Text('伤害值：${dmgRecord.damage}'),
                                      DropdownButtonFormField<int>(
                                        initialValue: _radianceDamages[dmgRecord],
                                        items: List.generate(10, (i) => DropdownMenuItem(
                                          value: i + 1,
                                          child: Text('${i + 1}'),
                                        )).toList(), 
                                        onChanged: (int? newValue) {
                                          setState(() {
                                            _radianceDamages[dmgRecord] = newValue ?? 1;
                                          });
                                        },
                                        isExpanded: true,
                                      ),
                                      SizedBox(height: 16),
                                    ],
                                  );
                                })
                              ]
                            ],
                          );
                        }
                      )
                    ] 
                  ] else if (_selectedTrait == langMap!['mental_disruption']) ...[ 
                    Text('精神干扰', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_mentalDisruptionPoint,
                      hint: Text('请选择干扰点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _mentalDisruptionPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['utopia_of_celerity']) ...[ 
                    Text('追猎的乌托邦', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_utopiaOfCelerityChoice,
                      hint: Text('请选择追猎选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('附加猎物印记')),
                        DropdownMenuItem(value: 1, child: Text('减少受到伤害')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _utopiaOfCelerityChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['glacial_circle']) ...[ 
                    Text('极寒环域', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_glacialCirclePoint,
                      hint: Text('请选择环域点数'),
                      items: List.generate(6, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _glacialCirclePoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['hydromancy']) ...[ 
                    Text('控水', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_hydromancyChoice,
                      hint: Text('请选择控水选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('脱水')),
                        DropdownMenuItem(value: 1, child: Text('浸没')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _hydromancyChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['water_torture']) ...[ 
                    Text('水之刑', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_waterTortureChoice,
                      hint: Text('请选择水刑选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('附加窒息')),
                        DropdownMenuItem(value: 1, child: Text('消除水刑')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _waterTortureChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_waterTortureChoice == 0)...[
                      Text('水刑点数', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField(
                        initialValue:_waterTorturePoint,
                        hint: Text('请选择水刑点数'),
                        items: List.generate(4, (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                          )).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _waterTorturePoint = newValue ?? 1; 
                          });
                        },
                        isExpanded: true,                      
                      ),
                      SizedBox(height: 16),
                    ]                                        
                  ] else if (_selectedTrait == langMap!['mass_energy_conversion']) ...[ 
                    Text('<04>质能转换', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _massEnergyChoice,
                      hint: Text('请选择质能选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('自身摸两张牌')),
                        DropdownMenuItem(value: 1, child: Text('从别人手里抽一张牌')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _massEnergyChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['tit_for_tat']) ...[ 
                    Text('针锋相对', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('自身点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_titForTatSourcePoint,
                      hint: Text('请选择针锋点数'),
                      items: List.generate(10, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(), 
                      onChanged: (int? newValue) {
                        setState(() {
                          _titForTatSourcePoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    Text('目标点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_titForTatTargetPoint,
                      hint: Text('请选择针锋点数'),
                      items: List.generate(10, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(), 
                      onChanged: (int? newValue) {
                        setState(() {
                          _titForTatTargetPoint = newValue ?? 1;
                        });
                      },
                      isExpanded: true,
                    ),
                  ] else if (_selectedTrait == langMap!['plucking_pouch']) ...[ 
                    Text('探囊取物', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _pluckingPouchChoice,
                      hint: Text('请选择探囊选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('使用卡牌')),
                        DropdownMenuItem(value: 1, child: Text('不使用卡牌')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _pluckingPouchChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['weathers_unfold']) ...[ 
                    Text('气象万千', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _weathersUnfoldChoice,
                      hint: Text('请选择气象选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('获得风')),
                        DropdownMenuItem(value: 1, child: Text('获得云')),
                        DropdownMenuItem(value: 2, child: Text('对敌方附加')),
                        DropdownMenuItem(value: 3, child: Text('对自身附加')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _weathersUnfoldChoice = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['ice_and_fire']) ...[ 
                    Text('冰与火之歌', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_iceAndFireChoice,
                      hint: Text('请选择冰与火选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('附加火')),
                        DropdownMenuItem(value: 1, child: Text('附加冰')),
                        DropdownMenuItem(value: 2, child: Text('转移状态')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _iceAndFireChoice = newValue ?? 0; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    if (_iceAndFireChoice == 2) ...[
                      Text('转移状态', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        initialValue:_iceAndFireStatus,
                        hint: Text('请选择转移状态'),
                        items:  _source != null && game.players[_source] != null 
                        ? game.players[_source]!.status.keys.map((String statusKey) {
                          return DropdownMenuItem(
                            value: statusKey,
                            child: Text(statusKey),
                          );
                        }).toList()
                        : [],
                        onChanged: (String? newValue) {
                          setState(() {
                            _iceAndFireStatus = newValue ?? '';
                          });
                        }
                      )
                    ]                     
                  ] else if (_selectedTrait == langMap!['unquestioning_trust']) ...[ 
                    Text('不容置疑的信任', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue:_unquestioningTrustChoice,
                      hint: Text('请选择信任选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('进入守备')),
                        DropdownMenuItem(value: 1, child: Text('支援攻击')),
                      ],
                      onChanged: (int? newValue) {
                        setState(() {
                          _unquestioningTrustChoice = newValue ?? 0;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField(
                      initialValue:_unquestioningTrustPoint,
                      hint: Text('请选择信任点数'),
                      items: List.generate(10, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                        )).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _unquestioningTrustPoint = newValue ?? 1; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] else if (_selectedTrait == langMap!['boing_spell']) ...[ 
                    Text('蹦蹦咒语', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      initialValue: _boingSpellChoice,
                      hint: Text('请选择蹦蹦选项'),
                      items: [
                        DropdownMenuItem(value: 0, child: Text('迅捷')),
                        DropdownMenuItem(value: 1, child: Text('迟缓')),
                      ], 
                      onChanged: (int? newValue) {
                        setState(() {
                          _boingSpellChoice = newValue ?? 0; 
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                  ] 
                ]
              ]
            ],
          ),
        ),
      ),
      
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭弹窗
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final cardSettingsManager = Provider.of<CardSettingsManager>(context, listen: false);
            if (_actionType == '行动') {
              String pointText = _pointController.text;
              if (pointText.isNotEmpty) {
                int? point = int.tryParse(pointText);
                if (point == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('请输入有效的点数')),
                  );
                  return;
                }
                final cardSettingsManager = Provider.of<CardSettingsManager>(context, listen: false);
                List<CardSetting> cardSettings = [];
                for (int i = 0; i < cardSettingsManager.settings.length; i++) {
                  cardSettings.add(cardSettingsManager.getCardSettings(i) == null 
                  ? DefaultCardSetting() : cardSettingsManager.getCardSettings(i)!);
                }                
                List<String> cardsList = [];
                for (var rowData in _cardTableData) {
                  cardsList.add(rowData['cardName']);
                }
                Map<String, dynamic> cardsArgs = {};
                for (var effectData in _attackEffectTableData) {
                  Map<String, dynamic> settings = effectData['settings'];
                  cardsArgs.addAll(settings); 
                }
                for (var effectData in _defenceEffectTableData) {
                  Map<String, dynamic> settings = effectData['settings'];
                  cardsArgs.addAll(settings); 
                }
                game.playCards(_source!, [_target!], point, cardsList, cardSettings, cardsArgs);
              }
            }
            else if (_actionType == '技能') {
              // 技能可用
              bool skillAble = true;
              if (skillAble) {                
                // 相转移 天国邮递员 净化 外星人 追击 沉默 镭射 止杀 镜像 分裂 交易 太阴 奇点 侵蚀 逆转乾坤 空袭 
                // 氤氲 安魂乐章 冰芒 护梦者 谜渊漩涡 灵魂震荡 补给 邪能侵袭 礼尚往来 怒海引路
                if ({langMap!['phase_transition'], langMap!['heaven_delivery'], langMap!['purification'], 
                  langMap!['stellar'], langMap!['chase'], langMap!['reticence'], langMap!['laser'], 
                  langMap!['kill_ceasing'], langMap!['inversion'], langMap!['fission'], langMap!['trading'], langMap!['lunar'], 
                  langMap!['singularity'], langMap!['corrosion'], langMap!['karma_reversal'], langMap!['airstrike'], 
                  langMap!['nebula_field'], langMap!['requiem'], langMap!['ice_splinter'], langMap!['dream_keeper'],
                  langMap!['abyssal_whirl'], langMap!['soul_tremor'], langMap!['replenishment'], langMap!['chaos_incursion'],
                  langMap!['give_and_take'], langMap!['rage_pilot']
                  }.contains(_selectedSkill)) {
                  game.castSkill(_source!, [_target!], _selectedSkill!, {});
                }
                // 嗜血 阈限 强化 屏障 不死 灵能注入 分裂 透支 开阳 博览 反重力 瞬影 极速 最后的希望
                // 屠杀 异镜解构 牺牲 斩神 点睛 不可动摇的守护
                else if ({langMap!['blood_thirst'], langMap!['threshold'], langMap!['reinforcement'], 
                  langMap!['barrier'], langMap!['undying'], langMap!['psionia'], langMap!['overdraw'], 
                  langMap!['mizar'], langMap!['perusing'], langMap!['anti_gravity'], langMap!['flash_shade'], 
                  langMap!['velocity'], langMap!['finale_hope'],
                  langMap!['massacre'], langMap!['deconstruction'], langMap!['sacrifice'], langMap!['deicide'], 
                  langMap!['kindle_eye'], langMap!['unwavering_guard']
                  }.contains(_selectedSkill)) {
                  game.castSkill(_source!, [_source!], _selectedSkill!, {});
                }
                // 赤焱炼狱 冰灭的135小节 裁冰裂霜 秩序结界
                else if ({langMap!['crimson_inferno'], langMap!['icy_oblivion_135_bars'],
                  langMap!['frost_shatter'], langMap!['order_aegis']
                  }.contains(_selectedSkill)) {
                  final targets = {?_target, ..._skillTargetList}.toList();
                  game.castSkill(_source!, targets, _selectedSkill!);
                }
                // 仁慈
                else if (_selectedSkill == langMap!['benevolence']) {
                  game.castSkill(_source!, [_target!], _selectedSkill!, {'type': _benevolenceChoice});
                }
                // 恐吓
                else if (_selectedSkill == langMap!['intimidation']) {
                  game.castSkill(_source!, [_source!], _selectedSkill!, {'point': _intimidationPoint});
                  game.throwDice(_source!, _source!, _intimidationPoint, DiceType.skill);
                }
                // 奉献
                else if (_selectedSkill == langMap!['devotion']) {
                  game.castSkill(_source!, [_target!], _selectedSkill!, {'point': _devotionPoint});
                }
                // 挑唆
                else if (_selectedSkill == langMap!['instigation']) {
                  game.castSkill(_source!, [_source!], _selectedSkill!, {'points': _instigationPoints, 'isInstigated': _isPlayerInstigated});
                  for (var tar in _instigationPoints.keys) {
                    game.throwDice(tar, tar, _instigationPoints[tar]!, DiceType.skill);
                  }
                }
                // 魂怨
                else if (_selectedSkill == langMap!['soul_rancor']) {
                  List<String> soulTargets = [];
                  for (var tar in _skillTargetList) {
                    soulTargets.add(tar);
                  }
                  if (soulTargets.length < 4) {
                    for (;soulTargets.length < 4;) {
                      soulTargets.add(_target!);
                    }
                  }
                  game.castSkill(_source!, soulTargets, _selectedSkill!);
                }
                // 斯威芬【造梦者】
                else if (_selectedSkill == langMap!['dream_weaver']) {
                  game.castSkill(_source!, [_source!], _selectedSkill!, {'point': _dreamWeaverChoice});
                }
                // 红烬【封焰的135秒】
                else if (_selectedSkill == langMap!['sealed_flame_135_seconds']) {
                  final targets = game.players.values.where((e) => e.hasStatus(langMap!['flaming']) && game.isEnemy(_source!, e.id) && !e.isDead).map((e) => e.id).toList();                  
                  game.castSkill(_source!, targets.isNotEmpty ? targets : [_target!], _selectedSkill!);
                }
                // 叶姬【须臾】
                else if (_selectedSkill == langMap!['emphemeral']) {
                  game.castSkill(_source!, [_target!], _selectedSkill!, {'status': _emphemeralStatus});
                }
                // 科亚特尔【天启之庭】
                else if (_selectedSkill == langMap!['apocalyptic_court']) {
                  final targets = [?_target, ..._skillTargetList];
                  game.castSkill(_source!, targets, _selectedSkill!, {'point':_apocalypticPoint});
                  game.throwDice(_source!, _source!, _apocalypticPoint, DiceType.skill);
                }
                // 祝烨明【八寒之七】
                else if (_selectedSkill == langMap!['seventh_frost']) {
                  game.castSkill(_source!, [_target!], _selectedSkill!, {'point': _seventhFrostPoint, 'status': _seventhFrostStatus});
                }
                // 方塔索【入梦之手】
                else if (_selectedSkill == langMap!['dream_grasp']) {
                  final targets = game.players.values.where((e) => !_skillTargetList.contains(e.id) && _target! != e.id && !e.isDead && e.id != 'empty')
                    .map((e) => e.id).toList();
                  game.castSkill(_source!, targets, _selectedSkill!);
                }
                // 沈姝华【奉献之爱】
                else if (_selectedSkill == langMap!['sacrificial_love']) {
                  //final targets = [...game.players.keys.where((chara) => chara != 'empty' && !game.players[chara]!.isDead)];
                  final targets = game.players.values.where((e) => e.id != 'empty' && !e.isDead).map((e) => e.id).toList();
                  game.castSkill(_source!, targets, _selectedSkill!);
                }
                // 蓝文策【三仙归洞】
                else if (_selectedSkill == langMap!['three_immortals_return']) {                  
                  game.castSkill(_source!, [_target!], _selectedSkill!, {'type': _threeImmortalsChoice});
                }
                // 卡拉卡【木头羊】
                else if (_selectedSkill == langMap!['timber_sheep']) {
                  game.castSkill(_source!, [_target!], _selectedSkill!, {'point': _timberSheepPoint});
                }
              }
            }
            else if (_actionType == '特质') {
              // 特质可用
              bool traitAble = true;
              // 特质不属于当前角色
              if (_source != traitData![_selectedTrait!]) {
                traitAble = false;
              }
              if (traitAble) { 
                // 星尘【幸运壁垒】
                if (_selectedTrait == langMap!['lucky_shield']) {
                  for (var damage in _luckyShieldDamages.keys) {
                    game.castTrait(_source!, [_source!], langMap!['lucky_shield'], 
                    {'damage': damage.damage, 'dmgSource': damage.source, 'point': _luckyShieldDamages[damage]});
                    game.throwDice(_source!, _source!, _luckyShieldDamages[damage]!, DiceType.trait);
                  }
                }
                // 黯星【决心】
                else if (_selectedTrait == langMap!['resolution']) {
                  game.castTrait(_source!, [_source!], langMap!['resolution'], {'point':_resolutionPoint});
                  game.throwDice(_source!, _source!, _resolutionPoint, DiceType.trait);
                }
                // 方寒【耀光爆裂】
                else if (_selectedTrait == langMap!['radiant_blast']) {
                  game.castTrait(_source!, [_target!], langMap!['radiant_blast'], {'point':_radiantBlastPoint});
                  game.throwDice(_source!, _source!, _radiantBlastPoint, DiceType.trait);
                }
                // 恪玥【咕了】
                else if (_selectedTrait == langMap!['escaping']) {
                  game.castTrait(_source!, [_source!], langMap!['escaping'], {'point':_escapingPoint});
                  game.throwDice(_source!, _source!, _escapingPoint, DiceType.trait);
                }
                // 岚【血灵斩】
                else if (_selectedTrait == langMap!['hema_slash']) {
                  game.castTrait(_source!, [_source!], langMap!['hema_slash']);
                }
                // 卿别【夜魇游吟】
                else if (_selectedTrait == langMap!['nightmare_refrain']) {
                  game.castTrait(_source!, [_target!], langMap!['nightmare_refrain'], {'type': 0});
                }
                // 扶风【大预言】
                else if (_selectedTrait == langMap!['grand_prophecy']) {
                  game.castTrait(_source!, [_source!], langMap!['grand_prophecy'], {'type': _prophecyChoice, 'point': _prophecyPoint});
                }
                // 星凝【希冀】
                else if (_selectedTrait == langMap!['yearning']) {
                  game.castTrait(_source!, [_target!], langMap!['yearning'], {'type': _yearningPoint});
                }
                // 星凝【祝愿】
                else if (_selectedTrait == langMap!['blessing']) {
                  game.castTrait(_source!, [_target!], langMap!['blessing']);
                }
                // 时雨【天霜封印】
                else if (_selectedTrait == langMap!['arctic_seal']) {
                  game.castTrait(_source!, [_target!], langMap!['arctic_seal'], {'point': _arcticSealPoint});
                  game.throwDice(_source!, _source!, _arcticSealPoint, DiceType.trait);
                }
                // 舸灯【引渡】
                else if (_selectedTrait == langMap!['ghost_ferry']) {
                  game.castTrait(_source!, [_source!], langMap!['ghost_ferry'], {"type": 1});
                }
                // 高淼【轻捷妙手】
                else if (_selectedTrait == langMap!['deft_touch']) {
                  game.castTrait(_source!, [_target!], langMap!['deft_touch'], {'type': _deftTouchPoint, 'skill': _deftTouchSkill});
                }
                // 长霾【律令】
                else if (_selectedTrait == langMap!['decree']) {
                  game.castTrait(_source!, [_target!], langMap!['decree'], {'type': _decreePoint});
                }
                // 云津【云系祝乐】
                else if (_selectedTrait == langMap!['celestial_joy']) {
                  game.castTrait(_source!, [_target!], langMap!['celestial_joy'], {'type': _celestialChoice, 'point': _celestialPoint});
                  if (_celestialChoice == 0) {
                    game.throwDice(_source!, _source!, _celestialPoint, DiceType.trait);
                  }
                }
                // 挑拣【晖夕】
                else if (_selectedTrait == langMap!['discerning']) {
                  game.castTrait(_source!, [_source!], langMap!['discerning'], {'point': _discerningPoint});
                }
                // 炎焕【心炎】
                else if (_selectedTrait == langMap!['cardio_blaze']) {
                  game.castTrait(_source!, [_target!], langMap!['cardio_blaze'], {'point': _cardioBlazePoint});
                  game.throwDice(_source!, _source!, _cardioBlazePoint, DiceType.trait);
                }
                // 斯威芬【梦的塑造】
                else if (_selectedTrait == langMap!['crafting_of_dreams']) {
                  game.castTrait(_source!, [_target!], langMap!['crafting_of_dreams'], {'type': _craftingDreamChoice, 'point': _craftingDreamPoint});
                }
                // 红烬【烈焰之体】
                else if (_selectedTrait == langMap!['conflagration_avatar']) {
                  game.castTrait(_source!, [_source!], langMap!['conflagration_avatar'], {'type': _conflagrationChoice, 'point': _conflagrationPoint});                
                  game.throwDice(_source!, _source!, _conflagrationPoint, DiceType.trait);                  
                }
                // 叶姬【永恒】
                else if (_selectedTrait == langMap!['eternity']) {
                  game.castTrait(_source!, [_target!], langMap!['eternity'], {'point': _eternityPoint, 'status': _eternityStatus});
                }
                // 太夕【黯灭】
                else if (_selectedTrait == langMap!['dark_dissolution']) {
                  if (_darkDissolutionChoice == 0) {
                    game.castTrait(_source!, [_source!], langMap!['dark_dissolution'], {'type': _darkDissolutionChoice});
                  }
                  else {
                    game.castTrait(_source!, [_source!], langMap!['dark_dissolution'], {'type': _darkDissolutionChoice, 'card': _darkDissolutionCard});
                  }
                }
                // 太夕【吞噬之锁】
                else if (_selectedTrait == langMap!['devouring_lock']) {
                  game.castTrait(_source!, [_target!], langMap!['devouring_lock']);
                }
                // 蒙德里安【禁忌知识】
                else if (_selectedTrait == langMap!['taboo_lore']) {
                  game.castTrait(_source!, [_target!], langMap!['taboo_lore'], {'type': _tabooLoreChoice});
                }
                // 红黎【红莲业火】
                else if (_selectedTrait == langMap!['lotus_flame']) {
                  game.castTrait(_source!, [_target!], langMap!['lotus_flame'], {'type': 1, 'tag': _lotusFlameChoice});                  
                }
                // 龙宇澈【光耀】
                else if (_selectedTrait == langMap!['radiance']) {
                  if (_radianceChoice == 0) {
                    game.castTrait(_source!, [_source!], langMap!['radiance'], {'type': 0});
                  }
                  else {
                    for (var damage in _radianceDamages.keys) {
                      game.castTrait(_source!, [_source!], langMap!['radiance'], 
                      {'type': 2, 'damage': damage.damage, 'dmgSource': damage.source, 'point': _radianceDamages[damage]});
                      game.throwDice(_source!, _source!, _radianceDamages[damage]!, DiceType.trait);
                    }
                  }
                }
                // 祝言夙【精神干扰】
                else if (_selectedTrait == langMap!['mental_disruption']) {
                  game.castTrait(_source!, [_target!], langMap!['mental_disruption'], {'point': _mentalDisruptionPoint});
                  game.throwDice(_target!, _target!, _mentalDisruptionPoint, DiceType.trait);
                }
                // 唐亚德【清心的乌托邦】
                else if (_selectedTrait == langMap!['utopia_of_clarity']) {
                  game.castTrait(_source!, [_target!], langMap!['utopia_of_clarity'], {'type': 1});
                }
                // 陆风【追猎的乌托邦】
                else if (_selectedTrait == langMap!['utopia_of_celerity']) {
                  game.castTrait(_source!, [_target!], langMap!['utopia_of_celerity'], {'type': _utopiaOfCelerityChoice * 2});
                }
                // 白谢【极寒环域】
                else if (_selectedTrait == langMap!['glacial_circle']) {
                  final targets = [?_target, ..._traitTargetList];
                  game.castTrait(_source!, targets, langMap!['glacial_circle'], {'type': 0, 'point': _glacialCirclePoint});
                  game.throwDice(_source!, _source!, _glacialCirclePoint, DiceType.trait);
                }
                // 奥菲莉娅【控水】
                else if (_selectedTrait == langMap!['hydromancy']) {
                  game.castTrait(_source!, [_target!], langMap!['hydromancy'], {'type': _hydromancyChoice});                  
                }
                // 奥菲莉娅【水之刑】
                else if (_selectedTrait == langMap!['water_torture']) {
                  game.castTrait(_source!, [_target!], langMap!['water_torture'], {'type': _waterTortureChoice, 'point': _waterTorturePoint});
                }
                // 符楹【光暗双生】
                else if (_selectedTrait == langMap!['lumen_umbra_gemini']) {
                  game.castTrait(_source!, [_source!], langMap!['lumen_umbra_gemini'], {'type': 0});
                }
                // EnGine-4【<04>质能转换】
                else if (_selectedTrait == langMap!['mass_energy_conversion']) {
                  if (_massEnergyChoice == 0) {
                    game.castTrait(_source!, [_source!], langMap!['mass_energy_conversion'], {'type': 2});
                  }
                  else {
                    String maxHpChara = '';
                    for (var player in game.gameSequence) {
                      if (player == langMap!['engine_4']) continue;
                      if (maxHpChara == '' || game.players[player]!.health > game.players[maxHpChara]!.health) {
                        maxHpChara = player;
                      }
                    }
                    game.castTrait(_source!, [maxHpChara], langMap!['mass_energy_conversion'], {'type': 3});
                  }
                }
                // 兰斯洛特【针锋相对】
                else if (_selectedTrait == langMap!['tit_for_tat']) {
                  game.castTrait(_source!, [_target!], langMap!['tit_for_tat'], {'sourcePoint': _titForTatSourcePoint, 
                  'targetPoint': _titForTatTargetPoint});
                }
                // 蓝文策【探囊取物】
                else if (_selectedTrait == langMap!['plucking_pouch']) {
                  game.castTrait(_source!, [_target!], langMap!['plucking_pouch'], {'type': _pluckingPouchChoice});
                }
                // DeFen-5 【<15>力场模拟】
                else if (_selectedTrait == langMap!['force_field_simulation']) { 
                  game.castTrait(_source!, [_target!], langMap!['force_field_simulation']);
                }
                // 卡拉卡【友情防守】
                else if (_selectedTrait == langMap!['buddy_block']) {
                  game.castTrait(_source!, [_target!], langMap!['buddy_block'], {'type': 2});
                }
                // 观风【气象万千】
                else if (_selectedTrait == langMap!['weathers_unfold']) {
                  if ({0, 1, 3}.contains(_weathersUnfoldChoice)) {
                    game.castTrait(_source!, [_source!], langMap!['weathers_unfold'], {'type': _weathersUnfoldChoice});
                  }
                  else {
                    game.castTrait(_source!, [_target!], langMap!['weathers_unfold'], {'type': _weathersUnfoldChoice});
                  }
                }
                // 安提忒斯【冰与火之歌】
                else if (_selectedTrait == langMap!['ice_and_fire']) {
                  if ({0, 1}.contains(_iceAndFireChoice)) {
                    game.castTrait(_source!, [_source!], langMap!['ice_and_fire'], {'type': _iceAndFireChoice});
                  }
                  else {
                    game.castTrait(_source!, [_target!], langMap!['ice_and_fire'], {'type': _iceAndFireChoice, 'status': _iceAndFireStatus});
                  }
                }
                // 曙光【不容质疑的信任】
                else if (_selectedTrait == langMap!['unquestioning_trust']) {
                  if (_unquestioningTrustChoice == 0) {
                    game.castTrait(_source!, [_source!], langMap!['unquestioning_trust'], {'type': 0, 'point': _unquestioningTrustPoint});
                  }
                  else {
                    var teammates = game.players.values.where((e) => e.id != 'empty' && game.isTeammate(e.id, _source!) && !e.isDead
                      && e.id != _target && !e.hasStatus(langMap!['frozen']) && !e.hasStatus(langMap!['dreaming']) &&
                      !e.hasStatus(langMap!['stellar_cage']) && !e.hasStatus(langMap!['dream_crafting']) &&
                      !e.hasStatus(langMap!['asphyxia'])).toList();
                    teammates.sort((a, b) => b.attack.compareTo(a.attack));
                    if (teammates.isNotEmpty) {
                      game.castTrait(_source!, [_target!], langMap!['unquestioning_trust'], {'type': 2, 'source': teammates.first.id, 'point': _unquestioningTrustPoint});
                    }
                  }
                }
                // 石蹄【蹦蹦咒语】
                else if (_selectedTrait == langMap!['boing_spell']) {
                  game.castTrait(_source!, [_target!], langMap!['boing_spell'], {'type': _boingSpellChoice});
                }
              }
            }
            // 道具卡设置清空
            cardSettingsManager.resetAllSettings();
            // 调用回调函数通知 InfoPageState 保存历史记录
            if (widget.onActionCompleted != null) {
              widget.onActionCompleted!();
            }
            Navigator.of(context).pop(); // 关闭弹窗
          },
          child: Text('确定'),
        ),
      ],
    );
  }
}