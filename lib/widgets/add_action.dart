import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/settings.dart';
import 'package:sns_calculator/widgets/attack_effect_settings.dart';
import 'package:sns_calculator/widgets/card_settings.dart';

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
  final List<String> _actionTypes = ['行动', '技能', '特质'];
  
  // 各个下拉菜单的当前选中值
  String? _actionType;
  String? _source;
  String? _target;
  String? _selectedSkill;
  String? _selectedTrait;

  // 玩家数据
  Character? _sourcePlayer;
  Character? _targetPlayer;

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
  Map<String, int> _instigationPoints = {};
  Map<String, int> _isPlayerInstigated = {};

  // 特质设置
  // 幸运壁垒
  Map<DamageRecord, int> _luckyShieldDamages = {};
  // 决心
  int _resolutionPoint = 2;
  // 耀光爆裂
  int _radiantBlastPoint = 1;
  // 咕了
  int _escapingPoint = 1;
  // 大预言
  int _prophecyPoint = 0;
  // 希冀
  int _yearningPoint = 1;
  // 天霜封印
  int _arcticSealPoint = 2;

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
          langMap = assets.langMap;
          _assetsLoaded = true;
        });
      }
    }

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
      items: cardTypes!.map((String item) {
        return PopupMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    ).then((String? selectedValue) {
      if (selectedValue != null) {
        setState(() {
          // 添加到表格数据中
          _cardTableData.add({
            'cardName': selectedValue,
            'settings': <String, dynamic>{}, // 可用于存储该行的设置
          });
        });
        // 添加到道具卡设置管理器中（不在 setState 中执行获取 provider）
        final cardSettingManager = Provider.of<CardSettingsManager>(context, listen: false);
        cardSettingManager.addNewCard(selectedValue);
        // 初始化部分设置
        if (langMap != null && selectedValue == langMap!['redstone']) {
          RedstoneSetting setting = RedstoneSetting();
          setting.playerProlonged = _source!;
          setting.statusProlonged = game.players[_source!]!.status.isEmpty ? '' : game.players[_source!]!.status.keys.first;
          cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
        }
        else if (langMap != null && selectedValue == langMap!['ascension_stair']) {
          AscensionStairSetting setting = AscensionStairSetting();
          for (var chara in game.players.values) {
            if (chara.id != 'empty') {
              setting.ascensionPoints[chara.id] = 1;
            }              
          }
          cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
        }
        else if (langMap != null && selectedValue == langMap!['arctic_heart']) {
          ArcticHeartSetting setting = ArcticHeartSetting();
          String skill = game.players[_source!]!.skill.isEmpty ? '' : game.players[_source!]!.skill.keys.first;
          setting.arcticHeartChoice = skill;
          cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
        }
        else if (langMap != null && selectedValue == langMap!['aurora_concussion']) {
          AuroraConcussionSetting setting = AuroraConcussionSetting();
          for (var chara in game.players.values) {
            if (chara.id != 'empty') {
              setting.auroraPoints[chara.id] = 1;
            }              
          }
          cardSettingManager.updateCardSettings(_cardTableData.length - 1, setting);
        }
      }
    });
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
        Rect.fromCenter(
          center: Offset(0, MediaQuery.of(context).size.height / 2), 
          width: 200, 
          height: 300),
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
        Rect.fromCenter(
          center: Offset(0, MediaQuery.of(context).size.height / 2), 
          width: 200, 
          height: 300),
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
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
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
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
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
              // 第一个下拉菜单
              Text('行动类型', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _actionType,
                hint: Text('请选择行动类型'),
                items: _actionTypes.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _actionType = newValue;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              
              // 第二个下拉菜单（来自表格第一列）
              Text('进攻角色', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _source,
                hint: Text('请选择第一个角色'),
                items: widget.characterList.where((item) => !game.players[item]!.isDead 
                  && !game.players[item]!.hasStatus(langMap!['gugu']))
                .map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _source = newValue;
                    // 如果第三个下拉菜单选择了与第二个相同的角色，则重置
                    if (_target == newValue) {
                      _target = null;
                    }
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              
              // 第三个下拉菜单（来自表格第一列，但排除第二个菜单已选择的项）
              Text('防守角色', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _target,
                hint: Text('请选择第二个角色'),
                items: widget.characterList
                    .where((item) => !game.players[item]!.isDead 
                      && !game.players[item]!.hasStatus(langMap!['gugu']))
                    .map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _target = newValue;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              
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
                SizedBox(height: 8),
                
                // 道具卡表格
                if (_cardTableData.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('名称')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _cardTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final String cardName = rowData['cardName'];
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(cardName)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => _deleteCardRow(index),
                                      tooltip: '删除',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, size: 18),
                                      onPressed: () => _showCardSettingsDialog(index, cardName),
                                      tooltip: '设置',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // 添加攻击特效按钮
                ElevatedButton(
                  onPressed: _showAttackEffectSelectionMenu,
                  child: Text('添加攻击特效'),
                ),
                SizedBox(height: 8),
  
                // 攻击特效表格
                if (_attackEffectTableData.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('攻击特效')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _attackEffectTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final AttackEffect effect = rowData['effect'];
            
                          return DataRow(
                            cells: [
                              DataCell(Text(effect.effectId)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => _deleteAttackEffectRow(index),
                                      tooltip: '删除',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, size: 18),
                                      onPressed: () => _showAttackEffectSettingsDialog(index, effect),
                                      tooltip: '设置',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                // 添加防守特效按钮
                ElevatedButton(
                  onPressed: _showDefenceEffectSelectionMenu,
                  child: Text('添加防守特效'),
                ),
                SizedBox(height: 8),
  
                // 防守特效表格
                if (_defenceEffectTableData.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('防守特效')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _defenceEffectTableData.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> rowData = entry.value;
                          final DefenceEffect effect = rowData['effect'];
            
                          return DataRow(
                            cells: [
                              DataCell(Text(effect.effectId)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => _deleteDefenceEffectRow(index),
                                      tooltip: '删除',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, size: 18),
                                      onPressed: () => _showDefenceEffectSettingsDialog(index, effect),
                                      tooltip: '设置',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
              ] else if (_actionType == '技能') ...[
                Text('技能目标', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showSkillTargetSelectionMenu,
                  child: Text('添加技能目标')),
                SizedBox(height: 8),

                if(_skillTargetList.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('技能目标')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _skillTargetList.asMap().entries.map((entry) { 
                          final int index = entry.key;
                          final String target = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text(target)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 18),
                                        onPressed: () => _removeSkillTarget(index),
                                    )                                    
                                  ]
                                )
                              )
                            ]
                          );
                        }).toList(),
                      )
                    )
                  )
                ],
                SizedBox(height: 16),

                Text('技能选择', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _selectedSkill,
                  hint: Text('请选择技能'),
                  items: skillData!.keys.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(), 
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSkill = newValue;
                    });
                  },
                  isExpanded: true,
                ),
                SizedBox(height: 16),

                if(_selectedSkill != null) ...[
                  Text('技能设置', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if(_selectedSkill == langMap!['benevolence']) ... [
                    Text('仁慈选择', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      value: _benevolenceChoice,
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
                    Text('恐吓点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      value: _intimidationPoint,
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
                    Text('奉献点数', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField(
                      value: _devotionPoint,
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
                            value:_isPlayerInstigated[chara.id],
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
                            value: _instigationPoints[chara.id],                            
                            items: List.generate(6, (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                              )).toList(),                              
                            onChanged: (int? newValue) {
                              setState(() {
                                _instigationPoints[chara.id] = newValue ?? 1;
                              });
                            }
                          )
                        ]
                      );
                    })
                  ]
                ]
              ] else if (_actionType == '特质') ...[
                Text('特质目标', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showTraitTargetSelectionMenu,
                  child: Text('添加特质目标')),
                SizedBox(height: 8),

                if(_traitTargetList.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('特质目标')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _traitTargetList.asMap().entries.map((entry) { 
                          final int index = entry.key;
                          final String target = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text(target)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 18),
                                        onPressed: () => _removeTraitTarget(index),
                                    )                                    
                                  ]
                                )
                              )
                            ]
                          );
                        }).toList(),
                      )
                    )
                  )
                ],
                SizedBox(height: 16),

                Text('特质选择', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _selectedTrait,
                  hint: Text('请选择特质'),
                  items: traitData!.keys.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(), 
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTrait = newValue;
                    });
                  },
                  isExpanded: true,
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
                                      value: _luckyShieldDamages[dmgRecord],
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
                      value:_resolutionPoint,
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
                      value:_radiantBlastPoint,
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
                      value:_escapingPoint,
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
                      value:_prophecyPoint,
                      hint: Text('请选择大预言选项'),
                      items:  [
                        DropdownMenuItem(value: 0, child: Text('不替换')),
                        DropdownMenuItem(value: 1, child: Text('替换')),
                      ], 
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
                      value:_yearningPoint,
                      hint: Text('请选择希冀选项'),
                      items:  [
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
                      value:_arcticSealPoint,
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
            _sourcePlayer = game.players[_source];
            _targetPlayer = game.players[_target];
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
                // 伤害计算初始化
                int attack = 0;
                int defence = 0;
                int attackPlus = 0;
                double attackMulti = 1;
                // 强化系数
                int reinforcementMulti = _sourcePlayer!.hasHiddenStatus('reinforcement') ? 2 : 1;
                // 行动可用
                bool actionAble = true;
                // 计算行动点消耗
                int cost = 0; 
                if (_cardTableData.isEmpty) {
                  cost = 1;
                }
                else {
                  for (var rowData in _cardTableData) {
                    cost++;
                    String cardName = rowData['cardName'];
                    // 休憩
                    if (cardName == langMap!['rest']) {
                      cost -= 2 * reinforcementMulti;
                    }                  
                  }
                }                
                // 极速
                if (_sourcePlayer!.hasHiddenStatus('velocity')) {
                  cost -= 3;
                }
                if (_sourcePlayer!.hasHiddenStatus('anti_velocity')) {
                  cost += 3;
                }
                // 舸灯【引渡】
                if (_source == langMap!['gentou']) {
                  List<int> costRef = [cost];
                  game.castTrait(_source!, [], langMap!['ghost_ferry'], {'type': 0, 'costRef': costRef});
                  cost = costRef[0];
                }
                // 行动点不足
                if (cost > _sourcePlayer!.movePoint) {
                  actionAble = false;
                }
                // 不能对自身行动
                if (_source == _target) {
                  actionAble = false;
                }
                // 行动次数不足
                if (_sourcePlayer!.actionTime < 1) {
                  actionAble = false;
                }
                // 状态【冰封】
                if (_sourcePlayer!.hasStatus(langMap!['frozen'])) {
                  actionAble = false;
                }
                if (actionAble) {
                // 行动点减少
                game.addAttribute(_source!, AttributeType.movepoint, -cost);
                // 行动次数减少
                _sourcePlayer!.actionTime--;                      
                // 遍历道具                               
                for (int i = 0; i < _cardTableData.length; i++) {                  
                  String cardName = _cardTableData[i]['cardName'];
                  Map<String, dynamic> settings = cardSettingsManager.getCardSettings(i)!.toJson();
                  // 卡牌数量减少
                  game.addAttribute(_source!, AttributeType.card, -1);
                  // 卡牌可用性
                  bool cardAble = true;
                  if (cardAble) {
                  // 破片水晶
                  if(cardName == langMap!['end_crystal']){                    
                    int crystalSelf = settings['crystalSelf'] as int? ?? 1;
                    int crystalMagic = settings['crystalMagic'] as int? ?? 1;                 
                    game.damagePlayer(_source!, _source!, (30 + 15 * crystalSelf) * reinforcementMulti, DamageType.magical);
                    for(Character chara in game.players.values){
                      if(chara.id != _source) {
                        game.damagePlayer(_source!, chara.id, (40 + 15 * crystalMagic) * reinforcementMulti, 
                        DamageType.magical, isAOE: true);}
                    }
                  }
                  // 阿波罗之箭
                  else if(cardName == langMap!['apollo_arrow']){
                    int minDefence = game.players[_target]!.defence;
                    for(Character chara in game.players.values){
                      if(chara.defence < minDefence){
                        minDefence = chara.defence;
                      }                      
                    }
                    if(minDefence == game.players[_target]!.defence){
                      game.addHiddenStatus(_target!, 'damageplus', 100 * reinforcementMulti, 1);
                    }
                  }
                  // 巴别塔
                  else if(cardName == langMap!['babel_tower']){
                    for(Character chara in game.players.values){
                      game.addHiddenStatus(chara.id, 'babel', 0, 1 * reinforcementMulti);
                    }
                  }
                  // 达摩克利斯之剑
                  else if(cardName == langMap!['damocles_sword']){
                    if (reinforcementMulti == 2) {
                      game.countdown.reinforcedDamocles += 1;
                    }
                    else {
                      game.countdown.damocles += 1;
                    }                    
                  }
                  // 短刀
                  else if(cardName == langMap!['wood_sword']){
                    game.addAttribute(_source!, AttributeType.attack, 10 * reinforcementMulti);
                    // attackPlus += 10;
                  }
                  // 钝化术
                  else if(cardName == langMap!['slowness_spell']){
                    game.addStatus(_target!, langMap!['slowness'], 1 * reinforcementMulti, 2);
                  }
                  // 堕灵吊坠
                  else if(cardName == langMap!['corrupt_pendant']){
                    game.addAttribute(_source!, AttributeType.attack, 5 * reinforcementMulti);
                    game.addAttribute(_target!, AttributeType.attack, -5 * reinforcementMulti);
                    game.damagePlayer(_source!, _source!, 60 * reinforcementMulti, DamageType.heal);
                    game.damagePlayer(_source!, _target!, 60 * reinforcementMulti, DamageType.magical);            
                  }
                  // 飞鸟·紫烈
                  else if(cardName == langMap!['violent_violet']){
                    int sequence = game.gameSequence.indexOf(_source!);
                    if(sequence == 0) {sequence = game.gameSequence.length - 1;}
                    else {sequence--;}
                    Character previousChara = game.players[game.gameSequence[sequence]]!;
                    // _logger.d(previousChara.id);
                    game.addHiddenStatus(_target!, 'damageplus', 2 * previousChara.defence  * reinforcementMulti, 1);
                  }
                  // 复合弓 
                  else if(cardName == langMap!['bow']){                    
                    int ammoCount = settings['ammoCount'] as int? ?? 1;
                    game.damagePlayer(_source!, _target!, 75 * ammoCount * reinforcementMulti, DamageType.magical);
                    game.players[_source]!.cardCount = 0;
                  }
                  // 高帽子
                  else if(cardName == langMap!['high_cap']){
                    game.addStatus(_target!, langMap!['tigris_dilemma'], 0, 1 * reinforcementMulti);
                  }
                  // 高能罐头
                  else if(cardName == langMap!['high_energy_can']){
                    game.addAttribute(_source!, AttributeType.movepoint, 1 * reinforcementMulti);
                    game.addAttribute(_source!, AttributeType.maxmove, 2 * reinforcementMulti);
                  }
                  // 鼓舞
                  else if(cardName == langMap!['hero_legend']){
                    game.damagePlayer(_source!, _source!, 100 * reinforcementMulti, DamageType.heal);
                    game.addHiddenStatus(_source!, 'hero_legend', 1 * reinforcementMulti, 1);
                  }
                  // 过往凝视
                  else if(cardName == langMap!['passing_gaze']){
                    game.addHiddenStatus(_target!, 'damageplus', 100 * reinforcementMulti, 1);
                    game.addStatus(_target!, langMap!['dissociated'], 0, 2);
                  }
                  // 寒绝凝冰
                  else if(cardName == langMap!['cryotheum']){
                    game.addStatus(_target!, langMap!['frost'], 5 * reinforcementMulti, 2);
                  }
                  // 后日谈
                  else if(cardName == langMap!['redstone']){
                    String statusProlonged = settings['statusProlonged'];
                    String playerProlonged = settings['playerProlonged'];         
                    if(statusProlonged != ''){
                      game.addStatus(playerProlonged, statusProlonged, 0, 1 * reinforcementMulti);
                    }                               
                  }
                  // 护身符
                  else if(cardName == langMap!['heart_locket']){
                    game.addAttribute(_source!, AttributeType.defence, 10 * reinforcementMulti);
                  }
                  // 缓生
                  else if(cardName == langMap!['regenerating']){
                    game.addStatus(_source!, langMap!['regeneration'], 4 * reinforcementMulti, 2);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 混沌电钻
                  else if(cardName == langMap!['chaotic_drill']){
                    game.addStatus(_target!, langMap!['confusion'], 0, 1 * reinforcementMulti);
                  }
                  // 混乱力场
                  else if(cardName == langMap!['ascension_stair']){
                    Map<String, int> ascensionPoints = settings['ascensionPoints'];
                    //_logger.d(ascensionPoints);
                    int minPoint = 6;
                    int maxPoint = 1;
                    List<String> ascensionChara = [];
                    for(String chara in ascensionPoints.keys){ 
                      if(ascensionPoints[chara] == minPoint){
                        ascensionChara.add(chara);
                      }
                      else if(ascensionPoints[chara]! < minPoint){
                        minPoint = ascensionPoints[chara]!;
                        ascensionChara = [chara];
                      }
                      if(ascensionPoints[chara]! > maxPoint){
                        maxPoint = ascensionPoints[chara]!;
                      }
                    }
                    //_logger.d(ascensionChara);
                    for(String chara in ascensionChara){
                      game.damagePlayer(_source!, chara, 50 * maxPoint * reinforcementMulti, DamageType.physical, isAOE: true);
                    }
                  }
                  // 极北之心
                  else if(cardName == langMap!['arctic_heart']){
                    String arcticHeartChoice = settings['arcticHeartChoice'];
                    game.players[_source]!.skill[arcticHeartChoice] = 
                    (game.players[_source]!.skill[arcticHeartChoice] ?? 0) - 1 * reinforcementMulti;             
                  }
                  // 极光震荡
                  else if(cardName == langMap!['aurora_concussion']){       
                    Map<String, int> auroraPoints = settings['auroraPoints'];
                    for(String chara in auroraPoints.keys){ 
                      if(auroraPoints[chara] == 1){
                        game.addStatus(chara, langMap!['exhausted'], 0, 1 * reinforcementMulti);
                      }
                    }
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 加护
                  else if(cardName == langMap!['dream_shelter']){
                    game.damagePlayer(_source!, _source!, 100 * reinforcementMulti, DamageType.heal);
                    game.addHiddenStatus(_source!, 'dream_shelter', 1 * reinforcementMulti, 1);
                  }
                  // 箭
                  else if(cardName == langMap!['arrow']){
                    game.addHiddenStatus(_target!, 'damageplus', 50 * reinforcementMulti, 1);
                  }
                  // 狼牙棒
                  else if(cardName == langMap!['mace']){
                    game.addHiddenStatus(_target!, 'damageplus', 90 * reinforcementMulti, 1);
                    game.addStatus(_target!, langMap!['fractured'], 0, 2);
                  }
                  // 猎魔灵刃
                  else if(cardName == langMap!['track']){                    
                    if(game.players[_target]!.hasStatus(langMap!['dodge'])){
                      game.removeStatus(_target!, langMap!['dodge']);
                      game.addHiddenStatus(_target!, 'track', 1 * reinforcementMulti, 1);
                    }               
                  }
                  // 林鸟·赤掠
                  else if(cardName == langMap!['crimson_swoop']){
                    int sequence = game.gameSequence.indexOf(_source!);
                    if(sequence == 0) {sequence = game.gameSequence.length - 1;}
                    else {sequence--;}
                    Character previousChara = game.players[game.gameSequence[sequence]]!;                    
                    game.addHiddenStatus(_target!, 'damageplus', previousChara.attack * reinforcementMulti, 1);
                  }
                  // 聆音掠影
                  else if(cardName == langMap!['echo_glimpse']){
                    game.addStatus(_target!, langMap!['distant'], 0, 1 * reinforcementMulti);
                  }
                  // 蛮力术
                  else if(cardName == langMap!['strength_spell']){
                    game.addStatus(_source!, langMap!['strength'], 3 * reinforcementMulti, 2);
                  }
                  // 蛮力术II
                  else if(cardName == langMap!['strength_spell_ii']){
                    game.addStatus(_source!, langMap!['strength'], 6 * reinforcementMulti, 2);
                  }
                  // 纳米渗透
                  else if(cardName == langMap!['nano_permeation']){
                    game.addHiddenStatus(_source!, 'nano', 0, 1);
                  }
                  // 潘多拉魔盒
                  else if(cardName == langMap!['pandora_box']){
                    int pandoraPoint = settings['pandoraPoint'] as int? ?? 1;
                    if([3, 6].contains(pandoraPoint)){
                      for(Character chara in game.players.values){
                        game.damagePlayer(emptyCharacter.id, chara.id, 100 * reinforcementMulti, DamageType.heal, isAOE: true);
                      }
                    }
                    else{
                      for(Character chara in game.players.values){
                        game.damagePlayer(emptyCharacter.id, chara.id, 300 * reinforcementMulti, DamageType.magical, isAOE: true);
                      }
                    }
                    game.addHiddenStatus(_source!, 'void', 0, 1);   
                  }
                  // 全息投影
                  else if(cardName == langMap!['hologram']){
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 荣光循途
                  else if(cardName == langMap!['glory_road']){
                    game.addStatus(_source!, langMap!['teroxis'], 1, 1);
                  }
                  // 融甲宝珠
                  else if(cardName == langMap!['penetrate']){
                    if(game.players[_target]!.armor > 0){
                      game.players[_target]!.armor = 0;
                      game.addHiddenStatus(_target!, 'penetrate', 1 * reinforcementMulti, 1);
                    }
                  }
                  // 刷新
                  else if(cardName == langMap!['refreshment']){
                    for (var skill in game.players[_source]!.skill.keys) {
                      game.players[_source]!.skill[skill] = 0;
                    }
                  }
                  // 水波荡漾
                  else if(cardName == langMap!['rippling_water']){
                    game.addStatus(_target!, langMap!['nebula'], 1 * reinforcementMulti, 1);
                  }
                  // 瞬疗
                  else if(cardName == langMap!['curing']){
                    game.damagePlayer(_source!, _source!, 120 * reinforcementMulti, DamageType.heal);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 天穹尘埃之障
                  else if(cardName == langMap!['aether_shroud']){
                    game.addStatus(_target!, langMap!['oculus_veil'], 0, 1 * reinforcementMulti);
                  }
                  // 同调
                  else if(cardName == langMap!['homology']){
                    for(Character chara in game.players.values){
                      if(chara.id != _source){
                        for(String status in chara.status.keys){
                          game.addStatus(_source!, status, chara.getStatusIntensity(status), 
                          chara.getStatusLayer(status) * reinforcementMulti);
                        }
                      }
                    }
                  }
                  // 无敌贯通
                  else if(cardName == langMap!['critical_strike']){
                    game.addHiddenStatus(_source!, 'critical', 0, 1);
                  }
                  // 西西弗斯之石头
                  else if(cardName == langMap!['sisyphus_stone']){
                    game.addStatus(_target!, langMap!['grind'], 0, 1 * reinforcementMulti);
                  }
                  
                  // 迅捷术
                  else if(cardName == langMap!['swift_spell']){
                    game.addStatus(_source!, langMap!['swift'], 1 * reinforcementMulti, 2);
                  }
                  // 炎极烈火
                  else if(cardName == langMap!['pyrotheum']){
                    game.addStatus(_target!, langMap!['flaming'], 5 * reinforcementMulti, 3);
                  }
                  // 伊甸园
                  else if(cardName == "伊甸园"){
                    game.countdown.eden += 1;
                  }
                  // 遗失碎片
                  else if(cardName == langMap!['fragment']){
                    game.addAttribute(_source!,AttributeType.card, 2 * reinforcementMulti);
                    game.addHiddenStatus(_target!, 'damageplus', 45 * reinforcementMulti, 1);
                  }
                  // 隐身术
                  else if(cardName == langMap!['invisibility_spell']){
                    game.addStatus(_source!, langMap!['dodge'], 0, 1);
                    game.addHiddenStatus(_source!, 'void', 0, 1);
                  }
                  // 御术者长矛·炎
                  else if(cardName == langMap!['flame_spear']){
                    game.addStatus(_source!, langMap!['lumen_flare'], 0, 1);
                  }
                  // 御术者重盾·霜
                  else if(cardName == langMap!['frost_shield']){
                    game.addStatus(_source!, langMap!['erode_gelid'], 0, 1);
                  }
                  // 圆盾
                  else if(cardName == langMap!['shield']){
                    game.addAttribute(_source!, AttributeType.armor, 100 * reinforcementMulti);
                    game.addAttribute(_source!, AttributeType.defence, 5 * reinforcementMulti);
                  }
                  // 长剑
                  else if(cardName == langMap!['rapier']){
                    game.addAttribute(_source!, AttributeType.attack, 15 * reinforcementMulti);
                    // attackPlus += 15;
                  }
                  // 折射水晶
                  else if(cardName == langMap!['amethyst']){
                    int amethystPoint = settings['amethystPoint'] as int? ?? 1;
                    if (amethystPoint == 1){
                      game.addHiddenStatus(_target!, 'damageplus', 80 * reinforcementMulti, 1);
                    }
                    else{
                      game.addHiddenStatus(_target!, 'damageplus', -40 * reinforcementMulti, 1);
                    }
                  }
                  // 终焉长戟
                  else if(cardName == langMap!['end_halberd']){
                    game.addHiddenStatus(_target!, 'end', 1 * reinforcementMulti, 1);
                  }

                  // 强化效果移除
                  if(game.players[_source]!.hasHiddenStatus('reinforcement')){
                    game.removeHiddenStatus(_source!, 'reinforcement');
                  }
                }
                }

                // 【烛焱】状态
                if(game.players[_source]!.hasStatus(langMap!['lumen_flare']) && 
                !game.players[_source]!.hasHiddenStatus('void')){
                  game.players[_source]!.status[langMap!['lumen_flare']]![3] += 1;
                }
                // 【磨砺】状态
                if(game.players[_source]!.hasStatus(langMap!['teroxis']) && 
                !game.players[_source]!.hasHiddenStatus('void')){
                  game.addStatus(_source!, langMap!['teroxis'], 1, 1);
                }

                // 应用攻击特效
                for (var effectData in _attackEffectTableData) {
                  AttackEffect effect = effectData['effect'];
                  Map<String, dynamic> settings = effectData['settings'];
  
                  // 【烛焱】特效
                  if (effect == AttackEffect.lumenFlare && game.players[_source]!.hasStatus(langMap!['lumen_flare'])) {
                    int lumenFlarePoint = settings['lumenFlarePoint'] as int? ?? 10;
                    if(game.players[_source]!.getStatusIntData(langMap!['lumen_flare']) % 3 == 0 &&
                      lumenFlarePoint <= 8 || lumenFlarePoint <= 2){
                        game.addStatus(_target!, langMap!['flaming'], 3, 1);
                    }
                  }
                  // 【障目】特效
                  if (effect == AttackEffect.oculusVeil && game.players[_source]!.hasStatus(langMap!['oculus_veil'])) {
                    int oculusVeilPoint = settings['oculusVeilPoint'] as int? ?? 2;
                    if (oculusVeilPoint == 1){
                      game.addHiddenStatus(_source!, 'void', 0, 1);
                    }
                  }
                }

                // 应用防守特效
                for (var effectData in _defenceEffectTableData) {
                  DefenceEffect effect = effectData['effect'];
                  Map<String, dynamic> settings = effectData['settings'];

                  // 【蚀凛】特效
                  if (effect == DefenceEffect.erodeGelid && game.players[_target]!.hasStatus(langMap!['erode_gelid'])) {
                    int erodeGelidPoint = settings['erodeGelidPoint'] as int? ?? 1;
                    if (erodeGelidPoint >= 9 - game.players[_target]!.getStatusIntData(langMap!['erode_gelid']) * 2){
                      game.addStatus(_source!, langMap!['frost'], 2, 1);
                      game.players[_target]!.status[langMap!['erode_gelid']]![3] = 0;
                    }
                    else {
                      game.players[_target]!.status[langMap!['erode_gelid']]![3] += 1;
                    }
                  }
                }
                
                // 计算伤害
                // 鼓舞
                if(game.players[_source]!.hasHiddenStatus('hero_legend')){
                  attackPlus += 10 * _sourcePlayer!.getHiddenStatusIntensity('hero_legend');
                  game.removeHiddenStatus(_source!, 'hero_legend');
                }
                // 加护
                if(game.players[_target]!.hasHiddenStatus('dream_shelter')){
                  attackPlus -= 10 * _targetPlayer!.getHiddenStatusIntensity('dream_shelter');
                  game.removeHiddenStatus(_target!, 'dream_shelter');
                }
                // 纳米渗透
                if(game.players[_source]!.hasHiddenStatus('nano')){
                  attackPlus += game.players[_target]!.defence;
                  game.removeHiddenStatus(_source!, 'nano');
                }                
                attack = game.players[_source]!.attack;
                defence = game.players[_target]!.defence;
                double baseDamage;
                // 图西乌【蚀月】
                if (_target == langMap!['tussiu']) {
                  List<int> pointRef = [point];
                  game.castTrait(_target!, [], langMap!['eclipse'], {'pointRef': pointRef});
                  point = pointRef[0];
                }
                if (attack > defence) {
                  baseDamage = ((attack + attackPlus) * attackMulti - defence) * point;
                }
                else {
                  baseDamage = 5 + 0.1 * (attack + attackPlus) * attackMulti;             
                }
                // 云云子【晨昏寥落】
                if (_source == langMap!['yun']) {
                  List<double> baseDamageRef = [baseDamage];
                  game.castTrait(_source!, [], langMap!['dusk_void'], {'baseDamageRef': baseDamageRef, 
                  'attack': (attack + attackPlus), 'attackMulti': attackMulti, 'point': point});
                  baseDamage = baseDamageRef[0];
                  game.addHiddenStatus(_source!, 'critical', 0, 1);
                }
                // 飖【血灵斩】
                if (_source == langMap!['windflutter'] && _sourcePlayer!.hasHiddenStatus('hema') && _sourcePlayer!.actionTime == 1){
                  game.addAttribute(_source!, AttributeType.attack, 15);
                }            
                game.damagePlayer(_source!, _target!, baseDamage.toInt(), DamageType.action);
                // 记录行动
                final recordProvider = Provider.of<RecordProvider>(context, listen: false);
                recordProvider.addActionRecord(GameTurn(round: game.round, turn: game.turn, extra: game.extra), 
                 _source!, _target!, point, [for (var rowData in _cardTableData) rowData['cardName'] as String]);
                }
              }              
            }
            else if (_actionType == '技能') {
              // final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
              final recordProvider = Provider.of<RecordProvider>(context, listen: false);
              // 技能是否可用
              bool skillAble = true;

              // 冷却未转好
              if (game.players[_source]!.skill.keys.contains(_selectedSkill)){
                if (game.players[_source]!.skill[_selectedSkill]! > 0){
                  skillAble = false;
                }
              }
              // 状态【混乱】【冰封】
              if ((game.players[_source]!.hasStatus(langMap!['confusion']) || game.players[_source]!.hasStatus(langMap!['frozen'])) 
                && _selectedSkill != langMap!['purification']) {
                skillAble = false;
              }
              // 仁慈
              if (_selectedSkill == langMap!['benevolence']) {
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, source: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                if (damageRecords.isEmpty){
                  skillAble = false;
                }
                else {
                  skillAble = false;
                  for (var record in damageRecords) {
                    DamageRecord damageRecord = record as DamageRecord;
                    if (damageRecord.damage >= 100) {
                      skillAble = true;
                      break;
                    }
                  }
                }
              }
              // 相转移
              else if (_selectedSkill == langMap!['phase_transition']) {
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, target: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                if (damageRecords.isEmpty){
                  skillAble = false;
                }        
              }
              // 阈限
              else if (_selectedSkill == langMap!['threshold']) {
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, target: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                if (damageRecords.isEmpty){
                  skillAble = false;
                }
                else {
                  skillAble = false;
                  for (var record in damageRecords) {
                    DamageRecord damageRecord = record as DamageRecord;
                    if (damageRecord.damage >= 250) {
                      skillAble = true;
                    }
                  }
                }                                
              }
              // 追击
              else if (_selectedSkill == langMap!['chase']) {
                GameRecord? record = recordProvider.getLatestRecordByType(RecordType.action);
                ActionRecord? actionRecord = record as ActionRecord?;
                if (actionRecord!.target != _target || actionRecord.source != _source) {
                  skillAble = false;
                }
                if (_targetPlayer!.health > 300){
                  skillAble = false;
                }
              }
              // 不死
              else if (_selectedSkill == langMap!['undying']) {
                if (_sourcePlayer!.health > 0){
                  skillAble = false;
                }
              }
              // 止杀
              else if (_selectedSkill == langMap!['kill_ceasing']){
                if (_targetPlayer!.damageDealtTurn < 200) {
                  skillAble = false;
                }
              }
              // 屠杀
              else if (_selectedSkill == langMap!['massacre']) {
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, source: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                int maxDamage = 0;
                for (var record in damageRecords) {
                  DamageRecord damageRecord = record as DamageRecord;
                  if (damageRecord.damage >= maxDamage) {
                    maxDamage = damageRecord.damage;
                  }
                }
                if (maxDamage < 250) {
                  skillAble = false;
                }
              }
              // 敏博士【异镜解构】
              else if (_selectedSkill == langMap!['deconstruction']){
                if (_sourcePlayer!.movePoint < 1){
                  skillAble = false;
                }
              }
              // 沉默
              if (_sourcePlayer!.hasHiddenStatus('reticence')){
                skillAble = false;
              }

              // 技能可用
              if (skillAble) {            
              // 仁慈
              if (_selectedSkill == langMap!['benevolence']) {
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, source: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                int maxDamage = 0;
                for (var record in damageRecords) {
                  DamageRecord damageRecord = record as DamageRecord;
                  if (damageRecord.damage >= maxDamage) {
                    maxDamage = damageRecord.damage;
                  }
                }
                game.addAttribute(_target!, AttributeType.health, maxDamage);
                game.addAttribute(_target!, AttributeType.dmgreceived, -maxDamage);
                game.addAttribute(_source!, AttributeType.dmgdealt, -maxDamage);
                if (_benevolenceChoice == 0) {
                  game.addAttribute(_source!, AttributeType.card, 2);
                }
                else {
                  game.damagePlayer(_source!, _source!, (game.players[_source!]!.maxHealth * 0.2).toInt(), DamageType.heal);
                }
              }
              // 相转移
              else if (_selectedSkill == langMap!['phase_transition']){
                Map<String, int> damageDealter = {};
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, target: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                for (var record in damageRecords) {
                  DamageRecord damageRecord = record as DamageRecord;
                  if (damageDealter.containsKey(damageRecord.source)) {
                    damageDealter[damageRecord.source] = damageDealter[damageRecord.source]! + damageRecord.damage;
                  }
                  else {
                    damageDealter[damageRecord.source] = damageRecord.damage;
                  }
                }
                game.addAttribute(_source!, AttributeType.health, _sourcePlayer!.damageReceivedTurn);
                game.addAttribute(_source!, AttributeType.dmgreceived, -_sourcePlayer!.damageReceivedTurn);                
                for (var source in damageDealter.keys) {
                  game.addAttribute(source, AttributeType.dmgdealt, -damageDealter[source]!);
                  game.damagePlayer(source, _target!, damageDealter[source]!, DamageType.physical);
                }
                // game.addHiddenStatus(_source!, 'transition', 0, 1);
              }
              // 天国邮递员
              else if (_selectedSkill == langMap!['heaven_delivery']){
                game.addHiddenStatus(_source!, 'heaven', 0, 1);
                game.addHiddenStatus(_target!, 'heaven', 0, 1);
              }
              // 净化
              else if (_selectedSkill == langMap!['purification']){
                List<dynamic> statusKeys = game.players[_target]!.status.keys.toList();
                for (var stat in statusKeys) {
                  if (![langMap!['teroxis'], langMap!['lumen_flare'], langMap!['erode_gelid']].contains(stat)){
                    game.removeStatus(_target!, stat);
                  }
                }
              }
              // 嗜血
              else if (_selectedSkill == langMap!['blood_thirsty']){
                int damageDealt = _sourcePlayer!.damageDealtTurn;                
                game.damagePlayer(_source!, _source!, (damageDealt * 0.5).toInt(), DamageType.heal);
              }
              // 外星人
              else if (_selectedSkill == langMap!['stellar']) {
                game.addStatus(_target!, langMap!['stellar_cage'], 0, 1);
              }
              // 恐吓
              else if (_selectedSkill == langMap!['intimidation']){
                if ([3, 6].contains(_intimidationPoint)){
                  game.addHiddenStatus(_source!, 'intimidation', 0, 1);
                }
              }
              // 阈限
              else if (_selectedSkill == langMap!['threshold']){
                List<GameRecord>? damageRecords = recordProvider.getFilteredRecords(type: RecordType.damage, target: _source, 
                startTurn: game.getGameTurn(), endTurn: game.getGameTurn());
                int maxDamage = 0;
                for (var record in damageRecords) {
                  DamageRecord damageRecord = record as DamageRecord;
                  if (damageRecord.damage > maxDamage) {
                    maxDamage = damageRecord.damage;
                  }
                }
                game.addAttribute(_source!, AttributeType.health, maxDamage - 100);                        
              }
              // 强化
              else if (_selectedSkill == langMap!['reinforcement']){
                game.addHiddenStatus(_source!, 'reinforcement', 0, 1);
              }
              // 追击
              else if (_selectedSkill == langMap!['chase']){
                game.addHiddenStatus(_source!, 'extra', 0, 1);
                game.addHiddenStatus(_source!, 'chase', 0, 1);
              }
              // 沉默
              else if (_selectedSkill == langMap!['reticence']){
                game.addHiddenStatus(_target!, 'reticence', 0, 1);
              }
              // 奉献
              else if (_selectedSkill == langMap!['devotion']){
                game.damagePlayer(_source!, _source!, 100 * _devotionPoint, DamageType.magical);
                game.damagePlayer(_source!, _target!, 100 * _devotionPoint, DamageType.heal);
                if (_devotionPoint >= 2) {
                  game.addAttribute(_source!, AttributeType.card, _devotionPoint - 1);
                }
              }
              // 屏障
              else if (_selectedSkill == langMap!['barrier']){
                game.addAttribute(_source!, AttributeType.armor, 150);
                game.addHiddenStatus(_source!, 'barrier', 0, 1);
              }
              // 镭射
              else if (_selectedSkill == langMap!['laser']){
                game.damagePlayer(_source!, _target!, 60, DamageType.physical);
                game.addStatus(_target!, langMap!['fragility'], 5, 1);
              }
              // 不死
              else if (_selectedSkill == langMap!['undying']) {
                _sourcePlayer!.isDead = false;
                _sourcePlayer!.health = 0;
                game.damagePlayer(_source!, _source!, 200, DamageType.revive);
                game.addAttribute(_source!, AttributeType.armor, 400);
                game.addHiddenStatus(_source!, 'undying', 0, 1);
              }
              // 止杀
              else if (_selectedSkill == langMap!['kill_ceasing']) {
                if (_targetPlayer!.cardCount < 2) {
                  game.addAttribute(_source!, AttributeType.card, _targetPlayer!.cardCount);
                  game.addAttribute(_target!, AttributeType.card, -_targetPlayer!.cardCount);
                }
                else {
                  game.addAttribute(_source!, AttributeType.card, 2);
                  game.addAttribute(_target!, AttributeType.card, -2);
                }
                game.addStatus(_target!, langMap!['exhausted'], 0, 1);
              }
              // 灵能注入
              else if (_selectedSkill == langMap!['psionia']) {
                game.damagePlayer(_source!, _source!, 75, DamageType.magical);
              }
              // 镜像
              else if (_selectedSkill == langMap!['inversion']) {
                game.addStatus(_target!, langMap!['mirror'], 0, 3);
                game.addHiddenStatus(_target!, 'mirror', 0, 3);
                _targetPlayer!.hiddenStatus['mirror']![3] = _targetPlayer!.damageReceivedTotal;
              }              
              // 分裂
              else if (_selectedSkill == langMap!['fission']) {
                game.addHiddenStatus(_source!, 'fission', 0, 1);
                game.addHiddenStatus(_target!, 'fission_target', 0, 1);
              }
              // 透支
              else if (_selectedSkill == langMap!['overdraw']) {
                game.addStatus(_source!, langMap!['burn_out'], 5, 1);
              }
              // 挑唆
              else if (_selectedSkill == langMap!['instigation']) {
                for (var chara in game.players.values) {
                  if (chara.id != _source) {
                    int point = _instigationPoints[chara.id]!;
                    if (_isPlayerInstigated[chara.id] == 0) {                      
                      int damage = _sourcePlayer!.attack > chara.defence ? (_sourcePlayer!.attack - chara.defence) * point :                       
                      5 + (0.1 * _sourcePlayer!.attack).toInt();
                      game.damagePlayer(_source!, chara.id, damage, DamageType.physical);
                    }
                    else {
                      Character nextChara = game.gameSequence.indexOf(chara.id) == game.gameSequence.length - 1 ? 
                      game.players[game.gameSequence[0]]! : game.players[game.gameSequence[game.gameSequence.indexOf(chara.id) + 1]]!;
                      int damage = chara.attack > nextChara.defence ? (chara.attack - nextChara.defence) * point : 
                      5 + (0.1 * chara.attack).toInt();
                      game.damagePlayer(chara.id, nextChara.id, damage, DamageType.physical);
                    }
                  }
                }
              }
              // 开阳
              else if (_selectedSkill == langMap!['mizar']) {
                game.addAttribute(_source!, AttributeType.card, 1);
              }
              // 太阴
              else if (_selectedSkill == langMap!['lunar']) {
                game.addAttribute(_target!, AttributeType.card, -2);
                if (_targetPlayer!.cardCount < 0) {
                  game.addAttribute(_target!, AttributeType.card, -game.players[_target]!.cardCount);
                }
              }
              // 博览
              else if (_selectedSkill == langMap!['perusing']) {
                game.addAttribute(_source!, AttributeType.card, 1);
              }
              // 反重力
              else if (_selectedSkill == langMap!['anti_gravity']) {
                game.countdown.antiGravity++;
              }
              // 奇点
              else if (_selectedSkill == langMap!['singularity']) {
                game.damagePlayer('empty', _target!, 300, DamageType.magical);
              }
              // 魂怨
              else if (_selectedSkill == langMap!['soul_rancor']) {
                game.damagePlayer(_source!, _target!, 50, DamageType.physical, isAOE: true);
                for (var charaId in _skillTargetList) {
                  game.damagePlayer(_source!, charaId, 50, DamageType.physical, isAOE: true);
                }
                if (_skillTargetList.length < 3) {
                  for (int i = _skillTargetList.length; i < 3; i++) {
                    game.damagePlayer(_source!, _target!, 50, DamageType.physical, isAOE: true);
                  }
                }
              }
              // 瞬影
              else if (_selectedSkill == langMap!['flash_shade']) {
                game.addHiddenStatus(_source!, 'extra', 0, 1);
              }
              // 侵蚀
              else if (_selectedSkill == langMap!['corrosion']) {
                game.addStatus(_target!, langMap!['corroded'], 1, 2);
              }
              // 逆转乾坤
              else if (_selectedSkill == langMap!['karma_reversal']) {                
                int tempHp = _sourcePlayer!.health;
                int tempMp = _sourcePlayer!.movePoint;
                int tempCard = _sourcePlayer!.cardCount;
                _sourcePlayer!.health = _targetPlayer!.health;
                _sourcePlayer!.movePoint = _targetPlayer!.movePoint;
                _sourcePlayer!.cardCount = _targetPlayer!.cardCount;
                _targetPlayer!.health = tempHp;
                _targetPlayer!.movePoint = tempMp;
                _targetPlayer!.cardCount = tempCard;            
              }
              // 极速
              else if (_selectedSkill == langMap!['velocity']) {
                game.addHiddenStatus(_source!, 'velocity', 0, 1);
              }
              // 空袭
              else if (_selectedSkill == langMap!['airstrike']) {
                if (_skillTargetList.isNotEmpty) {
                  game.damagePlayer(_source!, _skillTargetList[0], 100, DamageType.physical);
                  if (game.players[_skillTargetList[0]]!.id == _source) {
                    game.addAttribute(_source!, AttributeType.card, 2);
                  }
                }
                else {
                  game.damagePlayer(_source!, _target!, 100, DamageType.physical);
                }
              }
              // 黯星【屠杀】
              else if (_selectedSkill == langMap!['massacre']) {
                game.addAttribute(_source!, AttributeType.attack, 10);
                game.damagePlayer(_source!, _source!, 100, DamageType.heal);
                if (game.countdown.extraTurn == 0) {
                  game.addHiddenStatus(_source!, 'extra', 0, 1);
                }                
              }
              // 恋慕【氤氲】
              else if (_selectedSkill == langMap!['nebula_field']) {
                game.addStatus(_source!, langMap!['nebula'], 1, 2);
              }
              // 敏博士【异镜解构】
              else if (_selectedSkill == langMap!['deconstruction']) {
                game.addAttribute(_source!, AttributeType.card, 1);
                game.addAttribute(_source!, AttributeType.movepoint, -1);
              }
              // 技能进入CD
              if(_selectedSkill != null){
                game.players[_source]!.skill[_selectedSkill!] = skillData![_selectedSkill!][0];
                if (_source == langMap!['neko']) {
                  game.castTrait(_source!, [], langMap!['tireless_observer'], {'skill': _selectedSkill});
                }
              } 
              // 记录技能
              final targets = [if (_target != null) _target!, ..._skillTargetList];
              recordProvider.addSkillRecord(GameTurn(round: game.round, turn: game.turn, extra: game.extra), 
              _source!, targets, _selectedSkill!, {});
              }
              // 沉默后仍然进入CD
              if (!skillAble && _sourcePlayer!.hasHiddenStatus('reticence')) {
                game.players[_source]!.skill[_selectedSkill!] = skillData![_selectedSkill!][0];
              }              
            }
            else if (_actionType == '特质') {
              // 特质可用
              bool traitAble = true;
              if (_source != traitData![_selectedTrait!][0]) {
                traitAble = false;
              }
              if (traitAble) { 
                // 星尘【幸运壁垒】
                if (_selectedTrait == langMap!['lucky_shield']) {
                  for (var damage in _luckyShieldDamages.keys) {
                    game.castTrait(_source!, [], langMap!['lucky_shield'], 
                    {'damage': damage.damage, 'dmgSource': damage.source, 'point': _luckyShieldDamages[damage]});
                  }
                }
                // 黯星【决心】
                else if (_selectedTrait == langMap!['resolution']) {
                  game.castTrait(_source!, [], langMap!['resolution'], {'point':_resolutionPoint});
                }
                // 方寒【耀光爆裂】
                else if (_selectedTrait == langMap!['radiant_blast']) {
                  game.castTrait(_source!, [_target!], langMap!['radiant_blast'], {'point':_radiantBlastPoint});
                }
                // 恪玥【咕了】
                else if (_selectedTrait == langMap!['escaping']) {
                  game.castTrait(_source!, [], langMap!['escaping'], {'point':_escapingPoint});
                }
                // 飖【血灵斩】
                else if (_selectedTrait == langMap!['hema_slash']) {
                  game.castTrait(_source!, [], langMap!['hema_slash']);
                  if (_sourcePlayer!.hasHiddenStatus('hema') && _sourcePlayer!.actionTime == 1){
                    game.addAttribute(_source!, AttributeType.attack, 15);
                  }
                }
                // 扶风【大预言】
                else if (_selectedTrait == langMap!['grand_prophecy']) {
                  game.castTrait(_source!, [], langMap!['grand_prophecy'], {'point':_prophecyPoint});
                }
                // 星凝【希冀】
                else if (_selectedTrait == langMap!['yearning']) {
                  game.castTrait(_source!, [_target!], langMap!['yearning'], {'type':_yearningPoint});
                }
                // 星凝【祝愿】
                else if (_selectedTrait == langMap!['blessing']) {
                  game.castTrait(_source!, [_target!], langMap!['blessing']);
                }
                // 时雨【天霜封印】
                else if (_selectedTrait == langMap!['arctic_seal']) {
                  game.castTrait(_source!, [_target!], langMap!['arctic_seal'], {'point':_arcticSealPoint});
                }
                // 舸灯【引渡】
                else if (_selectedTrait == langMap!['ghost_ferry']) {
                  game.castTrait(_source!, [], langMap!['ghost_ferry'], {"type": 2});
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