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
      appBar: AppBar(title: Text(l10n.homeScreenTitle)),
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
