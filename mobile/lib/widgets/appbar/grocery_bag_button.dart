import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:i_cant_cook/pages/grocery_bag_page.dart';
import 'package:i_cant_cook/providers/grocery_bag_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';

/// Global grocery-bag entry point, mirroring [UserMenuWidget]: dropped into the
/// AppBar `actions` of the main screens so it sits next to the profile button.
/// Shows a count badge of items in the bag.
class GroceryBagButton extends StatefulWidget {
  const GroceryBagButton({super.key});

  @override
  State<GroceryBagButton> createState() => _GroceryBagButtonState();
}

class _GroceryBagButtonState extends State<GroceryBagButton> {
  @override
  void initState() {
    super.initState();
    // Load the bag once so the badge is populated wherever the button appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroceryBagProvider>();
      if (!provider.hasLoaded) provider.fetchBag();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Consumer<GroceryBagProvider>(
      builder: (context, provider, _) {
        final button = IconButton(
          tooltip: 'Grocery bag',
          onPressed: () {
            HapticService.mediumImpact();
            // Slide in like recipe detail / profile rather than the global
            // fade transition used by named routes.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroceryBagPage()),
            );
          },
          icon: Icon(Icons.shopping_cart_outlined, color: color, size: 26),
        );
        final count = provider.itemCount;
        if (count == 0) return button;
        // Pull the count in toward the icon and bump its size — the default
        // badge sits in the far corner and reads too small.
        return Badge.count(
          count: count,
          largeSize: 18,
          offset: const Offset(-6, 4),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          child: button,
        );
      },
    );
  }
}
