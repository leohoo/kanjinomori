import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_item.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/coin_display.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6D4C41),
              Color(0xFF5D4037),
              Color(0xFF4E342E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => gameNotifier.goToHome(),
                    ),
                    const Expanded(
                      child: Text(
                        'ショップ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    CoinDisplay(coins: player.coins, large: true),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  labelColor: AppColors.accentDark,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  tabs: const [
                    Tab(text: '武器'),
                    Tab(text: '衣装'),
                    Tab(text: '装飾'),
                    Tab(text: '演出'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ShopCategory(
                      category: ShopCategory.weapon,
                      player: player,
                    ),
                    _ShopCategory(
                      category: ShopCategory.costume,
                      player: player,
                    ),
                    _ShopCategory(
                      category: ShopCategory.decoration,
                      player: player,
                    ),
                    _ShopCategory(
                      category: ShopCategory.animation,
                      player: player,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCategory extends ConsumerWidget {
  final ShopCategory category;
  final dynamic player;

  const _ShopCategory({
    required this.category,
    required this.player,
  });

  bool _isOwned(String itemId) {
    switch (category) {
      case ShopCategory.weapon:
        return player.ownedWeapons.contains(itemId);
      case ShopCategory.costume:
        return player.ownedCostumes.contains(itemId);
      case ShopCategory.decoration:
      case ShopCategory.animation:
        return player.ownedDecorations.contains(itemId);
    }
  }

  bool _isEquipped(String itemId) {
    switch (category) {
      case ShopCategory.weapon:
        return player.equippedWeapon == itemId;
      case ShopCategory.costume:
        return player.equippedCostume == itemId;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ShopItem.getByCategory(category);
    final playerNotifier = ref.read(playerProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = _isOwned(item.id);
        final isEquipped = _isEquipped(item.id);
        final canAfford = player.coins >= item.price;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(
              color: isEquipped
                  ? AppColors.accent
                  : Colors.white.withOpacity(0.1),
              width: isEquipped ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(item.id),
                  color: _getCategoryColor(),
                  size: 28,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '装備中',
                      style: TextStyle(
                        color: AppColors.accentDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: isOwned
                ? (category == ShopCategory.weapon ||
                        category == ShopCategory.costume)
                    ? TextButton(
                        onPressed: isEquipped
                            ? null
                            : () {
                                if (category == ShopCategory.weapon) {
                                  playerNotifier.equipWeapon(item.id);
                                } else {
                                  playerNotifier.equipCostume(item.id);
                                }
                              },
                        child: Text(
                          isEquipped ? '装備中' : '装備',
                          style: TextStyle(
                            color: isEquipped
                                ? Colors.white38
                                : AppColors.accent,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      )
                : item.price == 0
                    ? const Text(
                        '無料',
                        style: TextStyle(color: Colors.white),
                      )
                    : ElevatedButton(
                        onPressed: canAfford
                            ? () => _showPurchaseDialog(
                                context, ref, item, playerNotifier)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford
                              ? AppColors.accent
                              : Colors.grey,
                          foregroundColor: AppColors.accentDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, size: 16),
                            const SizedBox(width: 4),
                            Text('${item.price}'),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor() {
    switch (category) {
      case ShopCategory.weapon:
        return Colors.red;
      case ShopCategory.costume:
        return Colors.blue;
      case ShopCategory.decoration:
        return Colors.purple;
      case ShopCategory.animation:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(String itemId) {
    switch (category) {
      case ShopCategory.weapon:
        if (itemId.contains('staff')) return Icons.auto_fix_high;
        if (itemId.contains('bow')) return Icons.gps_fixed;
        if (itemId.contains('sword') || itemId.contains('blade')) {
          return Icons.flash_on;
        }
        return Icons.sports_mma;
      case ShopCategory.costume:
        return Icons.checkroom;
      case ShopCategory.decoration:
        return Icons.auto_awesome;
      case ShopCategory.animation:
        return Icons.animation;
    }
  }

  void _showPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
    dynamic playerNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name}を購入しますか？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  '${item.price} コイン',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final success = playerNotifier.purchaseItem(item);
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name}を購入しました！'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('購入'),
          ),
        ],
      ),
    );
  }
}
