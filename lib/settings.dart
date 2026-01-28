import 'package:flutter/foundation.dart';

/// 抽象卡牌设置基类
abstract class CardSetting {
  /// 卡牌名称
  String get cardName;

  /// 从 JSON 数据初始化设置
  void fromJson(Map<String, dynamic> json);

  /// 将设置转换为 JSON 数据
  Map<String, dynamic> toJson();

  /// 重置为默认值
  void reset();

  /// 复制设置
  CardSetting copyWith();
}

/// 默认卡牌设置类
class DefaultCardSetting extends CardSetting {
  static const String name = "默认";
  
  final Map<String, dynamic> _settings = {};

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    _settings.clear();
    _settings.addAll(json);    
  }

  @override
  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(_settings);
  }

  @override
  void reset() {
    _settings.clear();
  }

  @override
  CardSetting copyWith() {
    final copy = DefaultCardSetting();
    copy._settings.addAll(_settings);
    return copy;
  }

  /// 获取设置值
  dynamic getSetting(String key) {
    return _settings[key];
  }

  /// 设置值
  void setSetting(String key, dynamic value) {
    _settings[key] = value;
  }
}

/// 破片水晶卡设置
class EndCrystalSetting extends CardSetting {
  static const String name = "破片水晶";
  
  int crystalMagic = 1;
  int crystalSelf = 1;

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    crystalMagic = json['crystalMagic'] ?? 1;
    crystalSelf = json['crystalSelf'] ?? 1;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'crystalMagic': crystalMagic,
      'crystalSelf': crystalSelf,
    };
  }

  @override
  void reset() {
    crystalMagic = 1;
    crystalSelf = 1;
  }

  @override
  CardSetting copyWith() {
    return EndCrystalSetting()
      ..crystalMagic = crystalMagic
      ..crystalSelf = crystalSelf;
  }
}

/// 复合弓卡设置
class BowSetting extends CardSetting {
  static const String name = "复合弓";
  
  int ammoCount = 1;

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    ammoCount = json['ammoCount'] ?? 1;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ammoCount': ammoCount,
    };
  }

  @override
  void reset() {
    ammoCount = 1;
  }

  @override
  CardSetting copyWith() {
    return BowSetting()
      ..ammoCount = ammoCount;
  }
}

/// 后日谈卡设置
class RedstoneSetting extends CardSetting {
  static const String name = "后日谈";
  
  String statusProlonged = '';
  String playerProlonged = '';

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    statusProlonged = json['statusProlonged'] ?? '';
    playerProlonged = json['playerProlonged'] ?? '';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'statusProlonged': statusProlonged,
      'playerProlonged': playerProlonged,
    };
  }

  @override
  void reset() {
    statusProlonged = '';
    playerProlonged = '';
  }

  @override
  CardSetting copyWith() {
    return RedstoneSetting()
      ..statusProlonged = statusProlonged
      ..playerProlonged = playerProlonged;
  }
}

/// 混乱力场卡设置
class AscensionStairSetting extends CardSetting {
  static const String name = "混乱力场";
  
  Map<String, int> ascensionPoints = {};

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    if (json['ascensionPoints'] != null) {
      ascensionPoints = Map<String, int>.from(json['ascensionPoints']);
    } else {
      ascensionPoints = {};
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ascensionPoints': ascensionPoints,
    };
  }

  @override
  void reset() {
    ascensionPoints = {};
  }

  @override
  CardSetting copyWith() {
    return AscensionStairSetting()
      ..ascensionPoints = Map<String, int>.from(ascensionPoints);
  }

  void initializePoints(List<String> playerIds) {
    ascensionPoints = {};
    for (var playerId in playerIds) {
      ascensionPoints[playerId] = 1;
    }
  }
}

/// 刷新卡设置
class RefreshmentSetting extends CardSetting {
  static const String name = "刷新";
  
  String refreshmentChoice = '';

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    refreshmentChoice = json['refreshmentChoice'] ?? '';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'refreshmentChoice': refreshmentChoice,
    };
  }

  @override
  void reset() {
    refreshmentChoice = '';
  }

  @override
  CardSetting copyWith() {
    return RefreshmentSetting()
      ..refreshmentChoice = refreshmentChoice;
  }
}

/// 极光震荡卡设置
class AuroraConcussionSetting extends CardSetting {
  static const String name = "极光震荡";
  
  Map<String, int> auroraPoints = {};

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    if (json['auroraPoints'] != null) {
      auroraPoints = Map<String, int>.from(json['auroraPoints']);
    } else {
      auroraPoints = {};
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'auroraPoints': auroraPoints,
    };
  }

  @override
  void reset() {
    auroraPoints = {};
  }

  @override
  CardSetting copyWith() {
    return AuroraConcussionSetting()
      ..auroraPoints = Map<String, int>.from(auroraPoints);
  }

  void initializePoints(List<String> playerIds) {
    auroraPoints = {};
    for (var playerId in playerIds) {
      auroraPoints[playerId] = 1;
    }
  }
}

/// 潘多拉魔盒卡设置
class PandoraBoxSetting extends CardSetting {
  static const String name = "潘多拉魔盒";
  
  int pandoraPoint = 1;

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    pandoraPoint = json['pandoraPoint'] ?? 1;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'pandoraPoint': pandoraPoint,
    };
  }

  @override
  void reset() {
    pandoraPoint = 1;
  }

  @override
  CardSetting copyWith() {
    return PandoraBoxSetting()
      ..pandoraPoint = pandoraPoint;
  }
}

/// 折射水晶卡设置
class AmethystSetting extends CardSetting {
  static const String name = "折射水晶";
  
  int amethystPoint = 1;

  @override
  String get cardName => name;

  @override
  void fromJson(Map<String, dynamic> json) {
    amethystPoint = json['amethystPoint'] ?? 1;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'amethystPoint': amethystPoint,
    };
  }

  @override
  void reset() {
    amethystPoint = 1;
  }

  @override
  CardSetting copyWith() {
    return AmethystSetting()
      ..amethystPoint = amethystPoint;
  }
}

/// 工厂类，用于创建卡牌设置实例
class CardSettingFactory {
  static CardSetting createSetting(String cardName) {
    switch (cardName) {
      case EndCrystalSetting.name:
        return EndCrystalSetting();
      case BowSetting.name:
        return BowSetting();
      case RedstoneSetting.name:
        return RedstoneSetting();
      case AscensionStairSetting.name:
        return AscensionStairSetting();
      case RefreshmentSetting.name:
        return RefreshmentSetting();
      case AuroraConcussionSetting.name:
        return AuroraConcussionSetting();
      case PandoraBoxSetting.name:
        return PandoraBoxSetting();
      case AmethystSetting.name:
        return AmethystSetting();
      default:
        return DefaultCardSetting();
    }
  }

  static CardSetting fromJson(String cardName, Map<String, dynamic> json) {
    final setting = createSetting(cardName);
    setting.fromJson(json);
    return setting;
  }
}

class CardSettingsManager extends ChangeNotifier {
  List<CardSetting?> _cardSettings = [];

  // 获取指定索引的卡牌设置
  CardSetting? getCardSettings(int index) {
    if (index >= 0 && index < _cardSettings.length) {
      return _cardSettings[index];
    }
    return null;
  }

  // 获取指定索引的卡牌设置，并转换为指定类型
  T? getCardSettingsAs<T extends CardSetting>(int index) {
    final setting = getCardSettings(index);
    if (setting is T) {
      return setting;
    }
    return null;
  }

  // 更改指定索引的卡牌设置
  void updateCardSettings(int index, CardSetting settings) {
    if (index >= 0 && index < _cardSettings.length) {
      _cardSettings[index] = settings;
      notifyListeners();
    }
  }

  // 添加新的卡牌设置
  void addNewCard([String? cardName]) {
    if (cardName != null) {
      _cardSettings.add(CardSettingFactory.createSetting(cardName));
    } else {
      _cardSettings.add(CardSettingFactory.createSetting(''));
    }
    notifyListeners();
  }
  
  // 移除指定索引的卡牌设置
  void removeCard(int index) {
    if (index >= 0 && index < _cardSettings.length) {
      _cardSettings.removeAt(index);
      notifyListeners();
    }
  }
  
  // 重置所有设置
  void resetAllSettings() {
    _cardSettings = [];
    notifyListeners();
  }
  
  // 初始化设置管理器，根据当前卡片数量调整设置数组大小
  void initializeWithCardCount(int count) {
    _cardSettings = List.generate(count, (index) => null).toList();
    notifyListeners();
  }

  // 从 JSON 数据恢复设置
  void loadFromJson(List<Map<String, dynamic>?> jsonData, List<String> cardNames) {
    _cardSettings = List.generate(
      jsonData.length, 
      (index) {
        final data = jsonData[index];
        final cardName = cardNames.length > index ? cardNames[index] : null;
        
        if (data != null && cardName != null) {
          return CardSettingFactory.fromJson(cardName, data);
        }
        return null;
      }
    ).toList();
    notifyListeners();
  }

  // 导出为 JSON 数据
  List<Map<String, dynamic>?> exportToJson() {
    return _cardSettings.map((setting) => setting?.toJson()).toList();
  }

  int get length => _cardSettings.length;
  List get settings => _cardSettings;
}