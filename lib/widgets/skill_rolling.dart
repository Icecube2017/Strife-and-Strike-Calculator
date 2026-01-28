import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_calculator/assets.dart';

class SkillRollingDialog extends StatefulWidget {
  const SkillRollingDialog({super.key});

  @override
  State<SkillRollingDialog> createState() => _SkillRollingDialogState();
}

class _SkillRollingDialogState extends State<SkillRollingDialog> {
  List<String> _pool = [];
  String _last = '';
  final Random _rnd = Random();
  bool _visible = false;
  Timer? _fadeTimer;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _resetPoolFromAssets();
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _clearTimer?.cancel();
    super.dispose();
  }

  void _resetPoolFromAssets() {
    final assets = Provider.of<AssetsManager>(context, listen: false);
    final Set<String> deck = assets.skillDeckData;
    setState(() {
      _pool = deck.toList(growable: true);
      _showTemporaryMessage('已重置抽取池，共 ${_pool.length} 项');
    });
  }

  void _drawOne() {
    if (_pool.isEmpty) {
      _showTemporaryMessage('已抽完');
      return;
    }
    final idx = _rnd.nextInt(_pool.length);
    final picked = _pool.removeAt(idx);
    _showTemporaryMessage(picked);
  }

  void _showTemporaryMessage(String msg) {
    // cancel previous timers
    _fadeTimer?.cancel();
    _clearTimer?.cancel();
    setState((){
      _last = msg;
      _visible = true;
    });

    // after delay, start fade
    _fadeTimer = Timer(const Duration(seconds: 2), () {
      setState((){
        _visible = false;
      });
      // clear text after fade duration
      _clearTimer = Timer(const Duration(milliseconds: 500), () {
        setState((){
          _last = '';
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('技能抽取'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _visible ? 1.0 : 0.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_last, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _drawOne,
                child: const Text('抽取'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _resetPoolFromAssets,
                child: const Text('重置'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭')),
      ],
    );
  }
}
