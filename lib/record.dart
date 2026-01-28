import 'core.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

enum RecordType {
  action,
  skill,
  trait,
  damage,
  heal,
  status,
  attribute
}

abstract class GameRecord {
  final RecordType type;
  final GameTurn turn;

  GameRecord({
    required this.type,
    required this.turn,  
  });

  Map<String, dynamic> toJson();
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    switch (RecordType.values.firstWhere((e) => e.name == json['type'])) {
      case RecordType.action:
        return ActionRecord.fromJson(json);
      case RecordType.skill:
        return SkillRecord.fromJson(json);
      case RecordType.trait:
        return TraitRecord.fromJson(json);
      case RecordType.damage:
        return DamageRecord.fromJson(json);
      case RecordType.heal:
        return HealRecord.fromJson(json);
      case RecordType.status:
        return StatusRecord.fromJson(json);
      case RecordType.attribute:
        return AttributeRecord.fromJson(json);
    }
  }
}

class ActionRecord extends GameRecord { 
  final String source;
  final String target;
  final int point;
  final List<String> cards;
  final bool attacked;

  ActionRecord({
    required this.source,
    required this.target,
    required this.point,
    required this.cards,
    required this.attacked,
    required super.turn
  }) : super(type: RecordType.action);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'action',
      'source': source,
      'target': target,
      'point': point,
      'cards': cards,
      'attacked': attacked,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra
    };
  }

  factory ActionRecord.fromJson(Map<String, dynamic> json) {
    return ActionRecord(
      source: json['source'],
      target: json['target'],
      point: json['point'],
      cards: List<String>.from(json['cards']),
      attacked: json['attacked'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class SkillRecord extends GameRecord { 
  final String source;
  final List<String> targets;
  final String name;
  final Map<String, dynamic> params;

  SkillRecord({
    required this.source,
    required this.targets,
    required this.name,
    required this.params,
    required super.turn,
  }) : super(type: RecordType.skill);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'skill',
      'source': source,
      'targets': targets,
      'name': name,
      'params': params,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra,
    };
  }

  factory SkillRecord.fromJson(Map<String, dynamic> json) {
    return SkillRecord(
      source: json['source'],
      targets: List<String>.from(json['targets']),
      name: json['name'],
      params: json['params'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class TraitRecord extends GameRecord { 
  final String source;
  final List<String> targets;
  final String name;
  final Map<String, dynamic> params;

  TraitRecord({
    required this.source,
    required this.targets,
    required this.name,
    required this.params,
    required super.turn,
  }) : super(type: RecordType.trait);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'trait',
      'source': source,
      'targets': targets,
      'name': name,
      'params': params,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra,
    };
  }

  factory TraitRecord.fromJson(Map<String, dynamic> json) {
    return TraitRecord(
      source: json['source'],
      targets: List<String>.from(json['targets']),
      name: json['name'],
      params: json['params'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class DamageRecord extends GameRecord { 
  final String source;
  final String target;  
  final int damage;
  final DamageType damageType;
  final String tag;

  DamageRecord({
    required this.source,
    required this.target,    
    required this.damage,
    required this.damageType,
    required this.tag,
    required super.turn,
  }) : super(type: RecordType.damage);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'damage',
      'source': source,
      'target': target,
      'damage': damage,
      'damageType': damageType.name,
      'tag': tag,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra,
    };
  }

  factory DamageRecord.fromJson(Map<String, dynamic> json) {
    return DamageRecord(
      source: json['source'],
      target: json['target'],
      damage: json['damage'],
      damageType: DamageType.values.firstWhere((e) => e.name == json['damageType']),
      tag: json['tag'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class HealRecord extends GameRecord { 
  final String source;
  final String target;  
  final int heal;
  final DamageType healType;
  final String tag;

  HealRecord({
    required this.source,
    required this.target,    
    required this.heal,
    required this.healType,
    required this.tag,
    required super.turn,
  }) : super(type: RecordType.heal);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'heal',
      'source': source,
      'target': target,
      'heal': heal,
      'healType': healType.name,
      'tag': tag,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra,
    };
  }

  factory HealRecord.fromJson(Map<String, dynamic> json) {
    return HealRecord(
      source: json['source'],
      target: json['target'],
      heal: json['heal'],
      healType: DamageType.values.firstWhere((e) => e.name == json['healType']),
      tag: json['tag'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class StatusRecord extends GameRecord { 
  final String source;
  final String target;  
  final String name;
  final List<int> paramsOld;
  final List<int> paramsNew;
  final String tag;

  StatusRecord({
    required this.source,
    required this.target,    
    required this.name,
    required this.paramsOld,
    required this.paramsNew,
    required this.tag,
    required super.turn,
  }) : super(type: RecordType.status);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'status',
      'source': source,
      'target': target,
      'name': name,
      'paramsOld': paramsOld,
      'paramsNew': paramsNew,
      'tag': tag,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra,
    };
  }

  factory StatusRecord.fromJson(Map<String, dynamic> json) {
    return StatusRecord(
      source: json['source'],
      target: json['target'],
      name: json['name'],
      paramsOld: List<int>.from(json['paramsOld']), 
      paramsNew: List<int>.from(json['paramsNew']), 
      tag: json['tag'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class AttributeRecord extends GameRecord { 
  final String source;
  final String target;  
  final String name;
  final int valueOld;
  final int valueNew;
  final String tag;

  AttributeRecord({
    required this.source,
    required this.target,    
    required this.name,
    required this.valueOld,
    required this.valueNew,
    required this.tag,
    required super.turn,
  }) : super(type: RecordType.attribute);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'attribute',
      'source': source,
      'target': target,
      'name': name,
      'valueOld': valueOld,
      'valueNew': valueNew,
      'tag': tag,
      'round': turn.round,
      'turn': turn.turn,
      'extra': turn.extra,
    };
  }

  factory AttributeRecord.fromJson(Map<String, dynamic> json) {
    return AttributeRecord(
      source: json['source'],
      target: json['target'],
      name: json['name'],
      valueOld: json['valueOld'],
      valueNew: json['valueNew'],
      tag: json['tag'],
      turn: GameTurn(
        round: json['round'],
        turn: json['turn'],
        extra: json['extra']
      ),
    );
  }
}

class RecordProvider with ChangeNotifier {
  List<GameRecord> _records = [];
  final int _maxRecordSize = 1000;

  List<GameRecord> get records => _records;

  // 添加记录
  void addRecord(GameRecord record) {
    _records.add(record);
    if (_records.length > _maxRecordSize) {
      _records.removeAt(0);
    }
    notifyListeners();
  }

  // 添加指定类型的记录
  void addActionRecord(GameTurn turn, String source, String target, int point, List<String> cards, bool attacked) {
    addRecord(ActionRecord(source: source, target: target, point: point, cards: cards, attacked: attacked, turn: turn));
  }

  void addSkillRecord(GameTurn turn, String source, List<String> targets, String name, Map<String, dynamic> params) {
    addRecord(SkillRecord(source: source, targets: targets, name: name, params: params, turn: turn));
  }

  void addTraitRecord(GameTurn turn, String source, List<String> targets, String name, Map<String, dynamic> params) {
    addRecord(TraitRecord(source: source, targets: targets, name: name, params: params, turn: turn));
  }

  void addDamageRecord(GameTurn turn, String source, String target, int damage, DamageType damageType, String tag) {
    addRecord(DamageRecord(source: source, target: target, damage: damage, damageType: damageType, tag: tag, turn: turn));
  }

  void addHealRecord(GameTurn turn, String source, String target, int heal, DamageType healType, String tag) {
    addRecord(HealRecord(source: source, target: target, heal: heal, healType: healType, tag: tag, turn: turn));
  }

  void addStatusRecord(GameTurn turn, String source, String target, String name, List<int> paramsOld, List<int> paramsNew, String tag) {
    addRecord(StatusRecord(source: source, target: target, name: name, paramsOld: paramsOld, paramsNew: paramsNew, tag: tag, turn: turn));
  }

  void addAttributeRecord(GameTurn turn, String source, String target, String name, int valueOld, int valueNew, String tag) {
    addRecord(AttributeRecord(source: source, target: target, name: name, valueOld: valueOld, valueNew: valueNew, tag: tag, turn: turn));
  }

  // 清空记录
  void clearRecords() {
    _records.clear();
    notifyListeners();
  }

  // 移除与传入记录匹配的记录
  void removeRecord(GameRecord record) {
    final String targetJson = jsonEncode(record.toJson());
    final int index = _records.indexWhere((r) => jsonEncode(r.toJson()) == targetJson);
    if (index != -1) {
      _records.removeAt(index);
      notifyListeners();
    }
  }

  // 获取满足指定条件的记录
  List<GameRecord> getFilteredRecords({RecordType? type, String? source, String? target,
    GameTurn? startTurn,GameTurn? endTurn}) {
    return _records.where((record) {
      // 类型过滤
      if (type != null && record.type != type) {
        return false;
      }

      // 来源过滤
      if (source != null) {
        bool matchSource = false;
        switch (record.type) {
          case RecordType.action:
            matchSource = (record as ActionRecord).source == source;
            break;
          case RecordType.skill:
            matchSource = (record as SkillRecord).source == source;
            break;
          case RecordType.trait:
            matchSource = (record as TraitRecord).source == source;
            break;
          case RecordType.damage:
            matchSource = (record as DamageRecord).source == source;
            break;
          case RecordType.heal:
            matchSource = (record as HealRecord).source == source;
            break;
          case RecordType.status:
            matchSource = (record as StatusRecord).source == source;
            break;
          case RecordType.attribute:
            matchSource = (record as AttributeRecord).source == source;
            break;
        }
        if (!matchSource) return false;
      }

      // 目标过滤
      if (target != null) {
        bool matchTarget = false;
        switch (record.type) {
          case RecordType.action:
            matchTarget = (record as ActionRecord).target == target;
            break;
          case RecordType.skill:
            matchTarget = (record as SkillRecord).targets.contains(target);
            break;
          case RecordType.trait:
            matchTarget = (record as TraitRecord).targets.contains(target);
            break;
          case RecordType.damage:
            matchTarget = (record as DamageRecord).target == target;
            break;
          case RecordType.heal:
            matchTarget = (record as HealRecord).target == target;
            break;
          case RecordType.status:
            matchTarget = (record as StatusRecord).target == target;
            break;
          case RecordType.attribute:
            matchTarget = (record as AttributeRecord).target == target;
            break;
        }
        if (!matchTarget) return false;
      }

      // 时间范围过滤
      if (startTurn != null && record.turn < startTurn) {
        return false;
      }
      
      if (endTurn != null && record.turn > endTurn) {
        return false;
      }

      return true;
    }).toList();
  }

  // 序列化记录为JSON字符串
  String serializeRecords() {
    List<Map<String, dynamic>> jsonRecords = _records.map((record) => record.toJson()).toList();
    return jsonEncode(jsonRecords);
  }

  // 从JSON字符串中反序列化记录
  void deserializeRecords(String json) {
    List<dynamic> jsonList = jsonDecode(json);
    _records = jsonList.map((json) => GameRecord.fromJson(Map<String, dynamic>.from(json))).toList();
    notifyListeners();
  }

  // 获取最新的记录
  GameRecord? getLatestRecord() {
    return _records.isNotEmpty ? _records.last : null;
  }

  // 获取指定类型的最新记录
  GameRecord? getLatestRecordByType(RecordType type) {
    return _records.reversed.where((record) => record.type == type).cast<GameRecord?>().firstWhere((_) => true, orElse: () => null);
  }

  // 移除指定轮次之后的记录
  void removeRecordsAfterTurn(GameTurn turn) {
    _records.removeWhere((record) {
      // 如果记录的轮次大于指定轮次，则移除
      if (record.turn > turn) {
        return true;
      }
      return false;
    });
  notifyListeners();
  }
}