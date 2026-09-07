import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_card.dart';
import 'home_screen.dart';
import 'support_screen.dart';

/// Bottom-navigation shell hosting the two Mindful sections:
/// Lock (home) and Support.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [HomeScreen(), SupportScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindfulColors.black,
      body: GlassBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: GlassCard(
            borderRadius: 26,
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.lock_outline,
                  selectedIcon: Icons.lock,
                  label: 'Lock',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                const SizedBox(width: 8),
                _NavItem(
                  icon: Icons.headset_mic_outlined,
                  selectedIcon: Icons.headset_mic,
                  label: 'Support',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? MindfulColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 22,
                  color:
                      selected ? MindfulColors.black : MindfulColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? MindfulColors.black
                        : MindfulColors.mist,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}