import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/logger.dart';
import 'package:sns_calculator/settings.dart';

class MockHistoryProvider extends Mock implements HistoryProvider {}
class MockGameLogger extends Mock implements GameLogger {}

class SpyRecordProvider extends RecordProvider {

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
        
    game.addPlayer(Character(CharacterId.pigeon.id, 1350, 65, 65, 0, 4, 2, 0, 1));
    game.addPlayer(Character(CharacterId.windflutter.id, 1350, 95, 35, 0, 5, 2, 0, 1));
    game.addPlayer(Character(CharacterId.loveless.id, 1200, 125, 20, 0, 4, 2, 0, 2));
    game.addPlayer(Character(CharacterId.k97.id, 1350, 65, 65, 0, 10, 10, 0, 5));
    game.addPlayer(Character(CharacterId.andrenin.id, 1350, 95, 35, 0, 6, 2, 0, 1));
    game.addPlayer(Character(CharacterId.flowwind.id, 1350, 80, 50, 0, 6, 2, 0, 1));
    game.endTurn();
  });

  test ('Trait test: Pigeon - Escaping - Success', () {
    expect(game.players[CharacterId.pigeon.id]!.hasHiddenStatus('gugu'), true);

    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});

    expect(game.players[CharacterId.pigeon.id]!.hasStatus(StatusId.gugu.id), true);
  });

  test ('Trait test: Pigeon - Escaping - Physical Damage Immunity', () {
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 0);
  });

  test ('Trait test: Pigeon - Escaping - Magical Damage Immunity', () {
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [CardId.bow.id], 
    [BowSetting()]);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 0);
  });

  test ('Trait test: Pigeon - Escaping - Status Immunity', () {
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [CardId.pyrotheum.id], 
    [DefaultCardSetting()]);

    expect(game.players[CharacterId.pigeon.id]!.hasStatus(StatusId.flaming.id), false);
  });

  test ('Trait test: Pigeon - Escaping - Dice Point Failed', () {
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 2});

    expect(game.players[CharacterId.pigeon.id]!.hasStatus(StatusId.gugu.id), false);
  });

  test ('Trait test: Pigeon - Renouncing - Success', () {
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 4});
    
    expect(game.players[CharacterId.windflutter.id]!.damageReceivedRound, 12);
    expect(game.players[CharacterId.loveless.id]!.damageReceivedRound, 32);
    expect(game.players[CharacterId.flowwind.id]!.damageReceivedRound, 12);
  });

  test ('Trait test: Pigeon - Renouncing - Damage Increasing', () {
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 3});
     game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.castTrait(CharacterId.pigeon.id, [CharacterId.pigeon.id], TraitId.escaping.id, 
    {'point': 4});
    
    expect(game.players[CharacterId.windflutter.id]!.damageReceivedRound, 24);
    expect(game.players[CharacterId.loveless.id]!.damageReceivedRound, 64);
    expect(game.players[CharacterId.flowwind.id]!.damageReceivedRound, 24);
  });

  test ('Trait test: Windflutter - Demonic Avatar - Success', () {
    game.playCards(CharacterId.pigeon.id, [CharacterId.windflutter.id], 30, [], []);
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.windflutter.id]!.damageDealtRound, 45);
    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 45);
  });

  test ('Trait test: Windflutter - Demonic Avatar - Health Failed', () { 
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [], []);
    
    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 30);
  });

  test ('Trait test: Windflutter - Hema Slash - Success', () { 
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [CardId.rest.id, CardId.curing.id], 
    [DefaultCardSetting(), DefaultCardSetting()]);
    game.castTrait(CharacterId.windflutter.id, [CharacterId.pigeon.id], TraitId.hemaSlash.id);
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 45);
    expect(game.players[CharacterId.windflutter.id]!.attack, 110);
    expect(game.players[CharacterId.windflutter.id]!.cardCount, 1);
    expect(game.players[CharacterId.windflutter.id]!.movePoint, 0);

    game.endTurn();

    expect(game.players[CharacterId.windflutter.id]!.attack, 95);
  });

  test ('Trait test: Windflutter - Hema Slash - Movepoint Failed', () { 
    game.endTurn();
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, 
    [CardId.rest.id, CardId.rest.id, CardId.curing.id, CardId.curing.id], 
    [DefaultCardSetting(), DefaultCardSetting(), DefaultCardSetting(), DefaultCardSetting()]);
    game.castTrait(CharacterId.windflutter.id, [CharacterId.pigeon.id], TraitId.hemaSlash.id);
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 0);
    expect(game.players[CharacterId.windflutter.id]!.attack, 95);
    expect(game.players[CharacterId.windflutter.id]!.cardCount, 0);
    expect(game.players[CharacterId.windflutter.id]!.movePoint, 2);
  });

  test ('Trait test: Windflutter - Hema Slash - Trait First', () { 
    game.endTurn();
    game.castTrait(CharacterId.windflutter.id, [CharacterId.pigeon.id], TraitId.hemaSlash.id);

    expect(game.players[CharacterId.windflutter.id]!.attack, 95);

    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [CardId.rest.id, CardId.curing.id], 
    [DefaultCardSetting(), DefaultCardSetting()]);
    game.playCards(CharacterId.windflutter.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 45);
    expect(game.players[CharacterId.windflutter.id]!.attack, 110);
    expect(game.players[CharacterId.windflutter.id]!.cardCount, 1);
    expect(game.players[CharacterId.windflutter.id]!.movePoint, 0);
  });

  test ('Trait test: Loveless - Don\'t Forget Me - Success', () { 
    game.playCards(CharacterId.pigeon.id, [CharacterId.loveless.id], 1, [], []);

    expect(game.players[CharacterId.loveless.id]!.damageReceivedRound, 121);

    game.endTurn();
    game.endTurn(); 
    game.playCards(CharacterId.loveless.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 198);
  });

  test ('Trait test: Loveless - Don\'t Forget Me - Damage Type Failed', () { 
    game.playCards(CharacterId.pigeon.id, [CharacterId.loveless.id], 0, [CardId.corruptPendant.id], 
    [DefaultCardSetting()]);

    expect(game.players[CharacterId.loveless.id]!.damageReceivedRound, 60);
    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 0);

    game.endTurn();
    game.endTurn(); 
    game.playCards(CharacterId.loveless.id, [CharacterId.pigeon.id], 0, [CardId.corruptPendant.id], 
    [DefaultCardSetting()]);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 60);
  });

  test ('Trait test: Loveless - Don\'t Forget Me - Invincible', () { 
    game.playCards(CharacterId.pigeon.id, [CharacterId.loveless.id], 10, [], []);
    game.endTurn();

    expect(game.players[CharacterId.loveless.id]!.isDead, false);

    game.endTurn();
    game.playCards(CharacterId.loveless.id, [CharacterId.pigeon.id], 1, [], []);

    expect(game.players[CharacterId.pigeon.id]!.damageReceivedRound, 198);

    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();

    expect(game.players[CharacterId.loveless.id]!.isDead, true);
  });

  test ('Trait test: K97 - Binary Noise - Success', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();

    expect(game.players[CharacterId.k97.id]!.hasHiddenStatus('binary'), true);
    expect(game.players[CharacterId.k97.id]!.actionTime, 2);
    game.playCards(CharacterId.k97.id, [CharacterId.windflutter.id], 1, [CardId.hexastal.id], 
    [DefaultCardSetting()]);    

    game.playCards(CharacterId.k97.id, [CharacterId.windflutter.id], 1, [CardId.octastal.id], 
    [DefaultCardSetting()]);

    expect(game.players[CharacterId.windflutter.id]!.damageReceivedRound, 60);
    expect(game.players[CharacterId.k97.id]!.armor, 1);
  });

  test ('Trait test: K97 - Binary Noise - Out of Turn', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.playCards(CharacterId.k97.id, [CharacterId.windflutter.id], 1, [CardId.hexastal.id], 
    [DefaultCardSetting()]);
    game.endTurn();
    game.playCards(CharacterId.andrenin.id, [CharacterId.k97.id], 1, [CardId.hexastal.id], 
    [DefaultCardSetting()]);
    game.playCards(CharacterId.k97.id, [CharacterId.windflutter.id], 1, [CardId.hexastal.id], 
    [DefaultCardSetting()]);

    expect(game.players[CharacterId.windflutter.id]!.damageReceivedRound, 60);
    expect(game.players[CharacterId.k97.id]!.armor, 0);
  });

  test ('Trait test: Andrenin - Rondo - Success', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.playCards(CharacterId.andrenin.id, [CharacterId.pigeon.id], 1, [CardId.hexastal.id], 
    [DefaultCardSetting()]);
    game.endTurn();

    expect(game.players[CharacterId.andrenin.id]!.hasStatus(StatusId.dodge.id), true);
  });

  test ('Trait test: Andrenin - Rondo - Failed', () { 
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.endTurn();
    game.playCards(CharacterId.andrenin.id, [CharacterId.pigeon.id], 10, [CardId.decastal.id], 
    [DefaultCardSetting()]);
    game.endTurn();

    expect(game.players[CharacterId.andrenin.id]!.hasStatus(StatusId.dodge.id), false);
  });

  test ('Trait test: Flowwind - Grand Prophecy - Failed', () { 
    game.castTrait(CharacterId.flowwind.id, [CharacterId.pigeon.id], TraitId.grandProphecy.id, {'type': 0, 
    'point': 1, 'maxPoint': 4});

    expect(game.players[CharacterId.flowwind.id]!.trait[TraitId.grandProphecy.id]!.castCount, 1);

    game.castTrait(CharacterId.flowwind.id, [CharacterId.pigeon.id], TraitId.grandProphecy.id, {'type': 0, 
    'point': 1, 'maxPoint': 4});

    expect(game.players[CharacterId.flowwind.id]!.trait[TraitId.grandProphecy.id]!.castCount, 1);

    game.endTurn();

    expect(game.players[CharacterId.flowwind.id]!.trait[TraitId.grandProphecy.id]!.castCount, 1);
  });
}
