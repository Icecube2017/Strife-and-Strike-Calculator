import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sns_calculator/core.dart';
import 'package:sns_calculator/game.dart';
import 'package:sns_calculator/history.dart';
import 'package:sns_calculator/record.dart';
import 'package:sns_calculator/logger.dart';
// import 'package:sns_calculator/settings.dart';

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
        
    game.addPlayer(Character(CharacterId.drMin.id, 1350, 105, 25, 0, 6, 2, 0, 1));
    game.addPlayer(Character(CharacterId.nepst.id, 1350, 95, 35, 0, 5, 2, 0, 1));
    game.addPlayer(Character(CharacterId.starcondon.id, 1350, 95, 35, 0, 5, 2, 0, 1));
    game.addPlayer(Character(CharacterId.shigure.id, 1350, 95, 35, 0, 5, 2, 0, 1));    
    game.addPlayer(Character(CharacterId.tussiu.id, 1350, 105, 25, 0, 6, 2, 0, 1));
    game.addPlayer(Character(CharacterId.gentou.id, 1600, 75, 45, 0, 5, 2, 0, 1));
    game.endTurn();
  });
}
