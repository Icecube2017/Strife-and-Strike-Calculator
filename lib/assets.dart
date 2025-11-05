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
  List<String>? cardTypes;
  // List<String>? skillTypes;

  // 初始化所有数据
  Future<void> loadData() async {
    try {
      // 加载语言数据
      String jsonString = await rootBundle.loadString('assets/map.json');
      langMap = json.decode(jsonString);
      for(String key in langMap!.keys.toList()){
        langMap![key] = langMap![key]![0];
      }
      // _logger.d(langMap!['end_crystal']);

      // 加载角色数据
      jsonString = await rootBundle.loadString('assets/character.json');
      characterData = json.decode(jsonString);

      // 加载角色类型数据
      jsonString = await rootBundle.loadString('assets/character_type.json');
      characterTypeData = json.decode(jsonString);

      // 加载再生类型数据
      jsonString = await rootBundle.loadString('assets/regenerate_type.json');
      regenerateTypeData = json.decode(jsonString);

      // 加载卡牌数据
      jsonString = await rootBundle.loadString('assets/cards.json');
      Map<String, dynamic> cardsJson = json.decode(jsonString);
      cardTypes = List<String>.from(cardsJson['道具卡']);

      // 加载技能数据
      jsonString = await rootBundle.loadString('assets/skills.json');
      skillData = json.decode(jsonString);

      // 加载技能效果数据
      //jsonString = await rootBundle.loadString('assets/skill_effects.json');

    } catch (e) {
      _logger.e('加载JSON文件失败: $e');
    }
  }
}

/*Future<Map<String, dynamic>> loadJsonFromAssets(String filePath) async {
  String jsonString = await rootBundle.loadString(filePath);
  return jsonDecode(jsonString);
}*/

// Map characterList =  await loadJsonFromAssets('assets/character.json');
