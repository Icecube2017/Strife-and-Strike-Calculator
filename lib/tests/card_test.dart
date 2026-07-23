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
class MockRecordProvider extends Mock implements RecordProvider {
  @override
    List<GameRecord> getFilteredRecords({
      RecordType? type,
      String? source,
      String? target,
      GameTurn? startTurn,
      GameTurn? endTurn,
    }) {
      return super.noSuchMethod(
        Invocation.method(#getFilteredRecords, [], {
          #type: type,
          #source: source,
          #target: target,
          #startTurn: startTurn,
          #endTurn: endTurn,
        }),
        returnValue: <GameRecord>[],
      ) as List<GameRecord>;
    }
}
class MockGameLogger extends Mock implements GameLogger {}

class SpyRecordProvider extends RecordProvider {
  int addDamageRecordCallCount = 0;
  GameTurn? lastDamageTurn;
  String? lastDamageSource;
  String? lastDamageTarget;
  int? lastDamageAmount;
  DamageType? lastDamageType;
  String? lastDamageTag;

  @override
  void addDamageRecord(
    GameTurn turn,
    String source,
    String target,
    int damage,
    DamageType damageType,
    DamageSource damageSource,
    String tag,
  ) {
    addDamageRecordCallCount++;
    lastDamageTurn = turn;
    lastDamageSource = source;
    lastDamageTarget = target;
    lastDamageAmount = damage;
    lastDamageType = damageType;
    lastDamageTag = tag;
    super.addDamageRecord(turn, source, target, damage, damageType, damageSource, tag);
  }
}

void main() {
  late Game game;
  late MockHistoryProvider mockHistoryProvider;
  late MockRecordProvider mockRecordProvider;
  late MockGameLogger mockLogger;  

  setUp(() {
    mockHistoryProvider = MockHistoryProvider();
    mockRecordProvider = MockRecordProvider();
    mockLogger = MockGameLogger();

    game = Game('test', GameType.single);
    game.setHistoryProvider(mockHistoryProvider);
    game.setRecordProvider(mockRecordProvider);
    game.setGameLogger(mockLogger);

    when(mockRecordProvider.getFilteredRecords(
      type: anyNamed('type'),
      source: anyNamed('source'),
      target: anyNamed('target'),
      startTurn: anyNamed('startTurn'),
      endTurn: anyNamed('endTurn'),
    )).thenReturn([]);
    
    game.addPlayer(Character(CharacterId.fangHan.id, 1350, 95, 35, 0, 5, 2, 0, 1));
    game.addPlayer(Character(CharacterId.viento.id, 1350, 80, 50, 0, 5, 2, 0, 1));
    game.endTurn();
  });

  /*test('Game initializes with correct state', () {
    expect(game.id, 'test_game_id');
    expect(game.gameType, GameType.single);
    // 构造函数会先加入一个占位的 'empty' 玩家
    expect(game.players.containsKey('empty'), true);
    expect(game.gameState, GameState.waiting);
  });

  test('Add and manage players and teams', () {
    // 创建简单角色并加入游戏
    Character p1 = Character('p1', 10, 2, 1, 0, 3, 1, 0, 1);
    Character p2 = Character('p2', 12, 3, 1, 0, 3, 1, 0, 1);
    game.addPlayer(p1);
    game.addPlayer(p2);

    expect(game.players.containsKey('p1'), true);
    expect(game.players.containsKey('p2'), true);
    expect(game.playerCount, 2);

    // 切换为队伍模式并添加队伍
    game.gameType = GameType.team;
    int teamId = game.addTeam();
    game.addPlayerToTeam(teamId, 'p1');
    game.addPlayerToTeam(teamId, 'p2');

    expect(game.getPlayerTeam('p1'), teamId);
    expect(game.getPlayerTeam('p2'), teamId);
    expect(game.isTeammate('p1', 'p2'), true);

    // 移除玩家
    game.removePlayer(p1);
    expect(game.players.containsKey('p1'), false);
  });*/
  test ('Card Test: End Crystal', () {
    expect(game.round, 1);
    expect(game.turn, 1);
    expect(game.extra, 0);
    
    game.playCards(CharacterId.fangHan.id, [CharacterId.viento.id], 1, [CardId.endCrystal.id], 
    [EndCrystalSetting()]);

    expect(game.players[CharacterId.fangHan.id]!.damageDealtTurn, 100);
    expect(game.players[CharacterId.fangHan.id]!.damageReceivedTurn, 45);
    expect(game.players[CharacterId.viento.id]!.damageReceivedTurn, 100);
  });

  test ('Card Test: Apollo Arrow', () {
    game.endTurn();
    game.playCards(CharacterId.viento.id, [CharacterId.fangHan.id], 1, [CardId.apolloArrow.id], [DefaultCardSetting()]);

    expect(game.players[CharacterId.viento.id]!.damageDealtTurn, 145);
    expect(game.players[CharacterId.fangHan.id]!.damageReceivedTurn, 145);
  });

  test ('Card Test: Babel', () {     
    game.playCards(CharacterId.fangHan.id, [CharacterId.viento.id], 1, [CardId.babelTower.id], [DefaultCardSetting()]);

    expect(game.players[CharacterId.fangHan.id]!.damageDealtTurn, 45);

    game.endTurn();
    game.playCards(CharacterId.viento.id, [CharacterId.fangHan.id], 1, [CardId.pyrotheum.id], [DefaultCardSetting()]);

    expect(game.players[CharacterId.viento.id]!.damageDealtTurn, 45);
    expect(game.players[CharacterId.fangHan.id]!.status, {});

    game.endTurn();
    game.playCards(CharacterId.fangHan.id, [CharacterId.viento.id], 1, [CardId.pyrotheum.id], [DefaultCardSetting()]);

    expect(game.players[CharacterId.viento.id]!.status[StatusId.flaming.id]!.intensity, 5);
  });
}
