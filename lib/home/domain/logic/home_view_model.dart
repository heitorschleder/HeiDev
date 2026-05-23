import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'home_state.dart';

@injectable
final class HomeViewModel {
  final ValueNotifier<HomeState> _state = ValueNotifier(HomeState.initial());

  ValueListenable<HomeState> get state => _state;

  void init() {}

  void onDisposed() => _state.dispose();
}
