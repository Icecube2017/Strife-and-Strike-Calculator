// 游戏类型
enum GameType{
  single,
  team,
  boss
}

// 游戏状态
enum GameState{
  waiting,
  start,
  over,
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
  maxcard,
  dmgdealt,
  dmgreceived,
  curdealt,
  curreceived
}

// 伤害类型
enum DamageType{
  action,
  physical,
  magical,
  heal,
  revive,
}

// 骰子类型
enum DiceType{
  action,
  card,
  skill,
  trait
}

// 标签
enum Tag{
  sharp('锋锐'),
  protect('铁御'),
  vital('生机'),
  destiny('命运'),
  mystique('秘法'),
  phantom('幻相'),
  magic('魔能'),
  weird('诡术'),
  disorder('失序'),
  sense('感知'),
  heat('灼热'),
  chill('霜寒');

  final String tagId;

  const Tag(this.tagId);
}

// 攻击特效
enum AttackEffect{ 
  lumenFlare('烛焱'),
  oculusVeil('障目'),
  nausea('反胃');

  final String effectId;

  const AttackEffect(this.effectId);
}

// 防守特效
enum DefenceEffect{ 
  erodeGelid('蚀凛');

  final String effectId;

  const DefenceEffect(this.effectId);
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

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'turn': turn,
      'extra': extra,
    };
  }

  factory GameTurn.fromJson(Map<String, dynamic> json) {
    return GameTurn(
      round: json['round'],
      turn: json['turn'],
      extra: json['extra'],
    );
  }

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