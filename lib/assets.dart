import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class AssetsManager{
  // 单例模式，确保全局只有一个AssetsManager实例
  static final AssetsManager _instance = AssetsManager._internal();
  factory AssetsManager() => _instance;
  AssetsManager._internal();

  // 日志系统
  static final Logger _logger = Logger();

  Map<String, dynamic>? langMap;
  Map<String, dynamic>? characterData;
  Map<String, dynamic>? characterTypeData;
  Map<String, dynamic>? regenerateTypeData;
  Map<String, dynamic>? skillData;
  Map<String, dynamic>? traitData;
  Map<String, dynamic> statusData = {};
  // 加载就绪标志与完成器，供外部 await
  final Completer<void> _readyCompleter = Completer<void>();
  bool isLoaded = false;
  Future<void> get ready => _readyCompleter.future;
  List<String>? cardTypes;
  // List<String>? skillTypes;

  // 初始化所有数据
  Future<void> loadData() async {
    try {
      // 明确按顺序加载：先语言，再其他依赖语言的资源（如 status）
      await _loadLang();
      await _loadOtherAssets();
    } catch (e) {
      _logger.e('加载JSON文件失败: $e');
      rethrow;
    } finally {
      isLoaded = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  // 将语言加载拆出，确保先执行
  Future<void> _loadLang() async {
    String jsonString = await rootBundle.loadString('assets/map.json');
    langMap = json.decode(jsonString);
    for (String key in langMap!.keys.toList()) {
      langMap![key] = langMap![key]![0];
    }
  }

  // 其他资源的加载，依赖 langMap 已经准备好
  Future<void> _loadOtherAssets() async {
    String jsonString;

    // 加载角色数据
    jsonString = await rootBundle.loadString('assets/character.json');
    characterData = json.decode(jsonString);

    // 加载角色类型数据
    jsonString = await rootBundle.loadString('assets/character_type.json');
    characterTypeData = json.decode(jsonString);

    // 加载行动点回复类型数据
    jsonString = await rootBundle.loadString('assets/regenerate_type.json');
    regenerateTypeData = json.decode(jsonString);

    // 加载卡牌数据
    jsonString = await rootBundle.loadString('assets/cards.json');
    Map<String, dynamic> cardsJson = json.decode(jsonString);
    cardTypes = List<String>.from(cardsJson['道具卡']);

    // 加载技能数据
    jsonString = await rootBundle.loadString('assets/skills.json');
    skillData = json.decode(jsonString);

    // 加载特质数据
    jsonString = await rootBundle.loadString('assets/traits.json');
    traitData = json.decode(jsonString);

    // 加载状态数据（此处依赖 langMap 已准备）
    jsonString = await rootBundle.loadString('assets/status.json');
    Map<String, dynamic>? statusDataRaw = json.decode(jsonString);
    for (String key in statusDataRaw!.keys.toList()) {
      final mappedKey = (langMap != null && langMap![key] != null)
          ? langMap![key].toString()
          : key;
      if (langMap == null || langMap![key] == null) {
        _logger.w('缺少 status 映射的翻译，使用原 key 回退: $key');
      }
      statusData[mappedKey] = statusDataRaw[key];
    }
  }
}

/*Future<Map<String, dynamic>> loadJsonFromAssets(String filePath) async {
  String jsonString = await rootBundle.loadString(filePath);
  return jsonDecode(jsonString);
}*/

// Map characterList =  await loadJsonFromAssets('assets/character.json');
