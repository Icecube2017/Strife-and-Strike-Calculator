import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/game.dart';
//import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/logger.dart';
import 'package:sns_calculator/settings.dart';

class MockHistoryProvider extends Mock implements HistoryProvider {}
class MockGameLogger extends Mock implements GameLogger {}

class SpyRecordProvider extends RecordProvider {

  /*@override
  void addDamageRecord(
    GameTurn turn,
    String source,
    String target,
    int damage,
    DamageType damageType,
    String tag,
  ) {
    addDamageRecordCallCount++;
    lastDamageTurn = turn;
    lastDamageSource = source;
    lastDamageTarget = target;
    lastDamageAmount = damage;
    lastDamageType = damageType;
    lastDamageTag = tag;
    super.addDamageRecord(turn, source, target, damage, damageType, tag);
  }*/
}

void main() {
  late Game game;
  late MockHistoryProvider mockHistoryProvider;
  late SpyRecordProvider mockRecordProvider;
  late MockGameLogger mockLogger;  

  setUp(() {
    mockHistoryProvider = MockHistoryProvider();
    mockRecordProvider = SpyRecordProvider();
    mockLogger = MockGameLogger();

    game = Game('test', GameType.single);
    game.setHistoryProvider(mockHistoryProvider);
    game.setRecordProvider(mockRecordProvider);
    game.setGameLogger(mockLogger);
    
    game.addPlayer(Character(CharacterId.chinro.id, 1600, 75, 45, 0, 5, 2, 0, 1));
    game.addPlayer(Character(CharacterId.neko.id, 1350, 95, 35, 0, 5, 2, 0, 1));
    game.addPlayer(Character(CharacterId.yun.id, 1350, 105, 25, 0, 5, 3, 0, 1));
    game.addPlayer(Character(CharacterId.starduster.id, 1350, 80, 50, 0, 6, 2, 0, 1));
    game.addPlayer(Character(CharacterId.darkstar.id, 1200, 125, 20, 0, 6, 2, 0, 1));
    game.addPlayer(Character(CharacterId.fangHan.id, 1350, 95, 35, 0, 5, 2, 0, 1));
    game.endTurn();
  });

  test ('Trait test: Chinro - Self Encouragement - Trigger Condition', () {
    expect(game.round, 1);
    expect(game.turn, 1);
    expect(game.extra, 0);
    
    game.endTurn();
    game.playCards(CharacterId.neko.id, [CharacterId.chinro.id], 1, [], []);

    expect(game.players[CharacterId.neko.id]!.damageDealtTurn, 50);

    game.endTurn();
    
    expect(game.players[CharacterId.chinro.id]!.cureDealtRound, 0);

    game.playCards(CharacterId.yun.id, [CharacterId.chinro.id], 20, [], []);
    game.endTurn();

    expect(game.players[CharacterId.chinro.id]!.health, 1280);
  });

  test ('Trait test: Chinro - Self Encouragement - Status Immune', () { 
    game.endTurn();
    game.playCards(CharacterId.neko.id, [CharacterId.chinro.id], 20, [CardId.passingGaze.id], 
    [DefaultCardSetting()]);
    game.endTurn();

    expect(game.players[CharacterId.chinro.id]!.health, 1280);
  });

  test ('Trait test: Chinro - Self Encouragement - Death', () { 
    game.endTurn();
    game.playCards(CharacterId.neko.id, [CharacterId.chinro.id], 40, [], []);
    game.endTurn();

    expect(game.players[CharacterId.chinro.id]!.isDead, true);
  });

  test ('Trait test: Neko - Tireless Observer - Success', () { 
    game.endTurn();
    game.castSkill(CharacterId.neko.id, [CharacterId.chinro.id], SkillId.laser.id);
    game.endTurn();

    expect(game.players[CharacterId.neko.id]!.skill[SkillId.laser.id]!.cooldown, 0);
  });

  test ('Trait test: Yun - Dusk Void - Damage Calculate', () { 
    game.endTurn();
    game.endTurn();
    game.playCards(CharacterId.yun.id, [CharacterId.chinro.id], 1, [], []);
    
    expect(game.players[CharacterId.yun.id]!.damageDealtTurn, 75);
    expect(game.players[CharacterId.chinro.id]!.damageReceivedTurn, 75);
  });

  test ('Trait test: Yun - Dusk Void - Lost Damage', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.yun.id], 1, [CardId.shield.id], [DefaultCardSetting()]);
    game.endTurn();
    game.endTurn();
    game.playCards(CharacterId.yun.id, [CharacterId.chinro.id], 1, [], []);
    
    expect(game.players[CharacterId.yun.id]!.damageDealtTurn, 75);
    expect(game.players[CharacterId.chinro.id]!.damageReceivedTurn, 75);
    expect(game.players[CharacterId.chinro.id]!.health, 1525);
    expect(game.players[CharacterId.chinro.id]!.armor, 100);
  });

  test ('Trait test: Yun - Dusk Void - Confusion Failed', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.yun.id], 1, [CardId.shield.id, CardId.chaoticDrill.id], 
    [DefaultCardSetting(), DefaultCardSetting()]);
    game.endTurn();
    game.endTurn();
    game.playCards(CharacterId.yun.id, [CharacterId.chinro.id], 1, [], []);
    
    expect(game.players[CharacterId.yun.id]!.damageDealtTurn, 55);
    expect(game.players[CharacterId.chinro.id]!.damageReceivedTurn, 55);
    expect(game.players[CharacterId.chinro.id]!.health, 1600);
    expect(game.players[CharacterId.chinro.id]!.armor, 45);
  });

  test ('Trait test: StarDuster - Lucky Shield - Success', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.starduster.id], 1, [], []);
    game.castTrait(CharacterId.starduster.id, [CharacterId.starduster.id], TraitId.luckyShield.id, 
    {'dmgSource': CharacterId.chinro.id, 'dmgType': DamageType.physical, 'damage': 25, 'point': 3});

    expect(game.players[CharacterId.starduster.id]!.damageReceivedTurn, 0);
  });

  test ('Trait test: StarDuster - Lucky Shield - Dice Point Failed', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.starduster.id], 1, [], []);
    game.castTrait(CharacterId.starduster.id, [CharacterId.starduster.id], TraitId.luckyShield.id, 
    {'dmgSource': CharacterId.chinro.id, 'dmgType': DamageType.physical, 'damage': 25, 'point': 1});

    expect(game.players[CharacterId.starduster.id]!.damageReceivedTurn, 25);
  });

  test ('Trait test: StarDuster - Lucky Shield - Damage Type Failed', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.starduster.id], 1, [CardId.passingGaze.id], 
    [BowSetting()]);
    game.castTrait(CharacterId.starduster.id, [CharacterId.starduster.id], TraitId.luckyShield.id, 
    {'dmgSource': CharacterId.chinro.id, 'dmgType': DamageType.magical, 'damage': 70, 'point': 3});

    expect(game.players[CharacterId.starduster.id]!.damageReceivedTurn, 95);
  });

  test ('Trait test: DarkStar - Resolution - Success', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.darkstar.id], 20, [], []);
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.darkstar.id, [CharacterId.darkstar.id], TraitId.resolution.id, 
    {'point': 1});

    expect(game.players[CharacterId.darkstar.id]!.isDead, false);
    expect(game.players[CharacterId.darkstar.id]!.health, 1);
  });

  test ('Trait test: DarkStar - Resolution - Nullify Failed', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.darkstar.id], 20, [CardId.chaoticDrill.id], 
    [DefaultCardSetting()]);
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.darkstar.id, [CharacterId.darkstar.id], TraitId.resolution.id, 
    {'point': 1});

    expect(game.players[CharacterId.darkstar.id]!.hasStatus(StatusId.confusion.id), true);
    expect(game.players[CharacterId.darkstar.id]!.isDead, false);
    expect(game.players[CharacterId.darkstar.id]!.health, 1);
  });

  test ('Trait test: DarkStar - Resolution - Dice Point Failed', () { 
    game.playCards(CharacterId.chinro.id, [CharacterId.darkstar.id], 20, [], []);
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.darkstar.id, [CharacterId.darkstar.id], TraitId.resolution.id, 
    {'point': 2});
    game.endTurn();

    expect(game.players[CharacterId.darkstar.id]!.isDead, true);
  });

  test ('Trait test: Fang Han - Radiant Blast - Success', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.fangHan.id, [CharacterId.fangHan.id], TraitId.radiantBlast.id, 
    {'point': 4});

    expect(game.players[CharacterId.fangHan.id]!.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity), 1);

    game.endTurn();
    game.playCards(CharacterId.chinro.id, [CharacterId.fangHan.id], 3, [], []);

    expect(game.players[CharacterId.fangHan.id]!.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity), -1);
    expect(game.players[CharacterId.fangHan.id]!.damageReceivedRound, 40);
    expect(game.players[CharacterId.chinro.id]!.damageReceivedRound, 105);
  });

  test ('Trait test: Fang Han - Radiant Blast - Double Success', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.fangHan.id, [CharacterId.fangHan.id], TraitId.radiantBlast.id, 
    {'point': 6});

    expect(game.players[CharacterId.fangHan.id]!.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity), 2);

    game.endTurn();
    game.playCards(CharacterId.chinro.id, [CharacterId.fangHan.id], 5, [], []);

    expect(game.players[CharacterId.fangHan.id]!.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity), -1);
    expect(game.players[CharacterId.fangHan.id]!.damageReceivedRound, 40);
    expect(game.players[CharacterId.chinro.id]!.damageReceivedRound, 210);
  });

  test ('Trait test: Fang Han - Radiant Blast - Dice Point Failed', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.fangHan.id, [CharacterId.fangHan.id], TraitId.radiantBlast.id, 
    {'point': 3});

    expect(game.players[CharacterId.fangHan.id]!.getStatusIntData(StatusId.soulFlare.id, StatusData.intensity), -1);
  });
}
