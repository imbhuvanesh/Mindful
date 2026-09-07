import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_lock.dart';
import '../services/lock_service.dart';
import '../theme/colors.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/glass_card.dart';
import 'lock_screen.dart';

/// Lock tab: a prominent Lock button, the currently locked apps with live
/// per-app countdowns, and an option to lock more.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _ticker;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _openLockScreen() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LockScreen()),
    );
    if (added == true) setState(() {});
  }

  Future<void> _dismissLock(AppLock lock) async {
    // Hide the card instantly (mid swipe-out animation) so it can't snap back.
    setState(() => _removing.add(lock.packageName));
    await LockService.instance.unlock(lock.packageName);
    if (mounted) {
      setState(() => _removing.remove(lock.packageName));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: LockService.instance,
        builder: (context, _) {
          final locks = _visibleLocks;
          return SafeArea(
            child: locks.isEmpty
                ? _EmptyState(onLock: _openLockScreen)
                : _LocksView(
                    locks: locks,
                    onLockMore: _openLockScreen,
                    onDismiss: _dismissLock,
                  ),
          );
        },
      ),
    );
  }

  List<AppLock> get _visibleLocks =>
      LockService.instance.locks
          .where((l) => !_removing.contains(l.packageName))
          .toList();
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLock});
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 48),
          const _Brand(),
          const Spacer(),
          const Icon(Icons.lock_open_outlined, size: 64, color: MindfulColors.white),
          const SizedBox(height: 16),
          Text(
            'No apps locked',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: MindfulColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the apps that distract you most. Mindful locks them for an '
            'hour so you can focus.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MindfulColors.gray,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onLock,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Lock apps'),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active-locks view
// ---------------------------------------------------------------------------

class _LocksView extends StatelessWidget {
  const _LocksView({
    required this.locks,
    required this.onLockMore,
    required this.onDismiss,
  });
  final List<AppLock> locks;
  final VoidCallback onLockMore;
  final void Function(AppLock lock) onDismiss;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const _Brand(),
        const SizedBox(height: 8),
        Text(
          '${locks.length} app${locks.length == 1 ? '' : 's'} locked · '
          'unlocks at ${_clockTime(locks.first.lockedUntil)}',
          style: const TextStyle(color: MindfulColors.gray, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...locks.map((lock) => Dismissible(
              key: ValueKey(lock.packageName),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDismiss(lock),
              background: const SizedBox.shrink(),
              secondaryBackground: const _SwipeUnlockBackground(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LockCard(lock: lock),
              ),
            )),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onLockMore,
          icon: const Icon(Icons.add),
          label: const Text('Lock more apps'),
        ),
      ],
    );
  }

  static String _clockTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _SwipeUnlockBackground extends StatelessWidget {
  const _SwipeUnlockBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(right: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x99EF4444)),
        color: const Color(0x1FEF4444),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Unlock',
            style: TextStyle(
              color: Color(0xFFFCA5A5),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.lock_open, size: 22, color: Color(0xFFFCA5A5)),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Text(
      'MINDFUL',
      style: TextStyle(
        color: MindfulColors.white,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: 8,
        shadows: [
          Shadow(color: MindfulColors.white.withValues(alpha: 0.25), blurRadius: 24),
        ],
      ),
    );
  }
}

class _LockCard extends StatefulWidget {
  const _LockCard({required this.lock});
  final AppLock lock;

  @override
  State<_LockCard> createState() => _LockCardState();
}

class _LockCardState extends State<_LockCard> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _confirmUnlock() async {
    final app = widget.lock;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Unlock ${app.appName}?'),
        content: const Text('It opens again right away. This ends the lock '
            'early for this app only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await LockService.instance.unlock(widget.lock.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = widget.lock;
    final remaining = lock.lockRemaining;
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    final countdown = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AppIconWidget(
            iconBytes: lock.iconBytes,
            appName: lock.appName,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lock.appName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MindfulColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlocks in $countdown',
                  style: const TextStyle(
                    color: MindfulColors.mist,
                    fontSize: 13,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _confirmUnlock,
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}