import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/game.dart';
//import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/settings.dart';
import 'package:sns_calculator/localized_ids.dart';

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
  final List<String> _ascensionStairOptions = ['1', '2', '3', '4'];
  Map<String, int> _ascensionPoints = {};
  // 刷新
  List<String> _refreshmentOptions = [];
  String _refreshmentChoice = '';
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
    final cardSettingsManager = Provider.of<CardSettingsManager>(context, listen: false);
    _settings = cardSettingsManager.getCardSettings(widget.cardIndex);

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
    } else if (_settings is RefreshmentSetting) {
      final setting = _settings as RefreshmentSetting;
      _refreshmentOptions = game.players[widget.source!]!.skill.keys.toList();
      _refreshmentChoice = setting.refreshmentChoice;
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
    if (widget.cardName == CardId.endCrystal.id) {
      newSetting = EndCrystalSetting()
        ..crystalMagic = _crystalMagic
        ..crystalSelf = _crystalSelf;
    } else if (widget.cardName == CardId.bow.id) {
      newSetting = BowSetting()
        ..ammoCount = _ammoCount;
    } else if (widget.cardName == CardId.redstone.id) {
      newSetting = RedstoneSetting()
        ..statusProlonged = _statusProlonged
        ..playerProlonged = _playerProlonged;
    } else if (widget.cardName == CardId.ascensionStair.id) {
      newSetting = AscensionStairSetting()
        ..ascensionPoints = Map<String, int>.from(_ascensionPoints);
    } else if (widget.cardName == CardId.refreshment.id) {
      newSetting = RefreshmentSetting()
        ..refreshmentChoice = _refreshmentChoice;
    } else if (widget.cardName == CardId.auroraConcussion.id) {
      newSetting = AuroraConcussionSetting()
        ..auroraPoints = Map<String, int>.from(_auroraPoints);
    } else if (widget.cardName == CardId.pandoraBox.id) {
      newSetting = PandoraBoxSetting()
        ..pandoraPoint = _pandoraPoint;
    } else if (widget.cardName == CardId.amethyst.id) {
      newSetting = AmethystSetting()
        ..amethystPoint = _amethystPoint;
    } else {
      newSetting = EndCrystalSetting(); // 默认情况
    }
    /*switch (widget.cardName) {
      case "end_crystal":
        newSetting = EndCrystalSetting()
          ..crystalMagic = _crystalMagic
          ..crystalSelf = _crystalSelf;
        break;
      case "bow":
        newSetting = BowSetting()
          ..ammoCount = _ammoCount;
        break;
      case "redstone":
        newSetting = RedstoneSetting()
          ..statusProlonged = _statusProlonged
          ..playerProlonged = _playerProlonged;
        break;
      case "ascension_stair":
        newSetting = AscensionStairSetting()
          ..ascensionPoints = Map<String, int>.from(_ascensionPoints);
        break;
      case "refreshment":
        newSetting = RefreshmentSetting()
          ..refreshmentChoice = _refreshmentChoice;
        break;
      case "aurora_concussion":
        newSetting = AuroraConcussionSetting()
          ..auroraPoints = Map<String, int>.from(_auroraPoints);
        break;
      case "pandora_box":
        newSetting = PandoraBoxSetting()
          ..pandoraPoint = _pandoraPoint;
        break;
      case "amethyst":
        newSetting = AmethystSetting()
          ..amethystPoint = _amethystPoint;
        break;
      default:
        newSetting = EndCrystalSetting(); // 默认情况
    }*/
    
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

  List<Widget> _buildIntDropdownGroup({
    required String label,
    required int value,
    required List<String> options,
    required ValueChanged<int?> onChanged,
    double spacing = 16,
  }) {
    return [
      Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      DropdownButtonFormField<int>(
        initialValue: value,
        hint: Text(label),
        items: options.map((String item) {
          final int parsed = int.parse(item);
          return DropdownMenuItem(
            value: parsed,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
      SizedBox(height: spacing),
    ];
  }

  List<Widget> _buildStringDropdownGroup({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    double spacing = 16,
  }) {
    return [
      Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        hint: Text(label),
        items: options.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
      SizedBox(height: spacing),
    ];
  }

  List<Widget> _buildPlayerPointGroups({
    required String title,
    required Map<String, int> points,
    required List<String> options,
    required void Function(String playerId, int? newValue) onChanged,
  }) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final String localeStr = localeProvider.getLocaleNameWithCountry().toLowerCase();

    return [
      Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      ...points.keys.map((playerId) {
        //final player = game.players[playerId]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocalizedIDs.labelFor(playerId, localeStr), style: TextStyle(fontSize: 12)),
            DropdownButtonFormField<int>(
              initialValue: points[playerId],
              hint: Text('选择点数'),
              items: options.map((option) {
                final int value = int.parse(option);
                return DropdownMenuItem(
                  value: value,
                  child: Text('$value'),
                );
              }).toList(),
              onChanged: (int? newValue) => onChanged(playerId, newValue),
              isExpanded: true,
            ),
            SizedBox(height: 8),
          ],
        );
      }),
    ];
  }

  List<Widget> _buildCardWidgets(String cardName) {
    if (cardName == CardId.endCrystal.id) {
      return [
        ..._buildIntDropdownGroup(
          label: '水晶2d4损血',
          value: _crystalSelf,
          options: _endCrystalOptions,
          onChanged: (int? newValue) {
            setState(() {
              _crystalSelf = newValue ?? 1;
            });
          },
        ),
        ..._buildIntDropdownGroup(
          label: '水晶d8伤害',
          value: _crystalMagic,
          options: _endCrystalOptions,
          onChanged: (int? newValue) {
            setState(() {
              _crystalMagic = newValue ?? 1;
            });
          },
        ),
      ];
    } else if (cardName == CardId.bow.id) {
      return _buildIntDropdownGroup(
        label: '弃牌张数',
        value: _ammoCount,
        options: _bowOptions,
        onChanged: (int? newValue) {
          setState(() {
            _ammoCount = newValue ?? 1;
          });
        },
      );
    } else if (cardName == CardId.redstone.id) {
      return [
        ..._buildStringDropdownGroup(
          label: '延长目标',
          value: _playerProlonged,
          options: _redstonePlayerOptions,
          onChanged: (String? newValue) {
            setState(() {
              _playerProlonged = newValue ?? '';
              _statusProlonged = game.players[newValue]!.status.isEmpty ? '' : game.players[newValue]!.status.keys.first;
              _updateRedstoneOptions();
            });
          },
        ),
        ..._buildStringDropdownGroup(
          label: '状态延长',
          value: _statusProlonged,
          options: _playerProlonged.isEmpty ? [] : _redstoneOptions,
          onChanged: (String? newValue) {
            setState(() {
              _statusProlonged = newValue ?? '';
            });
          },
        ),
      ];
    } else if (cardName == CardId.ascensionStair.id) {
      return _buildPlayerPointGroups(
        title: '混乱点数',
        points: _ascensionPoints,
        options: _ascensionStairOptions,
        onChanged: (playerId, newValue) {
          setState(() {
            _ascensionPoints[playerId] = newValue ?? 1;
          });
        },
      );
    } else if (cardName == CardId.refreshment.id) {
      return [
        ..._buildStringDropdownGroup(
          label: '冷却技能',
          value: _refreshmentChoice,
          options: _refreshmentOptions,
          onChanged: (String? newValue) {
            setState(() {
              _refreshmentChoice = newValue ?? '';
            });
          },
          spacing: 0,
        ),
      ];
    } else if (cardName == CardId.auroraConcussion.id) {
      return _buildPlayerPointGroups(
        title: '极光点数',
        points: _auroraPoints,
        options: _auroraOptions,
        onChanged: (playerId, newValue) {
          setState(() {
            _auroraPoints[playerId] = newValue ?? 1;
          });
        },
      );
    } else if (cardName == CardId.pandoraBox.id) {
      return _buildIntDropdownGroup(
        label: '魔盒点数',
        value: _pandoraPoint,
        options: _pandoraBoxOptions,
        onChanged: (int? newValue) {
          setState(() {
            _pandoraPoint = newValue ?? 1;
          });
        },
      );
    } else if (cardName == CardId.amethyst.id) {
      return _buildIntDropdownGroup(
        label: '折射点数',
        value: _amethystPoint,
        options: _amethystOptions,
        onChanged: (int? newValue) {
          setState(() {
            _amethystPoint = newValue ?? 1;
          });
        },
      );
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final String localeStr = localeProvider.getLocaleNameWithCountry().toLowerCase();
    return AlertDialog(
      title: Text('${LocalizedIDs.labelFor(widget.cardName, localeStr)} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildCardWidgets(widget.cardName),
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