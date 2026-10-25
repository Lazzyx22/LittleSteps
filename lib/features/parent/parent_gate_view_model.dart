import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class ParentGateViewModel extends ChangeNotifier {
  ParentGateViewModel(this.onUnlocked)
    : a = 12 + Random().nextInt(12),
      b = 7 + Random().nextInt(9);
  final VoidCallback onUnlocked;
  final int a, b;
  Timer? _hold;
  bool held = false;
  String feedback = '';
  void startHold() {
    cancelHold();
    _hold = Timer(const Duration(seconds: 2), () {
      held = true;
      notifyListeners();
    });
  }

  void cancelHold() => _hold?.cancel();
  void submit(String answer) {
    if (!held) return;
    if (int.tryParse(answer.trim()) == a + b) {
      onUnlocked();
    } else {
      feedback = 'Please try that sum again.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    cancelHold();
    super.dispose();
  }
}
