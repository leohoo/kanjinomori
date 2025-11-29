enum ShopCategory { weapon, costume, decoration, animation }

class ShopItem {
  final String id;
  final String name;
  final String description;
  final ShopCategory category;
  final int price;
  final String? iconPath;
  final Map<String, dynamic>? stats; // For weapons: damage bonus, etc.

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.iconPath,
    this.stats,
  });

  static List<ShopItem> get allItems => [
        // Weapons
        const ShopItem(
          id: 'wooden_staff',
          name: '木の杖',
          description: '初心者用の杖。攻撃力+5',
          category: ShopCategory.weapon,
          price: 0,
          stats: {'damage': 5},
        ),
        const ShopItem(
          id: 'bow_arrow',
          name: '弓矢',
          description: '遠距離攻撃が可能。攻撃力+10',
          category: ShopCategory.weapon,
          price: 100,
          stats: {'damage': 10},
        ),
        const ShopItem(
          id: 'magic_sword',
          name: '魔法の剣',
          description: '光の力を秘めた剣。攻撃力+20',
          category: ShopCategory.weapon,
          price: 300,
          stats: {'damage': 20},
        ),
        const ShopItem(
          id: 'dragon_blade',
          name: 'ドラゴンブレード',
          description: '伝説のドラゴンの剣。攻撃力+35',
          category: ShopCategory.weapon,
          price: 500,
          stats: {'damage': 35},
        ),

        // Costumes
        const ShopItem(
          id: 'default',
          name: '冒険者の服',
          description: '基本の冒険服',
          category: ShopCategory.costume,
          price: 0,
        ),
        const ShopItem(
          id: 'forest_outfit',
          name: '森の衣装',
          description: '森の精霊風の衣装',
          category: ShopCategory.costume,
          price: 80,
        ),
        const ShopItem(
          id: 'knight_armor',
          name: '騎士の鎧',
          description: '勇者のための鎧',
          category: ShopCategory.costume,
          price: 200,
        ),
        const ShopItem(
          id: 'wizard_robe',
          name: '魔法使いのローブ',
          description: '不思議な力を持つローブ',
          category: ShopCategory.costume,
          price: 250,
        ),

        // Decorations
        const ShopItem(
          id: 'flower_crown',
          name: '花の冠',
          description: '森の花で作られた冠',
          category: ShopCategory.decoration,
          price: 50,
        ),
        const ShopItem(
          id: 'butterfly_wings',
          name: '蝶の羽',
          description: '背中に輝く蝶の羽',
          category: ShopCategory.decoration,
          price: 150,
        ),
        const ShopItem(
          id: 'magic_aura',
          name: '魔法のオーラ',
          description: 'キャラクターを包む光',
          category: ShopCategory.decoration,
          price: 300,
        ),

        // Animations
        const ShopItem(
          id: 'sparkle_effect',
          name: 'キラキラ演出',
          description: '正解時にキラキラ光る',
          category: ShopCategory.animation,
          price: 60,
        ),
        const ShopItem(
          id: 'rainbow_effect',
          name: '虹の演出',
          description: '正解時に虹が出る',
          category: ShopCategory.animation,
          price: 120,
        ),
        const ShopItem(
          id: 'firework_effect',
          name: '花火の演出',
          description: '正解時に花火が上がる',
          category: ShopCategory.animation,
          price: 200,
        ),
      ];

  static List<ShopItem> getByCategory(ShopCategory category) {
    return allItems.where((item) => item.category == category).toList();
  }

  static ShopItem? getItem(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
