import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/settings.dart';

// 道具卡设置对话框组件
class CardSettingsDialog extends StatefulWidget {
  final int cardIndex;
  final String cardName;
  final String? source, target;

  const CardSettingsDialog({
    Key? key,
    required this.cardIndex,
    required this.cardName,
    this.source,
    this.target,

  }) : super(key: key);

  @override
  _CardSettingsDialogState createState() => _CardSettingsDialogState();
}

class _CardSettingsDialogState extends State<CardSettingsDialog> {
  late CardSetting? _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  final Logger _logger = Logger();
  
  // 破片水晶
  final List<String> _endCrystalOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];
  int _crystalMagic = 1;
  int _crystalSelf = 1;
  // 复合弓
  final List<String> _bowOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _ammoCount = 1;
  // 后日谈
  List<String> _redstoneOptions = [];
  List<String> _redstonePlayerOptions = [];
  String _statusProlonged = '';
  String _playerProlonged = '';
  // 混乱力场
  final List<String> _ascensionStairOptions = ['1', '2', '3', '4', '5', '6'];
  Map<String, int> _ascensionPoints = {};
  // 极北之心
  List<String> _arcticHeartOptions = [];
  String _arcticHeartChoice = '';
  // 极光震荡
  final List<String> _auroraOptions = ['1', '2'];
  Map<String, int> _auroraPoints = {};
  // 潘多拉魔盒
  final List<String> _pandoraBoxOptions = ['1', '2', '3', '4', '5', '6'];
  int _pandoraPoint = 1;
  // 折射水晶
  final List<String> _amethystOptions = ['1', '2'];
  int _amethystPoint = 1;

  Future<void> _loadAssetsData() async {
    // 首选从全局 Provider 获取已加载的 AssetsManager（在 main 已预加载）
    final assets = Provider.of<AssetsManager>(context, listen: false);
    if (assets.langMap == null) {
      // 兼容：如果 provider 中尚未加载，再进行加载
      await assets.loadData();
    }
    setState(() {
      langMap = assets.langMap;
    });
  }

  @override
  void initState() {
    super.initState();    
    final cardSettingsManager = Provider.of<CardSettingsManager>(context, listen: false);
    _settings = cardSettingsManager.getCardSettings(widget.cardIndex);
    // 从 Provider 获取已加载的语言映射（避免重复异步加载）
    final assets = Provider.of<AssetsManager>(context, listen: false);
    langMap = assets.langMap;

    // 根据不同卡牌类型初始化设置
    if (_settings is EndCrystalSetting) {
      final setting = _settings as EndCrystalSetting;
      _crystalMagic = setting.crystalMagic;
      _crystalSelf = setting.crystalSelf;
    } else if (_settings is BowSetting) {
      final setting = _settings as BowSetting;
      _ammoCount = setting.ammoCount;
    } else if (_settings is RedstoneSetting) {
      final setting = _settings as RedstoneSetting;
      _redstonePlayerOptions = [widget.source!, widget.target!];      
      _playerProlonged = setting.playerProlonged;
      _redstoneOptions = game.players[_playerProlonged]!.status.keys.toList();       
      _statusProlonged = setting.statusProlonged;
    } else if (_settings is AscensionStairSetting) {
      final setting = _settings as AscensionStairSetting;
      _ascensionPoints = Map<String, int>.from(setting.ascensionPoints);
    } else if (_settings is ArcticHeartSetting) {
      final setting = _settings as ArcticHeartSetting;
      _arcticHeartOptions = game.players[widget.source!]!.skill.keys.toList();
      _arcticHeartChoice = setting.arcticHeartChoice;
    } else if (_settings is AuroraConcussionSetting) {
      final setting = _settings as AuroraConcussionSetting;
      _auroraPoints = Map<String, int>.from(setting.auroraPoints);
    } else if (_settings is PandoraBoxSetting) {
      final setting = _settings as PandoraBoxSetting;
      _pandoraPoint = setting.pandoraPoint;
    } else if (_settings is AmethystSetting) {
      final setting = _settings as AmethystSetting;
      _amethystPoint = setting.amethystPoint;
    }
  }

  void _saveSettings() {
    final cardSettingsManager = Provider.of<CardSettingsManager>(context, listen: false);

    // 创建并保存特定卡牌设置
    CardSetting newSetting;
    switch (widget.cardName) {
      case "破片水晶":
        newSetting = EndCrystalSetting()
          ..crystalMagic = _crystalMagic
          ..crystalSelf = _crystalSelf;
        break;
      case "复合弓":
        newSetting = BowSetting()
          ..ammoCount = _ammoCount;
        break;
      case "后日谈":
        newSetting = RedstoneSetting()
          ..statusProlonged = _statusProlonged
          ..playerProlonged = _playerProlonged;
        break;
      case "混乱力场":
        newSetting = AscensionStairSetting()
          ..ascensionPoints = Map<String, int>.from(_ascensionPoints);
        break;
      case "极北之心":
        newSetting = ArcticHeartSetting()
          ..arcticHeartChoice = _arcticHeartChoice;
        break;
      case "极光震荡":
        newSetting = AuroraConcussionSetting()
          ..auroraPoints = Map<String, int>.from(_auroraPoints);
        break;
      case "潘多拉魔盒":
        newSetting = PandoraBoxSetting()
          ..pandoraPoint = _pandoraPoint;
        break;
      case "折射水晶":
        newSetting = AmethystSetting()
          ..amethystPoint = _amethystPoint;
        break;
      default:
        newSetting = EndCrystalSetting(); // 默认情况
    }
    
    cardSettingsManager.updateCardSettings(widget.cardIndex, newSetting);
    Navigator.of(context).pop();
  }

  void _updateRedstoneOptions() {
    setState(() {
      //_logger.d('${_playerProlonged}');
      if (_playerProlonged != '') {
        _redstoneOptions = game.players[_playerProlonged]!.status.keys.toList();
      } else {
        _redstoneOptions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.cardName} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.cardName == "破片水晶") ...[
              Text('水晶2d4损血', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _crystalSelf,
                hint: Text('水晶2d4损血'),
                items: _endCrystalOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _crystalSelf = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              Text('水晶d8伤害', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _crystalMagic,
                hint: Text('水晶d8伤害'),
                items: _endCrystalOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _crystalMagic = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ]
            else if (widget.cardName == "复合弓")...[
              Text('弃牌张数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _ammoCount,
                hint: Text('弃牌张数'),
                items: _bowOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _ammoCount = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ]
            else if(widget.cardName == "后日谈")...[
              Text('延长目标', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _playerProlonged.isEmpty ? null : _playerProlonged,
                hint: Text('延长目标'),
                items: _redstonePlayerOptions.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _playerProlonged = newValue ?? '';
                    _statusProlonged = game.players[newValue]!.status.isEmpty ? '' : game.players[newValue]!.status.keys.first;
                    _updateRedstoneOptions();
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
              Text('状态延长', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _statusProlonged.isEmpty ? null : _statusProlonged,
                hint: Text('状态延长'),
                items: (_playerProlonged.isEmpty) ? [] :
                _redstoneOptions.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _statusProlonged = newValue ?? '';
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ]
            else if(widget.cardName == '混乱力场')...[
              Text('混乱点数', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...game.gameSequence.map((playerId) {
              final player = game.players[playerId]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${player.id}:'),
                  DropdownButtonFormField<int>(
                    value: _ascensionPoints[playerId],
                    hint: Text('选择点数'),
                    items: _ascensionStairOptions.map((option) {
                      int value = int.parse(option);
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _ascensionPoints[playerId] = newValue ?? 1;
                      });
                    },
                    isExpanded: true,
                  ),
                 SizedBox(height: 8),
                ],
              );
             }),
            ]
            else if(widget.cardName == '极北之心')...[
              Text('冷却技能', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _arcticHeartChoice.isEmpty ? null : _arcticHeartChoice,
                hint: Text('选择技能'),
                items: _arcticHeartOptions.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _arcticHeartChoice = newValue ?? '';
                  });
                }
              )
            ]
            else if(widget.cardName == '极光震荡')...[
              Text('极光点数', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ..._auroraPoints.keys.map((playerId) {
              final player = game.players[playerId]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${player.id}:'),
                  DropdownButtonFormField<int>(
                    value: _auroraPoints[playerId],
                    hint: Text('选择点数'),
                    items: _auroraOptions.map((option) {
                      int value = int.parse(option);
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _auroraPoints[playerId] = newValue ?? 1;
                      });
                    },
                    isExpanded: true,
                  ),
                 SizedBox(height: 8),
                ],
              );
             }),
            ]
            else if(widget.cardName == '潘多拉魔盒')...[
              Text('魔盒点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _pandoraPoint,
                hint: Text('魔盒点数'),
                items: _pandoraBoxOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _pandoraPoint = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ] else if(widget.cardName == '折射水晶')...[
              Text('折射点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _amethystPoint,
                hint: Text('折射点数'),
                items: _amethystOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _amethystPoint = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('确定'),
        ),
      ],
    );
  }
}