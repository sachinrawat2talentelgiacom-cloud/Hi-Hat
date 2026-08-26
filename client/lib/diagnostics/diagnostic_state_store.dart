import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiagnosticState {
  const DiagnosticState({this.lastCommand, this.lastError});
  final String? lastCommand;
  final String? lastError;
}

class DiagnosticStateStore extends StateNotifier<DiagnosticState> {
  DiagnosticStateStore() : super(const DiagnosticState());
  void command(String value) => state = DiagnosticState(lastCommand: value);
  void error(String value) =>
      state = DiagnosticState(lastCommand: state.lastCommand, lastError: value);
  void reset() => state = const DiagnosticState();
}

final diagnosticStateProvider =
    StateNotifierProvider<DiagnosticStateStore, DiagnosticState>(
      (_) => DiagnosticStateStore(),
    );
