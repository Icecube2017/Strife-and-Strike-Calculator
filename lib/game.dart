import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sns_calculator/history.dart';
import 'dart:convert';
import 'assets.dart';
import 'core.dart';
import 'record.dart';

// 攻击特效
enum AttackEffect{ 
  lumenFlare('烛焱'),
  oculusVeil('障目');

  final String effectId;

  const AttackEffect(this.effectId);
}

// 防守特效
enum DefenceEffect{ 
  erodeGelid('蚀凛');

  final String effectId;

  const DefenceEffect(this.effectId);
}

// 全局状态效果
class GlobalCountdown{
  // 达摩克利斯之剑
  int damocles = 0;
  int reinforcedDamocles = 0;
  // 伊甸园
  int eden = 0;
  int reinforcedEden = 0;
  // 额外回合
  int extraTurn = 0;
  // 反重力
  int antiGravity = 0;
}

class Character{
  String id;
  int maxHealth, attack, defence, maxMove, moveRegen, regenType, regenTurn;
  int health = 0, armor = 0, movePoint = 0, cardCount = 2, actionTime = 0;
  int damageReceivedTotal = 0, damageDealtTotal = 0, damageDealtRound = 0, damageReceivedRound = 0,
  damageReceivedTurn = 0, damageDealtTurn = 0;
  bool isDead = false;
  Map<String, List<dynamic>> status = {}, hiddenStatus = {};
  Map<String, int> skill = {}, skillStatus = {};

  Character(this.id, this.maxHealth, this.attack, this.defence, this.movePoint, 
  this.maxMove, this.moveRegen, this.regenType, this.regenTurn){
    health = maxHealth;
  }

  bool hasStatus(String stat){
    return status.keys.contains(stat);
  }

  int getStatusIntensity(String stat){
    try{
      var statusData = status[stat];
      if (statusData != null && statusData.isNotEmpty) {
        return (statusData[0] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getStatusLayer(String stat){
    try{
      var statusData = status[stat];
      if (statusData != null && statusData.length > 1) {
        return (statusData[1] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getStatusIntData(String stat){
    try{
      var statusData = status[stat];
      if (statusData != null && statusData.length > 3) {
        return (statusData[3] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }
  
  int getHiddenStatusIntensity(String stat){ 
    try{
      var statusData = hiddenStatus[stat];
      if (statusData != null && statusData.isNotEmpty) {
        return (statusData[0] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getHiddenStatusLayer(String stat){ 
    try{
      var statusData = hiddenStatus[stat];
      if (statusData != null && statusData.length > 1) {
        return (statusData[1] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  int getHiddenStatusIntData(String stat){ 
    try{
      var statusData = hiddenStatus[stat];
      if (statusData != null && statusData.length > 3) {
        return (statusData[3] as num).toInt();
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  bool hasHiddenStatus(String stat){ 
    return hiddenStatus.keys.contains(stat);
  }
}

final Character emptyCharacter = Character('empty', 131072, 0, 0, 0, 0, 0, 0, 0);

class Game extends ChangeNotifier{
  String id;
  GameType gameType;
  List<String> gameSequence = [];
  Map<String, Character> players = {};
  var playerDied = {}, teams = {};
  int playerCount = 0, playerDiedCount = 0, turn = 0, round = 1, teamCount = 0, extra = 0;
  List<GameTurn> gameTurnList = [];
  GlobalCountdown countdown = GlobalCountdown();
  bool isGameOver = false;
  final Logger _logger = Logger(printer: PrettyPrinter(), output: MultiOutput([ConsoleOutput()]));

  final AssetsManager assets = AssetsManager();
  Map<String, dynamic>? langMap;
  Map<String, dynamic>? statusData;

  RecordProvider? _recordProvider;
  HistoryProvider? _historyProvider;

  Game(this.id, this.gameType){
    players['empty'] = emptyCharacter;
    _initializeAssets();
  }

  Future<void> _initializeAssets() async {
    await assets.loadData();
    langMap = assets.langMap;
    statusData = assets.statusData;
  }

  // 设置RecordProvider
  void setRecordProvider(RecordProvider recordProvider){
    _recordProvider = recordProvider;
  }

  // 设置HistoryProvider
  void setHistoryProvider(HistoryProvider historyProvider){
    _historyProvider = historyProvider;
  }

  GameTurn getGameTurn() {
    return GameTurn(round: round, turn: turn, extra: extra);
  }

  GameTurn getPreviousGameTurn() {
    return gameTurnList.length > 2 ? gameTurnList[gameTurnList.length - 2] : getGameTurn();
  }

  void clearGame(){
    players.clear();
    gameSequence.clear();
    playerDied.clear();
    teams.clear();
    playerCount = 0;
    turn = 0;
    round = 1;
    teamCount = 0;
    gameTurnList.clear();
    players['empty'] = emptyCharacter;
  }


  void addPlayer(Character character){
    players[character.id] = character;
    gameSequence.add(character.id);
    playerCount++;
  }

  void removePlayer(Character character){
    players.remove(character.id);
    gameSequence.remove(character.id);
    playerCount--;
  }

  void addAttribute(String charaId, AttributeType type, int value){
    Character chara = players[charaId]!;
    if(type == AttributeType.health){
      chara.health += value;
      if(chara.health > chara.maxHealth){chara.health = chara.maxHealth;}
      }
    else if(type == AttributeType.maxhp){chara.maxHealth += value;}
    else if(type == AttributeType.attack){chara.attack += value;}
    else if(type == AttributeType.defence){chara.defence += value;}
    else if(type == AttributeType.armor){chara.armor += value;}
    else if(type == AttributeType.movepoint){chara.movePoint += value;}
    else if(type == AttributeType.maxmove){chara.maxMove += value;}
    else if(type == AttributeType.card){chara.cardCount += value;}
    else if(type == AttributeType.dmgdealt) {chara.damageDealtTotal += value; chara.damageDealtRound += value; chara.damageDealtTurn += value;}
    else if(type == AttributeType.dmgreceived) {chara.damageReceivedTotal += value; chara.damageReceivedRound += value; chara.damageReceivedTurn += value;}
    refresh();
  }

  void addStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    List<int> statusDataOld = [chara.getStatusIntensity(status), chara.getStatusLayer(status)];
    if (chara.hasStatus(langMap!['gugu'])) {
      isImmune = true;
    }
    if(chara.hasHiddenStatus('babel')){
      isImmune = true;
    }
    if (charaId == langMap!['shigure'] && {langMap!['frozen'], langMap!['frost']}.contains(status)){
      List<bool> isImmuneRef = [isImmune];
      castTrait(charaId, [], langMap!['icy_blood'], {'type': 0, 'isImmuneRef': isImmuneRef});
      isImmune = isImmuneRef[0];
    }
    if(!isImmune){
      try{
        if(status == langMap!['teroxis']){
          if(chara.getStatusIntensity(langMap!['teroxis']) + intensity <= 5){
            chara.status[status]![0] += intensity;
            addAttribute(charaId, AttributeType.attack, 5 * intensity);
          }
          else{
            chara.status[status]![0] = 5;
            addAttribute(charaId, AttributeType.attack, 5 * (5 - chara.getStatusIntensity(langMap!['teroxis'])));
          }   
        }
        else if(status == langMap!['soul_flare']){
          chara.status[status]![0] += intensity;
        }
        else{
          chara.status[status]![1] += layer;
        }        
      }
      catch (e) {
        chara.status[status] = [intensity, layer, playerCount, 0];
        if (status == langMap!['frost']) {
          addAttribute(chara.id, AttributeType.attack, -4 * chara.getStatusIntensity(langMap!['frost']));
        }
        else if (status == langMap!['exhausted']) {
          chara.status[langMap!['exhausted']]![3] = (chara.attack / 2).toInt();
          addAttribute(chara.id, AttributeType.attack, -chara.getStatusIntData(langMap!['exhausted']));
        }
        else if (status == langMap!['strength']) {
          addAttribute(chara.id, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['strength']));
        }
        else if (status == langMap!['teroxis']) {
          addAttribute(chara.id, AttributeType.attack, 5 * intensity);
        }
        else if (status == langMap!['lumen_flare']) {
          addAttribute(chara.id, AttributeType.attack, 5);
        }
        else if (status == langMap!['erode_gelid']) {
          addAttribute(chara.id, AttributeType.defence, 5);
        }
        else if (status == langMap!['grind']) {
          chara.status[langMap!['grind']]![3] = 2;
          addAttribute(chara.id, AttributeType.maxmove, -chara.getStatusIntData(langMap!['grind']));
        }
        else if (status == langMap!['fragility']) {
          addAttribute(chara.id, AttributeType.defence, -2 * chara.getStatusIntensity(langMap!['fragility']));
        }
        else if (status == langMap!['mirror']) {
          chara.status[langMap!['mirror']]![3] = chara.attack * 1024 + chara.defence;
          addAttribute(chara.id, AttributeType.attack, chara.getStatusIntData(langMap!['mirror']) % 1024 - chara.attack);
          addAttribute(chara.id, AttributeType.defence, (chara.getStatusIntData(langMap!['mirror']) / 1024).toInt() - chara.defence);
        }
        else if (status == langMap!['burn_out']) {
          addAttribute(chara.id, AttributeType.attack, 5 * chara.getStatusIntensity(langMap!['burn_out']));
          addAttribute(chara.id, AttributeType.defence, -5 * chara.getStatusIntensity(langMap!['burn_out']));
        }
        else if (status == langMap!['corroded']) {
          addAttribute(chara.id, AttributeType.attack, -30);
        }

        // 冰火相融
        if (chara.hasStatus(langMap!['frost']) && chara.hasStatus(langMap!['flaming'])) {
          int frostIntensity = chara.getStatusIntensity(langMap!['frost']);
          int flamingIntensity = chara.getStatusIntensity(langMap!['flaming']);
          if (frostIntensity > flamingIntensity) {
            removeStatus(charaId, langMap!['flaming']);
            changeStatusIntensity(charaId, langMap!['frost'], frostIntensity - flamingIntensity);
          }
          else if (flamingIntensity > frostIntensity) {
            removeStatus(charaId, langMap!['frost']);
            changeStatusIntensity(charaId, langMap!['flaming'], flamingIntensity - frostIntensity);
          }
          else {
            removeStatus(charaId, langMap!['frost']);
            removeStatus(charaId, langMap!['flaming']);
          }
        }
      }
      _recordProvider!.addStatusRecord(GameTurn(round: round, turn: turn, extra: extra), 
      emptyCharacter.id, charaId, status, statusDataOld, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], '');
    }
    refresh();
  }

  void removeStatus(String charaId, String status){ 
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    if (status == langMap!['frost']) {
      addAttribute(chara.id, AttributeType.attack, 4 * chara.getStatusIntensity(langMap!['frost']));
    }
    else if (status == langMap!['exhausted']) {
      addAttribute(chara.id, AttributeType.attack, chara.getStatusIntData(langMap!['exhausted']));
    }
    else if (status == langMap!['strength']) {
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['strength']));
    }
    else if (status == langMap!['teroxis']) {
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['teroxis']));
    }
    else if (status == langMap!['lumen_flare']) {
      addAttribute(chara.id, AttributeType.attack, -5);
    }
    else if (status == langMap!['erode_gelid']) {
      addAttribute(chara.id, AttributeType.defence, -5);
    }
    else if (status == langMap!['grind']) {
      addAttribute(chara.id, AttributeType.maxmove, chara.getStatusIntData(langMap!['grind']));
    }
    else if (status == langMap!['fragility']) {
      addAttribute(chara.id, AttributeType.defence, 2 * chara.getStatusIntensity(langMap!['fragility']));
    }
    else if (status == langMap!['mirror']) {
      addAttribute(chara.id, AttributeType.attack, (chara.getStatusIntData(langMap!['mirror']) / 1024).toInt() - chara.attack);
      addAttribute(chara.id, AttributeType.defence, chara.getStatusIntData(langMap!['mirror']) % 1024 - chara.defence);
    }
    else if (status == langMap!['burn_out']) {
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['burn_out']));
      addAttribute(chara.id, AttributeType.defence, 5 * chara.getStatusIntensity(langMap!['burn_out']));
    }
    else if (status == langMap!['corroded']) {
      addAttribute(chara.id, AttributeType.attack, 30);
    }
    _recordProvider!.addStatusRecord(GameTurn(round: round, turn: turn, extra: extra), 
    emptyCharacter.id, charaId, status, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [0, 0], '');
    chara.status.remove(status);
    refresh();
  }

  void changeStatusIntensity(String charaId, String status, int intensity){
    Character chara = players[charaId]!;

    if (!chara.hasStatus(status)) {return;}

    if (status == langMap!['frost']) {
      addAttribute(chara.id, AttributeType.attack, 4 * chara.getStatusIntensity(langMap!['frost']) - 4 * intensity);
    }
    else if (status == langMap!['strength']) {
      addAttribute(chara.id, AttributeType.attack, -5 * chara.getStatusIntensity(langMap!['strength']) + 5 * intensity);
    }

    _recordProvider!.addStatusRecord(GameTurn(round: round, turn: turn, extra: extra), 
    emptyCharacter.id, charaId, status, [chara.getStatusIntensity(status), chara.getStatusLayer(status)], [intensity, chara.getStatusLayer(status)], '');
    chara.status[status]![0] = intensity;
  }

  void addHiddenStatus(String charaId, String status, int intensity, int layer){
    Character chara = players[charaId]!;
    bool isImmune = false;
    if(!isImmune){
      try{
        if(['damageplus', 'hero_legend', 'dream_shelter'].contains(status)){
          chara.hiddenStatus[status]![0] += intensity;
        }
        else{
          chara.hiddenStatus[status]![1] += layer;
        }
      }
      catch (e){
        chara.hiddenStatus[status] = [intensity, layer, playerCount, 0];
        if (status == 'yearning_atk') {
          addAttribute(charaId, AttributeType.attack, intensity);
        }
        else if (status == 'yearning_def') {
          addAttribute(charaId, AttributeType.defence, intensity);
        }
      }
    }
    refresh();
  }

  void removeHiddenStatus(String charaId, String status){ 
    Character chara = players[charaId]!;
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
    else if (status == 'yearning_atk') {
      addAttribute(charaId, AttributeType.attack, -chara.hiddenStatus[status]![0]);
    }
    else if (status == 'yearning_def') {
      addAttribute(charaId, AttributeType.defence, -chara.hiddenStatus[status]![0]);
    }   
    chara.hiddenStatus.remove(status);
    refresh();
  }

  void castTrait(String source, List<String> targets, String trait, [Map<String, dynamic>? args]){
    bool traitAble = true;
    int movePointCost = 0;
    Character sourceChara = players[source]!;
    List<Character> targetCharaList = targets.map((target) => players[target]!).toList();
    String target = targetCharaList.isEmpty ? '' : targetCharaList.first.id;
    Character targetChara = targetCharaList.isEmpty ? emptyCharacter : targetCharaList.first;
    Map<String, dynamic> traitData = args ?? {};
    // 特质触发条件
    // 茵竹【自勉】
    if (trait == langMap!['self_encouragement']) {
      if (sourceChara.health > sourceChara.maxHealth * 0.5 || sourceChara.health < 0 
      || sourceChara.hasHiddenStatus('encouragement')){
        traitAble = false;
      }
    }
    // 黯星【决心】
    else if (trait == langMap!['resolution']) {
      if (sourceChara.health > 0) {
        traitAble = false;
      }
    }
    // 飖 【天魔体】
    else if (trait == langMap!['demonic_avatar']) {
      if (sourceChara.health > sourceChara.maxHealth * 0.5) {
        traitAble = false;
      }
    }
    // 飖【血灵斩】
    else if (trait == langMap!['hema_slash']) {
      if (sourceChara.movePoint < 1 || sourceChara.cardCount < 1) {
        traitAble = false;
      }
    }
    // K97【二进制】
    else if (trait == langMap!['binary']) {
      int type = traitData['type'];
      if (type == 2 && sourceChara.armor <= 0) {
        traitAble = false;
      }
    }
    // 安德宁【回旋曲】
    else if (trait == langMap!['rondo']) {
      if (sourceChara.damageDealtTurn > 150) {
        traitAble = false;
      }
    }
    // 扶风【大预言】
    else if (trait == langMap!['grand_prophecy']) {
      if (sourceChara.movePoint < 1  || sourceChara.hasHiddenStatus('grand_prophecy')) {
        traitAble = false;
      }
    }
    // 星凝【祝愿】
    else if (trait == langMap!['blessing']) {
      if (sourceChara.movePoint < 1) {
        traitAble = false;
      }
    }
    // 时雨【天霜封印】
    else if (trait == langMap!['arctic_seal']) {
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
    else if (trait == langMap!['upon_the_clouds']) {
      if (sourceChara.health > 0 || sourceChara.hasHiddenStatus('cloud')) {
        traitAble = false;
      }
    }
    // 舸灯【引渡】
    else if (trait == langMap!['ghost_ferry']) {
      int type = traitData['type'];
      if (type == 1 && sourceChara.movePoint < 2) {
        traitAble = false;
      }
    }
    // 状态【混乱】【冰封】
    if ((sourceChara.hasStatus(langMap!['confusion']) || sourceChara.hasStatus(langMap!['frozen'])) 
    && trait != langMap!['resolution']) {
      traitAble = false;
    }
    // 行动点消耗
    if (movePointCost > sourceChara.movePoint) {
      traitAble = false;
    }
    else {
      addAttribute(source, AttributeType.movepoint, -movePointCost);
    }
    if (traitAble) {
      // 茵竹【自勉】
      if (trait == langMap!['self_encouragement']) {
        damagePlayer(source, source, (sourceChara.maxHealth * 0.8).toInt() - sourceChara.health, DamageType.heal);
        addHiddenStatus(source, 'encouragement', 0, -1);
      }
      // 妮卡欧【不倦的观测者】
      else if (trait == langMap!['tireless_observer']) {
        String skill = traitData['skill'];
        sourceChara.skill[skill] = sourceChara.skill[skill]! - 1;
      }
      // 云云子【晨昏寥落】
      else if (trait == langMap!['dusk_void']) {
        List<double> baseDamageRef = traitData['baseDamageRef'];
        int attack = traitData['attack'];
        double attackMulti = traitData['attackMulti'];
        int point = traitData['point'];
        baseDamageRef[0] = (point - 1) * (attack - 30) * attackMulti;
      }
      // 星尘【幸运壁垒】
      else if (trait == langMap!['lucky_shield']) {
        String dmgSource = traitData['dmgSource'];
        int damage = traitData['damage'];
        int point = traitData['point'];
        if ({3, 6}.contains(point)) {
          addAttribute(source, AttributeType.health, damage);
          addAttribute(source, AttributeType.dmgreceived, -damage);
          addAttribute(dmgSource, AttributeType.dmgdealt, -damage);
        }
      }
      // 黯星【决心】
      else if (trait == langMap!['resolution']) {
        int point = traitData['point'];
        if ({1, 5, 6}.contains(point)) {
          addAttribute(source, AttributeType.health, 1 - sourceChara.health);
        }
        else {
          addHiddenStatus(source, 'res_failed', 0, 1);
        }
      }
      // 方寒【耀光爆裂】
      else if (trait == langMap!['radiant_blast']) {
        int point = traitData['point'];
        if ({4, 5}.contains(point)) {
          addStatus(target, langMap!['soul_flare'], 1, -1);
        }
        else if (point == 6) {
          addStatus(target, langMap!['soul_flare'], 2, -1);
        }
      }
      // 恪玥【咕了】
      else if (trait == langMap!['escaping']) {
        int point = traitData['point'];
        if ({3, 6}.contains(point)) {
          addStatus(source, langMap!['gugu'], 0, 1);
        }
      }
      // 飖【天魔体】
      else if (trait == langMap!['demonic_avatar']) {
        List<double> damageMultiRef = traitData['damageMultiRef'] ;
        damageMultiRef[0] = damageMultiRef[0] * 1.5;
      }
      // 飖【血灵斩】
      else if (trait == langMap!['hema_slash']) {
        addAttribute(source, AttributeType.card, -1);
        addAttribute(source, AttributeType.movepoint, -1);
        sourceChara.actionTime++;
        addHiddenStatus(source, 'hema', 0, 0);    
      }
      // 恋慕【勿忘我】
      else if (trait == langMap!['dont_forget_me']) {
        int type = traitData['type'];
        if (type == 0) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] = damageMultiRef[0] * 3.3;
        }
        else if (type == 1) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] = damageMultiRef[0] * 2.7;
        }
        else if (type == 2) {
          addAttribute(source, AttributeType.health, 1 - sourceChara.health);
          addHiddenStatus(source, 'forget_me', 0, 1);
        }
      }
      // K97【二进制】
      else if (trait == langMap!['binary']) {
        int type = traitData['type'];
        if (type == 0) {
          addAttribute(source, AttributeType.health, -100);
          addAttribute(source, AttributeType.armor, 100);
        }
        else if (type == 1) {
          addAttribute(source, AttributeType.health, sourceChara.armor);
          addAttribute(source, AttributeType.armor, -sourceChara.armor);
        }
        else if (type == 2) {
          List<double> damageMultiRef = traitData['damageMultiRef'];
          damageMultiRef[0] = damageMultiRef[0] * 0.4;         
        }
      }
      // 安德宁【回旋曲】
      else if (trait == langMap!['rondo']) {
        addStatus(source, langMap!['dodge'], 0, 1);
      }
      // 扶风【大预言】
      else if (trait == langMap!['grand_prophecy']) {
        int point = traitData['point'];
        if (point == 1) {
          addAttribute(source, AttributeType.movepoint, -1);
        }
        addHiddenStatus(source, 'grand_prophecy', 0, 1);
      }
      // 奈普斯特【幽魂化】
      else if (trait == langMap!['spectralization']) {
        int type = traitData['type'];
        if (type == 0) {
          List<int> damageRef = traitData['damageRef'];
          damageRef[0] = 0;
        }
        else {
          List<dynamic> statusKeys = sourceChara.status.keys.toList();
          for (var stat in statusKeys) {
            removeStatus(source, stat);
          }
        }
      }
      // 奈普斯特【小惊吓】
      else if (trait == langMap!['little_spook']) {
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
            addStatus(chara, langMap!['uneasiness'], 1, 2);
          }
        }
      }
      // 星凝【希冀】
      else if (trait == langMap!['yearning']) {
        int type = traitData['type'];
        if (type == 0) {
          addHiddenStatus(target, 'yearning_atk', (sourceChara.damageDealtTurn * 0.1).toInt(), 1);
          
        }
        else {
          addHiddenStatus(target, 'yearning_def', (sourceChara.damageDealtTurn * 0.1).toInt(), 1);
        }
      }
      // 星凝【祝愿】
      else if (trait == langMap!['blessing']) {
        damagePlayer(source, target, 100, DamageType.heal);
        addAttribute(source, AttributeType.movepoint, -1);
        List<dynamic> statusKeys = targetChara.status.keys.toList();
        for (var stat in statusKeys) {
          if (statusData![stat][0] == "1") {
            removeStatus(target, stat);
          }
        }
      }
      // 时雨【天霜封印】
      else if (trait == langMap!['arctic_seal']){
        int point = traitData['point'];
        if ({1, 3, 6}.contains(point)) {
          addStatus(target, langMap!['frozen'], 0, 1);
        }
      }
      // 时雨【寒冰血脉】
      else if (trait == langMap!['icy_blood']){
        int type = traitData['type'];
        if (type == 0) {
          List<bool> isImmuneRef = traitData['isImmuneRef'];
          isImmuneRef[0] = true;
        }
        else {
          List<int> damagePlusRef = traitData['damagePlusRef'];
          if (targetChara.hasStatus(langMap!['frost'])) {
            damagePlusRef[0] = damagePlusRef[0] - 30 * targetChara.getStatusIntensity(langMap!['frost']);
          }
        }
      }
      // 图西乌【凌日】
      else if (trait == langMap!['transit']) {
        List<int> damagePlusRef = traitData['damagePlusRef'];
        List<double> damageMultiRef = traitData['damageMultiRef'];
        damagePlusRef[0] = 0;
        damageMultiRef[0] = 1;
      }
      // 图西乌【蚀月】
      else if (trait == langMap!['eclipse']) {
        List<int> pointRef = traitData['pointRef'];
        if (pointRef[0] > 5) {
          pointRef[0] = 5;
        }
      }
      // 舸灯【引渡】
      else if (trait == langMap!['ghost_ferry']) {
        int type = traitData['type'];
        if (type == 0) {
          List<int> costRef = traitData['costRef'];
          costRef[0] -= 1;
        }
        else {
          addAttribute(source, AttributeType.movepoint, -2);
          addAttribute(source, AttributeType.card, 2);
          addHiddenStatus(source, 'ferry', 0, 1);
        }
      }
      // 赐弥【在云端】
      else if (trait == langMap!['upon_the_clouds']) {
        int sourceSeq = gameSequence.indexOf(source) + 1;
        bool findHistory = false;

        for (int i = _historyProvider!.currentHistoryIndex; i >= 0; i--) {
          String history = _historyProvider!.getStateAt(i);
          Map<String, dynamic> gameState = jsonDecode(history);
          if (gameState['turn'] == sourceSeq) {
            findHistory = true;
          }
          if (findHistory && gameState['turn'] == (sourceSeq == 1 ? gameSequence.length : sourceSeq - 1)) {            
            String save = _historyProvider!.getStateAt(i + 1);
            Map<String, dynamic> saveState = jsonDecode(save);
            Map<String, dynamic> playersData = saveState['players'];
            addAttribute(source, AttributeType.health, playersData[source]['health'] - sourceChara.health);
            addAttribute(source, AttributeType.attack, playersData[source]['attack'] - sourceChara.attack);
            addAttribute(source, AttributeType.defence, playersData[source]['defence'] - sourceChara.defence);
            addAttribute(source, AttributeType.movepoint, playersData[source]['movePoint'] - sourceChara.movePoint);
            addAttribute(source, AttributeType.card, playersData[source]['cardCount'] - sourceChara.cardCount);
            sourceChara.skill = Map<String, int>.from(playersData[source]['skill']);
            sourceChara.status = Map<String, List<dynamic>>.from(playersData[source]['status']);
            addHiddenStatus(source, 'cloud', 0, 1);
            break;
          }
        }
      }

      // 记录特质
      _recordProvider!.addTraitRecord(GameTurn(round: round, turn: turn, extra: extra), source, targets, 
      trait, traitData);
    }
  }

  void damagePlayer(String source, String target, int damage, DamageType type, {String tag = '', bool isAOE = false}){ 
    Character sourceChara = players[source]!;
    Character targetChara = players[target]!;
    int damagePlus = 0;
    double damageMulti = 1;
    // 加伤相关道具
    if(targetChara.hasHiddenStatus('damageplus')){
      damagePlus += targetChara.getHiddenStatusIntensity('damageplus');
      removeHiddenStatus(target, 'damageplus');
      }
    // 道具【终焉长戟】
    if(targetChara.hasHiddenStatus('end')){
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('end'); i++) { 
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'end');
      }
    // 道具【猎魔灵刃】
    if(targetChara.hasHiddenStatus('track')){
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('track'); i++) {
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'track');
    }
    // 道具【融甲宝珠】
    if(targetChara.hasHiddenStatus('penetrate')){
      for (int i = 0; i < targetChara.getHiddenStatusIntensity('penetrate'); i++) {
        damageMulti *= 1.5;
      }      
      removeHiddenStatus(target, 'penetrate');
    }
    // 图西乌【凌日】
    if (target == langMap!['tussiu']) {
      List<int> damagePlusRef = [damagePlus];
      List<double> damageMultiRef = [damageMulti];
      castTrait(target, [], langMap!['transit'], {'damagePlusRef': damagePlusRef, 'damageMultiRef': damageMultiRef});
      damagePlus = damagePlusRef[0];
      damageMulti = damageMultiRef[0];
    }
    // 状态【氤氲】
    if(targetChara.hasStatus(langMap!['nebula'])){
      damageMulti *= (1.0 + 0.5 * targetChara.getStatusIntensity(langMap!['nebula']));      
    }
    // 状态【灵曜】
    if (targetChara.hasStatus(langMap!['soul_flare'])) {
      damagePlus -= 80 * targetChara.getStatusIntensity(langMap!['soul_flare']);
      damagePlayer(target, source, 105 * targetChara.getStatusIntensity(langMap!['soul_flare']), DamageType.magical);
      removeStatus(target, langMap!['soul_flare']);
    }
    // 状态【骑虎难下】
    if(targetChara.hasStatus(langMap!['tigris_dilemma'])){
      damageMulti *= 1.2;
    }
    // 状态【不安】
    if (sourceChara.hasStatus(langMap!['uneasiness'])){
      sourceChara.status[langMap!['uneasiness']]![1] -= 1;
    }
    // 技能【恐吓】
    if (targetChara.hasHiddenStatus('intimidation')) {
      damageMulti *= 0.5;
    }
    // 技能【分裂】
    if (sourceChara.hasHiddenStatus('fission')) {
      damageMulti *= 0.8;
    }
    // 飖【天魔体】
    if (source == langMap!['windflutter']) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(source, [], langMap!['demonic_avatar'], {'damageMultiRef': damageMultiRef});
      damageMulti = damageMultiRef[0];
    }
    // 恋慕【勿忘我】
    if (source == langMap!['loveless']) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(source, [], langMap!['dont_forget_me'], {'damageMultiRef': damageMultiRef, 'type': 0});
      damageMulti = damageMultiRef[0];
    }    
    if (target == langMap!['loveless']) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(source, [], langMap!['dont_forget_me'], {'damageMultiRef': damageMultiRef, 'type': 1});
      damageMulti = damageMultiRef[0];
    }
    // K97【二进制】
    if (target == langMap!['k97']) {
      List<double> damageMultiRef = [damageMulti];      
      castTrait(target, [], langMap!['binary'], {'damageMultiRef': damageMultiRef, 'type': 2});
      damageMulti = damageMultiRef[0];
    }
    // 时雨【寒冰血脉】
    if (target == langMap!['shigure']) {
      List<int> damagePlusRef = [damagePlus];
      castTrait(target, [source], langMap!['icy_blood'], {'type': 1, 'damagePlusRef': damagePlusRef});
      damagePlus = damagePlusRef[0];
    }
    // 舸灯【引渡】
    if (source == langMap!['gentou']) {
      if (sourceChara.hasHiddenStatus('ferry')) {
        damagePlus += 45;
        removeHiddenStatus(source, 'ferry');
      }
    }
    // 伤害计算 
    damage = ((damage + damagePlus) * damageMulti).toInt();
    
    // 状态【闪避】
    if(targetChara.hasStatus(langMap!['dodge']) && [DamageType.action, DamageType.physical].contains(type)){
      if(!sourceChara.hasHiddenStatus('critical')){        
        addHiddenStatus(source, 'void', 0, 1);
      }
      removeStatus(target, langMap!['dodge']);
    }
    // 状态【咕咕】
    if(targetChara.hasStatus(langMap!['gugu'])){
      if(!sourceChara.hasHiddenStatus('critical')){        
        addHiddenStatus(source, 'void', 0, 1);
      }      
    }
    // 奈普斯特【幽魂化】
    if (target == langMap!['nepst']) {
      if (isAOE) {
        List<int> damageRef = [damage];
        castTrait(target, [], langMap!['spectralization'], {'type': 0, 'damageRef': damageRef});
        damage = damageRef[0];
      }                  
    }
    // 不造成伤害
    if(sourceChara.hasHiddenStatus('void') && type == DamageType.action){
      damage = 0;
      removeHiddenStatus(source, 'void');
    }
    if (damage < 0) {
      damage = 0;
    }
    // 伤害结算
    if(type == DamageType.action){
      if (sourceChara.hasHiddenStatus('fission')) {
        Character fissionChara = emptyCharacter;
        for (var c in players.values) {
          if (c.hasHiddenStatus('fission_target')) {
            fissionChara = c;
            break;
          }
        }        
        removeHiddenStatus(source, 'fission');
        removeHiddenStatus(fissionChara.id, 'fission_target');
        damagePlayer(source, fissionChara.id, damage, DamageType.physical, isAOE: true);
      }
      if (targetChara.hasStatus(langMap!['fractured']) || sourceChara.hasHiddenStatus('critical')) {
        targetChara.health -= damage;
        if (sourceChara.hasHiddenStatus('critical')) removeHiddenStatus(source, 'critical');
      }
      else {
        targetChara.armor -= damage;
        if(targetChara.armor < 0) {
          if (!targetChara.hasHiddenStatus('barrier')){
            targetChara.health += targetChara.armor;
          }
          else {
            removeHiddenStatus(target, 'barrier');
          }
          targetChara.armor = 0;
        }
      }
    }
    else if (type == DamageType.physical) {
      if(targetChara.hasStatus(langMap!['fractured'])){
        targetChara.health -= damage;
      }
      else{
        targetChara.armor -= damage;
        if(targetChara.armor < 0){
          if (!targetChara.hasHiddenStatus('barrier')){
            targetChara.health += targetChara.armor;
          }
          else {
            removeHiddenStatus(target, 'barrier');
          }    
          targetChara.armor = 0;
        }
      }
    }
    else if(type == DamageType.magical){
      targetChara.health -= damage;
    }
    else if(type == DamageType.heal){
      if (targetChara.hasStatus(langMap!['dissociated']) == false){
        targetChara.health += damage;
        if(targetChara.health > targetChara.maxHealth){
          targetChara.health = targetChara.maxHealth;
        }
      }
    }
    else if (type == DamageType.revive) {
      targetChara.health += damage;
    }
    // 技能【镜像】
    if (targetChara.hasHiddenStatus('mirror')) {
      if (targetChara.damageReceivedTotal - targetChara.getHiddenStatusIntData('mirror')> 300) {
        removeStatus(target, langMap!['mirror']);
        removeHiddenStatus(target, 'mirror');
      }
    }

    // 伤害统计
    if (damage > 0) {
      addAttribute(source, AttributeType.dmgdealt, damage);
      addAttribute(target, AttributeType.dmgreceived, damage);
      _recordProvider!.addDamageRecord(GameTurn(round: round, turn: turn, extra: extra), 
        source, target, damage, type, tag);
    }    
    refresh();
  }

  // 结束轮次
  void endTurn(){
    //
    String currentCharaId;
    if(turn == 0){
      currentCharaId = gameSequence[0];
    }
    else{
      currentCharaId = gameSequence[turn - 1];
    }
    Character currentChara = players[currentCharaId]!;        

    // 全局状态结算
    if(turn == playerCount && !currentChara.hasHiddenStatus('extra')){
      // 达摩克利斯之剑
      for(; countdown.reinforcedDamocles > 0; countdown.reinforcedDamocles--){
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){ 
          if(target.health > maxHp){
            maxHp = target.health;
            maxHpChara = target;
          }          
        }
        damagePlayer(emptyCharacter.id, maxHpChara.id, 300, DamageType.magical);        
      }
      for(; countdown.damocles > 0; countdown.damocles--){
        Character maxHpChara = players[currentCharaId]!;
        int maxHp = maxHpChara.health;
        for(Character target in players.values){
          if(target.health > maxHp){
            maxHp = target.health;
            maxHpChara = target;
            // _logger.d(maxHpChara.id);
          }          
        }
        damagePlayer(emptyCharacter.id, maxHpChara.id, 150, DamageType.magical);      
      }        
    }

    // 状态结算
    // 霜冻
    if(currentChara.hasStatus(langMap!['frost'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 4 * currentChara.getStatusIntensity(langMap!['frost']), DamageType.magical, tag: 'frost');
    }
    // 灼炎
    if(currentChara.hasStatus(langMap!['flaming'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 10 * currentChara.getStatusIntensity(langMap!['flaming']), DamageType.magical, tag: 'flaming');
    }
    // 再生
    if(currentChara.hasStatus(langMap!['regeneration'])){
      damagePlayer(emptyCharacter.id, currentCharaId, 30 * currentChara.getStatusIntensity(langMap!['regeneration']), DamageType.heal);
    }

    // 特质结算
    // 茵竹【自勉】
    for(var chara in players.values) {
      if (chara.id == langMap!['chinro']){
        castTrait(chara.id, [], langMap!['self_encouragement']);
      }
    }
    if (currentCharaId == langMap!['andrenin']) {
      castTrait(currentCharaId, [], langMap!['rondo']);
    }

    // 状态层数削减
    if (countdown.extraTurn == 0) {
    for(Character chara in players.values){
      List<String> statusKeys = chara.status.keys.toList();
      for(String status in statusKeys){
        if(!{langMap!['teroxis'], langMap!['dodge'], langMap!['lumen_flare'], langMap!['erode_gelid'], langMap!['uneasiness']}.contains(status)){
          chara.status[status]![2]--;
        }
        if(chara.status[status]![2] <= 0){
          chara.status[status]![1]--;
          chara.status[status]![2] = playerCount;
        }
        if(chara.status[status]![1] == 0){
          removeStatus(chara.id, status);
        }
      }
      List<String> hiddenStatusKeys = chara.hiddenStatus.keys.toList();
      for(String status in hiddenStatusKeys){
        if (!['barrier'].contains(status)){
          chara.hiddenStatus[status]![2]--;
        }      
        if(chara.hiddenStatus[status]![2] <= 0){
          chara.hiddenStatus[status]![1]--;
          chara.hiddenStatus[status]![2] = playerCount;
        }
        if(chara.hiddenStatus[status]![1] == 0){
          removeHiddenStatus(chara.id, status);
        }
      }
    }
    }

    // 技能CD减少
    if (countdown.extraTurn == 0) {
      for (String skill in currentChara.skill.keys){
        if(currentChara.skill[skill]! > 0){
          currentChara.skill[skill] = currentChara.skill[skill]! - 1;
        }
      }
    }

    // 玩家死亡
    for (var chara in players.values) {
      if (chara.id == langMap!['loveless'] && chara.health <= 0 && round == 1) {
        castTrait(chara.id, [], langMap!['dont_forget_me'], {'type': 2});
      }
      if (chara.id == langMap!['cimme'] && chara.health <= 0) {
        castTrait(chara.id, [], langMap!['upon_the_clouds']);
      }
      if (chara.health <= 0 && !([langMap!['darkstar']].contains(chara.id)) ) {
        chara.isDead = true;
        playerDiedCount++;
      }
      if (chara.id == langMap!['darkstar'] && chara.hasHiddenStatus('res_failed')) {
        chara.isDead = true;
        playerDiedCount++;
      }
    }
    if (gameType == GameType.single && playerDiedCount == playerCount - 1) {
      isGameOver = true;
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
    currentCharaId = gameSequence[turn - 1];
    currentChara = players[currentCharaId]!;

    // 全局状态结算
    if (turn == 1) {
      for (; countdown.antiGravity > 0; countdown.antiGravity--) {
        gameSequence = gameSequence.reversed.toList();
      }
    }

    // 特质结算    
    for (var chara in players.values) {
      // 恋慕【勿忘我】
      if (chara.id == langMap!['loveless'] && chara.hasHiddenStatus('forget_me') && round >= 2) {
        removeHiddenStatus(chara.id, 'forget_me');
        chara.isDead = true;
        playerDiedCount++;
      }
      // 扶风【大预言】
      if (chara.id == langMap!['flowwind'] && chara.hasHiddenStatus('grand_prophecy') && turn == 1) {
        removeHiddenStatus(chara.id, 'grand_prophecy');                
      }
      // 奈普斯特【小惊吓】
      if (chara.id == langMap!['nepst'] && turn == 1 && extra == 0 && round > 1) {
        castTrait(chara.id, [], langMap!['little_spook']);
      }
    }
    // K97【二进制】
    if (currentCharaId == langMap!['k97']) {
      if (round % 2 == 1) {
        castTrait(currentCharaId, [], langMap!['binary'], {'type': 0});
      }
      else {
        castTrait(currentCharaId, [], langMap!['binary'], {'type': 1});
      }
    }
    // 奈普斯特【幽魂化】
    else if (currentCharaId == langMap!['nepst']) {
      castTrait(currentCharaId, [], langMap!['spectralization'], {'type': 1});
    }
    // 赐弥【在云端】
    else if (currentCharaId == langMap!['cimme']) {
      if (currentChara.hasHiddenStatus('cloud')) {
        removeHiddenStatus(currentCharaId, 'cloud');
      }
    }

    // 伤害统计重置
    for (var chara in players.values) {
      chara.damageDealtTurn = 0;
      chara.damageReceivedTurn = 0;
      if (turn == 1 && countdown.extraTurn == 0) {
        chara.damageDealtRound = 0;
        chara.damageReceivedRound = 0;      
      }
    }

    // 抽牌
    if (!currentChara.hasStatus(langMap!['frozen'])){
      addAttribute(currentCharaId, AttributeType.card, 2);
      if(currentChara.hasHiddenStatus('heaven')){
        addAttribute(currentCharaId, AttributeType.card, 1);
      }
    }
    

    // 行动点回复
    int moveRegen = 0;
    if(currentChara.regenType == 0){
      moveRegen = currentChara.moveRegen;
    }
    else if(currentChara.regenType == 2){
      moveRegen = currentChara.maxMove;
    }
    else if(currentChara.regenType == 3){
      moveRegen = (currentChara.cardCount / 2).ceil();
    }
    else if(currentChara.regenType == 4){
      if(round == 1){moveRegen = currentChara.maxMove;}
      else {moveRegen = currentChara.moveRegen;}
    }
    if(currentChara.hasStatus(langMap!['swift'])){
      moveRegen++;
    }
    if(currentChara.hasStatus(langMap!['slowness'])){
      moveRegen--;
    }
    if(currentChara.maxMove - currentChara.movePoint < moveRegen){
      moveRegen = currentChara.maxMove - currentChara.movePoint;
    }
    if(currentChara.isDead){
      moveRegen = 0;
    }
    if((round - 1) % currentChara.regenTurn == 0 && ([0, 3, 4].contains(currentChara.regenType))){
      addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
    }
    if(currentChara.movePoint == 0 && currentChara.regenType == 2){
      addAttribute(currentCharaId, AttributeType.movepoint, moveRegen);
    }

    // 行动次数增加
    currentChara.actionTime++;

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