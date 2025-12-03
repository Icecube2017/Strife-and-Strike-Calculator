import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/settings.dart';

// 道具卡设置对话框组件
class CardSettingsDialog extends StatefulWidget {
  final String cardName;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final String? source, target;

  const CardSettingsDialog({
    Key? key,
    required this.cardName,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.source,
    this.target,

  }) : super(key: key);

  @override
  _CardSettingsDialogState createState() => _CardSettingsDialogState();
}

class _CardSettingsDialogState extends State<CardSettingsDialog> {
  late Map<String, dynamic> _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  //Logger _logger = Logger();
  
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

  @override
  void initState() {
    super.initState();
    _loadAssetsData();
    _settings = Map<String, dynamic>.from(widget.initialSettings);

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _crystalMagic = _settings['crystalMagic'] ?? settingsProvider.crystalMagic;
    _crystalSelf = _settings['crystalSelf'] ?? settingsProvider.crystalSelf;
    _ammoCount = _settings['ammoCount'] ?? settingsProvider.ammoCount;
    _redstonePlayerOptions = [widget.source!, widget.target!];
    _updateRedstoneOptions();
    _statusProlonged = _settings['statusProlonged'] ?? settingsProvider.statusProlonged;
    _playerProlonged = _settings['playerProlonged'] ?? settingsProvider.playerProlonged;
    if (_settings['ascensionPoints'] != null) {
      _ascensionPoints = Map<String, int>.from(_settings['ascensionPoints']);
    } else {
      _ascensionPoints = Map<String, int>.from(settingsProvider.ascensionPoints);
    }
    _arcticHeartOptions = game.players[widget.source!]!.skill.keys.toList();
    _arcticHeartChoice = _settings['arcticHeartChoice'] ?? settingsProvider.arcticHeartChoice;
    if (_settings['auroraPoints'] != null) {
      _auroraPoints = Map<String, int>.from(_settings['auroraPoints']);
    } else {
      _auroraPoints = Map<String, int>.from(settingsProvider.auroraPoints);
    }
    _pandoraPoint = _settings['pandoraPoint'] ?? settingsProvider.pandoraPoint;
    _amethystPoint = _settings['amethystPoint'] ?? settingsProvider.amethystPoint;
  }

  Future<void> _loadAssetsData() async {
    AssetsManager assets = AssetsManager();
    await assets.loadData();
    langMap = assets.langMap;
  }

  void _saveSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    settingsProvider.setCrystalMagic(_crystalMagic);
    settingsProvider.setCrystalSelf(_crystalSelf);
    settingsProvider.setAmmoCount(_ammoCount);
    settingsProvider.setStatusProlonged(_statusProlonged);
    settingsProvider.setPlayerProlonged(_playerProlonged);
    settingsProvider.setAscensionPoints(_ascensionPoints);
    settingsProvider.setArcticHeartChoice(_arcticHeartChoice);
    settingsProvider.setAuroraPoints(_auroraPoints);
    settingsProvider.setPandoraPoint(_pandoraPoint);
    settingsProvider.setAmethystPoint(_amethystPoint);

    Map<String, dynamic> _newSettings = {
      'crystalMagic': _crystalMagic,
      'crystalSelf': _crystalSelf,
      'ammoCount': _ammoCount,
      'statusProlonged': _statusProlonged,
      'playerProlonged': _playerProlonged,
      'ascensionPoints': _ascensionPoints,
      'arcticHeartChoice': _arcticHeartChoice,
      'auroraPoints': _auroraPoints,
      'pandoraPoint': _pandoraPoint,
      'amethystPoint': _amethystPoint,
    };
    widget.onSettingsChanged(_newSettings);
    Navigator.of(context).pop();
  }

  void _updateRedstoneOptions() {
    setState(() {
      if (_playerProlonged.isNotEmpty && game.players.containsKey(_playerProlonged)) {
        _redstoneOptions = game.players[_playerProlonged]!.skill.keys.toList();
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
            // 仅当 cardName 为 "破片水晶" 时显示
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
                    _statusProlonged = '';
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
              ...game.gameSequence.map((playerId) {
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