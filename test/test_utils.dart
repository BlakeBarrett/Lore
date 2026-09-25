import 'package:mockito/mockito.dart';

/// Shared no-arg call recorder for widget tests. Lives in a helper (not in
/// another test file) so importing it from a test never pulls in a second
/// `main()` — no test file imports another test file.
class MockFunction extends Mock {
  void call();
}
