import 'dart:math';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/core.dart';
//import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/logger.dart';
import 'package:sns_calculator/settings.dart';

// 全局状态效果
class GlobalCountdown{
  // 达摩克利斯之剑
  int damocles = 0;
  int reinforcedDamocles = 0;
  // 失乐园
  int eden = 0;
  int reinforcedEden = 0;
  // 额外回合
  int extraTurn = 0;
  // 反重力
  int antiGravity = 0;
  // 高淼【轻捷妙手】
  String deftTouchSkill = '';
  String deftTouchTarget = '';
}

class Character{
  String id;
  int maxHealth, attack, defence, maxMove, moveRegen, regenType, regenTurn;
  int health = 0, armor = 0, movePoint = 0, cardCount = 2, maxCard = 6, actionTime = 0, jumpedTurn = 0;
  int damageReceivedTotal = 0, damageDealtTotal = 0, damageDealtRound = 0, damageReceivedRound = 0,
  damageReceivedTurn = 0, damageDealtTurn = 0;
  int cureReceivedTotal = 0, cureDealtTotal = 0, cureReceivedRound = 0, cureDealtRound = 0,
  cureReceivedTurn = 0, cureDealtTurn = 0;
  bool isDead = false;  
  Map<String, CharaStatus> status = {}, hiddenStatus = {};
  //Map<String, int> skill = {}, skillStatus = {};
  Map<String, CharaSkill> skill = {};
  Map<String, CharaTrait> trait = {};

  Character(this.id, this.maxHealth, this.attack, this.defence, this.movePoint, 
  this.maxMove, this.moveRegen, this.regenType, this.regenTurn){
    health = maxHealth;
    
    if (possessingSkills.containsKey(id)) {
      for (var sk in possessingSkills[id]!) {
        addSkillData(sk, cooldown: 0, isAble: true);
      }
    }
    if (possessingTraits.containsKey(id)) {
      for (var tr in possessingTraits[id]!) {
        addTraitData(tr, castCount: 0, maxCast: traitToType[tr]!.useCount, isAble: true);
      }
    }

    if (id == CharacterId.ennoia.id) {
      addHiddenStatusData('ennoia', intensity: 0, layer: -1);
    }
  }

  bool hasSkill(String sk){ 
    return skill.keys.contains(sk);
  }

  void addSkillData(String sk, {int cooldown = -1, bool isAble = true}) { 
    if (!skill.containsKey(sk)) {
      skill[sk] = CharaSkill(
        name: sk,
        cooldown: cooldown,
        isAble: isAble,
      );
    }
  }

  void setSkillData(String sk, {int cooldown = -1, bool isAble = true}) { 
    if (skill.containsKey(sk)) {
      skill[sk] = CharaSkill(
        name: sk,
        cooldown: cooldown == -1 ? skill[sk]!.cooldown : cooldown,
        isAble: isAble,
      );
    }
  }

  bool hasTrait(String tr){ 
    return trait.keys.contains(tr);
  }

  void addTraitData(String tr, {int castCount = -1, int maxCast = -1, bool isAble = true}) { 
    if (!trait.containsKey(tr)) {
      trait[tr] = CharaTrait(
        name: tr,
        castCount: castCount,
        maxCast: maxCast,
        isAble: isAble,
      );
      if (tr == TraitId.escaping.id) {
        addHiddenStatusData('gugu', intensity: 0, layer: -1);
      }
      else if (tr == TraitId.primordialHorologe.id) {
        addHiddenStatusData('horologe', intensity: 0, layer: -1);
      }
    }
  }

  void setTraitData(String tr, {int castCount = -1, int maxCast = -1, bool isAble = true}) { 
    if (trait.containsKey(tr)) {
      trait[tr] = CharaTrait(
        name: tr,
        castCount: castCount == -1 ? trait[tr]!.castCount : castCount,
        maxCast: maxCast == -1 ? trait[tr]!.maxCast : maxCast,
        isAble: isAble,
      );
    }
  }

  bool hasStatus(String stat){
    return status.keys.contains(stat);
  }

  int getStatusIntData(String stat, StatusData dataType) {
    try {
      var statusData = status[stat];
      if (statusData != null) {
        switch (dataType) {
          case StatusData.intensity:
            return statusData.intensity;
          case StatusData.layer:
            return statusData.layer;
          case StatusData.layerFraction:
            return statusData.layerFraction;
          case StatusData.intData:
            return statusData.intData;
          case StatusData.strData:
            return -1;
        }
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  String getStatusStringData(String stat, StatusData dataType){
    try {
      var statusData = status[stat];
      if (statusData != null) {
        if (dataType == StatusData.strData) {
          return statusData.strData;
        }
        else {
          return '';
        }
      }
      return '';
    } catch (e) {
      return '';
    } 
  }

  void addStatusData(String stat, {int intensity = -1, int layer = -1, int layerFraction = -1, int intData = -1, String strData = ''}) { 
    if (!status.containsKey(stat)) {
      status[stat] = CharaStatus(
        name: stat,
        intensity: intensity,
        layer: layer,
        layerFraction: layerFraction,
        intData: intData,
        strData: strData,
      );
    }
  }

  void setStatusData(String stat, {int intensity = -1, int layer = -1, int layerFraction = -1, int intData = -1, String strData = ''}) {
    if (status.containsKey(stat)) {
      status[stat] = CharaStatus(
        name: stat,
        intensity: intensity == -1 ? status[stat]!.intensity : intensity,
        layer: layer == -1 ? status[stat]!.layer : layer,
        layerFraction: layerFraction == -1 ? status[stat]!.layerFraction : layerFraction,
        intData: intData == -1 ? status[stat]!.intData : intData,
        strData: strData == '' ? status[stat]!.strData : strData,
      );
    }
  }

  void increaseStatusData(String stat, {int intensity = 0, int layer = 0, int layerFraction = 0, int intData = 0}) {
    if (status.containsKey(stat)) {
      status[stat] = CharaStatus(
        name: stat,
        intensity: status[stat]!.intensity + intensity < 0 ? status[stat]!.intensity : status[stat]!.intensity + intensity,
        layer: status[stat]!.layer + layer < 0 ? status[stat]!.layer : status[stat]!.layer + layer,
        layerFraction: status[stat]!.layerFraction + layerFraction < 0 ? status[stat]!.layerFraction : status[stat]!.layerFraction + layerFraction,
        intData: status[stat]!.intData + intData,
        strData: status[stat]!.strData,
      );
    }
  }

  bool hasHiddenStatus(String stat){ 
    return hiddenStatus.keys.contains(stat);
  }

  int getHiddenStatusIntData(String stat, StatusData dataType){ 
    try {
      var statusData = hiddenStatus[stat];
      if (statusData != null) {
        switch (dataType) {
          case StatusData.intensity:
            return statusData.intensity;
          case StatusData.layer:
            return statusData.layer;
          case StatusData.layerFraction:
            return statusData.layerFraction;
          case StatusData.intData:
            return statusData.intData;
          case StatusData.strData:
            return -1;
        }
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  String getHiddenStatusStringData(String stat, StatusData dataType){ 
    try {
      var statusData = hiddenStatus[stat];
      if (statusData != null) {
        if (dataType == StatusData.strData) {
          return statusData.strData;
        }
        else {
          return '';
        }
      }
      return '';
    }
    catch (e) {
      return '';
    }
  }

  void addHiddenStatusData(String stat, {int intensity = -1, int layer = -1, int layerFraction = -1, int intData = -1, String strData = ''}) { 
    if (!hiddenStatus.containsKey(stat)) {
      hiddenStatus[stat] = CharaStatus(
        name: stat,
        intensity: intensity,
        layer: layer,
        layerFraction: layerFraction,
        intData: intData,
        strData: strData,
      );
    }
  }

  void setHiddenStatusData(String stat, {int intensity = -1, int layer = -1, int layerFraction = -1, int intData = -1, String strData = ''}) {
    if (hiddenStatus.containsKey(stat)) {
      hiddenStatus[stat] = CharaStatus(
        name: stat,
        intensity: intensity == -1 ? hiddenStatus[stat]!.intensity : intensity,
        layer: layer == -1 ? hiddenStatus[stat]!.layer : layer,
        layerFraction: layerFraction == -1 ? hiddenStatus[stat]!.layerFraction : layerFraction,
        intData: intData == -1 ? hiddenStatus[stat]!.intData : intData,
        strData: strData == '' ? hiddenStatus[stat]!.strData : strData,
      );
    }
  }

  void increaseHiddenStatusData(String stat, {int intensity = 0, int layer = 0, int layerFraction = 0, int intData = 0}) { 
    if (hiddenStatus.containsKey(stat)) {
      hiddenStatus[stat] = CharaStatus(
        name: stat,
        intensity: hiddenStatus[stat]!.intensity + intensity < 0 ? hiddenStatus[stat]!.intensity : hiddenStatus[stat]!.intensity + intensity,
        //layer: hiddenStatus[stat]!.layer + layer < 0 ? hiddenStatus[stat]!.layer : hiddenStatus[stat]!.layer + layer,
        layer: hiddenStatus[stat]!.layer + layer,
        layerFraction: hiddenStatus[stat]!.layerFraction + layerFraction < 0 ? hiddenStatus[stat]!.layerFraction : hiddenStatus[stat]!.layerFraction + layerFraction,
        intData: hiddenStatus[stat]!.intData + intData,
        strData: hiddenStatus[stat]!.strData,
      );
    }
  }
}

final Character emptyCharacter = Character('empty', 131072, 0, 0, 0, 0, 0, 0, 0);

class Game extends ChangeNotifier{
  String id;
  GameType gameType;
  GameState gameState = GameState.waiting;
  List<String> gameSequence = [];
  Map<String, Character> players = {};
  var playerDied = {};
  Map<int, Set<String>> teams = {};
  int playerCount = 0, playerDiedCount = 0, turn = 0, round = 1, teamCount = 0, extra = 0;
  List<GameTurn> gameTurnList = [GameTurn(round: 1, turn: 0, extra: 0)];
  GlobalCountdown countdown = GlobalCountdown();
  final Logger _logger = Logger(printer: PrettyPrinter(), output: MultiOutput([ConsoleOutput()]));

  /*final AssetsManager assets = AssetsManager();
  Map<String, dynamic>? langMap;
  Map<String, dynamic>? skillCooldown;
  Map<String, dynamic>? statusInfo;
  Map<String, dynamic>? tagData;*/

  RecordProvider? _recordProvider;
  HistoryProvider? _historyProvider;
  GameLogger? _gameLogger;

  Game(this.id, this.gameType){
    players['empty'] = emptyCharacter;
    //_initializeAssets();
  }

  /*Future<void> _initializeAssets() async {
    // await assets.loadData();
    langMap = assets.langMap; // Updated to use assets.langMap directly
    skillCooldown = assets.skillData;
    statusInfo = assets.statusData;
    tagData = assets.tagData;
  }*/

  // 设置行动记录
  void setRecordProvider(RecordProvider recordProvider){
    _recordProvider = recordProvider;
  }

  // 设置历史记录
  void setHistoryProvider(HistoryProvider historyProvider){
    _historyProvider = historyProvider;
  }

  void setGameLogger(GameLogger logger){
    _gameLogger = logger;
  }

  GameTurn getGameTurn() {
    return GameTurn(round: round, turn: turn, extra: extra);
  }

  GameTurn getPreviousGameTurn() {
    return gameTurnList.length >= 2 ? gameTurnList[gameTurnList.length - 2] : getGameTurn();
  }

  GameTurn getStartGameTurn(int round) {
    return gameTurnList.last.round >= round && round > 0 ? GameTurn(round: round, turn: 1, extra: 0) : getGameTurn();
  }

  GameTurn getEndGameTurn(int round) { 
    return gameTurnList.last.round > round && round > 0 ? gameTurnList[gameTurnList.indexOf(GameTurn(round: round + 1, turn: 1, extra: 0)) - 1] : getGameTurn();
  }

  void clearGame(){
    players.clear();
    gameSequence.clear();
    playerDied.clear();
    teams.clear();
    playerCount = 0;
    playerDiedCount = 0;
    turn = 0;
    round = 1;
    extra = 0;
    teamCount = 0;
    gameTurnList = [GameTurn(round: 1, turn: 0, extra: 0)];
    countdown = GlobalCountdown();
    gameState = GameState.waiting;
    players['empty'] = emptyCharacter;
    refresh();
  }

  void addPlayer(Character character) {
    if (players.containsKey(character.id)){
      return;
    }

    players[character.id] = character;
    gameSequence.add(character.id);
    playerCount++;
    refresh();
  }

  void removePlayer(Character character) {
    if (!players.containsKey(character.id)){
      return;
    }

    players.remove(character.id);
    gameSequence.remove(character.id);
    // 从所有队伍中移除该玩家
    for (var entry in teams.entries){
      entry.value.remove(character.id);
    }
    playerCount--;
    refresh();
  }

  bool isCharacterInGame(String charaId){ 
    if (!players.containsKey(charaId)) return false;
    return !players[charaId]!.isDead;
  }

  // 添加一个队伍并返回队伍 id
  int addTeam(){
    teamCount += 1;

    List<int> teamIds = teams.keys.toList();
    teamIds.sort();
    int teamId = teamCount;
    for (int i = 0; i < teamIds.length; i++) {
      if (teamIds[i] != i + 1) {
        teamId = i + 1;
        break;
      }
    }

    teams[teamId] = <String>{};
    return teamId;
  }

  // 删除指定队伍
  void removeTeam(int teamId){
    if (teams.containsKey(teamId)){
      teams.remove(teamId);
      teamCount = teams.length;
    }
  }

  // 将玩家加入队伍
  void addPlayerToTeam(int teamId, String playerId){
    if (!players.containsKey(playerId)) return;
    // 从其它队伍移除
    for (var entry in teams.entries){
      entry.value.remove(playerId);
    }
    teams.putIfAbsent(teamId, () => <String>{});
    teams[teamId]!.add(playerId); // Added player to team
  }

  // 从队伍移除玩家
  void removePlayerFromTeam(int teamId, String playerId){
    if (teams.containsKey(teamId)){
      teams[teamId]!.remove(playerId);
    }
  }

  // 获取玩家所在队伍id
  int? getPlayerTeam(String playerId){
    for (var e in teams.entries){
      if (e.value.contains(playerId)) return e.key;
    }
    return null;
  }

  // 判断两个玩家是否是队友
  bool isTeammate (String source, String target) { 
    return source != target && getPlayerTeam(source) == getPlayerTeam(target) && gameType == GameType.team && source != 'empty' && target != 'empty';
  }

  // 判断两个玩家是否是敌人
  bool isEnemy (String source, String target) { 
    return source != target && (gameType == GameType.single || (getPlayerTeam(source) != getPlayerTeam(target) && gameType == GameType.team)) && source != 'empty' && target != 'empty';
  }

  // 切换游戏类型
  void toggleGameType(){
    var types = GameType.values;
    int idx = types.indexOf(gameType);
    idx = (idx + 1) % types.length;
    gameType = types[idx];
    refresh();
  }

  void addAttribute(String charaId, AttributeType type, int value){
    Character chara = players[charaId]!;
    int attValue = value;
    if(type == AttributeType.health){
      attValue = chara.health + attValue > chara.maxHealth ? chara.maxHealth - chara.health : attValue;
      chara.health += attValue;
    }
    else if(type == AttributeType.maxhp){
      chara.maxHealth += attValue;
      //chara.health = chara.health > chara.maxHealth ? chara.maxHealth : chara.health;
    }
    else if(type == AttributeType.attack){chara.attack += attValue;}
    else if(type == AttributeType.defence){chara.defence += attValue;}
    else if(type == AttributeType.armor){
      chara.armor += attValue;
      // 沈姝华【纯洁之爱】
      if (isCharacterInGame(CharacterId.shenShuhua.id) && chara.armor == 0) {
        castTrait(CharacterId.shenShuhua.id, [CharacterId.shenShuhua.id], TraitId.innocentLove.id, {'type': 1});
      }
      // K97【二进制噪声】
      if (chara.hasTrait(TraitId.binary.id)) {
        castTrait(charaId, [charaId], TraitId.binary.id, {'type': 2, 'armor': chara.armor, 'attValue': attValue});
      }
    }
    else if(type == AttributeType.movepoint){
      attValue = chara.movePoint + attValue > chara.maxMove ? chara.maxMove - chara.movePoint : attValue;
      attValue = chara.movePoint + attValue < 0 ? -chara.movePoint : attValue;
      chara.movePoint += attValue;
      // 云津【云系祝乐】
      if (charaId == CharacterId.clouddamp.id) {
        castTrait(charaId, [charaId], TraitId.celestialJoy.id, {'type': 2, 'movepoint': -attValue});
      }
      // 卡拉卡【友情防守】
      if (charaId == CharacterId.karak.id && chara.movePoint == chara.maxMove) {
        castTrait(charaId, [charaId], TraitId.buddyBlock.id, {'type': 1});
      }
    }
    else if(type == AttributeType.maxmove){
      chara.maxMove += attValue;
    }
    else if(type == AttributeType.card){
      attValue = chara.cardCount + attValue < 0 ? -chara.cardCount : attValue;
      chara.cardCount += attValue;
      // 蓝文曦【盈亏相济】
      if (chara.hasTrait(TraitId.lossGainEquilibrium.id)) {
        castTrait(charaId, [charaId], TraitId.lossGainEquilibrium.id, {'type': 0, 'count': attValue});
        castTrait(charaId, [charaId], TraitId.lossGainEquilibrium.id, {'type': 1, 'count': attValue});
      }
    }
    else if(type == AttributeType.maxcard){chara.maxCard += attValue;}
    else if(type == AttributeType.dmgdealt) {chara.damageDealtTotal += attValue; chara.damageDealtRound += attValue; chara.damageDealtTurn += attValue;}
    else if(type == AttributeType.dmgreceived) {chara.damageReceivedTotal += attValue; chara.damageReceivedRound += attValue; chara.damageReceivedTurn += attValue;}
    else if(type == AttributeType.curdealt) {chara.cureDealtTotal += attValue; chara.cureDealtRound += attValue; chara.cureDealtTurn += attValue;}
    else if(type == AttributeType.curreceived) {chara.cureReceivedTotal += attValue; chara.cureReceivedRound += attValue; chara.cureReceivedTurn += attValue;}
    else if(type == AttributeType.actiontime) {chara.actionTime += attValue;}
    if ({AttributeType.armor, AttributeType.attack, AttributeType.defence, AttributeType.movepoint, AttributeType.card, 
    AttributeType.maxhp, AttributeType.maxmove, AttributeType.maxcard}.contains(type)) {
      _gameLogger!.addAttributeLog(getGameTurn(), charaId, type.name, attValue);
    }    
  }

  void modifySkillCooldown(String source, String target, String skill, int cooldown) {
    Character targetChara = players[target]!;
    bool isImmune = false;

    if (!isImmune) {
      if (targetChara.hasSkill(skill)) {
        int modifiedCooldown = targetChara.skill[skill]!.cooldown + cooldown < 0 ? 0 : targetChara.skill[skill]!.cooldown + cooldown;
        targetChara.setSkillData(skill, cooldown: modifiedCooldown);
      }
      else {
        targetChara.skill[skill] = CharaSkill(name: skill, cooldown: cooldown, isAble: true);
      }
    }
  }

  void modifyTraitCastCount(String source, String target, String trait, int castCount) {
    Character targetChara = players[target]!;
    bool isImmune = false;

    if (!isImmune) {
      if (targetChara.hasTrait(trait)) {
        int modifiedCastCount = targetChara.trait[trait]!.castCount + castCount < 0 ? 0 : targetChara.trait[trait]!.castCount + castCount;
        targetChara.setTraitData(trait, castCount: modifiedCastCount);
      }
      else {
        targetChara.trait[trait] = CharaTrait(name: trait, maxCast: traitToType[trait]!.useCount, isAble: true);
      }
    }
  }

  void modifyCardCount(String source, String target, int count, CardEventType type) { 
    Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int modifiedCount = count;
    bool isImmune = false;

    if ({CardEventType.discard, CardEventType.grab}.contains(type)) {
      modifiedCount = targetChara.cardCount - modifiedCount < 0 ? targetChara.cardCount : modifiedCount;
      // 向月【心灵魔术】
      if (targetChara.hasHiddenStatus('sorcery')) {
        modifiedCount = targetChara.cardCount - modifiedCount - 2 < 0 ? targetChara.cardCount - 2 : modifiedCount;
      }
    }
    if ({CardEventType.play, CardEventType.give}.contains(type)) {
      modifiedCount = sourceChara.cardCount - modifiedCount < 0 ? sourceChara.cardCount : modifiedCount;
      // 向月【心灵魔术】
      if (sourceChara.hasHiddenStatus('sorcery')) {
        modifiedCount = sourceChara.cardCount - modifiedCount - 2 < 0 ? sourceChara.cardCount - 2 : modifiedCount;
      }
    }

    if (!isImmune) { 
      if (type == CardEventType.draw) {
        addAttribute(source, AttributeType.card, modifiedCount);
      }
      else if (type == CardEventType.discard) {
        addAttribute(target, AttributeType.card, -modifiedCount);
      }
      else if (type == CardEventType.play) {
        addAttribute(source, AttributeType.card, -modifiedCount);
      }
      else if (type == CardEventType.gain) {
        addAttribute(source, AttributeType.card, modifiedCount);
      }
      else if (type == CardEventType.grab) {
        addAttribute(source, AttributeType.card, modifiedCount);
        addAttribute(target, AttributeType.card, -modifiedCount);
      }
      else if (type == CardEventType.give) {
        addAttribute(source, AttributeType.card, -modifiedCount);
        addAttribute(target, AttributeType.card, modifiedCount);
      }
    }
  }

  void addStatus(String source, String target, String status, int intensity, int layer){
    Character targetChara = players[target]!;
    bool isImmune = false;
    int previousIntensity = targetChara.getStatusIntData(status, StatusData.intensity);
    int previousLayer = targetChara.getStatusIntData(status, StatusData.layer);
    if (targetChara.hasStatus(StatusId.gugu.id)) {
      isImmune = true;
    }
    if (targetChara.hasHiddenStatus('babel')){
      isImmune = true;
    }
    if ((targetChara.hasStatus(StatusId.eden.id) || targetChara.hasStatus(StatusId.luminance.id)) 
      && statusToType[status]!.buffType == BuffType.negative) {
      isImmune = true;
    }
    // 科亚特尔【拟造“伊甸园”】
    if (targetChara.hasStatus(StatusId.sanctify.id) && statusToType[status]!.buffType == BuffType.negative) {
      isImmune = true;
      modifyStatusLayer(target, target, StatusId.sanctify.id, -1);
      if (targetChara.getStatusIntData(StatusId.sanctify.id, StatusData.layer) == 0) {
        removeStatus(target, target, StatusId.sanctify.id);
      }
    }
    // 茵竹【自勉】
    if (targetChara.hasTrait(TraitId.selfEncouragement.id)) {
      List<bool> isImmuneRef = [isImmune];
      castTrait(target, [target], TraitId.selfEncouragement.id, {'type': 1, 'status': status, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    // 时雨【寒冰血脉】
    if (targetChara.hasTrait(TraitId.icyBlood.id) && {StatusId.frozen.id, StatusId.frost.id}.contains(status)){
      List<bool> isImmuneRef = [isImmune];
      castTrait(target, [target], TraitId.icyBlood.id, {'type': 0, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    // 红烬【烈焰之体】
    if (target == CharacterId.ember.id && {StatusId.frozen.id, StatusId.frost.id}.contains(status)){
      List<bool> isImmuneRef = [isImmune];
      castTrait(target, [target], TraitId.conflagrationAvatar.id, {'type': 0, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    // 阿波菲斯【毁灭暗影】
    if (target == CharacterId.apophis.id && status == StatusId.nightmare.id) {
      isImmune = true;
    }
    if (!isImmune) {
      if (targetChara.hasStatus(status)) {
        if (status == StatusId.soulFlare.id) {
          modifyStatusIntensity(source, target, status, intensity, log: false);
        }
        else {
          modifyStatusLayer(source, target, status, layer, log: false);
          if (intensity > targetChara.getStatusIntData(status, StatusData.intensity)) {
            modifyStatusIntensity(source, target, status, intensity - targetChara.getStatusIntData(status, StatusData.intensity), log: false);             
          }
        }        
      }
      else {
        targetChara.status[status] = CharaStatus(name: status, intensity: 0, layer: 0, layerFraction: playerCount, intData: 0, strData: '');
        modifyStatusLayer(source, target, status, layer, log: false);
        modifyStatusIntensity(source, target, status, intensity, log: false);
        if (status == StatusId.exhausted.id) {
          targetChara.setStatusData(status, intData: targetChara.attack ~/ 2);
          addAttribute(target, AttributeType.attack, -targetChara.getStatusIntData(status, StatusData.intData));
        }
        else if (status == StatusId.lumenFlare.id) {
          addAttribute(target, AttributeType.attack, 5);
        }
        else if (status == StatusId.erodeGelid.id) {
          addAttribute(target, AttributeType.defence, 5);
        }
        else if (status == StatusId.mirror.id) {
          targetChara.setStatusData(status, intData: targetChara.attack * 1024 + targetChara.defence);
          addAttribute(target, AttributeType.attack, targetChara.getStatusIntData(status, StatusData.intData) % 1024 - targetChara.attack);
          addAttribute(target, AttributeType.defence, (targetChara.getStatusIntData(status, StatusData.intData) ~/ 1024) - targetChara.defence);
        } 
        else if (status == StatusId.eden.id) {
          addHiddenStatus(target, 'apocalypse', 0, -1);
          List<String> statusList = targetChara.status.keys.toList();
          for (String stat in statusList) {
            if (statusToType[stat]!.buffType == BuffType.negative) {
              removeStatus(target, target, stat);
            }
          }
        }
        else if (status == StatusId.luminance.id) {
          List<String> statusList = targetChara.status.keys.toList();
          for (String stat in statusList) {
            if (statusToType[stat]!.buffType == BuffType.negative) {
              removeStatus(target, target, stat);
            }
          }
        }
        else if (status == StatusId.tenebrae.id) {
          addAttribute(target, AttributeType.attack, 10);
        }
        else if (status == StatusId.swordHeart.id) {
          List<String> statusList = targetChara.status.keys.toList();
          for (String stat in statusList) {
            if (statusToType[stat]!.buffType == BuffType.negative) {
              removeStatus(target, target, stat);
            }
          }
        }

        // 冰火相融
        if (targetChara.hasStatus(StatusId.frost.id) && targetChara.hasStatus(StatusId.flaming.id)) {
          int frostIntensity = targetChara.getStatusIntData(StatusId.frost.id, StatusData.intensity);
          int flamingIntensity = targetChara.getStatusIntData(StatusId.flaming.id, StatusData.intensity);
          if (frostIntensity > flamingIntensity) {
            removeStatus(target, target, StatusId.flaming.id);
            modifyStatusIntensity(target, target, StatusId.frost.id, -flamingIntensity);
          }
          else if (flamingIntensity > frostIntensity) {
            removeStatus(target, target, StatusId.frost.id);
            modifyStatusIntensity(target, target, StatusId.flaming.id, -frostIntensity);
          }
          else {
            removeStatus(target, target, StatusId.frost.id);
            removeStatus(target, target, StatusId.flaming.id);
          }
        }
        if (targetChara.hasStatus(StatusId.frozen.id) && targetChara.hasStatus(StatusId.infernoFire.id)) {
          int frozenLayer = targetChara.getStatusIntData(StatusId.frozen.id, StatusData.layer);
          int infernoFireLayer = targetChara.getStatusIntData(StatusId.infernoFire.id, StatusData.layer);
          if (frozenLayer > infernoFireLayer) {
            removeStatus(target, target, StatusId.infernoFire.id);
            modifyStatusLayer(target, target, StatusId.frozen.id, -infernoFireLayer);
          }
          else if (infernoFireLayer > frozenLayer) {
            removeStatus(target,target, StatusId.frozen.id);
            modifyStatusLayer(target, target, StatusId.infernoFire.id, -frozenLayer);
          }
          else {
            removeStatus(target, target, StatusId.frozen.id);
            removeStatus(target, target, StatusId.infernoFire.id);
          }
        }
      }
      _recordProvider!.addStatusRecord(getGameTurn(), source, target, status, [previousIntensity, previousLayer], 
        [targetChara.getStatusIntData(status, StatusData.intensity), targetChara.getStatusIntData(status, StatusData.layer)], StatusChange.add,'');
      _gameLogger!.addStatusLog(getGameTurn(), target, status, targetChara.getStatusIntData(status, StatusData.intensity), targetChara.getStatusIntData(status, StatusData.layer));
    }    
  }

  void removeStatus(String source, String target, String status){ 
    Character targetChara = players[target]!;
    int previousIntensity = targetChara.getStatusIntData(status, StatusData.intensity);
    int previousLayer = targetChara.getStatusIntData(status, StatusData.layer);

    if (!targetChara.hasStatus(status)) {return;}

    modifyStatusIntensity(source, target, status, -targetChara.getStatusIntData(status, StatusData.intensity), log: false);
    modifyStatusLayer(source, target, status, -targetChara.getStatusIntData(status, StatusData.layer), log: false);
  
    if (status == StatusId.exhausted.id) {
      addAttribute(target, AttributeType.attack, targetChara.getStatusIntData(StatusId.exhausted.id, StatusData.intData));
    }
    else if (status == StatusId.lumenFlare.id) {
      addAttribute(target, AttributeType.attack, -5);
    }
    else if (status == StatusId.erodeGelid.id) {
      addAttribute(target, AttributeType.defence, -5);
    }
    else if (status == StatusId.mirror.id) {
      addAttribute(target, AttributeType.attack, (targetChara.getStatusIntData(StatusId.mirror.id, StatusData.intData) ~/ 1024) - targetChara.attack);
      addAttribute(target, AttributeType.defence, targetChara.getStatusIntData(StatusId.mirror.id, StatusData.intData) % 1024 - targetChara.defence);
    }
    else if (status == StatusId.dreaming.id) {
      if (isCharacterInGame(CharacterId.valedictus.id)) {
        castTrait(CharacterId.valedictus.id, [target], TraitId.nightmareRefrain.id, {'type': 3});
      }
    }
    else if (status == StatusId.frozen.id) {
      // 祝烨明【八裂】
      if (isCharacterInGame(CharacterId.zhuYeming.id)) {
        (CharacterId.zhuYeming.id, [target], TraitId.cryoFissuring.id, {'type': 1});
      }
      // 白谢【极寒环域】
      if (isCharacterInGame(CharacterId.baiXie.id)) {
        castTrait(CharacterId.baiXie.id, [target], TraitId.glacialCircle.id, {'type': 2});
      }
    }
    else if (status == StatusId.tenebrae.id) {
      addAttribute(target, AttributeType.attack, -10);
    }

    _recordProvider!.addStatusRecord(getGameTurn(), source, target, status, 
      [previousIntensity, previousLayer], [0, 0], StatusChange.remove, '');
    targetChara.status.remove(status);
    _gameLogger!.addStatusLog(getGameTurn(), target, status, 0, 0);    
  }

  // 更改状态层数
  void modifyStatusLayer(String source, String target, String status, int layer, {bool log = true}) { 
    Character targetChara = players[target]!;
    int previousLayer = targetChara.getStatusIntData(status, StatusData.layer);

    if (!targetChara.hasStatus(status)) {
      addStatus(source, target, status, 0, layer);
      return;
    }

    int modifiedLayer = layer;
    if (targetChara.getStatusIntData(status, StatusData.layer) + layer < 0) {
      modifiedLayer = -targetChara.getStatusIntData(status, StatusData.layer);    
    }
    // 石蹄【蹦蹦咒语】
    if (target == CharacterId.stonehoof.id && status == StatusId.swift.id && layer > 0) {
      List<int> layerRef = [modifiedLayer];
      castTrait(target, [target], TraitId.boingSpell.id, {'type':  2, 'layerRef': layerRef});
      modifiedLayer = layerRef[0];
    }

    targetChara.increaseStatusData(status, layer: modifiedLayer);

    // 特质结算
    // ReFre-3【<06>自卫协议】
    if (target == CharacterId.refre3.id && isEnemy(source, target)) {
      castTrait(target, [source], TraitId.defensiveProtocol.id);
    }

    // 记录状态
    if (log) {    
      _recordProvider!.addStatusRecord(getGameTurn(), source, target, status, [targetChara.getStatusIntData(status, StatusData.intensity), previousLayer], 
        [targetChara.getStatusIntData(status, StatusData.intensity), previousLayer + modifiedLayer], layer <= 0 ? StatusChange.decrease : StatusChange.increase,'');
      _gameLogger!.addStatusLog(getGameTurn(), target, status, targetChara.getStatusIntData(status, StatusData.intensity), targetChara.getStatusIntData(status, StatusData.layer));
    }        
    refresh();
  }

  // 更改状态强度
  void modifyStatusIntensity(String source, String target, String status, int intensity, {bool log = true}) {
    Character targetChara = players[target]!;
    int previousIntensity = targetChara.getStatusIntData(status, StatusData.intensity);

    if (!targetChara.hasStatus(status)) {
      addStatus(source, target, status, intensity, 0);
      return;
    }

    // 防止状态强度溢出或过小
    int modifiedIntensity = intensity;
    if (targetChara.getStatusIntData(status, StatusData.intensity) + intensity < 0) {
      modifiedIntensity = -targetChara.getStatusIntData(status, StatusData.intensity);    
    }
    if (status == StatusId.dissociated.id && targetChara.getStatusIntData(StatusId.dissociated.id, StatusData.intensity) 
      + intensity > 10) {
      modifiedIntensity = 10 - targetChara.getStatusIntData(StatusId.dissociated.id, StatusData.intensity);
    }
    else if (status == StatusId.teroxis.id && targetChara.getStatusIntData(StatusId.teroxis.id, StatusData.intensity) 
      + intensity > 5) {
      modifiedIntensity = 5 - targetChara.getStatusIntData(StatusId.teroxis.id, StatusData.intensity);
    }

    // 修改角色属性
    if (status == StatusId.frost.id) {
      addAttribute(target, AttributeType.attack, -4 * modifiedIntensity);
    }
    else if (status == StatusId.strength.id) {
      addAttribute(target, AttributeType.attack, 5 * modifiedIntensity);
    }
    else if (status == StatusId.teroxis.id) {
      addAttribute(target, AttributeType.attack, 5 * modifiedIntensity);
    }
    else if (status == StatusId.grind.id) {
      addAttribute(target, AttributeType.maxmove, -modifiedIntensity);
      if (targetChara.movePoint > targetChara.maxMove) {
        addAttribute(target, AttributeType.movepoint, targetChara.maxMove - targetChara.movePoint);
      }
    }
    else if (status == StatusId.fragility.id) {
      addAttribute(target, AttributeType.defence, -5 * modifiedIntensity);
    }
    else if (status == StatusId.burnOut.id) {
      addAttribute(target, AttributeType.attack, 5 * modifiedIntensity);
      addAttribute(target, AttributeType.defence, -5 * modifiedIntensity);
    }
    else if (status == StatusId.corroded.id) {
      addAttribute(target, AttributeType.attack, -10 * modifiedIntensity);
    }
    else if (status == StatusId.weakness.id) {
      addAttribute(target, AttributeType.attack, -5 * modifiedIntensity);
    }
    else if (status == StatusId.drowsy.id) {
      addAttribute(target, AttributeType.attack, -5 * modifiedIntensity);
      addAttribute(target, AttributeType.defence, -5 * modifiedIntensity);
    }
    else if (status == StatusId.eden.id) {
      addAttribute(target, AttributeType.attack, 3 * modifiedIntensity);
    }
    else if (status == StatusId.dehydration.id) {
      addAttribute(target, AttributeType.defence, -10 * modifiedIntensity);
    }
    else if (status == StatusId.submerged.id) {
      addAttribute(target, AttributeType.attack, -10 * modifiedIntensity);
    }
    else if (status == StatusId.asphyxia.id) {
      addAttribute(target, AttributeType.maxhp, -30 * modifiedIntensity);
      if (targetChara.health > targetChara.maxHealth) {
        damagePlayer('empty', targetChara.id, targetChara.health - targetChara.maxHealth, DamageType.lost);
      }
    }
        
    targetChara.increaseStatusData(status, intensity: modifiedIntensity);

    // 特质结算
    // ReFre-3【<06>自卫协议】
    if (target == CharacterId.refre3.id && isEnemy(source, target)) {
      castTrait(target, [source], TraitId.defensiveProtocol.id);
    }

    // 记录状态
    if (log) {
      _recordProvider!.addStatusRecord(getGameTurn(), source, target, status, [previousIntensity, targetChara.getStatusIntData(status, StatusData.layer)], 
        [previousIntensity + modifiedIntensity, targetChara.getStatusIntData(status, StatusData.layer)], intensity <= 0 ? StatusChange.decrease : StatusChange.increase, '');
      _gameLogger!.addStatusLog(getGameTurn(), target, status, targetChara.getStatusIntData(status, StatusData.intensity), targetChara.getStatusIntData(status, StatusData.layer));
    }    
    refresh();
  }

  // 添加隐藏状态
  void addHiddenStatus(String charaId, String status, int intensity, int layer) {
    Character chara = players[charaId]!;
    bool isImmune = false;
    if(!isImmune){
      if (chara.hasHiddenStatus(status)) {
        if (status == 'dark') {
          if (chara.getHiddenStatusIntData('dark', StatusData.intensity) + intensity > 10) {
            chara.setHiddenStatusData(status, intensity: 10);
            addAttribute(charaId, AttributeType.attack, 2 * (10 - chara.getHiddenStatusIntData('dark', StatusData.intensity)));
          }
          else {
            chara.increaseHiddenStatusData(status, intensity: intensity);
            addAttribute(charaId, AttributeType.attack, 2 * intensity);
          }
        }
        else if (status == 'light_elf') {
          if (chara.getHiddenStatusIntData('light_elf', StatusData.intensity) + intensity > chara.getHiddenStatusIntData('light', StatusData.intensity)) {
            chara.setHiddenStatusData(status, intensity: chara.getHiddenStatusIntData('light', StatusData.intensity));
          }
          else {
            chara.increaseHiddenStatusData(status, intensity: intensity);
          }
        }
        else if (status == 'light') {
          if (chara.getHiddenStatusIntData('light', StatusData.intensity) + intensity > 5) {
            chara.setHiddenStatusData(status, intensity: 5);
          }
          else {
            chara.increaseHiddenStatusData(status, intensity: intensity);
          }
        }
        else if ({'damageplus', 'hero_legend', 'dream_shelter', 'clover', 'flover', 'annihilate', 'alcohol', 'celestial', 
          'dreaming', 'forbidden','shade', 'night', 'collective', 'destiny', 'rage', 'costminus', 'protocol', 
          'color_white', 'color_black', 'color_red', 'color_green', 'color_yellow', 'white_piece', 'black_piece',
          'ranger'}.contains(status)){          
          modifyHiddenStatusIntensity(charaId, status, intensity);
        }
        else {          
          modifyHiddenStatusLayer(charaId, status, layer);
          if ({'dice_size'}.contains(status) && intensity > chara.getHiddenStatusIntData(status, StatusData.intensity)) {
            modifyHiddenStatusIntensity(charaId, status, intensity - chara.getHiddenStatusIntData(status, StatusData.intensity));
          }
        }
      }
      else {
        chara.hiddenStatus[status] = CharaStatus(name: status, intensity: 0, layer: 0, layerFraction: playerCount, intData: 0, strData: '');
        modifyHiddenStatusLayer(charaId, status, layer);
        modifyHiddenStatusIntensity(charaId, status, intensity);
        if (status == 'air_lock') {
          chara.maxCard = 3;
        }
        else if (status == 'spirit_bind') {
          addAttribute(charaId, AttributeType.attack, -10);
          addAttribute(charaId, AttributeType.defence, -10);
        }
        else if (status == 'dream_force') {
          addAttribute(charaId, AttributeType.attack, 30);
          addAttribute(charaId, AttributeType.defence, 30);
        }
        else if (status == 'slayer') {
          addAttribute(charaId, AttributeType.attack, 10);
        }
        else if (status == 'gemini') {
          int geminiIntensity = chara.getHiddenStatusIntData('gemini', StatusData.intensity) % 2;
          if (geminiIntensity == 0) { 
            addAttribute(charaId, AttributeType.attack, -5);
            addAttribute(charaId, AttributeType.defence, 10);
          }
          else {
            addAttribute(charaId, AttributeType.attack, 10);
            addAttribute(charaId, AttributeType.defence, -5);
          }
        }
        else if (status == 'ranger_atk') {
          addAttribute(charaId, AttributeType.attack, 10);
        }
        else if (status == 'ranger_def') {
          addAttribute(charaId, AttributeType.defence, 10);
        }
      }
    }    
  }

  // 移除隐藏状态
  void removeHiddenStatus(String charaId, String status){ 
    Character chara = players[charaId]!;

    if (!chara.hasHiddenStatus(status)) {return;}

    modifyHiddenStatusIntensity(charaId, status, 0);
    modifyHiddenStatusLayer(charaId, status, 0);

    if (status == 'undying') {
      addAttribute(charaId, AttributeType.armor, -400);
      if (chara.armor < 0) chara.armor = 0;
    }
    else if (status == 'velocity') {
      addHiddenStatus(charaId, 'anti_velocity', 0, 1);
    }
    else if (status == 'hema') {
      addAttribute(charaId, AttributeType.attack, -15);
    }
    else if (status == 'touched') {
      countdown.deftTouchSkill = '';
      countdown.deftTouchTarget = '';
    }
    else if (status == 'annihilate') {
      addHiddenStatus(charaId, 'cycle', chara.getHiddenStatusIntData(status, StatusData.intensity), 1);
    }
    else if (status == 'air_lock') {
      chara.maxCard = chara.getHiddenStatusIntData('air_lock', StatusData.intensity);
    }
    else if (status == 'spirit_bind') {
      addAttribute(charaId, AttributeType.attack, 10);
      addAttribute(charaId, AttributeType.defence, 10);
    }
    else if (status == 'dream_force') {
      addAttribute(charaId, AttributeType.attack, -30);
      addAttribute(charaId, AttributeType.defence, -30);
    }
    else if (status == 'sacrifice') {
      damagePlayer('empty', charaId, 250, DamageType.lost);
    }
    else if (status == 'slayer') {
      addAttribute(charaId, AttributeType.attack, -10);
    }
    else if (status == 'ranger_atk') {
      addAttribute(charaId, AttributeType.attack, -10);
    }
    else if (status == 'ranger_def') {
      addAttribute(charaId, AttributeType.defence, -10);
    }

    chara.hiddenStatus.remove(status);    
  }

  // 更改隐藏状态层数
  void modifyHiddenStatusLayer(String charaId, String status, int layer){ 
    Character chara = players[charaId]!;

    if (!chara.hasHiddenStatus(status)) {
      addHiddenStatus(charaId, status, 0, layer);
      return;
    }

    int modifiedLayer = layer;

    chara.increaseHiddenStatusData(status, layer: modifiedLayer);
    refresh();
  }

  // 更改隐藏状态强度
  void modifyHiddenStatusIntensity(String charaId, String status, int intensity){
    Character chara = players[charaId]!;

    if (!chara.hasHiddenStatus(status)) {
      addHiddenStatus(charaId, status, intensity, 0);
      return;
    }

   int modifiedIntensity = intensity;
   if (chara.getHiddenStatusIntData(status, StatusData.intensity) + intensity < 0) {
     modifiedIntensity = -chara.getHiddenStatusIntData(status, StatusData.intensity);
   }

    if (status == 'yearning_atk') {
      addAttribute(charaId, AttributeType.attack, intensity);
    }
    else if (status == 'yearning_def') {
      addAttribute(charaId, AttributeType.defence, intensity);
    }
    else if (status == 'dark') {
      addAttribute(charaId, AttributeType.attack, 2 * intensity);
    }
    else if (status == 'sacrifice') {
      addAttribute(charaId, AttributeType.attack, 5 * intensity);
      addAttribute(charaId, AttributeType.defence, 5 * intensity);
    }
    else if (status == 'gemini') {
      int geminiIntensity = chara.getHiddenStatusIntData('gemini', StatusData.intensity) % 2;
      if (geminiIntensity == 0 && intensity % 2 == 1) { 
        addAttribute(charaId, AttributeType.attack, 15);
        addAttribute(charaId, AttributeType.defence, -15);
      }
      else if (geminiIntensity == 1 && intensity % 2 == 1) {
        addAttribute(charaId, AttributeType.attack, -15);
        addAttribute(charaId, AttributeType.defence, 15);
      }
    }

    chara.increaseHiddenStatusData(status, intensity: modifiedIntensity);
    refresh();
  }

  // 记录掷骰事件
  int throwDice(String source, String target, int point, int maxPoint, DiceType type, [Map<String, dynamic>? args]) {
    Character sourceChara = players[source]!;
    // Character targetChara = players[target]!;
    int modifiedPoint = point;

    // 图西乌【蚀月】
    if (target == CharacterId.tussiu.id && type == DiceType.action) {
      castTrait(target, [target], TraitId.eclipse.id, {'type': 0, 'point': point});
    }
    // 雷刚【斩神】
    if (source == CharacterId.leiGang.id && type == DiceType.action) {
      modifyHiddenStatusIntensity(source, 'deicide', point);
    }
    // 蒙德里安【禁忌知识】
    for (var chara in players.values) {
      if(chara.id == CharacterId.mondrian.id && point >= 4) {
        castTrait(chara.id, [chara.id], TraitId.tabooLore.id, {'type': 0});
        break;
      }
    }
    if (sourceChara.hasHiddenStatus('forbidden_minus') && type == DiceType.action) {
      modifiedPoint -= 1;
      removeHiddenStatus(source, 'forbidden_minus');
    }
    if (sourceChara.hasHiddenStatus('forbidden_plus') && type == DiceType.action) {
      modifiedPoint += 1;
      removeHiddenStatus(source, 'forbidden_plus');
    }
    // 星惑【众人的乌托邦】
    if (source == CharacterId.seiwaku.id && type == DiceType.action) { 
      if (point >= 6) {
        castTrait(source, [source], TraitId.collectiveUtopia.id, {'type': 1});
      }
      if (type == DiceType.action) {
        List<int> pointRef = [modifiedPoint];
        castTrait(source, [source], TraitId.collectiveUtopia.id, {'type': 0, 'pointRef': pointRef});
        modifiedPoint = pointRef[0];
      }
    }
    // 亭歆雨【彼岸之金】
    if (source == CharacterId.tingXinyu.id && sourceChara.hasHiddenStatus('destiny') && type == DiceType.action) {
      modifiedPoint += sourceChara.getHiddenStatusIntData('destiny', StatusData.intensity);
      removeHiddenStatus(source, 'destiny');
    }
    // 石蹄【蹦蹦咒语】
    if (source == CharacterId.stonehoof.id && type == DiceType.action) {
      List<int> pointRef = [modifiedPoint];
      castTrait(source, [source], TraitId.boingSpell.id, {'type': 3, 'pointRef': pointRef});
      modifiedPoint = pointRef[0];
    }
    // π123【二进制成对】
    if (sourceChara.hasTrait(TraitId.binaryDyad.id) && type == DiceType.action) {
      modifiedPoint += sourceChara.getHiddenStatusIntData('dyad', StatusData.intensity) % 1024;
    }

    // 状态【重伤】
    if (sourceChara.hasStatus(StatusId.wounded.id)) {
      damagePlayer('empty', source, 10 * sourceChara.getStatusIntData(StatusId.wounded.id, StatusData.intensity), DamageType.lost);
    }
    // 状态【不安】
    if (sourceChara.hasStatus(StatusId.uneasiness.id)) {
      modifiedPoint -= sourceChara.getStatusIntData(StatusId.uneasiness.id, StatusData.intensity);
      modifyStatusLayer(source, source, StatusId.uneasiness.id, -1);
      if (sourceChara.getStatusIntData(StatusId.uneasiness.id, StatusData.layer) == 0) {
        removeStatus(source, source, StatusId.uneasiness.id);
      }
    }
    // 状态【激昂】
    if (sourceChara.hasStatus(StatusId.impassioned.id)) {
      modifiedPoint += sourceChara.getStatusIntData(StatusId.impassioned.id, StatusData.intensity);
      modifyStatusLayer(source, source, StatusId.impassioned.id, -1);
      if (sourceChara.getStatusIntData(StatusId.impassioned.id, StatusData.layer) == 0) {
        removeStatus(source, source, StatusId.impassioned.id);
      }
    }

    // 道具【三叶草之祝】
    if (sourceChara.hasHiddenStatus('clover') && type == DiceType.action) {
      modifiedPoint += sourceChara.getHiddenStatusIntData('clover', StatusData.intensity);
      removeHiddenStatus(source, 'clover');
    }
    // 道具【四叶草之愿】
    if (sourceChara.hasHiddenStatus('flover') && type == DiceType.action) {
      modifiedPoint *= sourceChara.getHiddenStatusIntData('flover', StatusData.intensity);
      removeHiddenStatus(source, 'flover');
    }

    // 图西乌【蚀月】
    if (target == CharacterId.tussiu.id && type == DiceType.action) {
      List<int> pointRef = [modifiedPoint];
      castTrait(target, [target], TraitId.eclipse.id, {'type': 1, 'pointRef': pointRef});
      castTrait(target, [target], TraitId.eclipse.id, {'type': 2, 'pointRef': pointRef});
      modifiedPoint = pointRef[0];
    }
    // 雷刚【斩神】
    if (sourceChara.getHiddenStatusIntData('deicide', StatusData.intensity) > 0 && type == DiceType.action) {
      modifiedPoint = sourceChara.getHiddenStatusIntData('deicide', StatusData.intensity);
    }

    // 强化攻击
    double poweredAttackRate = 0.7;
    if (modifiedPoint / maxPoint >= poweredAttackRate && type == DiceType.action) {
      addHiddenStatus(source, 'power_attack', 0, 0);
    }
    // π123【二进制成对】
    if (sourceChara.hasTrait(TraitId.binaryDyad.id) && sourceChara.hasHiddenStatus('power_attack') && type == DiceType.action 
    && modifiedPoint / (sourceChara.getHiddenStatusIntData('dyad', StatusData.intensity) ~/ 1024) < poweredAttackRate) {
      removeHiddenStatus(source, 'power_attack');
    }
    if (sourceChara.hasHiddenStatus('dyad') && type == DiceType.action) {
      removeHiddenStatus(source, 'dyad');
    }

    if (modifiedPoint < 0) {
      modifiedPoint = 0;
    }
    return modifiedPoint;
  }

  // 使用道具
  bool castCard(String source, List<String> targets, String card, [Map<String, dynamic>? args]){
    bool cardAble = true;
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    Map<String, dynamic> cardArgs = args ?? {};
    // 红黎【红莲业火】
    if (sourceChara.hasHiddenStatus('lotus')) {
      int tagIndex = sourceChara.getHiddenStatusIntData('lotus', StatusData.intensity);
      TagId tag = TagId.values[tagIndex];
      List<String> tagList = cardTags[card]!;
      if (tagList.contains(tag.id)) {
        cardAble = false;
      }
    }
    // 唐亚德【清心的乌托邦】
    if (source == CharacterId.tangYade.id) {
      List<String> tagList = cardTags[card]!;
      if (tagList.contains(TagId.weird.id) || tagList.contains(TagId.magic.id)) {
        cardAble = false;
        castTrait(source, [source], TraitId.utopiaOfClarity.id, {'type': 2});
      }
    }
    // 亭歆雨【彼岸之金】
    if (source == CharacterId.tingXinyu.id) {
      List<String> tagList = cardTags[card]!;
      if (tagList.length >= 2) {
        cardAble = false;
      }
    }
    // 染序【五采】
    if (source == CharacterId.ranXu.id) {
      List<String> tagList = cardTags[card]!;
      int cardCount = sourceChara.getHiddenStatusIntData('cardcount', StatusData.intensity) >= 2 ? 2 : 1;
      int irisIntensity = sourceChara.getHiddenStatusIntData('iris', StatusData.intensity) % 5;
      int prohibitedCardIndex = 10 * cardCount + irisIntensity;
      if (tagList.contains(TagId.sharp.id) && {10, 20, 24}.contains(prohibitedCardIndex)
      || tagList.contains(TagId.mystique.id) && {11, 21, 20}.contains(prohibitedCardIndex)
      || tagList.contains(TagId.magic.id) && {12, 22, 21}.contains(prohibitedCardIndex)
      || tagList.contains(TagId.vital.id) && {13, 23, 22}.contains(prohibitedCardIndex)
      || tagList.contains(TagId.protect.id) && {14, 24, 23}.contains(prohibitedCardIndex)) {
        cardAble = false;
      }
    }
    if (cardAble) {
      int reinforcementMulti = sourceChara.getHiddenStatusStringData('reinforcement', StatusData.strData) == card ? 2 : 1;
      // 破片水晶
      if (card == CardId.endCrystal.id) {
        int crystalSelf = (cardArgs['crystalSelf'] as int?) ?? 1;
        int crystalMagic = (cardArgs['crystalMagic'] as int?) ?? 1;
        damagePlayer('empty', source, (30 + 15 * crystalSelf) * reinforcementMulti, DamageType.lost);
        for (Character chara in players.values) {
          if (isEnemy(source, chara.id)) {
            damagePlayer(source, chara.id, (40 + 15 * crystalMagic) * reinforcementMulti, 
            DamageType.physical, isAOE: true);}
        }
      }
      // 阿波罗之箭
      else if (card == CardId.apolloArrow.id) {
        int minDefence = targetChara.defence;
        for (Character chara in players.values) {
          if (chara.defence < minDefence && isEnemy(source, chara.id) && chara.id != 'empty' && !chara.isDead) {
            minDefence = chara.defence;
          }
        }
          if (minDefence == targetChara.defence) {
          addHiddenStatus(target, 'damageplus', 100 * reinforcementMulti, 0);
        }
      }
      // 八重镜
      else if (card == CardId.octastal.id) { 
        addHiddenStatus(source, 'dice_size', 8, 0);
      }
      // 巴别塔
      else if (card == CardId.babelTower.id) {
        for (Character chara in players.values) {
          addHiddenStatus(chara.id, 'babel', 0, 1 * reinforcementMulti);
        }
      }
      // 抽薪
      else if (card == CardId.filching.id) { 
        modifyCardCount(source, target, reinforcementMulti, CardEventType.grab);
        modifyCardCount(source, target, reinforcementMulti, CardEventType.draw);
      }
      // 达摩克利斯之剑
      else if (card == CardId.damoclesSword.id) {
        if (reinforcementMulti == 2) {
          countdown.reinforcedDamocles += 1;
        }
        else {
          countdown.damocles += 1;
        }
      }
      // 短刀
      else if (card == CardId.woodSword.id) {
        addAttribute(source, AttributeType.attack, 10 * reinforcementMulti);
      }
      // 钝化术
      else if (card == CardId.slownessSpell.id) {
        addStatus(source, target, StatusId.slowness.id, 1 * reinforcementMulti, 2);
      }
      // 堕灵吊坠
      else if (card == CardId.corruptPendant.id) {
        addAttribute(source, AttributeType.attack, 5 * reinforcementMulti);
        addAttribute(target, AttributeType.attack, -5 * reinforcementMulti);
        healPlayer(source, source, 60 * reinforcementMulti, DamageType.heal);
        damagePlayer(source, target, 60 * reinforcementMulti, DamageType.lost);
      }
      // 飞鸟·紫烈
      else if (card == CardId.violentViolet.id) {
        int sequence = gameSequence.indexOf(source);
        if (sequence == 0) {sequence = gameSequence.length - 1;}
        else {sequence--;}
        Character previousChara = players[gameSequence[sequence]]!;
        addHiddenStatus(target, 'damageplus', 2 * previousChara.defence  * reinforcementMulti, 0);
      }
      // 复合弓 
      else if (card == CardId.bow.id) {
        int ammoCount = sourceChara.cardCount;
        damagePlayer(source, target, 75 * ammoCount * reinforcementMulti, DamageType.magical);
        modifyCardCount(source, source, sourceChara.cardCount, CardEventType.discard);
      }
      // 高帽子
      else if (card == CardId.highCap.id) {
        addStatus(source, target, StatusId.tigrisDilemma.id, 0, 1 * reinforcementMulti);
      }
      // 高能罐头
      else if (card == CardId.highEnergyCan.id) {
        addAttribute(source, AttributeType.maxmove, 2 * reinforcementMulti);
        addAttribute(source, AttributeType.movepoint, 1 * reinforcementMulti);
      }
      // 鼓舞
      else if (card == CardId.heroLegend.id) {
        healPlayer(source, source, sourceChara.maxHealth ~/ 10 * reinforcementMulti, DamageType.heal);
        addHiddenStatus(source, 'hero_legend', 1 * reinforcementMulti, 1);
      }
      // 过往凝视
      else if (card == CardId.passingGaze.id) {
        damagePlayer(source, target, 70 * reinforcementMulti, DamageType.magical);
        addStatus(source, target, StatusId.dissociated.id, 10, 1);
      }
      // 寒绝凝冰
      else if (card == CardId.cryotheum.id) {
        addStatus(source, target, StatusId.frost.id, 5 * reinforcementMulti, 2);
      }
      // 后日谈
      else if (card == CardId.redstone.id) {
        String statusProlonged = cardArgs['statusProlonged'] ?? '';
        String playerProlonged = cardArgs['playerProlonged'] ?? '';
        if (statusProlonged != '' && playerProlonged != '') {
          //addStatus(source, playerProlonged, statusProlonged, 0, 1 * reinforcementMulti);
          modifyStatusLayer(source, playerProlonged, statusProlonged, 1 * reinforcementMulti);
        }
      }
      // 护身符
      else if (card == CardId.heartLocket.id) {
        addAttribute(source, AttributeType.defence, 10 * reinforcementMulti);
      }
      // 缓生
      else if (card == CardId.regenerating.id) {
        addStatus(source, source, StatusId.regeneration.id, 6 * reinforcementMulti, 2);
        addHiddenStatus(source, 'rest', 0, 0);
      }
      // 混沌电钻
      else if (card == CardId.chaoticDrill.id) {
        addStatus(source, target, StatusId.confusion.id, 0, 1 * reinforcementMulti);
      }
      // 混乱力场
      else if (card == CardId.ascensionStair.id) {
        Map<String, int> ascensionPoints = cardArgs['ascensionPoints'] ?? {};
        int minPoint = 4;
        int maxPoint = 1;
        List<String> ascensionChara = [];
        for (String chara in ascensionPoints.keys) { 
          if (ascensionPoints[chara] == minPoint)  {
            ascensionChara.add(chara);
          }
          else if (ascensionPoints[chara]! < minPoint) {
            minPoint = ascensionPoints[chara]!;
            ascensionChara = [chara];
          }
          if (ascensionPoints[chara]! > maxPoint) {
            maxPoint = ascensionPoints[chara]!;
          }
        }
        damagePlayer('empty', source, sourceChara.health ~/ 10, DamageType.lost);
        for (String chara in ascensionChara) {
          damagePlayer(source, chara, 50 * (maxPoint + 1) * reinforcementMulti, DamageType.physical, isAOE: true);
        }
      }
      // 极北之心
      else if (card == CardId.arcticHeart.id) {
        for (var sk in sourceChara.skill.keys) {
          modifySkillCooldown(source, source, sk, -2 * reinforcementMulti);
        }
      }
      // 极光震荡
      else if (card == CardId.auroraConcussion.id) {       
        Map<String, int> auroraPoints = cardArgs['auroraPoints'] ?? {};
        for(String chara in auroraPoints.keys){ 
          if(auroraPoints[chara] == 1){
            addStatus(source, chara, StatusId.exhausted.id, 0, 1 * reinforcementMulti);
          }
        }
        damagePlayer('empty', source, 50, DamageType.lost);
        addHiddenStatus(source, 'rest', 0, 0);
      }
      // 加护
      else if (card == CardId.dreamShelter.id) {
        healPlayer(source, source, (sourceChara.maxHealth - sourceChara.health) ~/ 20 * reinforcementMulti, DamageType.heal);
        addAttribute(source, AttributeType.maxhp, 200 * reinforcementMulti);
        addHiddenStatus(source, 'dream_shelter', 1 * reinforcementMulti, 1);
      }
      // 箭
      else if (card == CardId.arrow.id) {
        addHiddenStatus(target, 'damageplus', 50 * reinforcementMulti, 0);
      }
      // 狼牙棒
      else if (card == CardId.mace.id) {
        addHiddenStatus(target, 'damageplus', 60 * reinforcementMulti, 0);
        addStatus(source, target, StatusId.fractured.id, 0, 2);
      }
      // 猎魔灵刃
      else if (card == CardId.track.id) {
        if (players[target]!.hasStatus(StatusId.dodge.id)) {
          removeStatus(source, target, StatusId.dodge.id);
          addHiddenStatus(target, 'track', 1 * reinforcementMulti, 1);
        }
      }
      // 林鸟·赤掠
      else if (card == CardId.crimsonSwoop.id) {
        int sequence = gameSequence.indexOf(source);
        if (sequence == 0) {sequence = gameSequence.length - 1;}
        else {sequence--;}
        Character previousChara = players[gameSequence[sequence]]!;
        addHiddenStatus(target, 'damageplus', previousChara.attack * reinforcementMulti, 0);
      }
      // 聆音掠影
      else if (card == CardId.echoGlimpse.id) {
        addStatus(source, target, StatusId.distant.id, 0, 1 * reinforcementMulti);
      }
      // 六方棱
      else if (card == CardId.hexastal.id) {
        addHiddenStatus(source, 'dice_size', 6, 0);
      }
      // 蛮力术
      else if (card == CardId.strengthSpell.id) {
        addStatus(source, source, StatusId.strength.id, 3 * reinforcementMulti, 2);
      }
      // 蛮力术II
      else if (card == CardId.strengthSpellIi.id) {
        addStatus(source, source, StatusId.strength.id, 6 * reinforcementMulti, 2);
      }
      // 纳米渗透
      else if (card == CardId.nanoPermeation.id) {
        addHiddenStatus(source, 'nano', 0, 1);
      }
      // 潘多拉魔盒
      else if (card == CardId.pandoraBox.id) {
        int pandoraPoint = (cardArgs['pandoraPoint'] as int?) ?? 1;
        if ([3, 6].contains(pandoraPoint)) {
          for (Character chara in players.values) {
            if (chara.id != 'empty' && !chara.isDead) {
              healPlayer('empty', chara.id, 100 * reinforcementMulti, DamageType.heal, isAOE: true);
            }
          }
        }
        else {
          for (Character chara in players.values) {
            if (chara.id != 'empty' && !chara.isDead) {
              damagePlayer('empty', chara.id, 300 * reinforcementMulti, DamageType.magical, isAOE: true);  
            }
          }
        }
        addHiddenStatus(source, 'rest', 0, 0);   
      }
      // 全息投影
      else if (card == CardId.hologram.id) {
        addHiddenStatus(source, 'rest', 0, 0);
      }
      // 荣光循途
      else if (card == CardId.gloryRoad.id) {
        addStatus(source, source, StatusId.teroxis.id, 1, 1);
      }
      // 融甲宝珠
      else if (card == CardId.penetrate.id) {
        if (targetChara.armor > 0) {
          addAttribute(target, AttributeType.armor, -targetChara.armor);
          addHiddenStatus(target, 'penetrate', 1 * reinforcementMulti, 1);
        }
      }
      // 三叶草之祝
      else if (card == CardId.cloverBlessing.id) { 
        addHiddenStatus(source, 'clover', 2 * reinforcementMulti, 1);
      }
      // 十面璃
      else if (card == CardId.decastal.id) { 
        addHiddenStatus(source, 'dice_size', 10, 0);
      }
      // 刷新
      else if (card == CardId.refreshment.id) {
        String refreshmentChoice = args?['refreshmentChoice'] ?? '';
        if (refreshmentChoice != '') {
          //sourceChara.skill[refreshmentChoice]!.cooldown = 0;
          modifySkillCooldown(source, source, refreshmentChoice, -sourceChara.skill[refreshmentChoice]!.cooldown);
        }        
      }
      // 水波荡漾
      else if (card == CardId.ripplingWater.id) {
        addStatus(source, target, StatusId.nebula.id, 1 * reinforcementMulti, 1);
      }
      // 瞬疗
      else if (card == CardId.curing.id) {
        healPlayer(source, source, 120 * reinforcementMulti, DamageType.heal);
        addHiddenStatus(source, 'rest', 0, 0);
      }
      // 四叶草之愿
      else if (card == CardId.floverWish.id) { 
        addHiddenStatus(source, 'flover', 2 * reinforcementMulti, 1);
      }
      // 天穹尘埃之障
      else if (card == CardId.aetherShroud.id) {
        addStatus(source, target, StatusId.oculusVeil.id, 0, 1 * reinforcementMulti);
      }
      // 同调
      else if (card == CardId.homology.id) {
        Map<String, CharaStatus> tempStatus = {};
        List<dynamic> sourceStatusKeys = sourceChara.status.keys.toList();
        List<dynamic> targetStatusKeys = targetChara.status.keys.toList();
        for (String stat in targetChara.status.keys) {
          tempStatus[stat] = targetChara.status[stat]!;
        }
        for (String stat in targetStatusKeys) {
          removeStatus(source, target, stat);
        }
        for (String stat in sourceStatusKeys) {
          addStatus(source, target, stat, sourceChara.status[stat]!.intensity, sourceChara.status[stat]!.layer);
        }
        for (String stat in sourceStatusKeys) {
          removeStatus(source, source, stat);
        }
        for (String stat in tempStatus.keys) {
          addStatus(source, source, stat, tempStatus[stat]!.intensity, tempStatus[stat]!.layer);
        }
      }
      // 无敌贯通
      else if (card == CardId.criticalStrike.id) {
        addHiddenStatus(source, 'critical', 0, 0);
      }
      // 西西弗斯之石头
      else if (card == CardId.sisyphusStone.id) {
        addStatus(source, target, StatusId.grind.id, 1 * reinforcementMulti, 1);
      }
      // 休憩
      else if (card == CardId.rest.id) {
        addHiddenStatus(source, 'costminus', 2 * reinforcementMulti, 0);
      }
      // 迅捷术
      else if (card == CardId.swiftSpell.id) {
        addStatus(source, source, StatusId.swift.id, 1 * reinforcementMulti, 2);
        sourceChara.increaseStatusData(StatusId.swift.id, layerFraction: 1);
      }
      // 炎极烈火
      else if (card == CardId.pyrotheum.id) {
        addStatus(source, target, StatusId.flaming.id, 5 * reinforcementMulti, 3);
      }
      // 失乐园
      else if (card == CardId.edenGarden.id) {
        // 二进制编码失乐园触发次数，初始为10/11，正常为0，强化为1
        if (!sourceChara.hasHiddenStatus('eden')) {
          addHiddenStatus(source, 'eden', reinforcementMulti + 1, -1);
        }
        else {
          sourceChara.setHiddenStatusData('eden', 
            intensity: sourceChara.getHiddenStatusIntData('eden', StatusData.intensity) * 2 + reinforcementMulti - 1);
        }        
      }
      // 遗失碎片
      else if (card == CardId.fragment.id) {        
        modifyCardCount(source, target, 2 * reinforcementMulti, CardEventType.draw);
        addHiddenStatus(target, 'damageplus', 45 * reinforcementMulti, 0);
      }
      // 隐身术
      else if (card == CardId.invisibilitySpell.id) {
        addStatus(source, source, StatusId.dodge.id, 0, 1);
        addHiddenStatus(source, 'rest', 0, 0);
      }
      // 御术者长矛·炎
      else if (card == CardId.flameSpear.id) {
        addStatus(source, source, StatusId.lumenFlare.id, 0, 1);
      }
      // 御术者重盾·霜
      else if (card == CardId.frostShield.id) {
        addStatus(source, source, StatusId.erodeGelid.id, 0, 1);
      }
      // 圆盾
      else if (card == CardId.shield.id) {
        addAttribute(source, AttributeType.armor, 100 * reinforcementMulti);
        addAttribute(source, AttributeType.defence, 5 * reinforcementMulti);
      }
      // 长剑
      else if (card == CardId.rapier.id) {
        addAttribute(source, AttributeType.attack, 15 * reinforcementMulti);
      }
      // 昭示
      else if (card == CardId.declaration.id) {        
        modifyCardCount(source, target, reinforcementMulti, CardEventType.discard);
      }
      // 折射水晶
      else if (card == CardId.amethyst.id) {
        int amethystPoint = (args?['amethystPoint'] as int?) ?? 1;
        if (amethystPoint == 1) {
          addHiddenStatus(target, 'damageplus', 80 * reinforcementMulti, 0);
        }
        else {
          addHiddenStatus(target, 'damageplus', -40 * reinforcementMulti, 0);
        }
      }
      // 终焉长戟
      else if (card == CardId.endHalberd.id) {
        addHiddenStatus(target, 'end', 1 * reinforcementMulti, 1);
      }

      // 技能【强化】
      if (reinforcementMulti == 2) {
        removeHiddenStatus(source, 'reinforcement');
      }
    }

    return cardAble;
  }

  // 出牌
  bool playCards(String source, List<String> targets, int dicePoint, List<String> cards, List<CardSetting> cardSettings, [Map<String, dynamic>? args]){
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;    
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    int attack = 0, attackPlus = 0, defence = 0, defencePlus = 0, cost = 0, cardCost = 1, point = dicePoint;
    Map<String, dynamic> cardsArgs = args ?? {};    
    double attackMulti = 1.0, defenceMulti = 1.0;
    bool actionAble = true;    
    // 设置强化道具
    if (sourceChara.hasHiddenStatus('reinforcement')) {
      sourceChara.setHiddenStatusData('reinforcement', strData: cards.first);
    }
    // 回合外行动
    if (turn != gameSequence.indexOf(source) + 1) {
      actionAble = false;
      // 曙光【不容质疑的信任】
      if (sourceChara.hasHiddenStatus('unquestion') && cards.isEmpty) {
        actionAble = true;
      }
      // K97【二进制噪声】
      if (sourceChara.hasHiddenStatus('binary') && cards.length == 1) {
        actionAble = true;
      }
    }   
    // 计算行动点消耗
    if (cards.isEmpty) {
      cost = 1;
      // 长霾【律令·禁空】
      if (sourceChara.hasHiddenStatus('non_flying')) {
        cost++;
      }
    }
    else {
      for (String card in cards) {
        cardCost = 1;
        // 道具【休憩】
        if (card == CardId.rest.id) {
          castCard(source, [target], card);
        }
        // 长霾【律令·禁空】
        if (sourceChara.hasHiddenStatus('non_flying')) {
          cardCost++;
        }
        // 祝言夙【灵魂震荡】
        if (sourceChara.hasHiddenStatus('soul_tremor')) {
          cardCost++;
        }
        cost += cardCost;
      }
      if (sourceChara.hasHiddenStatus('costminus')) {
        cost -= sourceChara.getHiddenStatusIntData('costminus', StatusData.intensity);
        removeHiddenStatus(source, 'costminus');
      }
    }
    // 技能【极速】
    if (sourceChara.hasHiddenStatus('velocity')) {
      cost -= 3;
    }
    if (sourceChara.hasHiddenStatus('anti_velocity') && cards.isNotEmpty) {
      cost += 3;
    }
    // 舸灯【引渡】
    if (source == CharacterId.gentou.id) {
      List<int> costRef = [cost];
      castTrait(source, [source], TraitId.ghostFerry.id, {'type': 0, 'costRef': costRef});
      cost = costRef[0];
    }
    // 颜若卿【调和的乌托邦】
    else if (source == CharacterId.yanRuoqing.id) {
      List<int> costRef = [cost];
      castTrait(source, [source], TraitId.utopiaOfConcord.id, {'type': 0, 'costRef': costRef, 'cardList': cards});
      castTrait(source, [source], TraitId.utopiaOfConcord.id, {'type': 1, 'costRef': costRef, 'cardList': cards});
      cost = costRef[0];
    }
    // 沈姝华【纯洁之爱】
    if (source == CharacterId.shenShuhua.id) {
      List<int> costRef = [cost];
      castTrait(source, [source], TraitId.innocentLove.id, {'type': 0, 'costRef': costRef, 'cardList': cards});
      cost = costRef[0];
    }
    // 祝烨诚【凛息】
    if (source == CharacterId.zhuYecheng.id) {
      List<int> costRef = [cost];
      castTrait(source, [source], TraitId.icyStillness.id, {'type': 1, 'costRef': costRef, 'cardList': cards});
      cost = costRef[0];
    }
    // 染序【五采】
    if (source == CharacterId.ranXu.id) {
      addHiddenStatus(source, 'cardcount', cards.length, 0);
    }
    // 卡拉卡【友情防守】
    if (isCharacterInGame(CharacterId.karak.id)) {
      if (isEnemy(source, CharacterId.karak.id) && isTeammate(target, CharacterId.karak.id)) {
        List<int> costRef = [cost];
        castTrait(CharacterId.karak.id, [source], TraitId.buddyBlock.id, {'type': 0, 'costRef': costRef});
        cost = costRef[0];
      }
    }
    // 行动点不足    
    if (cost > sourceChara.movePoint && !{CharacterId.engine4.id}.contains(source)) {
      actionAble = false;
    }
    // EnGine-4【<04>质能转换】
    if (source == CharacterId.engine4.id) {
      cost = cards.isEmpty ? 1 : cards.length;
      if (sourceChara.health <= 24 * cost) {
        actionAble = false;
      }
    }
    // 行动点消耗修正 
    if (cost < 0) {
      cost = 0;
    }
    // 状态【冰封】【梦境】【星牢】【造梦】【窒息】
    if (sourceChara.hasStatus(StatusId.frozen.id) || sourceChara.hasStatus(StatusId.dreaming.id) || 
      sourceChara.hasStatus(StatusId.stellarCage.id) || sourceChara.hasStatus(StatusId.dreamCrafting.id) || 
      sourceChara.hasStatus(StatusId.asphyxia.id)) {
      actionAble = false;
    }
    // 技能【追击】
    if (sourceChara.hasHiddenStatus('chase') && !targetChara.hasHiddenStatus('chased')) {
      actionAble = false;
    }
    // 卿别【夜魇游吟】
    if (sourceChara.hasHiddenStatus('dream_src') && !targetChara.hasHiddenStatus('dream_tar')) {
      actionAble = false;
    }
    // 卿别【安魂乐章】
    if (sourceChara.hasHiddenStatus('requiem') && target != CharacterId.valedictus.id) {
      actionAble = false;
    }
    // 好好先生【深重情谊】
    if (sourceChara.hasHiddenStatus('favor') && target == CharacterId.mrNice.id) {
      actionAble = false;
    }
    // 太夕【谜渊漩涡】
    if (sourceChara.hasHiddenStatus('taunt') && !targetChara.hasHiddenStatus('abyss')) {
      actionAble = false;
    }
    // 祝言夙【精神干扰】
    if (sourceChara.hasHiddenStatus('disruption')) {
      actionAble = false;      
      modifyCardCount(source, target, cards.length, CardEventType.play);
      sourceChara.actionTime--;
    }
    // 祝言夙【灵魂震荡】
    if (sourceChara.hasHiddenStatus('soul_tremor') && sourceChara.movePoint < 2) {
      actionAble = false;
    }
    // 蓝文策【探囊取物】
    if (sourceChara.hasHiddenStatus('pluck') && !targetChara.hasHiddenStatus('pluck_tar')) {
      actionAble = false;
    }
    // K97【二进制噪声】
    if (sourceChara.hasHiddenStatus('binary') && cards.length != 1) {
      actionAble = false;
    }
    // 曙光【不容质疑的信任】
    if (sourceChara.hasHiddenStatus('unquestion') && cards.isNotEmpty) { 
      actionAble = false;
    }
    // 状态【障目】
    if (actionAble && sourceChara.hasStatus(StatusId.oculusVeil.id)) {
      int oculusVeilPoint = cardsArgs['oculusVeilPoint'] as int? ?? 2;
      throwDice(source, source, oculusVeilPoint, 2, DiceType.status);
      if (oculusVeilPoint == 1) {
        actionAble = false;
        addAttribute(source, AttributeType.movepoint, -cost);
        modifyCardCount(source, target, cards.length, CardEventType.play);
        sourceChara.actionTime--;
      }
    }    
    // 行动次数不足
    if (sourceChara.actionTime <= 0) {
      actionAble = false;
    }
     
    // 不能对自身行动
    if (source == target) {
      actionAble = false;
    }
    // 玩家死亡
    if (sourceChara.isDead || targetChara.isDead) {
      actionAble = false;
    }
    // 行动可用
    if (actionAble) {
      // 行动点减少
      if (source == CharacterId.engine4.id) {
        damagePlayer(source, source, 24 * cost, DamageType.lost);
      }
      else {
        addAttribute(source, AttributeType.movepoint, -cost);
      }

      // 行动次数减少
      //sourceChara.actionTime--;
      addAttribute(source, AttributeType.actiontime, -1);

      // 使用道具
      modifyCardCount(source, target, cards.length, CardEventType.play);
      for (int i = 0; i < cards.length; i++) {
        Map<String, dynamic> cardData = cardSettings[i].toJson();
        castCard(source, [target], cards[i], cardData);
      }

      // 状态【烛焱】
      if (sourceChara.hasStatus(StatusId.lumenFlare.id) && !sourceChara.hasHiddenStatus('rest')) {
        sourceChara.increaseStatusData(StatusId.lumenFlare.id, intData: 1);
      }
      // 状态【磨砺】
      if (sourceChara.hasStatus(StatusId.teroxis.id) && !sourceChara.hasHiddenStatus('rest') 
        && sourceChara.getStatusIntData(StatusId.teroxis.id, StatusData.intensity) < 5) {
        modifyStatusIntensity(source, source, StatusId.teroxis.id, 1);
      }

      // 应用攻击特效
      // 特效【烛焱】
      if (sourceChara.hasStatus(StatusId.lumenFlare.id)) {
        int lumenFlarePoint = cardsArgs['lumenFlarePoint'] as int? ?? 10;
        throwDice(source, target, lumenFlarePoint, 10, DiceType.status);
        if (sourceChara.getStatusIntData(StatusId.lumenFlare.id, StatusData.intData) % 3 == 0 && lumenFlarePoint <= 8
          || lumenFlarePoint <= 2) {
          addStatus(source, target, StatusId.flaming.id, 3, 1);
        }
      }

      // 特效【反胃】
      if (sourceChara.hasStatus(StatusId.nausea.id)) {
        int nauseaPoint = cardsArgs['nauseaPoint'] as int? ?? 1;
        throwDice(source, target, nauseaPoint, 6, DiceType.status);
        if ({2, 4, 6}.contains(nauseaPoint)) {
          addHiddenStatus(source, 'void', 0, 1);
        }
      }

      // 染序【五采】
      if (source == CharacterId.ranXu.id && !sourceChara.hasHiddenStatus('rest')) {
        castTrait(source, [target], TraitId.iridescentHue.id, {'cardList': cards});
      }
      for (int i = 0; i < sourceChara.getHiddenStatusIntData('color_yellow', StatusData.intensity); i++) {
        addAttribute(source, AttributeType.armor, sourceChara.health ~/ 10);
      }
      for (int i = 0; i < sourceChara.getHiddenStatusIntData('color_white', StatusData.intensity); i++) {
        damagePlayer(source, target, targetChara.health ~/ 10, DamageType.physical);
      }
      for (int i = 0; i < sourceChara.getHiddenStatusIntData('color_black', StatusData.intensity); i++) {
        addStatus(source, target, StatusId.frost.id, 2, 2);
      }
      for (int i = 0; i < sourceChara.getHiddenStatusIntData('color_red', StatusData.intensity); i++) {
        addStatus(source, target, StatusId.flaming.id, 2, 2);
      }
      for (int i = 0; i < sourceChara.getHiddenStatusIntData('color_green', StatusData.intensity); i++) {
        healPlayer(source, source, (sourceChara.maxHealth - sourceChara.health) ~/ 10, DamageType.heal);
      }

      if (sourceChara.hasHiddenStatus('kindle_yellow')) {
        addHiddenStatus(source, 'barrier', 0, -1);
      }
      if (sourceChara.hasHiddenStatus('kindle_white')) {
        addStatus(source, target, StatusId.wounded.id, 5, 2);
      }
      if (sourceChara.hasHiddenStatus('kindle_black')) {
        addStatus(source, target, StatusId.fragility.id, 2, 2);
      }
      if (sourceChara.hasHiddenStatus('kindle_red')) {
        addStatus(source, target, StatusId.uneasiness.id, 2, 2);
      }
      if (sourceChara.hasHiddenStatus('kindle_green')) {
        addAttribute(source, AttributeType.maxhp, 150);
      }
      // 观风【气象万千】
      if (source == CharacterId.viento.id && sourceChara.hasHiddenStatus('weather')) {
        if (!sourceChara.hasHiddenStatus('rest')) {
          List<StatusRecord> statusRecords = _recordProvider!.getFilteredRecords(type: RecordType.status, target: target).cast<StatusRecord>();
          String stat = statusRecords.lastWhere((e) => statusToType[e.name]!.buffType == BuffType.negative && e.changeType == StatusChange.add
            && targetChara.hasStatus(e.name), orElse: () => StatusRecord(source: '', target: '', name: '', paramsOld: [], paramsNew: [], 
            changeType: StatusChange.add, tag: '', turn: GameTurn(round: 1, turn: 1, extra: 0))).name;
          if (stat != '') {
            modifyStatusLayer(source, target, stat, sourceChara.getHiddenStatusIntData('cloud', StatusData.intensity));
            if (statusToType[stat]!.hasIntensity) {
              modifyStatusIntensity(source, target, stat, 2 * sourceChara.getHiddenStatusIntData('wind', StatusData.intensity));
            }
            else {
              modifyStatusLayer(source, target, stat, sourceChara.getHiddenStatusIntData('wind', StatusData.intensity));
            }
            modifyHiddenStatusIntensity(source, 'wind', -sourceChara.getHiddenStatusIntData('wind', StatusData.intensity));
            modifyHiddenStatusIntensity(source, 'cloud', -sourceChara.getHiddenStatusIntData('cloud', StatusData.intensity));
          }
        }
        else {
          List<StatusRecord> statusRecords = _recordProvider!.getFilteredRecords(type: RecordType.status, target: source).cast<StatusRecord>();
          String stat = statusRecords.lastWhere((e) => statusToType[e.name]!.buffType == BuffType.positive && e.changeType == StatusChange.add
            && sourceChara.hasStatus(e.name), orElse: () => StatusRecord(source: '', target: '', name: '', paramsOld: [], paramsNew: [], 
            changeType: StatusChange.add, tag: '', turn: GameTurn(round: 1, turn: 1, extra: 0))).name;
          if (stat != '') {
            modifyStatusLayer(source, source, stat, sourceChara.getHiddenStatusIntData('cloud', StatusData.intensity));
            if (statusToType[stat]!.hasIntensity) {
              modifyStatusIntensity(source, source, stat, 2 * sourceChara.getHiddenStatusIntData('wind', StatusData.intensity));
            }
            else {
              modifyStatusLayer(source, source, stat, sourceChara.getHiddenStatusIntData('wind', StatusData.intensity));
            }
            modifyHiddenStatusIntensity(source, 'wind', -sourceChara.getHiddenStatusIntData('wind', StatusData.intensity));
            modifyHiddenStatusIntensity(source, 'cloud', -sourceChara.getHiddenStatusIntData('cloud', StatusData.intensity));
          }
        }
      }
      // 安提忒斯【冰与火之歌】
      if (source == CharacterId.antithesis.id && sourceChara.hasHiddenStatus('ice_and_fire') 
        &&!sourceChara.hasHiddenStatus('rest')) {
        String status = sourceChara.getHiddenStatusStringData('ice_and_fire', StatusData.strData);
        if (statusToType[status]!.hasIntensity) {
          addStatus(source, target, status, 2 + sourceChara.getStatusIntData(status, StatusData.intensity), 
          sourceChara.getStatusIntData(status, StatusData.layer));
        }
        else {
          addStatus(source, target, status, 0, sourceChara.getStatusIntData(status, StatusData.layer));
        }
        removeStatus(source, source, status);
      }

      // 应用防守特效
      // 特效【蚀凛】
      if (targetChara.hasStatus(StatusId.erodeGelid.id)) {
        int erodeGelidPoint = cardsArgs['erodeGelidPoint'] as int? ?? 1;
        throwDice(source, target, erodeGelidPoint, 10, DiceType.status);
        if (erodeGelidPoint >= 9 - 2 * targetChara.getStatusIntData(StatusId.erodeGelid.id, StatusData.intData)) {
          addStatus(target, source, StatusId.frost.id, 2, 1);
          targetChara.setStatusData(StatusId.erodeGelid.id, intData: 0);
        } else {
          targetChara.increaseStatusData(StatusId.erodeGelid.id, intData: 1);
        }
      }

      // 特质结算
      // 好好先生【见面礼】
      if (source == CharacterId.mrNice.id && !sourceChara.hasHiddenStatus('rest')) {
        castTrait(source, [target], TraitId.introductoryGift.id);
      }
      // 科亚特尔【拟造“伊甸园”】
      else if (source == CharacterId.quetzalcoatl.id && !sourceChara.hasHiddenStatus('sanctify')) {
        attackMulti *= 1.5;
        removeHiddenStatus(source, 'sanctify');
      }
      // 阿波菲斯【毁灭暗影】
      else if (source == CharacterId.apophis.id && !sourceChara.hasHiddenStatus('rest')) {
        castTrait(source, [target], TraitId.ruinousShade.id, {'type': 0});
      }
      // 红黎【红莲业火】
      else if (source == CharacterId.dimpsy.id && !sourceChara.hasHiddenStatus('rest')) {
        castTrait(source, [target], TraitId.lotusFlame.id, {'type': 0});
      }
      // 雷刚【决意的乌托邦】
      else if (source == CharacterId.leiGang.id) {
        castTrait(source, [target], TraitId.utopiaOfResolve.id, {'type': 1, 'cardList': cards});
        castTrait(source, [target], TraitId.utopiaOfResolve.id, {'type': 2, 'cardList': cards});
      }
      // 安山定【后发的乌托邦】
      else if (source == CharacterId.anShanding.id && sourceChara.hasHiddenStatus('upspring')) {
        removeHiddenStatus(source, 'upspring');
      }
      // 亭歆雨【彼岸之金】
      else if (source == CharacterId.tingXinyu.id) {
        castTrait(source, [target], TraitId.aurelysium.id, {'cardList': cards});
      }
      // 翠灵【破土】
      else if (source == CharacterId.turbach.id) {
        final turbachId = CharacterId.turbach.id;
        var enemies = players.values.where((e) => e.id != 'empty' && isEnemy(e.id, turbachId) && !e.isDead).toList();
        enemies.sort((a, b) => b.health.compareTo(a.health));
        if (enemies.isNotEmpty) {
          List<String> earthBreakTargets = [enemies.first.id];
          if (enemies.length > 1) {
            earthBreakTargets.add(enemies[1].id);
          }
          castTrait(source, earthBreakTargets, TraitId.earthBreak.id, {'cardList': cards});
        }
      }
      // 符楹【光暗双生】
      else if (source == CharacterId.fuYing.id && !sourceChara.hasHiddenStatus('rest')) {
        int geminiIntensity = sourceChara.getHiddenStatusIntData('gemini', StatusData.intensity) % 2;
        castTrait(source, [target], TraitId.lumenUmbraGemini.id, {'type': geminiIntensity + 1});
      }
      // 祝烨诚【凛息】
      else if (source == CharacterId.zhuYecheng.id && !sourceChara.hasHiddenStatus('rest')) {
        castTrait(source, [target], TraitId.icyStillness.id, {'type': 0});
        castTrait(source, [target], TraitId.icyStillness.id, {'type': 2, 'cardList': cards});
      }
      // 焰心剑【陨光之刃】【山河剑意】
      else if (source == CharacterId.emberBlade.id) {
        if (!sourceChara.hasHiddenStatus('rest')) {
          castTrait(source, [target], TraitId.lightfallBlade.id, {'type': 0});
          castTrait(source, [target], TraitId.lightfallBlade.id, {'type': 1, 'cardList': cards});
        }        
        castTrait(source, [target], TraitId.landsGraceSwordsSoul.id, {'cardList': cards});
      }
      // 好好先生【深重情谊】
      if (target == CharacterId.mrNice.id && !sourceChara.hasHiddenStatus('rest')){
        castTrait(target, [source], TraitId.imposingFavor.id);
      }
      // 奥赛罗【黑白棋】
      if (isCharacterInGame(CharacterId.othello.id) && !sourceChara.hasHiddenStatus('rest')) {
        final othelloId = CharacterId.othello.id;
        castTrait(othelloId, [source], TraitId.reversi.id, {'type': 0});
      }
      // K97【二进制噪声】
      if (sourceChara.hasHiddenStatus('binary')) {
        removeHiddenStatus(source, 'binary');
      }
      
      // 状态结算
      // 阿波菲斯【毁灭暗影】
      if (isCharacterInGame(CharacterId.apophis.id) && sourceChara.hasStatus(StatusId.nightmare.id) 
        && sourceChara.getHiddenStatusIntData('night', StatusData.intensity) < 3) {
        Character chara = players[CharacterId.apophis.id]!;
        if (sourceChara.hasStatus(StatusId.eden.id)) {
              damagePlayer(chara.id, source, 20 + 40 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.magical);
              healPlayer(chara.id, chara.id, 10 + 20 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.heal);
        } else { 
          damagePlayer(chara.id, source, 10 + 20 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.magical);
          healPlayer(chara.id, chara.id, 5 + 10 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.heal);
        }
        addHiddenStatus(source, 'night', 1, -1);
        addHiddenStatus(chara.id, 'night', 1, -1);
        castTrait(chara.id, [source], TraitId.ruinousShade.id, {'type': 1});
      }
      // 符楹【邪能侵袭】
      if (sourceChara.hasStatus(StatusId.tenebrae.id)) {
        damagePlayer(source, target, targetChara.maxHealth ~/ 20, DamageType.magical);
      }

      // 投掷骰子
      int maxPoint = sourceChara.getHiddenStatusIntData('dice_size', StatusData.intensity) == -1 ? 4 
      : sourceChara.getHiddenStatusIntData('dice_size', StatusData.intensity);
      // 云云子【晨昏寥落】
      if (sourceChara.hasTrait(TraitId.duskVoid.id)) {
        List<int> maxPointRef = [maxPoint];
        castTrait(source, [source], TraitId.duskVoid.id, {'type': 1, 'maxPointRef': maxPointRef});
        maxPoint = maxPointRef[0];
      }

      // π123【二进制成对】
      if (sourceChara.hasTrait(TraitId.binaryDyad.id) && sourceChara.hasHiddenStatus('dyad')) {
        point = throwDice(source, target, point, 2, DiceType.action);
      } else {
        point = throwDice(source, target, point, maxPoint, DiceType.action);
      }
      

      // 计算伤害
      // 道具【鼓舞】
      if (sourceChara.hasHiddenStatus('hero_legend')) {
        attackPlus += 10 * sourceChara.getHiddenStatusIntData('hero_legend', StatusData.intensity);
        removeHiddenStatus(source, 'hero_legend');
      }
      // 道具【加护】
      if (targetChara.hasHiddenStatus('dream_shelter')) {
        defencePlus += 10 * targetChara.getHiddenStatusIntData('dream_shelter', StatusData.intensity);
        removeHiddenStatus(target, 'dream_shelter');
      }
      // 道具【纳米渗透】
      if (sourceChara.hasHiddenStatus('nano')) {
        defencePlus -= targetChara.defence;
        removeHiddenStatus(source, 'nano');
      }

      attack = sourceChara.attack;
      defence = targetChara.defence;
      double modifiedAttack = (attack + attackPlus) * attackMulti;
      double modifiedDefence = (defence + defencePlus) * defenceMulti;
      double baseDamage = (modifiedAttack > modifiedDefence) ? point * (modifiedAttack - modifiedDefence) : 5 + 0.1 * modifiedAttack;

      // 特质结算
      // 岚【血灵斩】
      if (sourceChara.hasTrait(TraitId.hemaSlash.id) && sourceChara.hasHiddenStatus('hema') && sourceChara.actionTime == 1) {
        addAttribute(source, AttributeType.attack, 15);
      }
      // 洛尔【毫无章法的进攻】
      if (source == CharacterId.lor.id) {
        castTrait(source, [target], TraitId.chaoticStrikes.id, {'type': 0, 'point': point});
        castTrait(source, [target], TraitId.chaoticStrikes.id, {'type': 1, 'point': point});
      }

      // 伤害结算
      if (!sourceChara.hasHiddenStatus('rest')) {
        // 云云子【晨昏寥落】
        if (sourceChara.hasTrait(TraitId.duskVoid.id)) {
          List<double> baseDamageRef = [baseDamage];
          List<DamageType> damageTypeRef = [DamageType.action];
          castTrait(source, [target], TraitId.duskVoid.id, {'type': 0, 'baseDamageRef': baseDamageRef, 'attack': (attack + attackPlus), 
            'attackMulti': attackMulti, 'point': point, 'damageTypeRef': damageTypeRef});
          baseDamage = baseDamageRef[0];
          DamageType damageType = damageTypeRef[0];
          if (sourceChara.hasHiddenStatus('critical')) {
            damageType = DamageType.lost;
          }
          damagePlayer(source, target, baseDamage.toInt(), damageType);    
        }
        else if (sourceChara.hasHiddenStatus('critical')) {
          damagePlayer(source, target, baseDamage.toInt(), DamageType.lost);
        }
        else {
          damagePlayer(source, target, baseDamage.toInt(), DamageType.action);
        }
      }
      // 记录行动
      _recordProvider!.addActionRecord(getGameTurn(), source, target, point, cards, !sourceChara.hasHiddenStatus('rest'));
      _gameLogger!.addActionLog(getGameTurn(), source, target, point, cards.toString(), 
        'attack: $attack, defence: $defence, attackPlus: $attackPlus, defencePlus: $defencePlus, attackMulti: $attackMulti, defenceMulti: $defenceMulti, point: $point, attacked: ${!sourceChara.hasHiddenStatus('rest')}');
      removeHiddenStatus(source, 'rest');
      refresh();
    }

    return actionAble;
  }

  // 使用技能
  bool castSkill(String source, List<String> targets, String skill, [Map<String, dynamic>? args]){
    bool skillAble = true;
    int movePointCost = 0;
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    Map<String, dynamic> skillData = args ?? {};
    // 技能发动条件
    // 仁慈
    if (skill == SkillId.benevolence.id) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
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
    else if (skill == SkillId.phaseTransition.id) {
      movePointCost = 2;
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
    }
    // 阈限
    else if (skill == SkillId.threshold.id) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
      else {
        skillAble = false;
        for (var record in damageRecords) {
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damage >= 250) {
            skillAble = true;
            break;
          }
        }
      }
    }
    // 追击
    else if (skill == SkillId.chase.id) {
      List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
        target: target, startTurn: getGameTurn(), endTurn: getGameTurn());
      if (actionRecords.isEmpty) {
        skillAble = false;
      }
      if (targetChara.health > 300) {
        skillAble = false;
      }
    }
    // 最后的希望
    else if (skill == SkillId.finaleHope.id) {
      movePointCost = 2;
    }
    // 不死
    else if (skill == SkillId.undying.id) {
      if (sourceChara.health > 0) {
        skillAble = false;
      }
    }
    // 止杀
    else if (skill == SkillId.killCeasing.id) {
      if (targetChara.damageDealtTurn < 200) {
        skillAble = false;
      }
    }
    // 镜像
    else if (skill == SkillId.inversion.id) {
      movePointCost = 1;
    }
    // 奇点
    else if (skill == SkillId.singularity.id) {
      movePointCost = 2;
    }
    // 瞬影
    else if (skill == SkillId.flashShade.id) {
      movePointCost = 1;
    }
    // 逆转乾坤
    else if (skill == SkillId.karmaReversal.id) {
      movePointCost = 2;
    }
    // 黯星【屠杀】
    else if (skill == SkillId.massacre.id) {
      List<GameRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn());
      if (damageRecords.isEmpty) {
        skillAble = false;
      }
      else {
        skillAble = false;
        for (var record in damageRecords) {
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damage >= 250) {
            skillAble = true;
            break;
          }
        }
      }
    }
    // 敏博士【异镜解构】
    else if (skill == SkillId.deconstruction.id) {
      if (sourceChara.movePoint < 1) {
        skillAble = false;
      }
    }
    // 卿别【安魂乐章】
    else if (skill == SkillId.requiem.id) {
      if (!targetChara.hasStatus(StatusId.dreaming.id)) {
        skillAble = false;
      }
    }
    // 炎焕【赤焱炼狱】
    else if (skill == SkillId.crimsonInferno.id) {
      if (targets.length > 3) {
        skillAble = false;
      }
    }
    // 斯威芬【造梦者】
    else if (skill == SkillId.dreamWeaver.id) {
      int point = skillData['point'];
      int dreamCount = sourceChara.getHiddenStatusIntData('dreaming', StatusData.intensity);
      if ((dreamCount + 1) ~/ 2 < point) {
        skillAble = false;
      }
    }
    // 红烬【封焰的135秒】
    else if (skill == SkillId.sealedFlame135Seconds.id) {
      int flamingLayer = 0;
      for (var chara in players.values) {
        if (chara.hasStatus(StatusId.flaming.id)) {
          flamingLayer += chara.getStatusIntData(StatusId.flaming.id, StatusData.layer);
        }
      }
      if (flamingLayer < 6) {
        skillAble = false;
      }
      List<ActionRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source, 
        startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
      if (actionRecords.isEmpty) {
        skillAble = false;
      }
    }
    // 好好先生【礼尚往来】
    else if (skill == SkillId.giveAndTake.id) {
      if (!targetChara.hasHiddenStatus('intro_gift')) {
        skillAble = false;
      }      
    }
    // 叶姬【永恒】
    else if (skill == SkillId.eternity.id) {
      String status = skillData['status'];
      int point = skillData['point'];
      if (status == '' || !statusToType[status]!.hasLayer || sourceChara.cardCount < point || point > 3) {
        skillAble = false;
      }
    }
    // 科亚特尔【天启之庭】
    else if (skill == SkillId.apocalypticCourt.id) {
      if (targets.length > 3) {
        skillAble = false;
      }
    }
    // 祝烨明【八寒之七】
    else if (skill == SkillId.seventhFrost.id) {
      String status = skillData['status'];
      if (status == '') {
        skillAble = false;
      }
    }
    // 方塔索【入梦之手】
    else if (skill == SkillId.dreamGrasp.id) {
      if (gameSequence.length - targets.length > 3) {
        skillAble = false;
      }
    }
    // 颜若卿【补给】
    else if (skill == SkillId.replenishment.id) {
      if (sourceChara.health < 250 || sourceChara.cardCount < 1) {
        skillAble = false;
      }
    }
    // 白谢【冰灭的135小节】
    else if (skill == SkillId.icyOblivion135Bars.id) {
      int frostLayer = 0;
      for (var chara in players.values) {
        if (chara.hasStatus(StatusId.frost.id)) {
          frostLayer += chara.getStatusIntData(StatusId.frost.id, StatusData.layer);
        }
      }
      if (sourceChara.health < 100 * targets.length - frostLayer * 50) {
        skillAble = false;
      }
      if (targets.length > 3 || targets.isEmpty){
        skillAble = false;
      }
    }
    else if (skill == SkillId.frostShatter.id) {
      if (targets.length > 2 || targets.isEmpty) {
        skillAble = false;
      }
    }
    // 符楹【秩序结界】
    else if (skill == SkillId.orderAegis.id) {
      if (sourceChara.getHiddenStatusIntData('gemini', StatusData.intensity) % 2 != 0) {
        skillAble = false;
      }
      if (targets.length > 3) {
        skillAble = false;
      }
    }
    // 符楹【邪能侵袭】
    else if (skill == SkillId.chaosIncursion.id) {
      if (sourceChara.getHiddenStatusIntData('gemini', StatusData.intensity) % 2 != 1) {
        skillAble = false;
      }
    }
    // 埃诺雅【溯洄】
    else if (skill == SkillId.anabasis.id) {
      movePointCost = 1;
    }
    // 蓝文曦【去伪存真】
    else if (skill == SkillId.veritasNonFalsitas.id) {
      int point = skillData['point'];
      if (point > 4 || point < 1) {
        skillAble = false;
      }
    }
    // 状态【混乱】【冰封】【梦境】【星牢】【造梦】
    if (sourceChara.hasStatus(StatusId.confusion.id) || sourceChara.hasStatus(StatusId.frozen.id) || 
          sourceChara.hasStatus(StatusId.dreaming.id) || sourceChara.hasStatus(StatusId.stellarCage.id) ||
          sourceChara.hasStatus(StatusId.dreamCrafting.id)){
      skillAble = false;
    }
    // 技能【净化】
    if (skill == SkillId.purification.id) {
      skillAble = true;
    }
    // 冷却未转好
    if (sourceChara.skill.keys.contains(skill)){
      if (sourceChara.skill[skill]!.cooldown > 0){
        skillAble = false;
      }
    }
    // 唐菁延【盈光】
    if (source == CharacterId.tangJingyan.id) {
      List<int> costRef = [movePointCost];
      castTrait(source, [source], TraitId.radiantFullness.id, {'costRef': costRef});
      movePointCost = costRef[0];
    }
    // 卡拉卡【友情防守】
    if (isCharacterInGame(CharacterId.karak.id)) {
      if (isEnemy(source, CharacterId.karak.id) && isTeammate(target, CharacterId.karak.id)) {
        List<int> costRef = [movePointCost];
        castTrait(CharacterId.karak.id, [source], TraitId.buddyBlock.id, {'type': 0, 'costRef': costRef});
        movePointCost = costRef[0];
      }
    }
    // 司库【裁虚留要】
    if (sourceChara.hasTrait(TraitId.essenceOverIllusion.id)) {
      List<int> costRef = [movePointCost];
      List<bool> skillAbleRef = [skillAble];
      final int cooldown = skillToType[skill]!.cooldown;
      castTrait(source, [source], TraitId.essenceOverIllusion.id, {'cooldown': cooldown, 'costRef': costRef, 'skillAbleRef': skillAbleRef});
      skillAble = skillAbleRef[0];
      movePointCost = costRef[0];
      modifySkillCooldown(source, source, skill, skillToType[skill]!.cooldown);
    }
    // 长霾【律令·禁空】
    if (sourceChara.hasHiddenStatus('non_flying')) {
      movePointCost++;
    }
    // 行动点不足
    if (movePointCost > sourceChara.movePoint) {
      skillAble = false;
    }
    // 亭歆雨【彼岸之金】
    if (sourceChara.hasHiddenStatus('weird')) {
      skillAble = false;
    }
    // 沉默
    if (skillAble) {
      if (sourceChara.hasHiddenStatus('reticence')){
        modifySkillCooldown(source, source, skill, skillToType[skill]!.cooldown);
        skillAble = false;
      }
    }
    // 玩家死亡
    if (sourceChara.isDead || targetChara.isDead) {
      skillAble = false;
    }
    // 技能可用
    if (skillAble) {
      addAttribute(source, AttributeType.movepoint, -movePointCost);
      // 仁慈
      if (skill == SkillId.benevolence.id) {
        int type = skillData['type'];
        if (type == 1) {          
          modifyCardCount(source, target, 2, CardEventType.draw);
        }
        else {
          healPlayer(source, source, sourceChara.maxHealth ~/ 5, DamageType.heal);
        }
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        int maxDamage = 0;
        for (var damageRecord in damageRecords) {
          if (damageRecord.damage > maxDamage) {
            maxDamage = damageRecord.damage;
          }
        }
        for (var damageRecord in damageRecords) {
          if (damageRecord.damage == maxDamage) {
            _recordProvider!.removeRecord(damageRecord);
            break;
          }
        }
        addAttribute(target, AttributeType.health, maxDamage);
        addAttribute(target, AttributeType.dmgreceived, -maxDamage);
        addAttribute(source, AttributeType.dmgdealt, -maxDamage);
      }
      // 相转移
      else if (skill == SkillId.phaseTransition.id) {
        Map<String, int> damageDealer = {};
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        for (var record in damageRecords) {
          if (damageDealer.containsKey(record.source)) {
            damageDealer[record.source] = damageDealer[record.source]! + record.damage;
          }
          else {
            damageDealer[record.source] = record.damage;
          }
          _recordProvider!.removeRecord(record);
        }
        addAttribute(source, AttributeType.health, sourceChara.damageReceivedTurn);
        addAttribute(source, AttributeType.dmgreceived, sourceChara.damageReceivedTurn);
        for (var dmgSource in damageDealer.keys) {
          addAttribute(dmgSource, AttributeType.dmgreceived, -damageDealer[dmgSource]!);
          damagePlayer(dmgSource, target, damageDealer[dmgSource]!, DamageType.physical);
        }
      }
      // 天国邮递员
      else if (skill == SkillId.heavenDelivery.id) {
        addHiddenStatus(target, 'heaven', 0, 1);
        addHiddenStatus(source, 'heaven', 0, 1);
        if (sourceChara.hasHiddenStatus('heaven')) {
          //sourceChara.hiddenStatus['heaven']![2] += 1;
          //sourceChara.setHiddenStatusData('heaven', layerFraction: sourceChara.getHiddenStatusIntData('heaven', StatusData.layerFraction) + 1);
          sourceChara.increaseHiddenStatusData('heaven', layerFraction: 1);
        }        
      }
      // 净化
      else if (skill == SkillId.purification.id) {
        List<dynamic> statusKeys = targetChara.status.keys.toList();
        for (var stat in statusKeys) {
          removeStatus(source, target, stat);
        }
      }
      // 嗜血
      else if (skill == SkillId.bloodThirst.id) {
        healPlayer(source, source, sourceChara.damageDealtTurn ~/ 2, DamageType.heal);
      }
      // 外星人
      else if (skill == SkillId.stellar.id) {
        addStatus(source, target, StatusId.stellarCage.id, 0, 1);
      }
      // 恐吓
      else if (skill == SkillId.intimidation.id) {
        /*int point = skillData['point'];
        throwDice(source, source, point, 6, DiceType.skill);
        if ({3, 6}.contains(point)) {
          addHiddenStatus(source, 'intimidation', 0, 1);
        }*/
        addHiddenStatus(source, 'intimidation', 0, 0);
        addStatus(source, target, StatusId.uneasiness.id, 1, 1);
      }
      // 阈限
      else if (skill == SkillId.threshold.id) {
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        int maxDamage = 0;
        String maxDmgSource = '';
        for (var record in damageRecords) {
          if (record.damage > maxDamage && {DamageType.action, DamageType.physical, DamageType.magical}.contains(record.damageType)) {
            maxDamage = record.damage;
            maxDmgSource = record.source;
          }
        }
        for (var record in damageRecords) {
          if (record.damage == maxDamage) {
            _recordProvider!.removeRecord(record);
            break;
          }
        }
        addAttribute(source, AttributeType.health, maxDamage - 100);
        addAttribute(source, AttributeType.dmgreceived, -maxDamage);
        addAttribute(maxDmgSource, AttributeType.dmgdealt, -maxDamage);
      }
      // 强化
      else if (skill == SkillId.reinforcement.id) {
        addHiddenStatus(source, 'reinforcement', 0, 1);
      }
      // 追击
      else if (skill == SkillId.chase.id) {
        addHiddenStatus(source, 'extra', 0, 1);
        addHiddenStatus(source, 'chase', 0, 1);
        addHiddenStatus(target, 'chased', 0, 1);
      }
      // 沉默
      else if (skill == SkillId.reticence.id) {
        addHiddenStatus(target, 'reticence', 0, 1);
      }
      // 奉献
      else if (skill == SkillId.devotion.id) {
        int point = skillData['point'];
        damagePlayer('empty', source, 100 * point, DamageType.lost);
        healPlayer(source, target, 100 * point, DamageType.heal);
        if (point >= 2) {          
          modifyCardCount(source, target, point - 1, CardEventType.draw);
        }
      }
      // 屏障
      else if (skill == SkillId.barrier.id) {
        addAttribute(source, AttributeType.armor, 150);
        addHiddenStatus(source, 'barrier', 0, -1);
      }
      // 镭射
      else if (skill == SkillId.laser.id) {
        damagePlayer(source, target, 60, DamageType.physical);
        addStatus(source, target, StatusId.fragility.id, 2, 1);
      }
      // 不死
      else if (skill == SkillId.undying.id) {
        sourceChara.isDead = false;
        healPlayer(source, source, 200 - sourceChara.health, DamageType.revive);
        addAttribute(source, AttributeType.armor, 400);
        addHiddenStatus(source, 'undying', 0, 2);
      }
      // 止杀
      else if (skill == SkillId.killCeasing.id) {
        modifyCardCount(source, target, 2, CardEventType.grab);
        addStatus(source, target, StatusId.exhausted.id, 1, 1);
      }
      // 灵能注入
      else if (skill == SkillId.psionia.id) {
        damagePlayer('empty', source, 75, DamageType.lost);
      }
      // 镜像
      else if (skill == SkillId.inversion.id) {
        addStatus(source, target, StatusId.mirror.id, 0, 3);
        addHiddenStatus(target, 'mirror', 0, 3);
        modifyHiddenStatusIntensity(target, 'mirror', targetChara.damageReceivedTotal);
      }
      // 分裂
      else if (skill == SkillId.fission.id) {
        addHiddenStatus(source, 'fission', 0, 1);
        addHiddenStatus(target, 'fission_target', 0, 1);
      }
      // 透支
      else if (skill == SkillId.overdraw.id) {
        addStatus(source, source, StatusId.burnOut.id, 5, 1);
      }
      // 挑唆
      else if (skill == SkillId.instigation.id) {
        Map<String, int> points = skillData['points'];
        Map<String, int> isInstigated = skillData['isInstigated'];
        for (var chara in players.values) {
          if (chara.id != source && chara.id != 'empty') {
            int point = points[chara.id]!;
            if (isInstigated[chara.id] == 0) {
              int damage = sourceChara.attack > chara.defence ? (sourceChara.attack - chara.defence) * point : 
                5 + sourceChara.attack ~/ 10;
                damagePlayer(source, chara.id, damage, DamageType.physical);
            }
            else {
              Character nextChara = gameSequence.indexOf(chara.id) == gameSequence.length - 1 ? 
                players[gameSequence.first]! : players[gameSequence[gameSequence.indexOf(chara.id) + 1]]!;
              int damage = chara.attack > nextChara.defence ? (chara.attack - nextChara.defence) * point : 
                5 + chara.attack ~/ 10;
              damagePlayer(chara.id, nextChara.id, damage, DamageType.physical);
            }
          }
        }
      }
      // 开阳
      else if (skill == SkillId.mizar.id) {        
        modifyCardCount(source, target, 1, CardEventType.gain);
      }
      // 太阴
      else if (skill == SkillId.lunar.id) {
        modifyCardCount(source, target, 2, CardEventType.discard);
      }
      // 博览
      else if (skill == SkillId.perusing.id) {        
        modifyCardCount(source, target, 1, CardEventType.gain);
      }
      // 反重力
      else if (skill == SkillId.antiGravity.id) {
        countdown.antiGravity++;
      }
      // 奇点
      else if (skill == SkillId.singularity.id) {
        damagePlayer('empty', target, 300, DamageType.lost);
      }
      // 魂怨
      else if (skill == SkillId.soulRancor.id) {
        for (var charaId in targets) {
          damagePlayer(source, charaId, 50, DamageType.physical, isAOE: true);
        }
      }
      // 瞬影
      else if (skill == SkillId.flashShade.id) {
        addHiddenStatus(source, 'extra', 0, 1);
      }
      // 侵蚀
      else if (skill == SkillId.corrosion.id) {
        addStatus(source, target, StatusId.corroded.id, 3, 1);
      }
      // 逆转乾坤
      else if (skill == SkillId.karmaReversal.id) {
        int tempHp = sourceChara.health;
        int tempMp = sourceChara.movePoint;
        int tempCard = sourceChara.cardCount;
        addAttribute(source, AttributeType.health, targetChara.health - sourceChara.health);
        addAttribute(source, AttributeType.movepoint, targetChara.movePoint - sourceChara.movePoint);        
        modifyCardCount(source, target, targetChara.cardCount, CardEventType.grab);
        addAttribute(target, AttributeType.health, tempHp - targetChara.health);
        addAttribute(target, AttributeType.movepoint, tempMp - targetChara.movePoint);        
        modifyCardCount(target, source, tempCard, CardEventType.grab);
      }
      // 极速
      else if (skill == SkillId.velocity.id) {
        addHiddenStatus(source, 'velocity', 0, 1);
      }
      // 空袭
      else if (skill == SkillId.airstrike.id) {
        damagePlayer(source, target, 100, DamageType.physical);
        if (target == source || isTeammate(source, target)) {
          modifyCardCount(target, source, 2, CardEventType.draw);
        }
      }
      // 黯星【屠杀】
      else if (skill == SkillId.massacre.id) {
        addAttribute(source, AttributeType.attack, 10);
        healPlayer(source, source, 100, DamageType.heal);
        if (extra == 0) {
          addHiddenStatus(source, 'extra', 0, 1);
        }
      }
      // 恋慕【氤氲】
      else if (skill == SkillId.nebulaField.id) {
        addStatus(source, target, StatusId.nebula.id, 1, 2);
      }
      // 卿别【安魂乐章】
      else if (skill == SkillId.requiem.id) {
        addHiddenStatus(target, 'requiem', 0, 2);
      }
      // 时雨【冰芒】
      else if (skill == SkillId.iceSplinter.id) {
        damagePlayer(source, target, 80, DamageType.magical);
        modifyStatusLayer(source, target, StatusId.frost.id, 1);
        modifyStatusIntensity(source, target, StatusId.frost.id, 3);
      }
      // 敏博士【异镜解构】
      else if (skill == SkillId.deconstruction.id) {        
        modifyCardCount(source, target, 1, CardEventType.gain);
      }
      // 炎焕【赤焱炼狱】
      else if (skill == SkillId.crimsonInferno.id) {
        for (var tar in targets) {
          addStatus(source, tar, StatusId.flaming.id, 5, 1);
        }
      }
      // 斯威芬【造梦者】
      else if (skill == SkillId.dreamWeaver.id) {
        int point = skillData['point'];
        sourceChara.increaseHiddenStatusData('dreaming', intensity: -(2 * point - 1));
        if (point == 1) {
          addHiddenStatus(source, 'dream_weave', 0, 1);
        }
        else if (point == 2) {          
          modifyCardCount(source, target, 1, CardEventType.gain);
        }
        else {
          addHiddenStatus(source, 'dream_force', 0, 2);
          for (var chara in players.values) {
            if (isEnemy(source, chara.id)) {
              addStatus(source, chara.id, StatusId.dreaming.id, 0, 1);
            }
          }
        }
      }
      // 红烬【封焰的135秒】
      else if (skill == SkillId.sealedFlame135Seconds.id) {
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source, 
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        DamageRecord damageRecord = damageRecords.firstWhere((e) => e.damageType == DamageType.action);
        for (var tar in targets) {
          damagePlayer(source, tar, (3 * damageRecord.damage) ~/ 2, DamageType.lost, isAOE: true);
          removeStatus(source, tar, StatusId.flaming.id);
        }
      }
      // 余梦得【护梦者】
      else if (skill == SkillId.dreamKeeper.id) {
        addStatus(source, target, StatusId.slowness.id, 1, 1);
        addStatus(source, target, StatusId.weakness.id, 2, 1);
      }
      // 好好先生【礼尚往来】
      else if (skill == SkillId.giveAndTake.id) {
        int damageReceivedLastRound = 0;
        List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source, 
          startTurn: GameTurn(round: round - 1, turn: 1, extra: 0), 
          endTurn: gameTurnList[gameTurnList.indexOf(GameTurn(round: round, turn: 1, extra: 0)) - 1]).cast<DamageRecord>();
        for (DamageRecord damageRecord in damageRecords) {
          damageReceivedLastRound += damageRecord.damage;
        }
        damagePlayer(source, target, damageReceivedLastRound ~/ 2, DamageType.magical);
        healPlayer(source, source, damageReceivedLastRound ~/ 2, DamageType.heal);
      }
      // 叶姬【永恒】
      else if (skill == SkillId.eternity.id) {
        String status = skillData['status'];
        int point = skillData['point'];
        modifyStatusLayer(source, target, status, point);        
        modifyCardCount(source, source, point, CardEventType.discard);
      }
      // 太夕【谜渊漩涡】
      else if (skill == SkillId.abyssalWhirl.id) {
        addHiddenStatus(source, 'abyss', 0, 1);
        addHiddenStatus(target, 'taunt', 0, 1);
      }
      // 科亚特尔【天启之庭】
      else if (skill == SkillId.apocalypticCourt.id) {
        int point = skillData['point'];
        throwDice(source, source, point, 4, DiceType.skill);
        for (String tar in targets) {
          addStatus(source, tar, StatusId.eden.id, point, 2);
        }
      }
      // 祝烨明【八寒之七】
      else if (skill == SkillId.seventhFrost.id) {
        int point = skillData['point'];
        String status = skillData['status'];
        if (point >= targetChara.getStatusIntData(status, StatusData.layer)) {
          addStatus(source, target, StatusId.moisturize.id, 0, targetChara.getStatusIntData(status, StatusData.layer));
          removeStatus(source, target, status);
        }
        else {
          addStatus(source, target, StatusId.moisturize.id, 0, point);
          targetChara.setStatusData(status, layer: targetChara.getStatusIntData(status, StatusData.layer) - point);
        }
        damagePlayer('empty', source, 50 * point, DamageType.magical);
      }
      // 方塔索【入梦之手】
      else if (skill == SkillId.dreamGrasp.id) {
        for (var tar in targets) {
          addStatus(source, tar, StatusId.dreaming.id, 0, 1);
        }
      }
      // 龙宇澈【牺牲】
      else if (skill == SkillId.sacrifice.id) {
        addHiddenStatus(source, 'sacrifice', sourceChara.getHiddenStatusIntData('light_elf', StatusData.intensity), 2);        
        sourceChara.setHiddenStatusData('light_elf', intensity: 0);
      }
      // 祝言夙【灵魂震荡】
      else if (skill == SkillId.soulTremor.id) {
        addHiddenStatus(target, 'soul_tremor', 0, 1);
      }
      // 雷刚【斩神】
      else if (skill == SkillId.deicide.id) {
        damagePlayer('empty', source, sourceChara.health ~/ 5, DamageType.lost);
        addAttribute(source, AttributeType.armor, sourceChara.maxHealth ~/ 10);
        if (sourceChara.health > 300) {
          addHiddenStatus(source, 'slayer', 0, 1);
        }
        else {
          addHiddenStatus(source, 'deicide', 0, 1);
        }
      }
      // 颜若卿【补给】
      else if (skill == SkillId.replenishment.id) {
        modifyCardCount(source, target, 1, CardEventType.draw);
        modifyCardCount(source, target, 2, CardEventType.give);
        damagePlayer('empty', source, 250, DamageType.lost);
        healPlayer(source, target, 250, DamageType.heal);
      }
      // 白谢【冰灭的135小节】
      else if (skill == SkillId.icyOblivion135Bars.id) {
        int frostLayer = 0;
        for (var chara in players.values) {
          if (chara.hasStatus(StatusId.frost.id)) {
            frostLayer += chara.getStatusIntData(StatusId.frost.id, StatusData.layer);
          }
        }
        damagePlayer('empty', source, 100 * targets.length - 50 * frostLayer, DamageType.lost);
        for (var tar in targets) {
          addStatus(source, tar, StatusId.frozen.id, 0, 1);
        }
      }
      // 沈姝华【奉献之爱】
      else if (skill == SkillId.sacrificialLove.id) {
        for (var tar in targets) {
          addAttribute(tar, AttributeType.armor, 50);
          if (isTeammate(tar, source) || tar == source) {
            addAttribute(tar, AttributeType.armor, 50);
          }
        }
      }
      // 符楹【秩序结界】
      else if (skill == SkillId.orderAegis.id) {
        for (var tar in targets) {
          damagePlayer(source, tar, 40, DamageType.magical, isAOE: true);
          healPlayer(source, source, 40, DamageType.heal);
        }
        addStatus(source, source, StatusId.luminance.id, 0, 1);
      }
      // 符楹【邪能侵袭】
      else if (skill == SkillId.chaosIncursion.id) {
        damagePlayer(source, target, 100, DamageType.magical);
        addStatus(source, source, StatusId.tenebrae.id, 0, 1);
      }
      // 祝烨诚【裁冰裂霜】
      else if (skill == SkillId.frostShatter.id) {
        for (var tar in targets) {
          var tarChara = players[tar]!;
          int frostLayer = !tarChara.hasStatus(StatusId.frost.id) ? 0 : tarChara.getStatusIntData(StatusId.frost.id, StatusData.layer);
          int frozenLayer = !tarChara.hasStatus(StatusId.frozen.id) ? 0 : tarChara.getStatusIntData(StatusId.frozen.id, StatusData.layer);
          int damage = 75 + 10 * frostLayer * tarChara.getStatusIntData(StatusId.frost.id, StatusData.intensity)
            + 30 * frozenLayer;
          damagePlayer(source, tar, damage, DamageType.physical, isAOE: true);
          addStatus(source, tar, StatusId.dissociated.id, 10, 1);
        }
      }
      // 蓝文策【三仙归洞】
      else if (skill == SkillId.threeImmortalsReturn.id) { 
        int type = skillData['type'];
        if (type == 0) {          
          modifyCardCount(source, target, 2, CardEventType.discard);
          addAttribute(target, AttributeType.movepoint, 2);
        }
        else if (type == 1) {          
          modifyCardCount(target, target, 2, CardEventType.draw);
          addAttribute(target, AttributeType.movepoint, -2);
        }
      }
      // 染序【点睛】
      else if (skill == SkillId.kindleEye.id) {
        addHiddenStatus(source, 'kindle', 2, 0);
      }
      // 卡拉卡【木头羊】
      else if (skill == SkillId.timberSheep.id) {
        int point = skillData['point'];
        addAttribute(source, AttributeType.movepoint, point);
      }
      // 守塔人【怒海引路】
      else if (skill == SkillId.ragePilot.id) {
        modifyStatusLayer(source, target, StatusId.regeneration.id, 1);
        modifyStatusIntensity(source, target, StatusId.regeneration.id, 3);
      }
      // 曙光【不可动摇的守护】
      else if (skill == SkillId.unwaveringGuard.id) {
        addAttribute(source, AttributeType.defence, 5);
        if (sourceChara.health < 400) {
          addStatus(source, source, StatusId.shelter.id, 4, 1);
        }
      }
      // 奥赛罗【余裕手】
      else if (skill == SkillId.spareMove.id) {
        /*int whitePieceCount = 0;
        for (var chara in players.values) {
          if (chara.hasHiddenStatus('white_piece') && chara.id != 'empty' && !chara.isDead) {
            whitePieceCount += chara.getHiddenStatusIntData('white_piece', StatusData.intensity);
            removeHiddenStatus(chara.id, 'white_piece');
          }
        }
        addAttribute(source, AttributeType.armor, 5 * whitePieceCount);*/
        if (targetChara.hasHiddenStatus( 'white_piece')) {
          addHiddenStatus(target, 'black_piece', targetChara.getHiddenStatusIntData('white_piece', StatusData.intensity), -1);
          removeHiddenStatus(target, 'white_piece');
        } else if (targetChara.hasHiddenStatus( 'black_piece')) {
          addHiddenStatus(target, 'white_piece', targetChara.getHiddenStatusIntData('black_piece', StatusData.intensity), -1);
          removeHiddenStatus(target, 'black_piece');
        }
        if (sourceChara.hasHiddenStatus('white_piece')) {
          modifyHiddenStatusIntensity(source, 'white_piece', 1);          
        } else if (sourceChara.hasHiddenStatus('black_piece')) {
          modifyHiddenStatusIntensity(source, 'black_piece', 1);
        }
      }
      // 埃诺雅【溯洄】
      else if (skill == SkillId.anabasis.id) {
        final int type = skillData['type'];
        final int point = skillData['point'];
        final String card = skillData['card'];
        final CardSetting settings = skillData['settings'];
        final int actionId = skillData['actionId'];
        if (type == 0) {
          damagePlayer(source, target, point ~/ 2, DamageType.physical);
          castCard(source, [target], card, settings.toJson());
        }
        else {
          String mirrorCard = '';
          if (mirrorCards[0].contains(card)) {
            mirrorCard = mirrorCards[1][mirrorCards[0].indexOf(card)];
          }
          else if (mirrorCards[1].contains(card)) {
            mirrorCard = mirrorCards[0][mirrorCards[1].indexOf(card)];
          }
          healPlayer(source, target, point ~/ 4, DamageType.heal);
          if (card != '') {
            castCard(source, [target], mirrorCard);
          }
        }
        removeHiddenStatus(source, 'action_$actionId');
        modifyHiddenStatusIntensity(source, 'horologe', -(1 << actionId));
      }
      // 蓝文曦【去伪存真】
      else if (skill == SkillId.veritasNonFalsitas.id) {
        int type = skillData['type'];
        int point = skillData['point'];
        if (type == 0) {
          damagePlayer(source, source, 50 * point, DamageType.lost);
          modifyCardCount(source, source, point, CardEventType.draw);
        }
        else {
          healPlayer(source, source, 50 * point, DamageType.heal);
          modifyCardCount(source, source, point, CardEventType.discard);
        }
      }

      // 技能进入CD
      modifySkillCooldown(source, source, skill, skillToType[skill]!.cooldown);
      // 叶姬【永恒】
      if (skill == SkillId.eternity.id) {
        int point = skillData['point'];
        modifySkillCooldown(source, source, skill, point + 1);
      }
      // 斯威芬【造梦者】
      if (skill == SkillId.dreamWeaver.id) {
        int point = skillData['point'];
        if (point == 2) {
          modifySkillCooldown(source, source, skill, 4);
        }
        else if (point == 3) {
          modifySkillCooldown(source, source, skill, 8);
        }
      }
      // 雷刚【斩神】
      else if (skill == SkillId.deicide.id) {
        if (sourceChara.health < 300) {
          modifySkillCooldown(source, source, skill, 4);
        }
      }
      // 卡拉卡【木头羊】
      else if (skill == SkillId.timberSheep.id) {
        int point = skillData['point'];
        modifySkillCooldown(source, source, skill, point);
      }

      // 道具结算
      // 失乐园
      for (var chara in players.values) {
        if (chara.hasHiddenStatus('eden') && chara.id != 'empty' && isEnemy(source, chara.id)) {
          int edenIntensity = chara.getHiddenStatusIntData('eden', StatusData.intensity) % 2 + 1;
          addStatus(chara.id, source, StatusId.fragility.id, 2 * edenIntensity, 1);
          chara.setHiddenStatusData('eden', intensity: chara.getHiddenStatusIntData('eden', StatusData.intensity) ~/ 2);
          if (chara.getHiddenStatusIntData('eden', StatusData.intensity) <= 1) {
            removeHiddenStatus(chara.id, 'eden');
          }
        }
      }

      // 特质结算
      // 妮卡欧【不倦的观测者】
      if (sourceChara.hasTrait(TraitId.tirelessObserver.id)) {
        castTrait(source, [source], TraitId.tirelessObserver.id, {'skill': skill});
      }
      // 唐菁延【延光】
      else if (source == CharacterId.tangJingyan.id) {
        if (isEnemy(source, target)) {
          castTrait(source, [target], TraitId.lingeringLight.id, {'type': 0, 'cooldown': sourceChara.skill[skill]});
        }
        else {
          var lingeringLightTargets = players.values.where((e) => (e.id == source || isTeammate(e.id, source)) 
            && !e.isDead && e.id != 'empty').map((e) => e.id).toList();
          castTrait(source, lingeringLightTargets, TraitId.lingeringLight.id, {'type': 1, 'cooldown': sourceChara.skill[skill]});
        }
      }
      // 好好先生【见面礼】
      else if (sourceChara.hasStatus(StatusId.gift.id)) {
        damagePlayer('empty', source, 2 * sourceChara.attack, DamageType.magical);
        addStatus(CharacterId.mrNice.id, source, StatusId.confusion.id, 0, 2);
        removeStatus(CharacterId.mrNice.id, source, StatusId.gift.id);
      }
      // 阿波菲斯【毁灭暗影】
      if (isCharacterInGame(CharacterId.apophis.id) && sourceChara.hasStatus(StatusId.nightmare.id) 
        && sourceChara.getHiddenStatusIntData('night', StatusData.intensity) < 3) {
        Character chara = players[CharacterId.apophis.id]!;
        if (sourceChara.hasStatus(StatusId.eden.id)) {
          damagePlayer(chara.id, source, 20 + 40 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.magical);
          healPlayer(chara.id, chara.id, 10 + 20 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.heal);
        }
        else { 
          damagePlayer(chara.id, source, 10 + 20 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.magical);
          healPlayer(chara.id, chara.id, 5 + 10 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.heal);
        }
        addHiddenStatus(source, 'night', 1, -1);
        addHiddenStatus(chara.id, 'night', 1, -1);
        castTrait(chara.id, [source], TraitId.ruinousShade.id, {'type': 1});
      }

      // 唐亚德【清心的乌托邦】
      if (source == CharacterId.tangYade.id) {
        castTrait(source, [source], TraitId.utopiaOfClarity.id, {'type': 0});
      }
      
      // 记录技能
      _recordProvider!.addSkillRecord(getGameTurn(), source, targets, skill, skillData);
      _gameLogger!.addSkillLog(getGameTurn(), source, targets.toString(), skill, skillData.toString());
      refresh();
    }

    return skillAble;
  }

  // 使用特质
  bool castTrait(String source, List<String> targets, String trait, [Map<String, dynamic>? args]){
    bool traitAble = true;
    int movePointCost = 0;
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    Map<String, dynamic> traitData = args ?? {};
    // 特质不属于玩家
    if (!sourceChara.hasTrait(trait)) {
      return false;
    }

    // 特质触发条件
    // 茵竹【自勉】
    if (trait == TraitId.selfEncouragement.id) {
      int type = traitData['type'];      
      if (type == 0 && (sourceChara.health > sourceChara.maxHealth * 0.5 || sourceChara.health < 0 
      || sourceChara.hasHiddenStatus('encouragement'))){
        traitAble = false;
      }
      else if (type == 1) {
        String status = traitData['status'];
        if (status != StatusId.dissociated.id) {
          traitAble = false;
        }
      }
    }
    // 星尘【幸运壁垒】
    else if (trait == TraitId.luckyShield.id) {
      DamageType damageType = traitData['dmgType'];
      if (!{DamageType.action, DamageType.physical}.contains(damageType)) {
        traitAble = false;
      }
    }
    // 黯星【决心】
    else if (trait == TraitId.resolution.id) {
      if (sourceChara.health > 0) {
        traitAble = false;
      }
    }    
    // 岚【天魔体】
    else if (trait == TraitId.demonicAvatar.id) {
      DamageType damageType = traitData['dmgType'];
      if (sourceChara.health > sourceChara.maxHealth * 0.5 || damageType != DamageType.action) {
        traitAble = false;
      }
    }
    // 岚【血灵斩】
    else if (trait == TraitId.hemaSlash.id) {
      movePointCost = 1;
      if (sourceChara.cardCount < 1) {
        traitAble = false;
      }
    }
    // 恋慕【勿忘我】
    else if (trait == TraitId.dontForgetMe.id) {
      int type = traitData['type'];
      if (type == 0) {
        DamageType damageType = traitData['dmgType'];
        if (damageType != DamageType.action) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        DamageType damageType = traitData['dmgType'];
        if (!{DamageType.action, DamageType.physical, DamageType.magical}.contains(damageType)) {
          traitAble = false;
        }
      }
      else if (type == 2) {
        if (sourceChara.health > 0 || round > 1) {
          traitAble = false;
        }
      }
    }
    // K97【二进制噪声】
    else if (trait == TraitId.binary.id) {
      int type = traitData['type'];
      /*if (type == 0 && sourceChara.armor > 0) {
        traitAble = false;
      }
      else if (type == 1 && sourceChara.armor <= 0) {
        traitAble = false;
      }*/
      if (type == 2) {
        int armor = traitData['armor'];
        int attValue = traitData['attValue'];
        if (armor == 0 || attValue != armor) {
          traitAble = false;
        }        
      }
    }
    // 安德宁【回旋曲】
    else if (trait == TraitId.rondo.id) {
      if (sourceChara.damageDealtTurn > 150) {
        traitAble = false;
      }
    }
    // 扶风【大预言】
    else if (trait == TraitId.grandProphecy.id) {
      int type = traitData['type'];
      if (type == 1) {
        movePointCost = 1;
      }
      if (sourceChara.hasHiddenStatus('grand_prophecy')) {
        traitAble = false;
      }
    }
    // 星凝【祝愿】
    else if (trait == TraitId.blessing.id) {
      movePointCost = 1;
    }
    // 时雨【天霜封印】
    else if (trait == TraitId.arcticSeal.id) {
      List<GameRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: target, 
        startTurn: getPreviousGameTurn(), endTurn: getGameTurn());
      traitAble = false;
      for (var record in damageRecords) {
        DamageRecord damageRecord = record as DamageRecord;
        if (damageRecord.tag == 'frost') {
          traitAble = true;
        }
      }
    }
    // 赐弥【在云端】
    else if (trait == TraitId.uponTheClouds.id) {
      if (sourceChara.health > 0 || sourceChara.hasHiddenStatus('cloud')) {
        traitAble = false;
      }
    }
    // 舸灯【引渡】
    else if (trait == TraitId.ghostFerry.id) { 
      int type = traitData['type'];
      if (type == 1) {
        movePointCost = 2;
      }
    }
    // 长霾【律令】
    else if (trait == TraitId.decree.id) {
      movePointCost = 1;
      List<TraitRecord> traitRecords =  _recordProvider!.getFilteredRecords(type: RecordType.trait, source: source,
        target: target, startTurn: GameTurn(round: 1, turn: 1, extra: 0), endTurn: getGameTurn()).cast<TraitRecord>();
      TraitRecord? latestRecord = traitRecords.isEmpty ? null : traitRecords.last;
      if (latestRecord != null) {
        int type = traitData['type'];
        if (type == latestRecord.params['type']) {
          traitAble = false;
        }
      }
      if (targetChara.hasHiddenStatus('non_flying') || targetChara.hasHiddenStatus('air_lock') ||
            targetChara.hasHiddenStatus('demon_seal') || targetChara.hasHiddenStatus('spirit_bind')) {
        traitAble = false;
      }
    }
    // 卿别【夜魇游吟】
    else if (trait == TraitId.nightmareRefrain.id) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
        if (targetChara.hasHiddenStatus('dream')) {
          traitAble = false;
        }
        /*List<GameRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          target: target, startTurn: getPreviousGameTurn(), endTurn: getGameTurn());
        if (actionRecords.isEmpty) {
          traitAble = false;
        }*/
      }
    }
    // 云津【云系祝乐】
    else if (trait == TraitId.celestialJoy.id) {
      int type = traitData['type'];
      if (type == 0) {
        if (!sourceChara.hasHiddenStatus('celestial')) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntData('celestial', StatusData.intensity) < 2) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        movePointCost = 2;
        if (sourceChara.movePoint != sourceChara.maxMove) {
          traitAble = false;
        }
      }
    }
    // 炎焕【心炎】
    else if (trait == TraitId.cardioBlaze.id) {
      movePointCost = 1;
    }
    // 樊求【游侠】
    else if (trait == TraitId.ranger.id) {
      int type = traitData['type'];      
      if (type == 1 && (sourceChara.hasHiddenStatus('ranger_used') || 
      sourceChara.getHiddenStatusIntData('ranger', StatusData.intensity) < 3)) {
        traitAble = false;
      }
    }
    // 樊求【精准】
    else if (trait == TraitId.precision.id) {
      if (!targetChara.hasHiddenStatus('power_attack') || isEnemy(source, target)) {
        traitAble = false;
      }
    }
    // 斯威芬【梦的塑造】
    else if (trait == TraitId.craftingOfDreams.id) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 2;
        if (sourceChara.hasStatus(StatusId.dreamCrafting.id)) {
          traitAble = false;
        }
      }
      else if ((type == 1 || type == 2) && !sourceChara.hasStatus(StatusId.dreamCrafting.id)) {        
        traitAble = false;
      }
    }
    // 红烬【烈焰之体】
    else if (trait == TraitId.conflagrationAvatar.id) {
      int type = traitData['type'];
      if (type == 1) {
        List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        if (actionRecords.isEmpty) {
          traitAble = false;
        }
      }
      else if (type == 2) { 
        List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, target: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        if (actionRecords.isEmpty) {
          traitAble = false;
        }
      }
    }
    // 余梦得【梦的守护】
    else if (trait == TraitId.guardianOfDreams.id) {
      int type = traitData['type'];
      if (type == 0) {
        List<ActionRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
        for (var record in actionRecords) {
          if (record.attacked == true) {
            traitAble = false;
            break;
          }
        }
      }
      else if (type == 1) {
        if (!sourceChara.hasStatus(StatusId.dreamGuarding.id)) {
          traitAble = false;
        }
      }
      else if (type == 2) {
        List<ActionRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
        if (actionRecords.isNotEmpty) {
          if (actionRecords.last.attacked == true) {
            traitAble = false;
          }
        }
        /*for (var actionRecord in actionRecords) {
          if (actionRecord.attacked == true) {
            traitAble = false;
            break;
          }
        }*/
        List<GameRecord> skillRecords =  _recordProvider!.getFilteredRecords(type: RecordType.skill, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn());
        if (skillRecords.isNotEmpty) {
          traitAble = false;
        }
      }
    }
    // 好好先生【见面礼】
    else if (trait == TraitId.introductoryGift.id) {
      if (targetChara.hasHiddenStatus('intro_gift')) {
        traitAble = false;
      }
    }
    // 好好先生【深重情谊】
    else if (trait == TraitId.imposingFavor.id) {
      if (playerCount - playerDiedCount <= 2) {
        traitAble = false;
      }
    }
    // 叶姬【须臾】
    else if (trait == TraitId.ephemeral.id) {
      movePointCost = 1;
      String status = traitData['status'];      
      if (status == '' || !statusToType[status]!.hasIntensity || !statusToType[status]!.hasLayer) {
        traitAble = false;
      }
    }
    // 太夕【黯灭】
    else if (trait == TraitId.darkDissolution.id) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
      }
      else if (type == 1) {
        if (sourceChara.cardCount < 1) {
          traitAble = false;
        }
      }
    }
    // 太夕【吞噬之锁】
    else if (trait == TraitId.devouringLock.id) {
      if (sourceChara.getHiddenStatusIntData('dark', StatusData.intensity) < 2){
        traitAble = false;
      }
    }
    // 科亚特尔【拟造“伊甸园”】
    else if (trait == TraitId.artificialEden.id) {
      if (sourceChara.damageDealtTurn > 0) {
        traitAble = false;
      }
    }
    // 科亚特尔【善恶天平】
    else if (trait == TraitId.balanceOfLightAndShadow.id) {
      traitAble = false;
      if (sourceChara.hasStatus(StatusId.eden.id) && sourceChara.hasStatus(StatusId.nightmare.id)) {
        traitAble = true;
      }
    }
    // 蒙德里安【禁忌知识】
    else if (trait == TraitId.tabooLore.id) {
      int type = traitData['type'];
      if ({1, 2}.contains(type)) {
        if (sourceChara.getHiddenStatusIntData('forbidden', StatusData.intensity) < 1) {
          traitAble = false;
        }
      }  
    }
    // 阿波菲斯【永夜无终】
    else if (trait == TraitId.endlessNight.id) {
      if (sourceChara.getHiddenStatusIntData('night', StatusData.intensity) < 9) {
        traitAble = false;
      }
    }
    // 红黎【红莲业火】
    else if (trait == TraitId.lotusFlame.id) {
      int type = traitData['type'];
      if (type == 1 && !targetChara.hasStatus(StatusId.flaming.id)) {        
        traitAble = false;        
      }      
    }
    // 红黎【冰火相融】
    else if (trait == TraitId.iceFireFusion.id) {
      if (targetChara.hasStatus(StatusId.flaming.id)) {
        traitAble = false;
      }
    }
    // 祝烨明【八裂】
    else if (trait == TraitId.cryoFissuring.id) {
      int type = traitData['type'];
      if (type == 0 && !targetChara.hasStatus(StatusId.moisturize.id)) {
        traitAble = false;
      }
    }
    // 方塔索【神游】
    else if (trait == TraitId.astralProjection.id) {
      int type = traitData['type'];
      if (type == 0 && !sourceChara.hasStatus(StatusId.dreaming.id)) {
        traitAble = false;        
      }
    }
    // 龙宇澈【光耀】
    else if (trait == TraitId.radiance.id) {
      int type = traitData['type'];
      if (type == 0) {
        if (sourceChara.cardCount < 1) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntData('light', StatusData.intensity) <= sourceChara.getHiddenStatusIntData('light_elf', StatusData.intensity) && 
          sourceChara.getHiddenStatusIntData('light', StatusData.intensity) > 0) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        if (!({2, 3, 4}.contains(sourceChara.getHiddenStatusIntData('light', StatusData.intensity)) && 
          sourceChara.health <= sourceChara.maxHealth - 200 * (sourceChara.getHiddenStatusIntData('light', StatusData.intensity) - 1))) {
          traitAble = false;
        }
      }
      else if (type == 2) {
        DamageType damageType = traitData['dmgType'];
        if (!{DamageType.action, DamageType.physical, DamageType.magical}.contains(damageType)) {
          traitAble = false;
        }
      }
    }
    // 龙宇澈【燃魂】
    else if (trait == TraitId.soulBurning.id) {
      if (sourceChara.hasHiddenStatus('soul_burning')) {
        traitAble = false;
      }
    }
    // 祝言夙【精神干扰】
    else if (trait == TraitId.mentalDisruption.id) {
      if (!{1, gameSequence.length - 1}.contains((gameSequence.indexOf(source) - gameSequence.indexOf(target)) % gameSequence.length)) {
        traitAble = false;
      }
    }
    // 唐亚德【清心的乌托邦】
    else if (trait == TraitId.utopiaOfClarity.id) {
      int type = traitData['type'];
      if (type == 1) {
        if (!sourceChara.hasHiddenStatus('clarity')) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntData('clarity', StatusData.intensity) < 1) {
          traitAble = false;
        }
      }     
    }
    // 雷刚【决意的乌托邦】
    else if (trait == TraitId.utopiaOfResolve.id) {
      int type = traitData['type'];
      if (type == 0 && (sourceChara.health > 300 || sourceChara.hasHiddenStatus('resolve'))) {
        traitAble = false;
      }
      else if (type == 2) {
        List<String> cardList = traitData['cardList'];
        traitAble = false;
        for (String card in cardList) {
          List<String> tagList = cardTags[card]!;
          if (tagList.contains(TagId.vital.id)){
            traitAble = true;
            break;
          }
        }
      }
    }
    // 陆风【追猎的乌托邦】
    else if (trait == TraitId.utopiaOfCelerity.id) {
      int type = traitData['type'];
      if (type == 0 && (sourceChara.cardCount < 1 || targetChara.hasStatus(StatusId.prey.id))) {
        traitAble = false;
      }
      else if (type == 1 && !targetChara.hasStatus(StatusId.prey.id)) {
        traitAble = false;
      }
      else if (type == 2 && !targetChara.hasStatus(StatusId.prey.id)) {
        traitAble = false;
      }
    }
    // 安山定【后发的乌托邦】
    else if (trait == TraitId.utopiaOfUpspring.id) {
      int type = traitData['type'];
      if (type == 0) { 
        List<ActionRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
        List<SkillRecord> skillRecords =  _recordProvider!.getFilteredRecords(type: RecordType.skill, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<SkillRecord>();
        if (actionRecords.isNotEmpty || skillRecords.isNotEmpty) {
          traitAble = false;
        }
      }
      else {
        if (!sourceChara.hasHiddenStatus('upspring')) {
          traitAble = false;
        }
      }
    }
    // 颜若卿【调和的乌托邦】
    else if (trait == TraitId.utopiaOfConcord.id) {
      int type = traitData['type'];
      if (type == 1) {
        traitAble = false;
        List<String> cardList = traitData['cardList'];
        for (String card in cardList) {
          if ({CardId.filching.id, CardId.regenerating.id, CardId.curing.id, CardId.auroraConcussion.id,
            CardId.pandoraBox.id, CardId.homology.id, CardId.invisibilitySpell.id}.contains(card)) {
            traitAble = true;
            break;
          }
        }        
      }
      else if (type == 2) {
        int damage = traitData['damage'];
        if (damage < 300) {
          traitAble = false;
        }
      }      
    }
    // 白谢【极寒环域】
    else if (trait == TraitId.glacialCircle.id) {
      int type = traitData['type'];
      if (type == 0) {
        List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        if (damageRecords.isEmpty) {
          traitAble = false;
        }
      }
    }
    // 沈姝华【纯洁之爱】
    else if (trait == TraitId.innocentLove.id) {
      int type = traitData['type'];
      if (type == 0) {
        List<String> cardList = traitData['cardList'];
        if (cardList.isEmpty) {
          traitAble = false;
        }
      }
    }
    // 翠灵【生息】
    else if (trait == TraitId.lifeBreath.id) {
      int type = traitData['type'];
      if (type == 0) {
        if (sourceChara.damageReceivedRound <= 300) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        if (!sourceChara.hasHiddenStatus('breath')) {
          traitAble = false;
        }
      }
    }
    // 湍云【屏息】
    else if (trait == TraitId.holdBreath.id) {
      int type = traitData['type'];
      if (type == 0 && (sourceChara.damageDealtRound >= 120 || sourceChara.damageDealtRound <= 0)) {
        traitAble = false;        
      }
      else if (type == 1 && !sourceChara.hasHiddenStatus('hold')) {
        traitAble = false;
      }
      else if (type == 2) {
        List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, source: source,
          startTurn: GameTurn(round: round, turn: 1, extra: 0), endTurn: getGameTurn()).cast<DamageRecord>();        
        for (DamageRecord damageRecord in damageRecords) {
          if (damageRecord.damageType == DamageType.action && damageRecord.damage > 0) {
            traitAble = false;
            break;
          }
        }        
      }
      else if (type == 3 && !sourceChara.hasHiddenStatus('holding')) {
        traitAble = false;
      }
    }
    // 湍云【惊弓】
    else if (trait == TraitId.gunShy.id) {
      int type = traitData['type'];
      if (type == 0 && sourceChara.damageDealtRound < 300) {
        traitAble = false;
      }
      else if (type == 1 && !sourceChara.hasHiddenStatus('gun_shy')) {
        traitAble = false;
      }
    }
    // ReFre-3【<06>自卫协议】
    else if (trait == TraitId.defensiveProtocol.id) {
      if (sourceChara.getHiddenStatusIntData('protocol', StatusData.intensity) >= 1) {
        traitAble = false;
      }
    }
    // 洛尔【不断燃烧的愤怒】
    else if (trait == TraitId.smolderingRage.id) {
      int type = traitData['type'];
      int rageIntensity = sourceChara.getHiddenStatusIntData('rage', StatusData.intensity) == -1 
        ? 0 : sourceChara.getHiddenStatusIntData('rage', StatusData.intensity);
      if (type == 0 && !(sourceChara.health < sourceChara.maxHealth - 200 * (rageIntensity + 1))) {
        traitAble = false;
      }
    }
    // 洛尔【毫无章法的进攻】
    else if (trait == TraitId.chaoticStrikes.id) {
      int type = traitData['type'];
      int point = traitData['point'];
      if (type == 0 && point > 2) {
        traitAble = false;
      }
      else if (type == 1 && point < 3) {
        traitAble = false;
      }
    }
    // 奥菲莉娅【控水】
    else if (trait == TraitId.hydromancy.id) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
        if (targetChara.hasStatus(StatusId.submerged.id)) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        movePointCost = 1;
        if (targetChara.hasStatus(StatusId.dehydration.id)) {
          traitAble = false;
        }
      }
    }
    // 奥菲莉娅【水之刑】
    else if (trait == TraitId.waterTorture.id) {
      int type = traitData['type'];
      if (type == 0) {
        movePointCost = 1;
        if (!targetChara.hasStatus(StatusId.submerged.id) && !targetChara.hasStatus(StatusId.dehydration.id)) {
          traitAble = false;
        }
      }
      else if (type == 1) {
        if (!targetChara.hasStatus(StatusId.asphyxia.id)) {
          traitAble = false;
        }
      }
    }
    // 符楹【光暗双生】
    else if (trait == TraitId.lumenUmbraGemini.id) { 
      int type = traitData['type'];
      if (type == 0 && sourceChara.cardCount < 1) {
        traitAble = false;
      }
    }
    // EnGine-4【<04>质能转换】
    else if (trait == TraitId.massEnergyConversion.id) {
      int type = traitData['type'];
      if (type == 0) {        
        int damage = traitData['damage'];
        if (damage < 64) {
          traitAble = false;
        }
      }
      else if (type == 1 && sourceChara.damageDealtRound > 0) {        
        traitAble = false;
      }
      else if ((type == 2 || type == 3) && !sourceChara.hasHiddenStatus('conversion')) {
        traitAble = false;
      }
    }
    // DeFen-5【<15>力场模拟】
    else if (trait == TraitId.forceFieldSimulation.id) {
      if (sourceChara.cardCount < 1) {
        traitAble = false;
      }      
    }
    // 兰斯洛特【针锋相对】
    else if (trait == TraitId.titForTat.id) {
      List<ActionRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, target: source,
        startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
      if (actionRecords.isEmpty) {
        traitAble = false;
      }
    }
    // 卡拉卡【友情防守】
    else if (trait == TraitId.buddyBlock.id) {
      int type = traitData['type'];
      if (type == 2 && sourceChara.movePoint != 0) {
        traitAble = false;
      }
    }
    // 观风【气象万千】
    else if (trait == TraitId.weathersUnfold.id) {
      int type = traitData['type'];
      if (type == 0 || type == 1) {
        List<ActionRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<ActionRecord>();
        if (actionRecords.isEmpty) {
          traitAble = false;
        }
        if (sourceChara.getHiddenStatusIntData('cloud', StatusData.intensity) 
          + sourceChara.getHiddenStatusIntData('wind', StatusData.intensity) >= 3) {
          traitAble = false;
        }
      }
    }
    // 安提忒斯【冰与火之歌】
    else if (trait == TraitId.iceAndFire.id) { 
      int type = traitData['type'];
      if (type == 2) {
        movePointCost = 1;
      }
    }
    // 守塔人【潮海明灯】
    else if (trait == TraitId.tideBeacon.id) { 
      traitAble = false;
      for (var stat in targetChara.status.keys) {
        if (statusToType[stat]!.buffType == BuffType.negative) {
          traitAble = true;
          break;
        }
      }
    }
    // 曙光【不容置疑的信任】
    else if (trait == TraitId.unquestioningTrust.id) { 
      int type = traitData['type'];
      if (type == 0) {
        List<ActionRecord> actionRecords =  _recordProvider!.getFilteredRecords(type: RecordType.action, target: source,
          startTurn: getStartGameTurn(round - 1), endTurn: getEndGameTurn(round - 1)).cast<ActionRecord>();
        if (actionRecords.length > 2) {
          traitAble = false;
        }
      }
      else if (type == 1 && (targetChara.hasHiddenStatus('support_def') || !sourceChara.hasHiddenStatus('trust'))) {
        traitAble = false;
      }
      else if (type == 2 && (targetChara.hasHiddenStatus('support_atk') || !sourceChara.hasHiddenStatus('trust'))) {
        traitAble = false;
      }
      else if (type == 3) {
        int damage = traitData['damage'];
        DamageType damageType = traitData['dmgType'];
        if (damage < 300 || damageType != DamageType.action) {
          traitAble = false;
        }
      }
    }
    // 石蹄【蹦蹦咒语】
    else if (trait == TraitId.boingSpell.id) { 
      int type = traitData['type'];
      if (type == 0 || type == 1) {
        movePointCost = 1;
      }
    }
    // 埃诺雅【原初时计】
    else if (trait == TraitId.primordialHorologe.id) { 
      if (sourceChara.getHiddenStatusIntData('horologe', StatusData.intensity) == 31) {
        traitAble = false;
      }
    }
    // 蓝文曦【盈亏相济】
    else if (trait == TraitId.lossGainEquilibrium.id) { 
      int type = traitData['type'];
      int count = traitData['count'];
      if (type == 0 && count < 3 || type == 1 && count > -3 || type == 2 && count != 0) { 
        traitAble = false;
      }
    }
    // 状态【混乱】【冰封】
    if (sourceChara.hasStatus(StatusId.confusion.id) || sourceChara.hasStatus(StatusId.frozen.id)) {
      traitAble = false;
    }
    // 状态【梦境】【星牢】
    if ((sourceChara.hasStatus(StatusId.dreaming.id) || sourceChara.hasStatus(StatusId.stellarCage.id)) 
      && turn == gameSequence.indexOf(source)) {
      traitAble = false;
    }
    // 长霾【律令·禁空】
    if (sourceChara.hasHiddenStatus('non_flying') && movePointCost > 0) {
      movePointCost++;
    }
    // 长霾【律令·封魔】
    if (sourceChara.hasHiddenStatus('demon_seal')) {
      traitAble = false;
    }
    // 亭歆雨【彼岸之金】
    if (sourceChara.hasHiddenStatus('strange')) {
      traitAble = false;
    }
    // 行动点不足
    if (movePointCost > sourceChara.movePoint) {
      traitAble = false;
    }
    // 使用次数不足
    if (sourceChara.trait[trait]!.castCount >= sourceChara.trait[trait]!.maxCast 
    && sourceChara.trait[trait]!.maxCast > 0) {
      //traitAble = false;
    }
    // 永久可用特质
    if ({TraitId.resolution.id}.contains(trait)) {
      traitAble = true;
    }
    // 玩家死亡
    if (sourceChara.isDead || targetChara.isDead) {
      traitAble = false;
    }
    if (traitAble) {
      // 行动点减损
      if (movePointCost > 0) {
        addAttribute(source, AttributeType.movepoint, -movePointCost);
      }
      // 特质使用次数增加
      if (sourceChara.trait[trait]!.maxCast > 0) {
        modifyTraitCastCount(source, source, trait, 1);
      }
      // 茵竹【自勉】
      if (trait == TraitId.selfEncouragement.id) {
        int type = traitData['type'];
        if (type == 0) {
          healPlayer(source, source, (sourceChara.maxHealth * 0.8).toInt() - sourceChara.health, DamageType.heal);
          addHiddenStatus(source, 'encouragement', 0, -1);
        }
        else {          
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;
        }        
      }
      // 妮卡欧【不倦的观测者】
      else if (trait == TraitId.tirelessObserver.id) {
        String skill = traitData['skill'];
        modifySkillCooldown(source, source, skill, -1);
      }
      // 云云子【晨昏寥落】
      else if (trait == TraitId.duskVoid.id) {
        int type = traitData['type'];
        if (type == 0) { 
          List<double> baseDamageRef = traitData['baseDamageRef'];
          int attack = traitData['attack'];
          double attackMulti = traitData['attackMulti'];
          int point = traitData['point'];
          List<DamageType> damageTypeRef = traitData['damageTypeRef'];
          damageTypeRef[0] = DamageType.lost;
          baseDamageRef[0] = (point) * (attack - 30) * attackMulti;
        }
        else {
          List<int> maxPointRef = traitData['maxPointRef'];
          maxPointRef[0] += 1;
        }
      }
      // 星尘【幸运壁垒】
      else if (trait == TraitId.luckyShield.id) {
        String dmgSource = traitData['dmgSource'];
        int damage = traitData['damage'];
        int point = traitData['point'];
        throwDice(source, source, point, 6, DiceType.trait);
        if ({3, 6}.contains(point)) {
          addAttribute(source, AttributeType.health, damage);
          addAttribute(source, AttributeType.dmgreceived, -damage);
          addAttribute(dmgSource, AttributeType.dmgdealt, -damage);
        }
        List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source,
          startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
        for (DamageRecord damageRecord in damageRecords) {
          if (damageRecord.source == dmgSource && damageRecord.damage == damage) {
            _recordProvider!.removeRecord(damageRecord);
            break;
          }
        }
      }
      // 黯星【决心】
      else if (trait == TraitId.resolution.id) {
        int point = traitData['point'];
        throwDice(source, source, point, 6, DiceType.trait);
        if ({1, 5, 6}.contains(point)) {
          addAttribute(source, AttributeType.health, 1 - sourceChara.health);
        }
        else {
          addHiddenStatus(source, 'res_failed', 0, 1);
        }
      }
      // 方寒【耀光爆裂】
      else if (trait == TraitId.radiantBlast.id) {
        int point = traitData['point'];
        throwDice(source, source, point, 6, DiceType.trait);
        if ({4, 5}.contains(point)) {
          addStatus(source, target, StatusId.soulFlare.id, 1, 1);
        }
        else if (point == 6) {
          addStatus(source, target, StatusId.soulFlare.id, 2, 1);
        }
      }
      // 恪玥【咕尘散】
      else if (trait == TraitId.escaping.id) {
        int point = traitData['point'];
        throwDice(source, source, point, 6, DiceType.trait);
        if ({3, 6}.contains(point)) {
          addStatus(source, source, StatusId.gugu.id, 0, 1);
          modifyHiddenStatusIntensity(source, 'gugu', 1);
        }
        else {
          final renouncingTargets = players.values.where((e) => isEnemy(source, e.id)).map((e) => e.id).toList();
          castTrait(source, renouncingTargets, TraitId.renouncing.id);
        }
      }
      // 恪玥【歇尘凡】
      else if (trait == TraitId.renouncing.id) {
        int damage = 60 * sourceChara.getHiddenStatusIntData('gugu', StatusData.intensity) ~/ targets.length;
        for (var tar in targets) {
          damagePlayer(source, tar, damage, DamageType.physical, isAOE: true);
        }
        modifyHiddenStatusIntensity(source, 'gugu', -sourceChara.getHiddenStatusIntData('gugu', StatusData.intensity));
      }
      // 岚【天魔体】
      else if (trait == TraitId.demonicAvatar.id) {
        List<double> damageMultiRef = traitData['damageMultiRef'] ;
        damageMultiRef[0] = damageMultiRef[0] * 1.5;
      }
      // 岚【血灵斩】
      else if (trait == TraitId.hemaSlash.id) {        
        modifyCardCount(source, source, 1, CardEventType.discard);
        addAttribute(source, AttributeType.actiontime, 1);
        addHiddenStatus(source, 'hema', 0, 0);
        if (sourceChara.actionTime == 1) {
          addAttribute(source, AttributeType.attack, 15);
        }
      }
      // 恋慕【勿忘我】
      else if (trait == TraitId.dontForgetMe.id) {
        int type = traitData['type'];
        if (type == 0) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 3.3;
        }
        else if (type == 1) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 2.7;
        }
        else if (type == 2) {
          addAttribute(source, AttributeType.health, 1 - sourceChara.health);
          addHiddenStatus(source, 'forget_me', 0, 1);
        }
      }
      // K97【二进制噪声】
      else if (trait == TraitId.binary.id) {
        int type = traitData['type'];
        if (type == 0) {
          if (sourceChara.armor == 0) {
            addAttribute(source, AttributeType.armor, 1);
          } else {
            healPlayer(source, source, sourceChara.armor, DamageType.heal);
            addAttribute(source, AttributeType.armor, -sourceChara.armor);
          }          
        }
        else if (type == 2) {
          addHiddenStatus(source, 'binary', 0, 0);
          addHiddenStatus(source, 'costminus', 1, 0);
          addAttribute(source, AttributeType.card, 1);
          addAttribute(source, AttributeType.actiontime, 1);
        }        
      }
      // 安德宁【回旋曲】
      else if (trait == TraitId.rondo.id) {
        addStatus(source, source, StatusId.dodge.id, 0, 1);
      }
      // 卿别【夜魇游吟】
      else if (trait == TraitId.nightmareRefrain.id) {
        int type = traitData['type'];
        if (type == 0) {
          addStatus(source, target, StatusId.dreaming.id, 0, 1);
          addHiddenStatus(target, 'dream', 0, 2);
          addHiddenStatus(target, 'dream_tar', 0, 0);
          addHiddenStatus(source, 'dream_src', 0, 0);
        }
        else if (type == 1) {
          addHiddenStatus(source, 'nightmare', 0, 0);
        }
        else if (type == 2) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] = damageMultiRef[0] * 1.2;
        }
        else {
          addStatus(source, target, StatusId.drowsy.id, 1, 1);
        }
      }
      // 扶风【大预言】
      else if (trait == TraitId.grandProphecy.id) {
        int point = traitData['point'];
        int maxPoint = traitData['maxPoint'];
        throwDice(target, target, point, maxPoint, DiceType.trait);
        
        //addHiddenStatus(source, 'grand_prophecy', 0, 1);
      }
      // 奈普斯特【幽魂化】
      else if (trait == TraitId.spectralization.id) {
        int type = traitData['type'];
        if (type == 0) {
          List<int> damageRef = traitData['damageRef'];
          damageRef[0] = 0;
        }
        else {
          List<dynamic> statusKeys = sourceChara.status.keys.toList();
          for (var stat in statusKeys) {
            removeStatus(source, source, stat);
          }
        }
      }
      // 奈普斯特【小惊吓】
      else if (trait == TraitId.littleSpook.id) {
        List<GameRecord> actionDamageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, 
          startTurn: GameTurn(round: round - 1, turn: 1, extra: 0), endTurn: getGameTurn());
        Set<String> actionSources = {};
        for (var record in actionDamageRecords) { 
          DamageRecord damageRecord = record as DamageRecord;
          if (damageRecord.damageType == DamageType.action && damageRecord.damage > 0) {
            actionSources.add(damageRecord.source);
          }
        }
        for (var chara in players.keys) {
          if (!actionSources.contains(chara)) {
            addStatus(source, chara, StatusId.uneasiness.id, 1, 2);
          }
        }
      }
      // 星凝【希冀】
      else if (trait == TraitId.yearning.id) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(target, 'yearning_atk', (sourceChara.damageDealtTurn * 0.1).toInt(), 1);
          
        }
        else {
          addHiddenStatus(target, 'yearning_def', (sourceChara.damageDealtTurn * 0.1).toInt(), 1);
        }
      }
      // 星凝【祝愿】
      else if (trait == TraitId.blessing.id) {
        healPlayer(source, target, 100, DamageType.heal);
        List<dynamic> statusKeys = targetChara.status.keys.toList();
        for (var stat in statusKeys) {
          if (statusToType[stat]!.buffType == BuffType.negative) {
            removeStatus(source, target, stat);
          }
        }
      }
      // 时雨【天霜封印】
      else if (trait == TraitId.arcticSeal.id){
        int point = traitData['point'];
        throwDice(source, source, point, 6, DiceType.trait);
        if ({1, 3, 6}.contains(point)) {
          addStatus(source, target, StatusId.frozen.id, 0, 1);
          if (targetChara.hasStatus(StatusId.frozen.id)) {
            // 此处是为了平衡回合结束时，冰封状态的层数减少，否则轮到该玩家时，冰封状态已经结束            
            targetChara.increaseStatusData(StatusId.frozen.id, layerFraction: 1); 
          }
        }
      }
      // 时雨【寒冰血脉】
      else if (trait == TraitId.icyBlood.id){
        int type = traitData['type'];
        if (type == 0) {
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;
        }
        else {
          List<int> damagePlusRef = traitData['damagePlusRef'];
          if (targetChara.hasStatus(StatusId.frost.id)) {
            damagePlusRef[0] = damagePlusRef[0] - 30 * targetChara.getStatusIntData(StatusId.frost.id, StatusData.intensity);
          }
        }
      }
      // 图西乌【凌日】
      else if (trait == TraitId.transit.id) {
        List<int> damagePlusRef = traitData['damagePlusRef'];
        List<double> damageMultiRef = traitData['damageMultiRef'];
        damagePlusRef[0] = 0;
        damageMultiRef[0] = 1;
      }
      // 图西乌【蚀月】
      else if (trait == TraitId.eclipse.id) {
        int type = traitData['type'];
        if (type == 0) {
          int point = traitData['point'];
          addHiddenStatus(source, 'eclipse', point, 1);
        }
        else if (type == 1) {
          List<int> pointRef = traitData['pointRef'];
          if (sourceChara.hasHiddenStatus('eclipse')) {
            pointRef[0] = sourceChara.getHiddenStatusIntData('eclipse', StatusData.intensity);
            removeHiddenStatus(source, 'eclipse');
          }          
        }
        else {
          List<int> pointRef = traitData['pointRef'];
          if (pointRef[0] > 5) {
            pointRef[0] = 5;
          }
        }        
      }
      // 舸灯【引渡】
      else if (trait == TraitId.ghostFerry.id) {
        int type = traitData['type'];
        if (type == 0) {
          List<int> costRef = traitData['costRef'];
          costRef[0] -= 1;          
        }
        else {          
          modifyCardCount(source, target, 2, CardEventType.draw);
          addHiddenStatus(source, 'ferry', 0, 1);
        }
      }
      // 赐弥【在云端】
      else if (trait == TraitId.uponTheClouds.id) {
        int sourceSeq = gameSequence.indexOf(source) + 1;
        bool findHistory = false;

        for (int i = _historyProvider!.currentHistoryIndex; i >= 0; i--) {
          String history = _historyProvider!.getStateAt(i);
          Map<String, dynamic> gameState = jsonDecode(history);
          if (gameState['turn'] == sourceSeq) {
            findHistory = true;
          }
          if (findHistory && (gameState['turn'] == (sourceSeq == 1 ? gameSequence.length : sourceSeq - 1) || 
            sourceSeq == 1 && gameState['round'] == 1 && i == 0)) {            
            String save = _historyProvider!.getStateAt(i + 1);
            Map<String, dynamic> saveState = jsonDecode(save);
            Map<String, dynamic> playersData = saveState['players'];
            addAttribute(source, AttributeType.health, playersData[source]['health'] - sourceChara.health);
            addAttribute(source, AttributeType.attack, playersData[source]['attack'] - sourceChara.attack);
            addAttribute(source, AttributeType.defence, playersData[source]['defence'] - sourceChara.defence);
            addAttribute(source, AttributeType.movepoint, playersData[source]['movePoint'] - sourceChara.movePoint);
            addAttribute(source, AttributeType.card, playersData[source]['cardCount'] - sourceChara.cardCount);
            sourceChara.skill = {};
            if (playersData[source]['skill'] is Map) {
              (playersData[source]['skill'] as Map).forEach((k, v) {
                try {
                  sourceChara.skill[k.toString()] = CharaSkill.fromJson(Map<String, dynamic>.from(v));
                } catch (e) {
                  //
                }
              });
            }            
            sourceChara.status = {};
            if (playersData[source]['status'] is Map) {
              (playersData[source]['status'] as Map).forEach((k, v) {
                try {
                  sourceChara.status[k.toString()] = CharaStatus.fromJson(Map<String, dynamic>.from(v));
                } catch (e) {
                  //
                }
              });
            }
            addHiddenStatus(source, 'cloud', 0, 1);
            break;
          }
        }
      }
      // 高淼【轻捷妙手】
      else if (trait == TraitId.deftTouch.id) {
        int type = traitData['type'];
        if (type == 0) {          
          modifyCardCount(source, source, 1, CardEventType.draw);
        }
        else {
          String skill = traitData['skill'];
          countdown.deftTouchSkill = skill;
          countdown.deftTouchTarget = target;
          addHiddenStatus(target, 'touched', 0, 1);
        }
      }
      // 沫【湮灭性轮回】
      else if (trait == TraitId.annihilativeCycle.id) {
        int type = traitData['type'];
        if (type == 0) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 2;
        }
        else {
          int damage = traitData['damage'];
          addHiddenStatus(target, 'annihilate', (damage * 0.4).toInt(), 1);
        }
      }
      // 长霾【我还能喝】
      else if (trait == TraitId.imDrunk.id) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(source, 'alcohol', 50, -1);
        }
        else {
          int damage = traitData['damage'];
          addHiddenStatus(source, 'alcohol', (0.4 * damage).toInt(), -1);
          if (damage >= 300) {
            damagePlayer(source, target, sourceChara.getHiddenStatusIntData('alcohol', StatusData.intensity), DamageType.physical);
            modifyHiddenStatusIntensity(source, 'alcohol', -sourceChara.getHiddenStatusIntData('alcohol', StatusData.intensity));
            addStatus(source, source, StatusId.weakness.id, 1, 1);
            addStatus(source, target, StatusId.nausea.id, 0, 2);
          }
        }
      }
      // 长霾【律令】
      else if (trait == TraitId.decree.id) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(target, 'non_flying', 0, 1);
        }
        else if (type == 1) {
          addHiddenStatus(target, 'air_lock', targetChara.maxCard, 1);
        }
        else if (type == 2) {
          addHiddenStatus(target, 'demon_seal', 0, 1);
        }
        else {
          addHiddenStatus(target, 'spirit_bind', 0, 1);
        }        
      }
      // 云津【云系祝乐】
      else if (trait == TraitId.celestialJoy.id) {
        int type = traitData['type'];
        if (type == 0) {
          int point = traitData['point'];
          throwDice(source, source, point, 2, DiceType.trait);
          if (point == 2) {
            addAttribute(source, AttributeType.movepoint, 1);
          }
          modifyHiddenStatusIntensity(source, 'celestial', -2);
        }
        else if (type == 1) {          
          modifyCardCount(source, source, 1, CardEventType.draw);
        }
        else {
          int movepoint = traitData['movepoint'];
          if (movepoint > 0) {
            addHiddenStatus(source, 'celestial', movepoint, -1);
          }
        }
      }
      // 晖夕【挑拣】
      else if (trait == TraitId.discerning.id) {
        int point = traitData['point'];
        int maxPoint = traitData['maxPoint'];
        throwDice(source, source, point, maxPoint, DiceType.action);
      }
      // 唐菁延【延光】
      else if (trait == TraitId.lingeringLight.id) {
        int type = traitData['type'];
        int cooldown = traitData['cooldown'];
        if (type == 0) {
          addAttribute(target, AttributeType.movepoint, -(cooldown + 2) ~/ 3);
        }
        else {
          for (var tar in targets) {
            addAttribute(tar, AttributeType.movepoint, (cooldown + 2) ~/ 3);
          }          
        }
      }
      // 唐菁延【盈光】
      else if (trait == TraitId.radiantFullness.id) {
        List<int> costRef = traitData['costRef'];
        costRef[0] = 0;
      }
      // 炎焕【心炎】
      else if (trait == TraitId.cardioBlaze.id) {
        int point = traitData['point'];
        throwDice(source, source, point, 6, DiceType.trait);
        if ({2, 3, 4}.contains(point)) {
          for (var chara in players.values) {
            if (chara.id != source) {
              for (var stat in chara.status.keys) {  
                if (statusToType[stat]!.buffType == BuffType.negative) {
                  addStatus(source, chara.id, StatusId.infernoFire.id, 5, 1);
                  break;
                }
              }              
            }
          }
        }
      }
      // 樊求【游侠】
      else if (trait == TraitId.ranger.id) { 
        int type = traitData['type'];
        if (type == 0) {
          bool hasTeammate = false;
          for (var chara in players.values) {
            if (isTeammate(source, chara.id) && !chara.isDead) {
              hasTeammate = true;
              break;
            }
          }
          if (hasTeammate) {
            addHiddenStatus(source, 'ranger_def', 0, 1);
            removeHiddenStatus(source, 'ranger');
          }
          else {
            addHiddenStatus(source, 'ranger_atk', 0, 1);
            addHiddenStatus(source, 'ranger', 1, -1);
          }
        }
        else {
          addAttribute(source, AttributeType.attack, 10);
          addHiddenStatus(source, 'ranger_used', 0, -1);
        }
      }
      // 樊求【精准】
      else if (trait == TraitId.precision.id) { 
        List<double> damageMultiRef = traitData['damageMultiRef'];
        damageMultiRef[0] *= 1.3;
      }
      // 斯威芬【梦的塑造】
      else if (trait == TraitId.craftingOfDreams.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          modifyCardCount(source, source, 1, CardEventType.discard);
          addStatus(source, source, StatusId.dreamCrafting.id, 0, 1);
        }
        else if (type == 1) {
          removeStatus(source, source, StatusId.dreamCrafting.id);
        }
        else if (type == 2) {
          int point = traitData['point'];
          if ({1, 2, 6}.contains(point)) {
            addHiddenStatus(source, 'dreaming', 2, -1);
          }
          else  {
            addHiddenStatus(source, 'dreaming', 1, -1);
          }
        }
        else if (type == 3) {
          addHiddenStatus(source, 'nightmare', 0, 0);
        }
        else {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 1.1;
        }
      }
      // 红烬【烈焰之体】
      else if (trait == TraitId.conflagrationAvatar.id) { 
        int type = traitData['type'];        
        if (type == 0) { 
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;          
        }
        else if (type == 1) {
          int point = traitData['point'];
          throwDice(source, source, point, 6, DiceType.trait);
          if ({2, 4, 5}.contains(point)) {
            List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, source: source, 
              startTurn: getGameTurn(), endTurn: getGameTurn());
            for (var record in actionRecords) {
              ActionRecord actionRecord = record as ActionRecord;
              addStatus(source, actionRecord.target, StatusId.flaming.id, 5, 3);     
            }
          }
        }
        else if (type == 2) {
          int point = traitData['point'];
          throwDice(source, source, point, 6, DiceType.trait);
          if ({2, 4, 5}.contains(point)) {
            List<GameRecord> actionRecords = _recordProvider!.getFilteredRecords(type: RecordType.action, target: source, 
              startTurn: getGameTurn(), endTurn: getGameTurn());
            for (var record in actionRecords) {
              ActionRecord actionRecord = record as ActionRecord;
              addStatus(source, actionRecord.source, StatusId.flaming.id, 5, 3);     
            }
          }
        }
      }
      // 余梦得【梦的守护】
      else if (trait == TraitId.guardianOfDreams.id) {
        int type = traitData['type'];
        if (type == 0) {
          addStatus(source, source, StatusId.dreamGuarding.id, 0, 1);
        }
        else if (type == 1) {
          addHiddenStatus(source, 'dream_guard', 0, 1);
        }
        else if (type == 2) {
          if (sourceChara.skill.keys.contains(SkillId.dreamKeeper.id)) {
            modifySkillCooldown(source, source, SkillId.dreamKeeper.id, -1);
          }
        }
      }
      // 好好先生【见面礼】
      else if (trait == TraitId.introductoryGift.id) { 
        addStatus(source, target, StatusId.gift.id, 0, -1);
        addHiddenStatus(target, 'intro_gift', 0, -1);
      }
      // 好好先生【深重情谊】
      else if (trait == TraitId.imposingFavor.id) {
        addHiddenStatus(target, 'favor', 0, 2);
      }
      // 叶姬【须臾】
      else if (trait == TraitId.ephemeral.id) {        
        String status = traitData['status'];
        modifyStatusIntensity(source, target, status, targetChara.getStatusIntData(status, StatusData.intensity) 
        * (targetChara.getStatusIntData(status, StatusData.layer) - 1));
        modifyStatusLayer(source, target, status, -targetChara.getStatusIntData(status, StatusData.layer) + 1);
      }
      // 太夕【黯灭】
      else if (trait == TraitId.darkDissolution.id) {
        int type = traitData['type'];
        if (type == 0) {
          modifyHiddenStatusIntensity(source, 'dark', 1);
        }
        else if (type == 1) {
          String card = traitData['card'];
          modifyCardCount(source, source, 1, CardEventType.discard);
          if (cardTags[card]!.length > 1){
            modifyHiddenStatusIntensity(source, 'dark', 2);
          }
          else {
            modifyHiddenStatusIntensity(source, 'dark', 1);
          }          
        }
      }
      // 太夕【吞噬之锁】
      else if (trait == TraitId.devouringLock.id) {         
        modifyHiddenStatusIntensity(source, 'dark', -2);
        damagePlayer(source, target, 75, DamageType.physical);
        healPlayer(source, source, 75, DamageType.heal);
        addStatus(source, target, StatusId.constraint.id, 0, 1);
      }
      // 科亚特尔【拟造“伊甸园”】
      else if (trait == TraitId.artificialEden.id) { 
        addStatus(source, source, StatusId.sanctify.id, 0, 1);
        addHiddenStatus(source, 'sanctify', 0, 1);
        if (sourceChara.hasHiddenStatus('sanctify')) {
          sourceChara.increaseHiddenStatusData('sanctify', layerFraction: 1);
        }
      }
      // 科亚特尔【善恶天平】
      else if (trait == TraitId.balanceOfLightAndShadow.id) { 
        addHiddenStatus(source, 'balance_change', 0, 1);
      }
      // 蒙德里安【禁忌知识】
      else if (trait == TraitId.tabooLore.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'forbidden', 1, -1);
        }
        else if (type == 1) {           
          modifyHiddenStatusIntensity(source, 'forbidden', -1);
          if (targetChara.hasStatus(StatusId.eden.id)) {
            removeStatus(source, target, StatusId.eden.id);
            damagePlayer(source, source, 75, DamageType.physical);
          }
          else {
            addHiddenStatus(source, 'forbidden_plus', 0, 1);
            damagePlayer(source, target, 75, DamageType.physical);
          }     
        }
        else if (type == 2) {           
          modifyHiddenStatusIntensity(source, 'forbidden', -1);
          if (targetChara.hasStatus(StatusId.eden.id)) {
            removeStatus(source, target, StatusId.eden.id);
            damagePlayer(source, source, 75, DamageType.physical);
          }
          else {            
            addHiddenStatus(target, 'forbidden_minus', 0, 1);
            damagePlayer(source, target, 75, DamageType.physical);
          }          
        }
        else {
          int heal = traitData['heal'];
          healPlayer(target, source, heal, DamageType.heal);
        }
      }
      // 阿波菲斯【毁灭暗影】
      else if (trait == TraitId.ruinousShade.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          if (!sourceChara.hasHiddenStatus('shade')) {
            addHiddenStatus(source, 'shade', 1, -1);
          }
          addStatus(source, target, StatusId.nightmare.id, sourceChara.getHiddenStatusIntData('shade', StatusData.intensity), 2);
          addHiddenStatus(target, 'night', 0, -1);
        }
        else if (type == 1) { 
          castTrait(source, targets, TraitId.endlessNight.id);
          for (var chara in players.values) {
            if (chara.id == CharacterId.mondrian.id && !chara.isDead) {              
              if (targetChara.hasStatus(StatusId.eden.id)) {
                castTrait(chara.id, [source], TraitId.tabooLore.id, {'type': 3, 'heal': 6 + 12 * targetChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity)});                              
              } 
              else {
                castTrait(chara.id, [source], TraitId.tabooLore.id, {'type': 3, 'heal': 3 + 6 * targetChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity)});              
              }
              castTrait(source, targets, TraitId.ruinousShade.id, {'type': 2, 'damage': 30 * chara.getHiddenStatusIntData('forbidden', StatusData.intensity)}); 
              break;
            }
          }
        }
        else {
          int damage = traitData['damage'];
          damagePlayer(source, target, damage, DamageType.magical);
        }
      }
      // 阿波菲斯【永夜无终】
      else if (trait == TraitId.endlessNight.id) { 
        addHiddenStatus(source, 'shade', 1, -1);
        modifyHiddenStatusIntensity(source, 'night', -sourceChara.getHiddenStatusIntData('night', StatusData.intensity));
      }
      // 红黎【红莲业火】
      else if (trait == TraitId.lotusFlame.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(source, target, StatusId.flaming.id, 5, 1);
        }
        else if (type == 1) {
          int tag = traitData['tag'];
          addHiddenStatus(target, 'lotus', tag, 1);
        }
      }
      // 红黎【冰火相融】
      else if (trait == TraitId.iceFireFusion.id) { 
        List<double> damageMultiRef = traitData['damageMultiRef'];
        damageMultiRef[0] *= 1.5;
      }
      // 祝烨明【八裂】
      else if (trait == TraitId.cryoFissuring.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          int layers = traitData['damage'] ~/ 100;
          if (layers >= targetChara.getStatusIntData(StatusId.moisturize.id, StatusData.layer)) {
            addStatus(source, target, StatusId.frozen.id, 0, targetChara.getStatusIntData(StatusId.moisturize.id, StatusData.layer));
            removeStatus(source, target, StatusId.moisturize.id);
          }
          else {
            addStatus(source, target, StatusId.frozen.id, 0, layers);
            modifyStatusLayer(source, target, StatusId.moisturize.id, -layers);
          }
        }
        else {
          damagePlayer(source, target, targetChara.maxHealth ~/ 8, DamageType.physical);
        }
      }
      // 方塔索【神游】
      else if (trait == TraitId.astralProjection.id) { 
        int type = traitData['type'];
        if (type == 0) {          
          addHiddenStatus(source, 'astral', 0, 1);
        }
        else if (type == 1) { 
          List<int> damagePlusRef = traitData['damagePlusRef'];
          damagePlusRef[0] += 40;
        }
        else {
          addHiddenStatus(source, 'nightmare', 0, 1);
        }
      }
      // 龙宇澈【光耀】
      else if (trait == TraitId.radiance.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          if (!sourceChara.hasHiddenStatus('light')) {
            addHiddenStatus(source, 'light', 2, -1);
          }
          modifyCardCount(source, source, 1, CardEventType.discard);
          addHiddenStatus(source, 'light_elf', 1, -1);
          castTrait(source, [source], TraitId.soulBurning.id);
        }
        else if (type == 1) { 
          int intensity = (sourceChara.maxHealth - sourceChara.health) ~/ 200 + 2 - sourceChara.getHiddenStatusIntData('light', StatusData.intensity);
          addHiddenStatus(source, 'light', intensity, -1);
        }
        else {
          String dmgSource = traitData['dmgSource'];
          int damage = traitData['damage'];
          int point = traitData['point'];
          throwDice(source, source, point, 10, DiceType.trait);
          if (point <= sourceChara.getHiddenStatusIntData('light_elf', StatusData.intensity)) {
            addAttribute(source, AttributeType.health, damage);
            addAttribute(source, AttributeType.dmgreceived, -damage);
            addAttribute(dmgSource, AttributeType.dmgdealt, -damage);
          }
          List<DamageRecord> damageRecords =  _recordProvider!.getFilteredRecords(type: RecordType.damage, target: source,
            startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
          for (DamageRecord damageRecord in damageRecords) {
            if (damageRecord.source == dmgSource && damageRecord.damage == damage) {
              _recordProvider!.removeRecord(damageRecord);
              break;
            }
          }
        }
      }
      // 龙宇澈【燃魂】
      else if (trait == TraitId.soulBurning.id) { 
        if (sourceChara.hasHiddenStatus('light')) {
          addHiddenStatus(source, 'soul_burning', 0, -1);
        }        
      }
      // 祝言夙【精神干扰】
      else if (trait == TraitId.mentalDisruption.id) { 
        int point = traitData['point'];
        throwDice(target, target, point, 6, DiceType.trait);
        if ({3, 4}.contains(point)) {
          addHiddenStatus(target, 'disruption', 0, 1);
        }
      }
      // 星惑【众人的乌托邦】
      else if (trait == TraitId.collectiveUtopia.id) { 
        int type = traitData['type'];
        if (type == 0) {
          List<int> pointRef = traitData['pointRef'];
          int pointPlus = 1;
          for (var chara in players.values) {
            if (isTeammate(source, chara.id) && !chara.isDead) {              
              pointPlus += 1;
            }
            if (chara.id == CharacterId.longYuche.id && chara.hasHiddenStatus('light_elf')) {
              pointPlus += chara.getHiddenStatusIntData('light_elf', StatusData.intensity);
            }
          }
          if (sourceChara.hasHiddenStatus('collective')) {
            pointPlus += sourceChara.getHiddenStatusIntData('collective', StatusData.intensity);
          }          
          pointRef[0] += pointPlus; 
        }
        else {
          addHiddenStatus(source, 'collective', 1, -1);
        }
      }
      // 唐亚德【清心的乌托邦】
      else if (trait == TraitId.utopiaOfClarity.id) { 
        int type = traitData['type'];
        if (type == 0) {           
          modifyHiddenStatusIntensity(source, 'clarity', 1);
        }
        else if (type == 1) { 
          modifyHiddenStatusIntensity(source, 'clarity', -1);
          damagePlayer(source, target, 80, DamageType.physical);
        }
        else {
          for (var skill in sourceChara.skill.keys) {
            modifySkillCooldown(source, source, skill, -1);         
          }
        }
      }
      // 雷刚【决意的乌托邦】
      else if (trait == TraitId.utopiaOfResolve.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addAttribute(source, AttributeType.armor, 100);
          addHiddenStatus(source, 'barrier', 0, -1);
          addHiddenStatus(source, 'resolve', 0, -1);
        }
        else if (type == 1) { 
          List<String> cardList = traitData['cardList'];
          if (sourceChara.health < 300) {
            for (String card in cardList) {
              List<String> tagList = cardTags[card]!;
              if (tagList.contains(TagId.vital.id)){
                addAttribute(source, AttributeType.armor, 50);
              }
            }
          }
          else {
            for (String card in cardList) {
              List<String> tagList = cardTags[card]!;
              if (tagList.contains(TagId.vital.id) || tagList.contains(TagId.sharp.id)){
                damagePlayer('empty', source, 100, DamageType.lost);
              }
            }
          }          
        }
        else { 
          removeHiddenStatus(source, 'rest');
        }
      }
      // 陆风【追猎的乌托邦】
      else if (trait == TraitId.utopiaOfCelerity.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(source, target, StatusId.prey.id, 0, -1);
          modifyCardCount(source, source, 1, CardEventType.discard);
        }
        else if (type == 1) { 
          List<double> damageMultiRef = traitData['damageMultiRef'];
          addAttribute(source, AttributeType.movepoint, 1);
          damageMultiRef[0] *= 1.2;
        }
        else { 
          addHiddenStatus(target, 'prey', 0, 1);
            removeStatus(source, target, StatusId.prey.id);
        }
      }
      // 安山定【后发的乌托邦】
      else if (trait == TraitId.utopiaOfUpspring.id) { 
        int type = traitData['type'];
        if (type == 0) {
          addStatus(source, source, StatusId.poised.id, 0, 1);
          //sourceChara.status[StatusId.poised.id]![2] += 1;
          sourceChara.increaseStatusData(StatusId.poised.id, layerFraction: 1);
          addHiddenStatus(source, 'upspring', 0, -1);
        }
        else {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] *= 0.75;          
        }        
      }
      // 颜若卿【调和的乌托邦】
      else if (trait == TraitId.utopiaOfConcord.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          List<int> costRef = traitData['costRef'];
          List<String> cardList = traitData['cardList'];
          for (String card in cardList) {
            List<String> tagList = cardTags[card]!;
            if (tagList.contains(TagId.vital.id)){
              costRef[0] -= 1;
            }
          }          
        }
        else if (type == 1) { 
          List<int> costRef = traitData['costRef'];
          costRef[0] = 0;
        }
        else { 
          addStatus(source, source, StatusId.regeneration.id, 3, 1);
          modifyCardCount(source, source, 1, CardEventType.draw);
        }
      }
      // 亭歆雨【彼岸之金】
      else if (trait == TraitId.aurelysium.id) { 
        List<String> cardList = traitData['cardList'];
        Set<String> tagSet = {};        
        for (var card in cardList) { 
          List<String> tagList = cardTags[card]!;
          tagSet.addAll(tagList);
        }
        if (tagSet.length < 5) {
          for (var card in cardList) {
            List<String> tagList = cardTags[card]!;
            for (var tag in tagList) {
              if (tag == TagId.sharp.id) {
                addAttribute(source, AttributeType.attack, 5);
              }
              else if (tag == TagId.protect.id) {
                addAttribute(source, AttributeType.defence, 5);
              }
              else if (tag == TagId.vital.id) {
                healPlayer(source, source, 50, DamageType.heal);
              }
              else if (tag == TagId.destiny.id) {
                addHiddenStatus(source, 'destiny', 1, 1);
              }
              else if (tag == TagId.mystique.id) {
                for (var stat in sourceChara.status.keys) {
                  if (statusToType[stat]!.buffType == BuffType.positive) {
                    modifyStatusLayer(source, source, stat, 1);
                  }
                }
              }
              else if (tag == TagId.phantom.id) {
                modifyCardCount(source, source, 1, CardEventType.draw);
              }
              else if (tag == TagId.magic.id) {
                removeStatus(source, target, StatusId.dodge.id);
                addAttribute(target, AttributeType.armor, -targetChara.armor);
              }
              else if (tag == TagId.weird.id) {
                addHiddenStatus(target, 'weird', 0, 1);
              }
              else if (tag == TagId.disorder.id) {
                addAttribute(target, AttributeType.movepoint, -1);
              }
              else if (tag == TagId.sense.id) {
                addAttribute(source, AttributeType.movepoint, 1);
              }
              else if (tag == TagId.heat.id) {
                damagePlayer(source, target, 30, DamageType.magical);
              }
              else if (tag == TagId.chill.id) {
                addStatus(source, target, StatusId.frost.id, 1, 1);
              }
            }
          }
        }
        else {
          for (var card in cardList) {
            List<String> tagList = cardTags[card]!;
            for (var tag in tagList) {
              if (tag == TagId.sharp.id) {
                addAttribute(source, AttributeType.attack, 10);
              }
              else if (tag == TagId.protect.id) {
                addAttribute(source, AttributeType.defence, 10);
              }
              else if (tag == TagId.vital.id) {
                healPlayer(source, source, 100, DamageType.heal);
              }
              else if (tag == TagId.destiny.id) {
                addHiddenStatus(source, 'destiny', 2, 1);
              }
              else if (tag == TagId.mystique.id) {
                for (var stat in sourceChara.status.keys) {
                  if (statusToType[stat]!.buffType == BuffType.positive) {
                    modifyStatusLayer(source, source, stat, 2);
                  }
                }
              }
              else if (tag == TagId.phantom.id) {
                modifyCardCount(source, source, 2, CardEventType.draw);
              }
              else if (tag == TagId.magic.id) {
                removeStatus(source, target, StatusId.dodge.id);
                addAttribute(target, AttributeType.armor, -targetChara.armor);
                for (var stat in targetChara.status.keys.toList()) {
                  if (statusToType[stat]!.buffType == BuffType.positive) {
                    removeStatus(source, target, stat);
                  }
                }
              }
              else if (tag == TagId.weird.id) {
                addHiddenStatus(target, 'weird', 0, 1);
                addHiddenStatus(target, 'strange', 0, 1);
              }
              else if (tag == TagId.disorder.id) {
                addAttribute(target, AttributeType.movepoint, -2);
              }
              else if (tag == TagId.sense.id) {
                addAttribute(source, AttributeType.movepoint, 2);
              }
              else if (tag == TagId.heat.id) {
                damagePlayer(source, target, 60, DamageType.magical);
              }
              else if (tag == TagId.chill.id) {
                addStatus(source, target, StatusId.frost.id, 2, 1);
              }
            }
          }
        }
      }
      // 白谢【极寒环域】
      else if (trait == TraitId.glacialCircle.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          int point = traitData['point'];
          throwDice(source, source, point, 6, DiceType.trait);
          if ({2, 4, 5}.contains(point)) {
            List<DamageRecord> damageRecords = _recordProvider!.getFilteredRecords(type: RecordType.damage, 
              target: source, startTurn: getGameTurn(), endTurn: getGameTurn()).cast<DamageRecord>();
            for (var record in damageRecords) {
              if ({DamageType.action, DamageType.physical}.contains(record.damageType)) {
                addAttribute(record.target, AttributeType.health, record.damage ~/ 2);
                addAttribute(record.target, AttributeType.dmgreceived, record.damage ~/ 2);
                addAttribute(record.source, AttributeType.dmgdealt, -record.damage ~/ 2);
              }
              _recordProvider!.addDamageRecord(record.turn, record.source, record.target, record.damage ~/ 2, record.damageType, record.tag);
              _recordProvider!.removeRecord(record);
            }

            for (var tar in targets) {
              addStatus(source, tar, StatusId.frost.id, 3, 1);
            }
          }
        }
        else if (type == 1) { 
          addAttribute(target, AttributeType.attack, -2);
          addAttribute(target, AttributeType.defence, -3);
        }
        else {
          addAttribute(target, AttributeType.attack, -5);
          addAttribute(target, AttributeType.defence, -5);
        }
      }
      // 沈姝华【纯洁之爱】
      else if (trait == TraitId.innocentLove.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          List<String> cardList = traitData['cardList'];
          int cardOverlapped = 0;
          int maxOverlapped = 0;
          for (var tag in TagId.values) {
            cardOverlapped = 0;
            for (var card in cardList) {
              List<String> tagList = cardTags[card]!;
              if (tagList.contains(tag.id)) {
                cardOverlapped += 1;
              }
            }
            if (cardOverlapped > maxOverlapped) {
              maxOverlapped = cardOverlapped;
            }
          }
          List<int> costRef = traitData['costRef'];
          costRef[0] -= (maxOverlapped - 1);
        }
        else {
          modifyCardCount(source, source, 1, CardEventType.draw);
        }
      }
      // 翠灵【生息】
      else if (trait == TraitId.lifeBreath.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'breath', 0, 1);
        }
        else if (type == 1) { 
          for (var tar in targets) {
            damagePlayer(source, tar, 50, DamageType.lost, isAOE: true);
            healPlayer(source, source, 50, DamageType.heal);
          }
          removeHiddenStatus(source, 'breath');
        }
      }
      // 翠灵【破土】
      else if (trait == TraitId.earthBreak.id) { 
        List<String> cardList = traitData['cardList'];
        for (String card in cardList) {
          List<String> tagList = cardTags[card]!;
          if (tagList.contains(TagId.vital.id)) {
            for (var tar in targets) {
              addStatus(source, tar, StatusId.tear.id, 5, 1);
            }
          }
        }
      }
      // 湍云【屏息】
      else if (trait == TraitId.holdBreath.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'hold', 0, 1);
        }
        else if (type == 1) { 
          addStatus(source, source, StatusId.charge.id, 0, 1);
          modifyStatusIntensity(source, source, StatusId.charge.id, 3);
          removeHiddenStatus(source, 'hold');
        }
        else if (type == 2) {
          addHiddenStatus(source, 'holding', 0, 1);
        }
        else { 
          addStatus(source, source, StatusId.charge.id, 0, 1);
          modifyStatusIntensity(source, source, StatusId.charge.id, 5);
          removeHiddenStatus(source, 'holding');
        }
      }
      // 湍云【惊弓】
      else if (trait == TraitId.gunShy.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addHiddenStatus(source, 'gun_shy', 0, 1);
        }
        else if (type == 1) { 
          addStatus(source, source, StatusId.uneasiness.id, 1, 1);
          removeHiddenStatus(source, 'gun_shy');
        }
      }
      // ReFre-3【<06>自卫协议】
      else if (trait == TraitId.defensiveProtocol.id) { 
        damagePlayer(source, target, sourceChara.attack - targetChara.defence, DamageType.physical);
        addStatus(source, target, StatusId.frost.id, 5, 1);
        addHiddenStatus(source, 'protocol', 1, 1);
      }
      // ReFre-3【<0C>热能回收】
      else if (trait == TraitId.thermalRecovery.id) { 
        addStatus(source, source, StatusId.charge.id, targetChara.getStatusIntData(StatusId.frost.id, StatusData.intensity), 1);
      }
      // 洛尔【不断燃烧的愤怒】
      else if (trait == TraitId.smolderingRage.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          int rageIntensity = targetChara.getHiddenStatusIntData('rage', StatusData.intensity) == -1 
            ? 0 : targetChara.getHiddenStatusIntData('rage', StatusData.intensity);
          addAttribute(source, AttributeType.attack, 5 * ((targetChara.maxHealth - targetChara.health) ~/ 200 - rageIntensity));
          addHiddenStatus(source, 'rage', ((targetChara.maxHealth - targetChara.health) ~/ 200 - rageIntensity), -1);
        }
        else { 
          addStatus(source, source, StatusId.wounded.id, 5, 1);
        }
      }
      // 洛尔【毫无章法的进攻】
      else if (trait == TraitId.chaoticStrikes.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(source, target, StatusId.unbalanced.id, targetChara.attack * 3, 1);
        }
        else { 
          addAttribute(target, AttributeType.maxhp, -targetChara.getStatusIntData(StatusId.unbalanced.id, StatusData.intensity));
          modifyStatusLayer(source, target, StatusId.unbalanced.id, -1);
          if (targetChara.maxHealth < targetChara.health) {
            damagePlayer('empty', target, targetChara.health - targetChara.maxHealth, DamageType.lost);
            addStatus(source, target, StatusId.confusion.id, 0, 1);
            addHiddenStatus(source, 'unbalanced', 0, 1);
          }
        }
      }
      // 奥菲莉娅【控水】
      else if (trait == TraitId.hydromancy.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(source, target, StatusId.dehydration.id, 1, 2);
        }
        else { 
          addStatus(source, target, StatusId.submerged.id, 1, 2);
        }
      }
      // 奥菲莉娅【水之刑】
      else if (trait == TraitId.waterTorture.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          int point = traitData['point'];
          addStatus(source, target, StatusId.asphyxia.id, point, 1);
          removeStatus(source, target, StatusId.dehydration.id);
          removeStatus(source, target, StatusId.submerged.id);
        }
        else { 
          damagePlayer('empty', target, 50 * targetChara.getStatusIntData(StatusId.asphyxia.id, StatusData.intensity), DamageType.lost);
          removeStatus(source, target, StatusId.asphyxia.id);
        }
      }
      // 符楹【光暗双生】
      else if (trait == TraitId.lumenUmbraGemini.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          modifyHiddenStatusIntensity(source, 'gemini', 1);
          modifyCardCount(source, source, 1, CardEventType.discard);
        }
        else if (type == 1) { 
          healPlayer(source, source, sourceChara.maxHealth ~/ 20, DamageType.heal);
        }
        else {
          damagePlayer(source, target, targetChara.maxHealth ~/ 20, DamageType.magical);
        }
      }
      // EnGine-4【<04>质能转换】
      else if (trait == TraitId.massEnergyConversion.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          int damage = traitData['damage'];
          switch (damage) {
            case >= 244:
              healPlayer(source, source, 17 * (sourceChara.maxHealth - sourceChara.health) ~/ 50, DamageType.heal);
              break;
            case >= 124:
              healPlayer(source, source, 6 * (sourceChara.maxHealth - sourceChara.health) ~/ 25, DamageType.heal);
              break;
            case >= 64:
              healPlayer(source, source, 7 * (sourceChara.maxHealth - sourceChara.health) ~/ 50, DamageType.heal);
              break;
          }
        }
        else if (type == 1){
          addHiddenStatus(source, 'conversion', 0, 1);
        }
        else if (type == 2){
          modifyCardCount(source, source, 2, CardEventType.draw);
        }
        else {
          modifyCardCount(source, target, 1, CardEventType.grab);
        }
      }
      // 兰斯洛特【针锋相对】
      else if (trait == TraitId.titForTat.id) { 
        int sourcePoint = traitData['sourcePoint'];
        int targetPoint = traitData['targetPoint'];
        if (sourceChara.hasHiddenStatus('tit_for_tat')) {
          sourcePoint += sourceChara.getHiddenStatusIntData('tit_for_tat', StatusData.intensity);
        }
        if (sourcePoint > targetPoint) {
          addAttribute(source, AttributeType.attack, 5);
          damagePlayer(source, target, (sourcePoint - targetPoint) * (sourceChara.attack - targetChara.defence), DamageType.physical);
          removeHiddenStatus(source, 'tit_for_tat');
        }
        else {
          //addHiddenStatus(source, 'tit_for_tat', 1, -1);
          modifyHiddenStatusIntensity(source, 'tit_for_tat', 1);
        }
      }
      // 祝烨诚【凛息】
      else if (trait == TraitId.icyStillness.id) {
        int type = traitData['type'];
        if (type == 0) { 
          addStatus(source, target, StatusId.frost.id, 2, 1);
        }
        else if (type == 1) {
          List<String> cardList = traitData['cardList'];
          List<int> costRef = traitData['costRef'];
          for (String card in cardList) {
            List<String> tagList = cardTags[card]!;
            if (tagList.contains(TagId.chill.id) || tagList.contains(TagId.mystique.id)) {
              costRef[0] -= 1;
            }
          }
        }
        else {
          List<String> cardList = traitData['cardList'];
          for (String card in cardList) {
            List<String> tagList = cardTags[card]!;
            if (tagList.contains(TagId.chill.id) || tagList.contains(TagId.mystique.id)) {
              modifyStatusLayer(source, target, StatusId.frost.id, 1);
              modifyStatusIntensity(source,target, StatusId.frost.id, 1);
            }
          }
        }
      }
      // 蓝文策【探囊取物】
      else if (trait == TraitId.pluckingPouch.id) {
        int type = traitData['type'];
        addHiddenStatus(source, 'pluck', 0, 0);
        addHiddenStatus(target, 'pluck_tar', 0, 0);
        if (type == 0) { 
          addHiddenStatus(source, 'costminus', 1, 0);
          modifyCardCount(source, target, 1, CardEventType.grab);
        }
      }
      // DeFen-5【<15>力场模拟】
      else if (trait == TraitId.forceFieldSimulation.id) { 
        addAttribute(source, AttributeType.defence, 3);
        modifyCardCount(source, source, 1, CardEventType.discard);
      }
      // 染序【五采】
      else if (trait == TraitId.iridescentHue.id) { 
        if (!sourceChara.hasHiddenStatus('iris')) {
          addHiddenStatus(source, 'iris', 0, -1);
        }
        List<String> cardList = traitData['cardList'];
        int cardCount = cardList.length;
        for (int i = 0; i < cardCount; i++) {
          modifyHiddenStatusIntensity(source, 'iris', 1);
          switch (sourceChara.getHiddenStatusIntData('iris', StatusData.intensity) % 5){
            case 0:
              addHiddenStatus(source, 'color_yellow', 1, 0);
              if (sourceChara.getHiddenStatusIntData('kindle', StatusData.intensity) > 0) {
                addHiddenStatus(source, 'kindle_yellow', 1, 0);
                modifyHiddenStatusIntensity(source, 'kindle', -1);
              }
              break;
            case 1:
              addHiddenStatus(source, 'color_white', 1, 0);
              if (sourceChara.getHiddenStatusIntData('kindle', StatusData.intensity) > 0) {
                addHiddenStatus(source, 'kindle_white', 1, 0);
                modifyHiddenStatusIntensity(source, 'kindle', -1);
              }
              break;
            case 2:
              addHiddenStatus(source, 'color_black', 1, 0);
              if (sourceChara.getHiddenStatusIntData('kindle', StatusData.intensity) > 0) {
                addHiddenStatus(source, 'kindle_black', 1, 0);
                modifyHiddenStatusIntensity(source, 'kindle', -1);
              }
              break;
            case 3:
              addHiddenStatus(source, 'color_red', 1, 0);
              if (sourceChara.getHiddenStatusIntData('kindle', StatusData.intensity) > 0) {
                addHiddenStatus(source, 'kindle_red', 1, 0);
                modifyHiddenStatusIntensity(source, 'kindle', -1);
              }
              break;
            case 4:
              addHiddenStatus(source, 'color_green', 1, 0);
              if (sourceChara.getHiddenStatusIntData('kindle', StatusData.intensity) > 0) {
                addHiddenStatus(source, 'kindle_green', 1, 0);
                modifyHiddenStatusIntensity(source, 'kindle', -1);
              }
              break;
          }
        }
      }
      // 卡拉卡【友情防守】
      else if (trait == TraitId.buddyBlock.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          List<int> costRef = traitData['costRef'];
          costRef[0] += 1;
          addAttribute(source, AttributeType.movepoint, 1);
        }
        else if (type == 1) { 
          addAttribute(source, AttributeType.movepoint, -sourceChara.movePoint);
          for (var chara in players.values) {
            if ((isTeammate(source, chara.id) || chara.id == source) && chara.id != 'empty') {
              List<String> statusKeys = chara.status.keys.toList();
              for (String stat in statusKeys) {
                if (statusToType[stat]!.buffType == BuffType.negative) {
                  removeStatus(source, chara.id, stat);
                }
              }
              addAttribute(chara.id, AttributeType.movepoint, 1);
            }
          }
        }
        else {
          addAttribute(target, AttributeType.movepoint, -1);
        }
      }
      // 观风【气象万千】
      else if (trait == TraitId.weathersUnfold.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          modifyHiddenStatusIntensity(source, 'wind', 1);
        }
        else if (type == 1) { 
          modifyHiddenStatusIntensity(source, 'cloud', 1);
        }        
        else { 
          addHiddenStatus(source, 'weather', 0, 0);
        }
      }
      // 安提忒斯【冰与火之歌】
      else if (trait == TraitId.iceAndFire.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          modifyStatusLayer(source, source, StatusId.flaming.id, 2);
          modifyStatusIntensity(source, source, StatusId.flaming.id, 2);
        }
        else if (type == 1) { 
          modifyStatusLayer(source, source, StatusId.frost.id, 2);
          modifyStatusIntensity(source, source, StatusId.frost.id, 2);
        }
        else {
          String status = traitData['status'];
          addHiddenStatus(source, 'ice_and_fire', 0, 0);
          sourceChara.setHiddenStatusData('ice_and_fire', strData: status);
        }
      }
      // 守塔人【潮海明灯】
      else if (trait == TraitId.tideBeacon.id) { 
        List<StatusRecord> statusRecords = _recordProvider!.getFilteredRecords(type: RecordType.status, target: target).cast<StatusRecord>();
        String status = statusRecords.lastWhere((e) => statusToType[e.name]!.buffType == BuffType.negative && e.changeType == StatusChange.add
          && targetChara.hasStatus(e.name)).name;
        removeStatus(source, target, status);
        addStatus(source, target, StatusId.impassioned.id, 2, 1);
      }
      // 焰心剑【陨光之刃】
      else if (trait == TraitId.lightfallBlade.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          damagePlayer(source, target, 40, DamageType.magical);
        }
        else if (type == 1) { 
          List<String> cardList = traitData['cardList'];
          for (String card in cardList) {
            List<String> tagList = cardTags[card]!;
            if (tagList.contains(TagId.sharp.id)) {
              addAttribute(source, AttributeType.attack, 5);
              damagePlayer(source, target, 20, DamageType.physical);
            }
          }
        }
      }
      // 焰心剑【山河剑意】
      else if (trait == TraitId.landsGraceSwordsSoul.id) { 
        List<String> cardList = traitData['cardList'];
        int cardOverlapped = 0;
        for (var tag in TagId.values) {
          cardOverlapped = 0;
          for (var card in cardList) {
            List<String> tagList = cardTags[card]!;
            if (tagList.contains(tag.id)) {
              cardOverlapped++;
            }            
          }
          if (cardOverlapped >= 3) {
            addStatus(source, source, StatusId.swordHeart.id, 5, 1);
            break;
          }
        }
      }
      // 曙光【不容质疑的信任】
      else if (trait == TraitId.unquestioningTrust.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          int point = traitData['point'];
          addStatus(source, source, StatusId.shelter.id, point, 1);
          addHiddenStatus(source, 'trust', 0, 1);
        }
        else if (type == 1) { 
          addHiddenStatus(target, 'support_def', 0, -1);
        }
        else if (type == 2) {
          String supportAttackSource = traitData['source'];
          addHiddenStatus(supportAttackSource, 'support_atk', 0, -1);
          addHiddenStatus(supportAttackSource, 'unquestion', 0, 0);
          addHiddenStatus(supportAttackSource, 'costminus', 1, 0);
          addAttribute(supportAttackSource, AttributeType.actiontime, 1);          
          // playCards(supportAttackSource, [target], point, [], []);
        }
        else {
          modifySkillCooldown(source, source, SkillId.unwaveringGuard.id,-1);
        }
      }
      // 奥赛罗【黑白棋】
      else if (trait == TraitId.reversi.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          if (targetChara.hasHiddenStatus('black_piece')) {
            addHiddenStatus(target, 'black_piece', 1, -1);
          } else {
            addHiddenStatus(target, 'white_piece', 1, -1);
          }
        }
        else if (type == 1) { 
          if (targetChara.hasHiddenStatus('black_piece') && targetChara.cardCount % 2 == 0) {
            addHiddenStatus(target, 'white_piece', targetChara.getHiddenStatusIntData('black_piece', StatusData.intensity), -1);
            removeHiddenStatus(target, 'black_piece');
          } else if (targetChara.hasHiddenStatus('white_piece') && targetChara.cardCount % 2 == 1) {
            addHiddenStatus(target, 'black_piece', targetChara.getHiddenStatusIntData('white_piece', StatusData.intensity), -1);
            removeHiddenStatus(target, 'white_piece');
          }
        }
        else if (type == 2) { 
          int pieceCount = 0;
          for (var chara in players.values) {
            if (chara.hasHiddenStatus('black_piece')) {
              pieceCount += chara.getHiddenStatusIntData('black_piece', StatusData.intensity);
            } else if (chara.hasHiddenStatus('white_piece')) {
              pieceCount += chara.getHiddenStatusIntData('white_piece', StatusData.intensity);
            }
          }
          for (var tar in targets) {
            damagePlayer(source, tar, 5 * pieceCount, DamageType.lost, isAOE: true);
            healPlayer(source, source, 5 * pieceCount, DamageType.heal);
          }
        }
        else {
          addHiddenStatus(source, 'black_piece', 2, -1);
        }
      }
      // 石蹄【蹦蹦咒语】
      else if (trait == TraitId.boingSpell.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          modifyStatusIntensity(source, target, StatusId.swift.id, 1);
          modifyStatusLayer(source, target, StatusId.swift.id, 1);
        }
        else if (type == 1) { 
          modifyStatusIntensity(source, target, StatusId.slowness.id, 1);
          modifyStatusLayer(source, target, StatusId.slowness.id, 1);          
        }
        else if (type == 2) { 
          List<int> layerRef = traitData['layerRef'];
          layerRef[0] *= 2;
        }
        else { 
          List<int> pointRef = traitData['pointRef'];
          pointRef[0] += (sourceChara.getStatusIntData(StatusId.swift.id, StatusData.layer) + 
          sourceChara.getStatusIntData(StatusId.swift.id, StatusData.intensity)) ~/ 4 * 2;
        }
      }
      // 埃诺雅【原初时计】
      else if (trait == TraitId.primordialHorologe.id) { 
        int point = traitData['point'];    
        String card = traitData['card'];
        int horologeSpace = sourceChara.getHiddenStatusIntData('horologe', StatusData.intensity);
        int emptyIndex = -1;
        for (int i = 0; i < 5; i++) {
          if (horologeSpace & (1 << i) == 0) {
            emptyIndex = i;
            break;
          }
        }
        addHiddenStatus(source, 'action_$emptyIndex', point, -1);
        sourceChara.setHiddenStatusData('action_$emptyIndex',strData: card);
        modifyHiddenStatusIntensity(source, 'horologe', 1 << emptyIndex);
      }
      // 向月【心灵魔术】
      else if (trait == TraitId.mentalSorcery.id) {
        if (targetChara.cardCount >= 2) {
          addHiddenStatus(target, 'sorcery', 0, 1);
        }
        else {
          damagePlayer(source, target, 150, DamageType.magical);
        }
      }
      // 司库【断、舍、离】
      else if (trait == TraitId.danshari.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addAttribute(source, AttributeType.armor, 30 * (sourceChara.cardCount + sourceChara.movePoint));
          addHiddenStatus(source, 'danshari', sourceChara.movePoint, 2);
          addAttribute(source, AttributeType.movepoint, -sourceChara.movePoint);
          modifyCardCount(source, source, sourceChara.cardCount, CardEventType.discard);
        }
        else {
          if (sourceChara.hasHiddenStatus('danshari')) {
            modifyCardCount(source, source, sourceChara.getHiddenStatusIntData('danshari', StatusData.intensity), CardEventType.draw);
            removeHiddenStatus(source, 'danshari');
          }
        }
      }
      // 司库【裁虚留要】
      else if (trait == TraitId.essenceOverIllusion.id) { 
        List<bool> skillAbleRef = traitData['skillAbleRef'];
        List<int> costRef = traitData['costRef'];
        int cooldown = traitData['cooldown'];
        skillAbleRef[0] = false;
        costRef[0] = 0;
        addAttribute(source, AttributeType.movepoint, cooldown ~/ 3);
      }
      // π123【二进制成对】
      else if (trait == TraitId.binaryDyad.id) { 
        List<int> points = traitData['points'];
        for (int i = 0; i < points.length; i++) {
          throwDice(source, target, points[i], 2, DiceType.trait);
          modifyHiddenStatusIntensity(source, 'dyad', points[i]);
        }
        modifyHiddenStatusIntensity(source, 'dyad', 2048 * (points.length + 1));
      }
      // 蓝文曦【盈亏相济】
      else if (trait == TraitId.lossGainEquilibrium.id) { 
        int type = traitData['type'];
        if (type == 0) { 
          addAttribute(source, AttributeType.defence, 5);
        } 
        else if (type == 1) { 
          addAttribute(source, AttributeType.attack, 5);
        } 
        else {
          modifyCardCount(source, source, 2, CardEventType.draw);
        }
      }

      // 特质结算
      // 阿波菲斯【毁灭暗影】
      if (isCharacterInGame(CharacterId.apophis.id) && sourceChara.hasStatus(StatusId.nightmare.id) 
        && sourceChara.getHiddenStatusIntData('night', StatusData.intensity) < 3) {
        Character chara = players[CharacterId.apophis.id]!;
        if (sourceChara.hasStatus(StatusId.eden.id)) {
          damagePlayer(chara.id, source, 20 + 40 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.magical);
          healPlayer(chara.id, chara.id, 10 + 20 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.heal);
        } else { 
          damagePlayer(chara.id, source, 10 + 20 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.magical);
          healPlayer(chara.id, chara.id, 5 + 10 * sourceChara.getStatusIntData(StatusId.nightmare.id, StatusData.intensity), DamageType.heal);
        }
        addHiddenStatus(source, 'night', 1, -1);
        addHiddenStatus(chara.id, 'night', 1, -1);
        castTrait(chara.id, [source], TraitId.ruinousShade.id, {'type': 1});
      }

      // 记录特质
      _recordProvider!.addTraitRecord(GameTurn(round: round, turn: turn, extra: extra), source, targets, 
      trait, traitData);
      _gameLogger!.addTraitLog(getGameTurn(), source, targets.toString(), trait, traitData.toString());
      refresh();
    }

    return traitAble;
  }

  void damagePlayer(String source, String target, int damage, DamageType type, {String tag = '', bool isAOE = false}){ 
    Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int damagePlus = 0;
    double damageMulti = 1;

    // 伤害转移
    // 余梦得【梦的守护】
    if (isCharacterInGame(CharacterId.yuMengde.id) && isTeammate(CharacterId.yuMengde.id, target) 
      && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      Character yuMengdeChara = players[CharacterId.yuMengde.id]!;
      castTrait(CharacterId.yuMengde.id, [CharacterId.yuMengde.id], TraitId.guardianOfDreams.id, {'type': 1});
      if (yuMengdeChara.hasHiddenStatus('dream_guard')) {
        target = CharacterId.yuMengde.id;
        targetChara = yuMengdeChara;
        removeHiddenStatus(CharacterId.yuMengde.id, 'dream_guard');
      }
    }
    // 曙光【不容置疑的信任】
    if (isCharacterInGame(CharacterId.daybreak.id) && isTeammate(CharacterId.daybreak.id, target) 
      && {DamageType.action}.contains(type)) {
      Character daybreakChara = players[CharacterId.daybreak.id]!;
      castTrait(CharacterId.daybreak.id, [target], TraitId.unquestioningTrust.id, {'type': 1});
      if (targetChara.hasHiddenStatus('support_def')) {
        target = CharacterId.daybreak.id;
        targetChara = daybreakChara;
      }
    }

    // 加伤相关道具
    if (targetChara.hasHiddenStatus('damageplus') && type == DamageType.action) {
      damagePlus += targetChara.getHiddenStatusIntData('damageplus', StatusData.intensity);
      removeHiddenStatus(target, 'damageplus');
      }
    // 道具【终焉长戟】
    if (targetChara.hasHiddenStatus('end') && type == DamageType.action) {
      for (int i = 0; i < targetChara.getHiddenStatusIntData('end', StatusData.intensity); i++) { 
        damageMulti *= 1.5;
      }
      removeHiddenStatus(target, 'end');
    }
    // 道具【融甲宝珠】
    if (targetChara.hasHiddenStatus('penetrate') && type == DamageType.action) {
      for (int i = 0; i < targetChara.getHiddenStatusIntData('penetrate', StatusData.intensity); i++) {
        damageMulti *= 1.5;
      }
      removeHiddenStatus(target, 'penetrate');
    }
    // 图西乌【凌日】
    if (target == CharacterId.tussiu.id && type == DamageType.action) {
      List<int> damagePlusRef = [damagePlus];
      List<double> damageMultiRef = [damageMulti];
      castTrait(target, [target], TraitId.transit.id, {'damagePlusRef': damagePlusRef, 'damageMultiRef': damageMultiRef});
      damagePlus = damagePlusRef[0];
      damageMulti = damageMultiRef[0];
    }

    // 状态【氤氲】
    if (targetChara.hasStatus(StatusId.nebula.id) && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damageMulti *= (1.0 + 0.5 * targetChara.getStatusIntData(StatusId.nebula.id, StatusData.intensity));
    }
    // 状态【灵曜】
    if (targetChara.hasStatus(StatusId.soulFlare.id) && {DamageType.action, DamageType.physical}.contains(type)) {
      damagePlus -= 80 * targetChara.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity);
      damagePlayer(target, source, 105 * targetChara.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity), DamageType.magical);
      removeStatus(target, target, StatusId.soulFlare.id);
    }
    // 状态【骑虎难下】
    /*if(targetChara.hasStatus(StatusId.tigrisDilemma.id) && {DamageType.action}.contains(type)){
      damageMulti *= 1.2;
    }*/
    // 状态【润化】
    if (targetChara.hasStatus(StatusId.moisturize.id) && type == DamageType.action) {
      damagePlus -= 50;
    }
    // 状态【撕裂】
    if (targetChara.hasStatus(StatusId.tear.id) && type == DamageType.action) {
      damagePlayer(source, target, 10 * targetChara.getStatusIntData(StatusId.tear.id, StatusData.intensity), DamageType.lost);
      modifyStatusLayer(target, target, StatusId.tear.id, -1);
    }
    // 状态【蓄力】
    if (sourceChara.hasStatus(StatusId.charge.id) && type == DamageType.action) {
      damagePlus += 10 * sourceChara.getStatusIntData(StatusId.charge.id, StatusData.intensity);
      modifyStatusLayer(source, source, StatusId.charge.id, -1);
    }
    // 状态【造梦】
    if (targetChara.hasStatus(StatusId.dreamCrafting.id) && type == DamageType.action) {
      damageMulti *= 0.75;
    }
    // 状态【剑心】
    if (sourceChara.hasStatus(StatusId.swordHeart.id) && type == DamageType.action) {
      damageMulti *= (1 + 0.2 * sourceChara.getStatusIntData(StatusId.swordHeart.id, StatusData.intensity));
    }
    // 状态【加护】
    if (targetChara.hasStatus(StatusId.shelter.id) && type == DamageType.action) {
      damageMulti *= (1 - 0.1 * targetChara.getStatusIntData(StatusId.shelter.id, StatusData.intensity));
      modifyStatusLayer(target, target, StatusId.shelter.id, -1);
    }

    // 技能【恐吓】
    if (targetChara.hasHiddenStatus('intimidation') && type == DamageType.action) {
      damageMulti *= 0.65;      
    }
    // 技能【分裂】
    if (sourceChara.hasHiddenStatus('fission') && type == DamageType.action) {
      damageMulti *= 0.8;
    }
    // 卿别【安魂乐章】
    if (sourceChara.hasStatus('requiem') && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damagePlus += 75;
    }
    // 斯威芬【造梦者】
    if (sourceChara.hasHiddenStatus('dream_weave') && type == DamageType.action) {
      damagePlayer(source, target, 50, DamageType.magical);
      addStatus(source, target, StatusId.dreaming.id, 0, 1);
      removeHiddenStatus(source, 'dream_weave');
    }
    // 科亚特尔【天启之庭】
    if (targetChara.hasHiddenStatus('apocalypse') && {DamageType.action, DamageType.physical}.contains(type)) {
      damageMulti *= 0.75;
      removeHiddenStatus(target, 'apocalypse');
    }
    
    // 岚【天魔体】
    if (sourceChara.hasTrait(TraitId.demonicAvatar.id)) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [source], TraitId.demonicAvatar.id, {'damageMultiRef': damageMultiRef, 'dmgType': type});
      damageMulti = damageMultiRef[0];
    }
    // 恋慕【勿忘我】
    if (sourceChara.hasTrait(TraitId.dontForgetMe.id)) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [source], TraitId.dontForgetMe.id, {'type': 0, 'damageMultiRef': damageMultiRef, 'dmgType': type});
      damageMulti = damageMultiRef[0];
    }    
    if (targetChara.hasTrait(TraitId.dontForgetMe.id)) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(target, [target], TraitId.dontForgetMe.id, {'type': 1, 'damageMultiRef': damageMultiRef, 'dmgType': type});
      damageMulti = damageMultiRef[0];
    }
    // 卿别【夜魇游吟】
    if (source == CharacterId.valedictus.id && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<double> damageMultiRef = [damageMulti];
      if (targetChara.hasStatus(StatusId.dreaming.id)) {
        castTrait(source, [source], TraitId.nightmareRefrain.id, {'type': 2, 'damageMultiRef': damageMultiRef});
      }
      damageMulti = damageMultiRef[0];
    }
    // 时雨【寒冰血脉】
    if (targetChara.hasTrait(TraitId.icyBlood.id) && {DamageType.action, DamageType.physical}.contains(type)) {
      List<int> damagePlusRef = [damagePlus];
      castTrait(target, [source], TraitId.icyBlood.id, {'type': 1, 'damagePlusRef': damagePlusRef});
      damagePlus = damagePlusRef[0];
    }
    // 舸灯【引渡】
    if (source == CharacterId.gentou.id && type == DamageType.action) {
      if (sourceChara.hasHiddenStatus('ferry')) {
        damagePlus += 45;
        removeHiddenStatus(source, 'ferry');
      }
    }
    // 沫【湮灭性轮回】
    if (source == CharacterId.froth.id && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [target], TraitId.annihilativeCycle.id, {'type': 0, 'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 斯威芬【梦的塑造】
    if (source == CharacterId.sweven.id && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      if (targetChara.hasStatus(StatusId.dreaming.id)) {
        castTrait(source, [source], TraitId.craftingOfDreams.id, {'type': 4, 'damageMultiRef': damageMultiRef});
      }
      damageMulti = damageMultiRef[0];
    }
    // 余梦得【梦的守护】
    if (targetChara.hasStatus(StatusId.dreamGuarding.id) && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damageMulti *= 0.8;
    }
    // 红黎【冰火相融】
    if (source == CharacterId.dimpsy.id && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [target], TraitId.iceFireFusion.id, {'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 方塔索【神游】
    if (target == CharacterId.phantos.id && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<int> damagePlusRef = [damagePlus];
      castTrait(target, [target], TraitId.astralProjection.id, {'type': 1, 'damagePlusRef': damagePlusRef});
      damagePlus = damagePlusRef[0];
    }
    // 陆风【追猎的乌托邦】
    if (source == CharacterId.luFeng.id && targetChara.hasStatus(StatusId.prey.id) && type == DamageType.action) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(source, [target], TraitId.utopiaOfCelerity.id, {'type': 1, 'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    if (sourceChara.hasHiddenStatus('prey')) {
      damageMulti *= 0.8;
      removeHiddenStatus(source, 'prey');
    }
    // 樊求【精准】
    for (var chara in players.values) {
      if (chara.hasTrait(TraitId.precision.id) && type == DamageType.action) {
        List<double> damageMultiRef = [damageMulti];
        castTrait(chara.id, [source], TraitId.precision.id, {'damageMultiRef': damageMultiRef});
        damageMulti = damageMultiRef[0];
      }
    }    
    // 安山定【后发的乌托邦】
    if (source == CharacterId.anShanding.id && type == DamageType.action && sourceChara.hasStatus(StatusId.poised.id)) {
      damageMulti *= 2;
    }
    if (target == CharacterId.anShanding.id && targetChara.hasHiddenStatus('upspring') 
    && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<double> damageMultiRef = [damageMulti];
      castTrait(target, [target], TraitId.utopiaOfUpspring.id, {'type': 1, 'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 洛尔【毫无章法的进攻】
    if (source == CharacterId.lor.id && sourceChara.hasHiddenStatus('unbalanced') && type == DamageType.action) {
      damageMulti *= 0.5;
    }
    
    // 伤害计算
    damage = ((damage + damagePlus) * damageMulti).toInt();
    
    // 无视伤害效果
    // 状态【闪避】
    if (targetChara.hasStatus(StatusId.dodge.id) && {DamageType.action, DamageType.physical}.contains(type)) {
      addHiddenStatus(source, 'void', 0, 1);
      removeStatus(target, target, StatusId.dodge.id);
    }
    // 状态【咕咕】
    if (targetChara.hasStatus(StatusId.gugu.id) && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      addHiddenStatus(source, 'void', 0, 1);
    }
    // 状态【梦境】
    if (targetChara.hasStatus(StatusId.dreaming.id)) {
      // 卿别【夜魇游吟】
      if (source == CharacterId.valedictus.id) {
        castTrait(source, [target], TraitId.nightmareRefrain.id, {'type': 1});
      }
      // 斯威芬【梦的塑造】
      if (source == CharacterId.sweven.id) {
        castTrait(source, [target], TraitId.craftingOfDreams.id, {'type': 3});
      }
      // 方塔索【神游】
      if (source == CharacterId.phantos.id) {
        castTrait(source, [target], TraitId.astralProjection.id, {'type': 2});
      }
      if (!sourceChara.hasHiddenStatus('nightmare') && {DamageType.action, DamageType.physical}.contains(type)) {
        addHiddenStatus(source, 'void', 0, 1);
      }
    }
    // 太夕【谜渊漩涡】
    if (target == CharacterId.nyxumbra.id && targetChara.hasHiddenStatus('abyss')){
      final int absorbedDamage = damage - 400;
      if (absorbedDamage > 0) {
        damage = 400;
        addHiddenStatus(target, 'dark', absorbedDamage ~/ 50, -1);
      }
    }
    // 奈普斯特【幽魂化】
    if (target == CharacterId.nepst.id && isAOE && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      List<int> damageRef = [damage];
      castTrait(target, [target], TraitId.spectralization.id, {'type': 0, 'damageRef': damageRef});
      damage = damageRef[0];      
    }
    // 方塔索【神游】
    if (target == CharacterId.phantos.id && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      castTrait(target, [target], TraitId.astralProjection.id, {'type': 0});
      if (targetChara.hasHiddenStatus('astral')) {        
        addHiddenStatus(source, 'void', 0, 1);
        removeHiddenStatus(target, 'astral');
      }
    }
    // 符楹【秩序结界】
    if (targetChara.hasStatus(StatusId.luminance.id)) {
      damage = 0;
    }
    // DeFen-5【<15>力场模拟】
    if (target == CharacterId.defen5.id) {
      addAttribute(target, AttributeType.defence, -damage ~/ 50);
      damage = 0;
    }
    
    // 不造成伤害
    /*if (sourceChara.hasHiddenStatus('rest') && type == DamageType.action) {
      damage = 0;
      removeHiddenStatus(source, 'rest');
    }*/
    if (sourceChara.hasHiddenStatus('void') && {DamageType.action, DamageType.physical, DamageType.magical}.contains(type)) {
      damage = 0;
      removeHiddenStatus(source, 'void');
    }
    if (damage < 0) {
      damage = 0;
    }
    // 伤害结算
    if (type == DamageType.action) {
      if (sourceChara.hasHiddenStatus('fission')) {
        Character fissionChara = players.values.firstWhere((e) => e.hasHiddenStatus('fission_target'));
        removeHiddenStatus(source, 'fission');
        removeHiddenStatus(fissionChara.id, 'fission_target');
        damagePlayer(source, fissionChara.id, damage, DamageType.physical, isAOE: true);
      }
      if (targetChara.hasStatus(StatusId.fractured.id)) {
        addAttribute(target, AttributeType.health, -damage);
      }
      else {
        if (targetChara.armor > 0) {
          if (damage > targetChara.armor) {
            if (targetChara.hasHiddenStatus('barrier')) {
              addAttribute(target, AttributeType.armor, -targetChara.armor);
              removeHiddenStatus(target, 'barrier');
            }
            else {
              addAttribute(target, AttributeType.health, -damage + targetChara.armor);
              addAttribute(target, AttributeType.armor, -targetChara.armor);
            }
          }
          else {
            addAttribute(target, AttributeType.armor, -damage);
          }
        }
        else {
          addAttribute(target, AttributeType.health, -damage);
        }
      }
    }
    else if (type == DamageType.physical) {
      if (targetChara.hasStatus(StatusId.fractured.id)) {
        addAttribute(target, AttributeType.health, -damage);
      }
      else {
        if (targetChara.armor > 0) {
          if (damage > targetChara.armor) {
            if (targetChara.hasHiddenStatus('barrier')) {
              addAttribute(target, AttributeType.armor, -targetChara.armor);
              removeHiddenStatus(target, 'barrier');
            }
            else {
              addAttribute(target, AttributeType.health, -damage + targetChara.armor);
              addAttribute(target, AttributeType.armor, -targetChara.armor);
            }
          }
          else {
            addAttribute(target, AttributeType.armor, -damage);
          }
        }
        else {
          addAttribute(target, AttributeType.health, -damage);
        }
      }
    }
    else if (type == DamageType.magical) {
      addAttribute(target, AttributeType.health, -damage);
    }
    else if (type == DamageType.lost) {
      addAttribute(target, AttributeType.health, -damage);
    }
    
    // 道具【猎魔灵刃】
    if (targetChara.hasHiddenStatus('track') && type == DamageType.action) {
      damagePlayer(source, target, damage ~/ 2 * targetChara.getHiddenStatusIntData('track', StatusData.intensity), DamageType.magical);
      removeHiddenStatus(target, 'track');
    }
    // 技能【镜像】
    if (targetChara.hasHiddenStatus('mirror')) {
      if (targetChara.damageReceivedTotal - targetChara.getHiddenStatusIntData('mirror', StatusData.intensity) > 300) {
        removeStatus(target, target, StatusId.mirror.id);
        removeHiddenStatus(target, 'mirror');
      }
    }
    // 沫【湮灭性轮回】
    if (source == CharacterId.froth.id && type == DamageType.action) {
      castTrait(source, [target], TraitId.annihilativeCycle.id, {'type': 1, 'damage': damage});
    }
    // 长霾【我还能喝】
    if (target == CharacterId.sumoggu.id) {
      castTrait(target, [source], TraitId.imDrunk.id, {'type': 1, 'damage': damage});
    }
    // 祝烨明【八裂】
    if (source == CharacterId.zhuYeming.id) {
      castTrait(source, [target], TraitId.cryoFissuring.id, {'type': 0, 'damage': damage});
    }
    // 颜若卿【调和的乌托邦】
    if (target == CharacterId.yanRuoqing.id) {
      castTrait(target, [target], TraitId.utopiaOfConcord.id, {'type': 2, 'damage': damage});
    }
    // EnGine-4【<04>质能转换】
    if (source == CharacterId.engine4.id) {
      castTrait(source, [target], TraitId.massEnergyConversion.id, {'type': 0, 'damage': damage});
    }
    // 曙光【不容质疑的信任】
    if (targetChara.hasTrait(TraitId.unquestioningTrust.id)) {
      castTrait(target, [target], TraitId.unquestioningTrust.id, {'type': 3, 'damage': damage, 'dmgType': type});
    }

    // 伤害统计
    if (damage > 0) {
      addAttribute(source, AttributeType.dmgdealt, damage);
      addAttribute(target, AttributeType.dmgreceived, damage);
      _recordProvider!.addDamageRecord(GameTurn(round: round, turn: turn, extra: extra), 
        source, target, damage, type, tag);
      _gameLogger!.addDamageLog(getGameTurn(), source, target, damage, type, 
        'damagePlus: $damagePlus, damageMulti: $damageMulti');
    }
    refresh();
  }

  void healPlayer(String source, String target, int heal, DamageType type, {String tag = '', bool isAOE = false}) {
    // Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int healPlus = 0;
    double healMulti = 1;
    bool healAble = true;

    if (targetChara.hasStatus(StatusId.dissociated.id)) {
      healMulti *= (1 - 0.1 * targetChara.getStatusIntData(StatusId.dissociated.id, StatusData.intensity));
    }

    heal = ((heal + healPlus) * healMulti).toInt();

    if (type == DamageType.heal){
      // 龙宇澈【燃魂】
      if (target == CharacterId.longYuche.id && targetChara.hasHiddenStatus('soul_burning')) {                
        healAble = false;        
      }
      // 雷刚【决意的乌托邦】
      if (target == CharacterId.leiGang.id) {
        healAble = false;
      }
      if (healAble) {
        if (targetChara.hasStatus(StatusId.wounded.id)) {
          modifyStatusLayer(target, target, StatusId.wounded.id, -1);
        }
        addAttribute(target, AttributeType.health, heal);

        // 守塔人【潮海明灯】
        if (isCharacterInGame(CharacterId.towerGuardian.id)) {          
          if (isTeammate(target, CharacterId.towerGuardian.id) || target == CharacterId.towerGuardian.id) {
            castTrait(CharacterId.towerGuardian.id, [target], TraitId.tideBeacon.id);
          }
        }
      }
    }
    else if (type == DamageType.revive) {
      targetChara.health += heal;
    }

    // 治疗统计
    if (heal > 0 && healAble) {
      addAttribute(source, AttributeType.curdealt, heal);
      addAttribute(target, AttributeType.curreceived, heal);
      _recordProvider!.addHealRecord(GameTurn(round: round, turn: turn, extra: extra), 
        source, target, heal, type, tag);
      _gameLogger!.addHealLog(getGameTurn(), source, target, heal);
    }
    refresh();
  }

  // 结束轮次
  void endTurn(){
    // 设置游戏状态为进行中
    if (gameState == GameState.waiting) {
      gameState = GameState.start;
    }
    // 获取当前角色
    String currentCharaId;
    if (turn == 0) {
      currentCharaId = gameSequence[0];
    }
    else {
      currentCharaId = gameSequence[turn - 1];
    }
    Character currentChara = players[currentCharaId]!;

    if (turn != 0) {
    // 全局状态结算
    if (turn == playerCount && !currentChara.hasHiddenStatus('extra')) {
      // 达摩克利斯之剑
      for (; countdown.reinforcedDamocles > 0; countdown.reinforcedDamocles--) {
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){ 
          if(target.health > maxHp && target.id != 'empty' && !target.isDead) {
            maxHp = target.health;
            maxHpChara = target;
          }
        }
        damagePlayer('empty', maxHpChara.id, 300, DamageType.magical);
      }
      for (; countdown.damocles > 0; countdown.damocles--) {
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){
          if(target.health > maxHp && target.id != 'empty' && !target.isDead){
            maxHp = target.health;
            maxHpChara = target;
          }
        }
        damagePlayer('empty', maxHpChara.id, 150, DamageType.magical);
      }
    }

    // 状态结算
    // 霜冻
    if (currentChara.hasStatus(StatusId.frost.id)) {
      damagePlayer('empty', currentCharaId, 6 * currentChara.getStatusIntData(StatusId.frost.id, StatusData.intensity), 
        DamageType.magical, tag: 'frost');
      // 白谢【极寒环域】
      if (isCharacterInGame(CharacterId.baiXie.id)) {
        castTrait(CharacterId.baiXie.id, [currentCharaId], TraitId.glacialCircle.id, {'type': 1});
      }
      // ReFre-3【<0C>热能回收】
      if (isCharacterInGame(CharacterId.refre3.id)) {
        castTrait(CharacterId.refre3.id, [currentCharaId], TraitId.thermalRecovery.id);
      }
    }
    // 灼炎
    if (currentChara.hasStatus(StatusId.flaming.id)) {
      damagePlayer('empty', currentCharaId, 10 * currentChara.getStatusIntData(StatusId.flaming.id, StatusData.intensity), 
        DamageType.magical, tag: 'flaming');
    }
    // 狱焱
    if (currentChara.hasStatus(StatusId.infernoFire.id)) {
      damagePlayer('empty', currentCharaId, 15 * currentChara.getStatusIntData(StatusId.infernoFire.id, StatusData.intensity), 
        DamageType.magical, tag: 'inferno_fire');
    }
    // 脱水
    if (currentChara.hasStatus(StatusId.dehydration.id)) {
      damagePlayer('empty', currentCharaId, 30 * currentChara.getStatusIntData(StatusId.dehydration.id, StatusData.intensity), 
        DamageType.magical, tag: 'dehydration');
    }
    // 再生
    if (currentChara.hasStatus(StatusId.regeneration.id)) {
      healPlayer(currentCharaId, currentCharaId, 20 * currentChara.getStatusIntData(StatusId.regeneration.id, StatusData.intensity), 
        DamageType.heal);
    }

    // 特质结算    
    for (var chara in players.values) {
      // 茵竹【自勉】
      if (chara.hasTrait(TraitId.selfEncouragement.id)) {
        castTrait(chara.id, [chara.id], TraitId.selfEncouragement.id, {'type': 0});
      }      
    }
    // 龙宇澈【光耀】
    if (isCharacterInGame(CharacterId.longYuche.id)) {      
      castTrait(CharacterId.longYuche.id, [CharacterId.longYuche.id], TraitId.radiance.id, {'type': 1});
    }
    // 雷刚【决意的乌托邦】
    if (isCharacterInGame(CharacterId.leiGang.id)) {      
      castTrait(CharacterId.leiGang.id, [CharacterId.leiGang.id], TraitId.utopiaOfResolve.id, {'type': 0});
    }
    // 翠灵【生息】
    if (isCharacterInGame(CharacterId.turbach.id) && turn == gameSequence.length && countdown.extraTurn == 0) {      
      castTrait(CharacterId.turbach.id, [CharacterId.turbach.id], TraitId.lifeBreath.id, {'type': 0});
    }
    // 湍云【屏息】【惊弓】
    if (isCharacterInGame(CharacterId.zephyr.id) && turn == gameSequence.length && countdown.extraTurn == 0) {      
      castTrait(CharacterId.zephyr.id, [CharacterId.zephyr.id], TraitId.holdBreath.id, {'type': 0});
      castTrait(CharacterId.zephyr.id, [CharacterId.zephyr.id], TraitId.holdBreath.id, {'type': 2});
      castTrait(CharacterId.zephyr.id, [CharacterId.zephyr.id], TraitId.gunShy.id, {'type': 0});
    }
    // EnGine-4【<04>质能转换】
    if (isCharacterInGame(CharacterId.engine4.id) && turn == gameSequence.length && countdown.extraTurn == 0) {
      castTrait(CharacterId.engine4.id, [CharacterId.engine4.id], TraitId.massEnergyConversion.id, {'type': 1});
    }
    // 奥赛罗【黑白棋】
    if (isCharacterInGame(CharacterId.othello.id)) {      
      castTrait(CharacterId.othello.id, [currentCharaId], TraitId.reversi.id, {'type': 1});
    }

    // 安德宁【回旋曲】
    if (currentChara.hasTrait(TraitId.rondo.id)) {
      castTrait(currentCharaId, [currentCharaId], TraitId.rondo.id);
    }
    // 沫 行动点
    else if (currentCharaId == CharacterId.froth.id) {
      if (currentChara.damageDealtTurn >= 300) {
        addAttribute(currentCharaId, AttributeType.movepoint, -currentChara.damageDealtTurn ~/ 300);
      }
    }
    // 卿别 行动点
    else if (currentCharaId == CharacterId.valedictus.id) {
      for (var chara in players.values) {
        if (chara.hasStatus(StatusId.dreaming.id)) {
          addAttribute(currentCharaId, AttributeType.movepoint, 1);
        }
      }
    }
    // 埃诺雅 行动点
    else if (isCharacterInGame(CharacterId.ennoia.id)) {
      final Character ennoiaChara = players[CharacterId.ennoia.id]!;
      modifyHiddenStatusIntensity(CharacterId.ennoia.id, 'ennoia', 1);      
      if (ennoiaChara.getHiddenStatusIntData('ennoia', StatusData.intensity) % 2 == 0 &&
      ennoiaChara.getHiddenStatusIntData('ennoia', StatusData.intensity) ~/ 1024 < 3) {
        addAttribute(CharacterId.ennoia.id, AttributeType.movepoint, 1);
        modifyHiddenStatusIntensity(CharacterId.ennoia.id, 'ennoia', 1024);
      }
      if (turn == gameSequence.length && !currentChara.hasHiddenStatus('extra')) {
        modifyHiddenStatusIntensity(CharacterId.ennoia.id, 'ennoia', -(ennoiaChara.getHiddenStatusIntData('ennoia', StatusData.intensity) ~/ 1024) * 1024);
      }
    }
    // 余梦得【梦的守护】
    else if (currentCharaId == CharacterId.yuMengde.id) {
      castTrait(currentCharaId, [currentCharaId], TraitId.guardianOfDreams.id, {'type': 0});
      castTrait(currentCharaId, [currentCharaId], TraitId.guardianOfDreams.id, {'type': 2});
    }
    // 太夕 行动点
    else if (currentCharaId == CharacterId.nyxumbra.id) {
      if (currentChara.cureReceivedTurn >= 100) {
        addAttribute(currentCharaId, AttributeType.movepoint, 1);
      }
    }
    // 科亚特尔【拟造“伊甸园”】
    else if (currentCharaId == CharacterId.quetzalcoatl.id) {
      castTrait(currentCharaId, [currentCharaId], TraitId.artificialEden.id);
    }
    // 安山定【后发的乌托邦】
    else if (currentCharaId == CharacterId.anShanding.id) {
      castTrait(currentCharaId, [currentCharaId], TraitId.utopiaOfUpspring.id, {'type': 0});
    }
    // 奥赛罗【黑白棋】
    else if (currentCharaId == CharacterId.othello.id) {
      List<String> reversiTargets = [];
      if (currentChara.hasHiddenStatus('black_piece')) {
        reversiTargets = players.values.where((e) => e.hasHiddenStatus('white_piece') && isEnemy(currentCharaId, e.id) 
          && !e.isDead && e.id != 'empty').map((e) => e.id).toList();
      }
      else {
        reversiTargets = players.values.where((e) => e.hasHiddenStatus('black_piece') && isEnemy(currentCharaId, e.id) 
          && !e.isDead && e.id != 'empty').map((e) => e.id).toList();
      }
      castTrait(currentCharaId, reversiTargets, TraitId.reversi.id, {'type': 2});
    }
    // 司库【断、舍、离】
    if (currentChara.hasTrait(TraitId.danshari.id)) {
      castTrait(currentCharaId, [currentCharaId], TraitId.danshari.id, {'type': 0});
    }
    // 蓝文曦【盈亏相济】
    if (currentChara.hasTrait(TraitId.lossGainEquilibrium.id)) {
      final int cardCount = currentChara.cardCount;
      castTrait(currentCharaId, [currentCharaId], TraitId.lossGainEquilibrium.id, {'type': 2, 'count': cardCount});      
    }
    // 阿波菲斯【毁灭暗影】
    if (currentChara.hasHiddenStatus('night')) {
      modifyHiddenStatusIntensity(currentCharaId, 'night', -currentChara.getHiddenStatusIntData('night', StatusData.intensity));
    }    

    // 弃牌
    if (currentChara.cardCount > currentChara.maxCard) {
      modifyCardCount(currentCharaId, currentCharaId, currentChara.cardCount - currentChara.maxCard, CardEventType.discard);
    }

    // 状态层数削减
    if (countdown.extraTurn == 0) {
    for (var chara in players.values){
      List<String> statusKeys = chara.status.keys.toList();
      for (String status in statusKeys){        
        if (statusToType[status]!.decayOverTurn) {
          chara.increaseStatusData(status, layerFraction: -1);
        }
        if (chara.getStatusIntData(status, StatusData.layerFraction) <= 0) {
          modifyStatusLayer(chara.id, chara.id, status, -1);
          chara.setStatusData(status, layerFraction: playerCount);
        }
        if (chara.getStatusIntData(status, StatusData.layer) == 0) {
          removeStatus(chara.id, chara.id, status);
        }
      }
      List<String> hiddenStatusKeys = chara.hiddenStatus.keys.toList();
      for (String status in hiddenStatusKeys){
        if (!['barrier'].contains(status)) {
          chara.increaseHiddenStatusData(status, layerFraction: -1);
        }      
        if (chara.getHiddenStatusIntData(status, StatusData.layerFraction) <= 0) {
          modifyHiddenStatusLayer(chara.id, status, -1);
          chara.setHiddenStatusData(status, layerFraction: playerCount);
        }
        if (chara.getHiddenStatusIntData(status, StatusData.layer) == 0) {
          removeHiddenStatus(chara.id, status);
        }
      }
    }
    }

    // 技能CD减少
    if (countdown.extraTurn == 0) {
      for (String skill in currentChara.skill.keys){
        modifySkillCooldown(currentCharaId, currentCharaId, skill, -1);
      }
    }

    // 玩家死亡
    for (var chara in players.values) {
      // 恋慕【勿忘我】
      if (chara.hasTrait(TraitId.dontForgetMe.id)) {
        castTrait(chara.id, [chara.id], TraitId.dontForgetMe.id, {'type': 2});
      }
      // 赐弥【在云端】
      if (chara.id == CharacterId.cimme.id && chara.health <= 0) {
        castTrait(chara.id, [chara.id], TraitId.uponTheClouds.id);
      }
      if (chara.health <= 0 && !chara.isDead && !chara.hasTrait(TraitId.resolution.id) 
      && !chara.hasTrait(TraitId.forceFieldSimulation.id)) {
        chara.isDead = true;
        playerDiedCount++;
      }
      // 黯星【决心】
      if (chara.hasTrait(TraitId.resolution.id) && chara.hasHiddenStatus('res_failed')) {
        chara.isDead = true;
        playerDiedCount++;
      }
      // DeFen-5【<15>力场模拟】
      if (chara.id == CharacterId.defen5.id && chara.defence <= 0) {        
        chara.isDead = true;
        playerDiedCount++;        
      }
    }
    // 好好先生【深重情谊】
    if (playerCount - playerDiedCount <= 2) {
      for (var chara in players.values) {
        if (chara.hasHiddenStatus('favor')) {
          removeHiddenStatus(chara.id, 'favor');
        }
      }
    }
    bool teamGameOver = false;
    if (gameType == GameType.team) {
      teamGameOver = true;
      for (var chara1 in players.values) {
        for (var chara2 in players.values) {
          if (isEnemy(chara1.id, chara2.id) && !chara2.isDead && !chara1.isDead) {
            teamGameOver = false;
            break;
          }
        }
      }
    }
    if (gameType == GameType.single && playerDiedCount == playerCount - 1 || teamGameOver || playerDiedCount == playerCount) {
      gameState = GameState.over;
      for (var chara in players.values) {
        if (!(chara.id == 'empty')) {
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'DamageDealt', chara.damageDealtTotal);
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'DamageReceived', chara.damageReceivedTotal);          
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'CureDealt', chara.cureDealtTotal);
          _gameLogger!.addStatisticsLog(getGameTurn(), chara.id, 'CureReceived', chara.cureReceivedTotal);
        }
      }
    }
    }

    // 额外回合
    if (countdown.extraTurn == 1) {
      countdown.extraTurn = 0;
    }
    if (!currentChara.hasHiddenStatus('extra')) {
      turn++;
      extra = 0;
    }
    else {
      removeHiddenStatus(currentCharaId, 'extra');
      extra++;
      countdown.extraTurn = 1;
    }
    // 轮次变更
    if(turn > playerCount){
      turn = 1;
      round++;
    }
    gameTurnList.add(getGameTurn());
    // 技能【反重力】
    if (turn == 1) {
      for (; countdown.antiGravity > 0; countdown.antiGravity--) {
        gameSequence = gameSequence.reversed.toList();
      }
    }
    currentCharaId = gameSequence[turn - 1];
    currentChara = players[currentCharaId]!;

    // 伤害统计重置
    for (var chara in players.values) {
      chara.damageDealtTurn = 0;
      chara.damageReceivedTurn = 0;
      chara.cureDealtRound = 0;
      chara.cureReceivedRound = 0;
      if (turn == 1 && countdown.extraTurn == 0) {
        chara.damageDealtRound = 0;
        chara.damageReceivedRound = 0;
        chara.cureDealtRound = 0;
        chara.cureReceivedRound = 0;
      }
    }

    // 行动次数恢复
    bool actionAble = true;
    if (actionAble) {
      currentChara.actionTime = 1;
    }

    // 特质使用次数恢复
    bool traitRecoverAble = false;
    if (turn == 1) {
      traitRecoverAble = true;
    }
    if (traitRecoverAble) {
      for (var chara in players.values) {
        for (var tr in chara.trait.keys) {
          if (chara.trait[tr]!.maxCast > 0) {
            modifyTraitCastCount(chara.id, chara.id, tr, -chara.trait[tr]!.castCount);
          }
        }
      }
    }

    // 特质结算  
    for (var chara in players.values) {
      // 恋慕【勿忘我】
      if (chara.hasTrait(TraitId.dontForgetMe.id)) {
        if (!chara.isDead && chara.hasHiddenStatus('forget_me') && round >= 2) {
          removeHiddenStatus(chara.id, 'forget_me');
          chara.isDead = true;
          playerDiedCount++;
        }
      }      
    }
    // 奈普斯特【小惊吓】
    if (isCharacterInGame(CharacterId.nepst.id)) {      
      final Character nepstChara = players[CharacterId.nepst.id]!;
      if (!nepstChara.isDead && turn == 1 && extra == 0 && round > 1) {
        castTrait(CharacterId.nepst.id, [CharacterId.nepst.id], TraitId.littleSpook.id);
      }
    }
    // 太夕【黯灭】
    if (isCharacterInGame(CharacterId.nyxumbra.id)) {      
      if (round == 1 && turn == 1) {
        addHiddenStatus(CharacterId.nyxumbra.id, 'dark', 0, -1);
      }
    }
    // 科亚特尔【善恶天平】
    if (isCharacterInGame(CharacterId.quetzalcoatl.id)) {      
      final Character quetzalcoatlChara = players[CharacterId.quetzalcoatl.id]!;
      castTrait(CharacterId.quetzalcoatl.id, [CharacterId.quetzalcoatl.id], TraitId.balanceOfLightAndShadow.id);
      if (quetzalcoatlChara.hasHiddenStatus('balance_change') && !quetzalcoatlChara.hasHiddenStatus('balance')) {
        addHiddenStatus(CharacterId.quetzalcoatl.id, 'balance', 0, -1);
        removeHiddenStatus(CharacterId.quetzalcoatl.id, 'balance_change');
        addAttribute(CharacterId.quetzalcoatl.id, AttributeType.attack, 15);
      }
      else if (quetzalcoatlChara.hasHiddenStatus('balance') && !quetzalcoatlChara.hasHiddenStatus('balance_change')) {
        removeHiddenStatus(CharacterId.quetzalcoatl.id, 'balance');
        addAttribute(CharacterId.quetzalcoatl.id, AttributeType.attack, -15);
      }
    }
    // 翠灵【生息】
    if (isCharacterInGame(CharacterId.turbach.id)) {      
      final targets = [...players.keys.where((tar) => !players[tar]!.isDead && tar != CharacterId.turbach.id)];
      castTrait(CharacterId.turbach.id, targets, TraitId.lifeBreath.id, {'type': 1});
    }
    // 湍云【屏息】【惊弓】
    if (isCharacterInGame(CharacterId.zephyr.id)) {      
      castTrait(CharacterId.zephyr.id, [CharacterId.zephyr.id], TraitId.holdBreath.id, {'type': 1});
      castTrait(CharacterId.zephyr.id, [CharacterId.zephyr.id], TraitId.holdBreath.id, {'type': 3});
      castTrait(CharacterId.zephyr.id, [CharacterId.zephyr.id], TraitId.gunShy.id, {'type': 1});
    }
    // 洛尔【不断燃烧的愤怒】
    if (isCharacterInGame(CharacterId.lor.id)) {            
      if (round == 1 && turn == 1) {
        castTrait(CharacterId.lor.id, [CharacterId.lor.id], TraitId.smolderingRage.id, {'type': 1});
      }
    }
    // 符楹【光暗双生】
    if (isCharacterInGame(CharacterId.fuYing.id)) {      
      if (round == 1 && turn == 1) {
        addHiddenStatus(CharacterId.fuYing.id, 'gemini', 0, -1);
      }      
    }
    // 观风【气象万千】
    if (isCharacterInGame(CharacterId.viento.id)) {      
      if (round == 1 && turn == 1) {
        addHiddenStatus(CharacterId.viento.id, 'wind', 0, -1);
        addHiddenStatus(CharacterId.viento.id, 'cloud', 1, -1);
      }
    }
    // 奥赛罗【黑白棋】
    if (isCharacterInGame(CharacterId.othello.id)) {      
      if (round == 1 && turn == 1) {
        addHiddenStatus(CharacterId.othello.id, 'black_piece', 0, -1);
        castTrait(CharacterId.othello.id, [CharacterId.othello.id], TraitId.reversi.id, {'type': 3});
      }      
    }

    for (var chara in players.values) {
      // 沫【湮灭性轮回】
      if (isCharacterInGame(CharacterId.froth.id) && chara.hasHiddenStatus('cycle') && turn == playerCount) {
        addAttribute(chara.id, AttributeType.armor, chara.getHiddenStatusIntData('cycle', StatusData.intensity));
        removeHiddenStatus(chara.id, 'cycle');
      }
    }
    // K97【二进制噪声】
    if (currentChara.hasTrait(TraitId.binary.id)) {
      castTrait(currentCharaId, [currentCharaId], TraitId.binary.id, {'type': 0});
    }
    // 奈普斯特【幽魂化】
    else if (currentCharaId == CharacterId.nepst.id) {
      castTrait(currentCharaId, [currentCharaId], TraitId.spectralization.id, {'type': 1});
    }
    // 赐弥【在云端】
    else if (currentCharaId == CharacterId.cimme.id) {
      if (currentChara.hasHiddenStatus('cloud')) {
        removeHiddenStatus(currentCharaId, 'cloud');
      }
    }
    // 长霾【我还能喝】
    else if (currentCharaId == CharacterId.sumoggu.id) {
      castTrait(currentCharaId, [currentCharaId], TraitId.imDrunk.id, {'type': 0});
    }
    // 樊求【游侠】
    else if (currentChara.hasTrait(TraitId.ranger.id)) {
      castTrait(currentCharaId, [currentCharaId], TraitId.ranger.id, {'type': 0});
      castTrait(currentCharaId, [currentCharaId], TraitId.ranger.id, {'type': 1});
    }
    // 洛尔【不断燃烧的愤怒】
    else if (currentCharaId == CharacterId.lor.id) {
      castTrait(currentCharaId, [currentCharaId], TraitId.smolderingRage.id, {'type': 0});
    }

    // 抽牌
    bool drawAble = true;
    // 状态【冰封】【咕咕】【星牢】【梦境】【束缚】【窒息】
    if (currentChara.hasStatus(StatusId.frozen.id) || currentChara.hasStatus(StatusId.gugu.id) 
        || currentChara.hasStatus(StatusId.stellarCage.id) || currentChara.hasStatus(StatusId.dreaming.id) 
        || currentChara.hasStatus(StatusId.constraint.id) || currentChara.hasStatus(StatusId.asphyxia.id)) {
      drawAble = false;
    }
    if (currentChara.isDead) {
      drawAble = false;
    }
    if (drawAble) {      
      modifyCardCount(currentCharaId, currentCharaId, 2, CardEventType.draw);
      // 技能【天国邮递员】
      if (currentChara.hasHiddenStatus('heaven')) {
        modifyCardCount(currentCharaId, currentCharaId, 2, CardEventType.draw);
        removeHiddenStatus(currentCharaId, 'heaven');
      }
      // 司库【断、舍、离】
      if (currentChara.hasTrait(TraitId.danshari.id)) {
        castTrait(currentCharaId, [currentCharaId], TraitId.danshari.id, {'type': 1});
      }
    }    

    // 行动点回复
    bool recoverAble = true;
    if (currentChara.hasStatus(StatusId.stellarCage.id) || currentChara.hasStatus(StatusId.dreaming.id)) {
      currentChara.jumpedTurn++;
      recoverAble = false;
    }
    if (currentChara.isDead) {
      recoverAble = false;
    }
    if (recoverAble) {
      int moveRegen = 0;
      if (currentChara.regenType == 0) {
        moveRegen = currentChara.moveRegen;
      }
      else if (currentChara.regenType == 2) {
        moveRegen = currentChara.maxMove;
      }
      else if (currentChara.regenType == 3) {
        moveRegen = (currentChara.cardCount / 2).ceil();
      }
      else if (currentChara.regenType == 4) {
      if (round == 1) {moveRegen = currentChara.maxMove;}
      else {moveRegen = currentChara.moveRegen;}
      }
      // 状态【迅捷】
      if (currentChara.hasStatus(StatusId.swift.id)) {
        moveRegen += currentChara.getStatusIntData(StatusId.swift.id, StatusData.intensity);
      }
      // 状态【迟缓】
      if (currentChara.hasStatus(StatusId.slowness.id)) {
        moveRegen -= currentChara.getStatusIntData(StatusId.slowness.id, StatusData.intensity);
      }
      // 状态【浸没】
      if (currentChara.hasStatus(StatusId.submerged.id)) {
        moveRegen -= currentChara.getStatusIntData(StatusId.submerged.id, StatusData.intensity);
      }
      if (moveRegen < 0) {
        moveRegen = 0;
      }
      if (currentChara.maxMove - currentChara.movePoint < moveRegen) {
        moveRegen = currentChara.maxMove - currentChara.movePoint;
      }
      if (([0, 3, 4].contains(currentChara.regenType)) && (round - 1 - currentChara.jumpedTurn) % currentChara.regenTurn == 0) {
        addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
      }
      if (currentChara.movePoint == 0 && currentChara.regenType == 2) {
        addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
      }
    }

    refresh();
  }  

  void refresh(){
    notifyListeners();
  }
}

class GameManager{
  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();
  
  Game game = Game('game1', GameType.single);
}
