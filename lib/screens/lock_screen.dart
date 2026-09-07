import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zo_app_blocker/app_info.dart';

import '../services/lock_service.dart';
import '../theme/colors.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_card.dart';

/// Shows a permission gate followed by an installable-apps list with
/// checkboxes, finishing with a lock button.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

enum _Phase { checking, permissions, loading, list }

class _LockScreenState extends State<LockScreen> {
  _Phase _phase = _Phase.checking;
  final Set<String> _selected = {};
  List<AppInfo> _apps = [];
  bool _usage = false;
  bool _overlay = false;
  bool _notif = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final usage = await LockService.instance.hasUsageAccess;
    final overlay = await LockService.instance.hasOverlayAccess;
    final notif = await LockService.instance.hasNotificationAccess;
    _usage = usage;
    _overlay = overlay;
    _notif = notif;

    if (!mounted) return;
    setState(() {
      if (usage && overlay && notif) {
        _phase = _Phase.loading;
        _loadApps();
      } else {
        _phase = _Phase.permissions;
      }
    });
  }

  Future<void> _loadApps() async {
    final apps = await LockService.instance.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _phase = _Phase.list;
    });
  }

  Future<void> _recheckPermissions() async {
    final usage = await LockService.instance.hasUsageAccess;
    final overlay = await LockService.instance.hasOverlayAccess;
    final notif = await LockService.instance.hasNotificationAccess;
    _usage = usage;
    _overlay = overlay;
    _notif = notif;
    if (!mounted) return;
    if (usage && overlay && notif) {
      setState(() {
        _phase = _Phase.loading;
        _loadApps();
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: MindfulColors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        switch (_phase) {
                          _Phase.permissions => 'Permissions needed',
                          _Phase.list => 'Select apps to lock',
                          _ => 'Mindful',
                        },
                        style: const TextStyle(
                          color: MindfulColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (_phase) {
                  _Phase.checking || _Phase.loading =>
                    const Center(child: CircularProgressIndicator()),
                  _Phase.permissions => _PermGate(
                      usage: _usage,
                      overlay: _overlay,
                      notif: _notif,
                      onRecheck: _recheckPermissions,
                    ),
                  _Phase.list => _AppPicker(
                      apps: _apps,
                      selected: _selected,
                      onToggle: (pkg) => setState(() {
                        if (!_selected.add(pkg)) _selected.remove(pkg);
                      }),
                      onLock: _lockSelected,
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _lockSelected() async {
    final toLock =
        _apps.where((a) => _selected.contains(a.packageName)).toList();
    await LockService.instance.lockApps(toLock);
    if (mounted) Navigator.of(context).pop(true);
  }
}

// ---------------------------------------------------------------------------
// Permission gate
// ---------------------------------------------------------------------------

class _PermGate extends StatelessWidget {
  const _PermGate({
    required this.usage,
    required this.overlay,
    required this.notif,
    required this.onRecheck,
  });

  final bool usage;
  final bool overlay;
  final bool notif;
  final Future<void> Function() onRecheck;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Mindful needs a few permissions to block apps. '
          'All data stays on your device.',
          style: TextStyle(color: MindfulColors.gray, height: 1.5),
        ),
        const SizedBox(height: 16),
        _PermRow(
          icon: Icons.insights_outlined,
          title: 'Usage access',
          ok: usage,
          onRequest: LockService.instance.requestUsageAccess,
        ),
        const SizedBox(height: 10),
        _PermRow(
          icon: Icons.layers_outlined,
          title: 'Display over other apps',
          ok: overlay,
          onRequest: LockService.instance.requestOverlayAccess,
        ),
        const SizedBox(height: 10),
        _PermRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          ok: notif,
          onRequest: LockService.instance.requestNotificationAccess,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onRecheck,
          child: const Text('Check & continue'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onRecheck,
          child: const Text('I\'ve granted all three — check again'),
        ),
      ],
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.ok,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final bool ok;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: ok ? scheme.primary : scheme.error),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: MindfulColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (ok)
            Icon(Icons.check_circle, color: scheme.primary, size: 22)
          else
            TextButton(onPressed: onRequest, child: const Text('Allow')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App picker
// ---------------------------------------------------------------------------

class _AppPicker extends StatefulWidget {
  const _AppPicker({
    required this.apps,
    required this.selected,
    required this.onToggle,
    required this.onLock,
  });

  final List<AppInfo> apps;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onLock;

  @override
  State<_AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<_AppPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.apps.where((a) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return a.appName.toLowerCase().contains(q) ||
          a.packageName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search apps…',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching apps'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final app = filtered[i];
                    final selected =
                        widget.selected.contains(app.packageName);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AppRow(
                        app: app,
                        selected: selected,
                        onToggle: () => widget.onToggle(app.packageName),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton(
              onPressed: widget.selected.isEmpty ? null : widget.onLock,
              child: widget.selected.isEmpty
                  ? const Text('Select an app')
                  : Text(
                      'Lock ${widget.selected.length} app${widget.selected.length == 1 ? '' : 's'}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.selected,
    required this.onToggle,
  });

  final AppInfo app;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onToggle,
        contentPadding: EdgeInsets.zero,
        leading: AppIconWidget(
          iconBytes: app.icon,
          appName: app.appName,
          size: 40,
        ),
        title: Text(app.appName, overflow: TextOverflow.ellipsis),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
    );
  }
}