// 游戏类型
enum GameType{
  single,
  team,
  boss
}

// 属性类型
enum AttributeType{
  health, 
  maxhp, 
  attack, 
  defence, 
  armor, 
  movepoint, 
  maxmove, 
  card,
  dmgdealt,
  dmgreceived,
}

// 伤害类型
enum DamageType{
  action,
  physical,
  magical,
  heal,
  revive,
}

// 游戏状态标记
class GameTurn {
  final int round;
  final int turn;
  final int extra;

  GameTurn({
    required this.round,
    required this.turn,
    required this.extra,
  });

  bool operator <(GameTurn other) {
    if (round != other.round) return round < other.round;
    if (turn != other.turn) return turn < other.turn;
    if (extra != other.extra) return extra < other.extra;
    return false;
  }

  // 重载 > 运算符
  bool operator >(GameTurn other) {
    if (round != other.round) return round > other.round;
    if (turn != other.turn) return turn > other.turn;
    if (extra != other.extra) return extra > other.extra;
    return false;
  }

  // 重载 <= 运算符
  bool operator <=(GameTurn other) {
    return this < other || this == other;
  }

  // 重载 >= 运算符
  bool operator >=(GameTurn other) {
    return this > other || this == other;
  }

  // 重载 == 运算符
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GameTurn &&
        other.round == round &&
        other.turn == turn &&
        other.extra == extra;
  }

  // 重载 hashCode
  @override
  int get hashCode => Object.hash(round, turn, extra);

  int compareTo(GameTurn other) {
    if (round != other.round) return round.compareTo(other.round);
    if (turn != other.turn) return turn.compareTo(other.turn);
    return extra.compareTo(other.extra);
  }

  @override
  String toString() {
    return 'GameTurn(round: $round, turn: $turn, extra: $extra)';
  }
}