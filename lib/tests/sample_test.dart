import 'package:flutter_test/flutter_test.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/core.dart'; // 假设核心枚举和类在这里
//import 'package:sns_calculator/assets.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/logger.dart';
import 'package:mockito/mockito.dart';

class MockHistoryProvider extends Mock implements HistoryProvider {}
class MockRecordProvider extends Mock implements RecordProvider {}
class MockGameLogger extends Mock implements GameLogger {}

void main() {
  late Game game;
  late MockHistoryProvider mockHistoryProvider;
  late MockRecordProvider mockRecordProvider;
  late MockGameLogger mockLogger;

  setUp(() {
    mockHistoryProvider = MockHistoryProvider();
    mockRecordProvider = MockRecordProvider();
    mockLogger = MockGameLogger();
    game = Game('test_game_id', GameType.single);
    game.setHistoryProvider(mockHistoryProvider);
    game.setRecordProvider(mockRecordProvider);
    game.setGameLogger(mockLogger);
  });

  test('Game initializes with correct state', () {
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
  });
}