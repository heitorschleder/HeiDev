import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../domain/logic/home_state.dart';
import '../../domain/logic/home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = getIt<HomeViewModel>()..init();
  }

  @override
  void dispose() {
    _vm.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeScreenTitle),
        actions: [_UserMenuButton(vm: _vm)],
      ),
      body: ValueListenableBuilder<HomeState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }
          return Center(
            child: Text(l10n.homeScreenGreeting, style: Theme.of(context).textTheme.headlineMedium),
          );
        },
      ),
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final email = vm.userEmail ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<_UserMenuAction>(
        tooltip: email,
        offset: const Offset(0, 48),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Text(email, style: Theme.of(context).textTheme.bodySmall),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _UserMenuAction.logout,
            child: Row(
              children: [
                const Icon(Icons.logout),
                const SizedBox(width: 12),
                Text(l10n.homeScreenLogout),
              ],
            ),
          ),
        ],
        onSelected: (action) {
          if (action == _UserMenuAction.logout) unawaited(vm.signOut());
        },
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

enum _UserMenuAction { logout }
