import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/assets.dart';

// 攻击特效设置对话框组件
class AttackEffectSettingsDialog extends StatefulWidget {
  final AttackEffect effect;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final String? source, target;

  const AttackEffectSettingsDialog({
    Key? key,
    required this.effect,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.source,
    this.target,
  }) : super(key: key);

  @override
  _AttackEffectSettingsDialogState createState() => _AttackEffectSettingsDialogState();
}

class _AttackEffectSettingsDialogState extends State<AttackEffectSettingsDialog> {
  late Map<String, dynamic> _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  // 烛焱
  final List<String> _lumenFlareOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _lumenFlarePoint = 1;
  // 障目
  final List<String> _oculusVeilOptions = ['1', '2'];
  int _oculusVeilPoint = 1;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.initialSettings);
    _lumenFlarePoint = _settings['lumenFlarePoint'] ?? 1;
    _oculusVeilPoint = _settings['oculusVeilPoint'] ?? 1;
    // 从全局 Provider 获取已加载的语言/资源映射
    final assets = Provider.of<AssetsManager>(context, listen: false);
    langMap = assets.langMap;
  }

  void _saveSettings() {
    _settings['lumenFlarePoint'] = _lumenFlarePoint;
    _settings['oculusVeilPoint'] = _oculusVeilPoint;
    widget.onSettingsChanged(_settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.effect.effectId} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 根据不同的攻击特效显示不同的设置选项
            if (widget.effect == AttackEffect.lumenFlare) ...[
              Text('烛焱点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _lumenFlarePoint,
                hint: Text('烛焱点数'),
                items: _lumenFlareOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _lumenFlarePoint = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ] else if (widget.effect == AttackEffect.oculusVeil) ...[
              Text('障目点数', style: TextStyle(fontWeight: FontWeight.bold)), 
              DropdownButtonFormField<int>(
                value: _oculusVeilPoint,
                hint: Text('障目点数'),
                items: _oculusVeilOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _oculusVeilPoint = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
            ] else ...[
              Text('暂无设置选项'),
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

// 防守特效设置对话框组件
class DefenceEffectSettingsDialog extends StatefulWidget {
  final DefenceEffect effect;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final String? source, target;

  const DefenceEffectSettingsDialog({
    Key? key,
    required this.effect,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.source,
    this.target,
  }) : super(key: key);

  @override
  _DefenceEffectSettingsDialogState createState() => _DefenceEffectSettingsDialogState();
}

class _DefenceEffectSettingsDialogState extends State<DefenceEffectSettingsDialog> {
  late Map<String, dynamic> _settings;

  Game game = GameManager().game;

  Map<String, dynamic> ?langMap;

  // 蚀凛
  final List<String> _erodeGelidOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int _erodeGelidPoint = 1;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.initialSettings);    
    _erodeGelidPoint = _settings['erodeGelidPoint'] ?? 1;
  }

  void _saveSettings() {    
    _settings['erodeGelidPoint'] = _erodeGelidPoint;
    widget.onSettingsChanged(_settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.effect.effectId} 设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 根据不同的攻击特效显示不同的设置选项
            if (widget.effect == DefenceEffect.erodeGelid) ...[
              Text('蚀凛点数', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<int>(
                value: _erodeGelidPoint,
                hint: Text('蚀凛点数'),
                items: _erodeGelidOptions.map((String item) {
                  int value = int.parse(item);
                  return DropdownMenuItem(
                    value: value,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _erodeGelidPoint = newValue ?? 1;
                  });
                },
                isExpanded: true,
              ),
              SizedBox(height: 16),
            ] else ...[
              Text('暂无设置选项'),
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