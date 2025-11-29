enum BattleAction { attack, shield, jump, none }

enum BattleState { waiting, playerTurn, enemyTelegraph, enemyAction, victory, defeat }

class BattleCharacter {
  final String name;
  int hp;
  final int maxHp;
  int damage;
  BattleAction currentAction;

  BattleCharacter({
    required this.name,
    required this.maxHp,
    required this.damage,
    BattleAction? currentAction,
  })  : hp = maxHp,
        currentAction = currentAction ?? BattleAction.none;

  bool get isAlive => hp > 0;

  double get hpPercentage => hp / maxHp;

  void takeDamage(int amount) {
    hp = (hp - amount).clamp(0, maxHp);
  }

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
  }

  void reset() {
    hp = maxHp;
    currentAction = BattleAction.none;
  }
}

class BattleResult {
  final bool playerWon;
  final int coinsEarned;
  final int damageDealt;
  final int damageTaken;

  BattleResult({
    required this.playerWon,
    required this.coinsEarned,
    required this.damageDealt,
    required this.damageTaken,
  });
}

class Battle {
  final BattleCharacter player;
  final BattleCharacter enemy;
  BattleState state;
  BattleAction? enemyNextAction;
  int turnCount;
  int playerDamageDealt;
  int playerDamageTaken;
  bool hasKanjiBonus; // From answering kanji correctly in stage

  Battle({
    required String playerName,
    required int playerHp,
    required int playerDamage,
    required String enemyName,
    required int enemyHp,
    required int enemyDamage,
    this.hasKanjiBonus = false,
  })  : player = BattleCharacter(
          name: playerName,
          maxHp: playerHp,
          damage: playerDamage,
        ),
        enemy = BattleCharacter(
          name: enemyName,
          maxHp: enemyHp,
          damage: enemyDamage,
        ),
        state = BattleState.waiting,
        turnCount = 0,
        playerDamageDealt = 0,
        playerDamageTaken = 0;

  void startBattle() {
    state = BattleState.playerTurn;
    turnCount = 1;
  }

  // Player performs an action
  ActionResult playerAction(BattleAction action) {
    player.currentAction = action;

    if (action == BattleAction.attack) {
      // Attack deals damage if enemy is not shielding
      if (enemy.currentAction != BattleAction.shield) {
        int damage = player.damage;
        if (hasKanjiBonus) {
          damage = (damage * 1.5).round(); // 50% bonus from kanji
        }
        enemy.takeDamage(damage);
        playerDamageDealt += damage;

        if (!enemy.isAlive) {
          state = BattleState.victory;
          return ActionResult(
            success: true,
            message: '${enemy.name}を倒した！',
            damage: damage,
          );
        }

        return ActionResult(
          success: true,
          message: '攻撃が命中！$damageダメージ',
          damage: damage,
        );
      } else {
        return ActionResult(
          success: false,
          message: '敵がシールドで防御した！',
          damage: 0,
        );
      }
    }

    // Shield and Jump are defensive, success depends on enemy action
    return ActionResult(
      success: true,
      message: action == BattleAction.shield ? 'シールド構え！' : 'ジャンプ！',
      damage: 0,
    );
  }

  // Determine enemy's next action (called to telegraph)
  BattleAction prepareEnemyAction() {
    state = BattleState.enemyTelegraph;

    // Simple AI: random action selection
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    // 60% attack, 25% shield, 15% jump
    if (random < 60) {
      enemyNextAction = BattleAction.attack;
    } else if (random < 85) {
      enemyNextAction = BattleAction.shield;
    } else {
      enemyNextAction = BattleAction.jump;
    }

    return enemyNextAction!;
  }

  // Enemy executes their action
  ActionResult enemyAction() {
    state = BattleState.enemyAction;
    final action = enemyNextAction ?? BattleAction.attack;
    enemy.currentAction = action;

    if (action == BattleAction.attack) {
      // Check if player defended
      if (player.currentAction == BattleAction.shield) {
        return ActionResult(
          success: false,
          message: 'シールドで防御成功！',
          damage: 0,
        );
      } else if (player.currentAction == BattleAction.jump) {
        return ActionResult(
          success: false,
          message: 'ジャンプで回避成功！',
          damage: 0,
        );
      } else {
        // Player didn't defend, takes damage
        player.takeDamage(enemy.damage);
        playerDamageTaken += enemy.damage;

        if (!player.isAlive) {
          state = BattleState.defeat;
          return ActionResult(
            success: true,
            message: '負けてしまった...',
            damage: enemy.damage,
          );
        }

        return ActionResult(
          success: true,
          message: '${enemy.damage}ダメージを受けた！',
          damage: enemy.damage,
        );
      }
    }

    // Enemy shield/jump (defensive turns)
    state = BattleState.playerTurn;
    turnCount++;
    return ActionResult(
      success: true,
      message: action == BattleAction.shield
          ? '${enemy.name}はシールドを構えた'
          : '${enemy.name}はジャンプした',
      damage: 0,
    );
  }

  void nextTurn() {
    if (state == BattleState.enemyAction) {
      state = BattleState.playerTurn;
      turnCount++;
      player.currentAction = BattleAction.none;
      enemy.currentAction = BattleAction.none;
      enemyNextAction = null;
    }
  }

  BattleResult getResult() {
    return BattleResult(
      playerWon: state == BattleState.victory,
      coinsEarned: state == BattleState.victory ? 20 + (turnCount < 5 ? 10 : 0) : 0,
      damageDealt: playerDamageDealt,
      damageTaken: playerDamageTaken,
    );
  }
}

class ActionResult {
  final bool success;
  final String message;
  final int damage;

  ActionResult({
    required this.success,
    required this.message,
    required this.damage,
  });
}
