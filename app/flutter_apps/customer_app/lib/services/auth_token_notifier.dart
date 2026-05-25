import 'dart:async';

class AuthTokenEvent {
  const AuthTokenEvent({
    required this.reason,
    required this.version,
  });

  final String reason;
  final int version;
}

class AuthTokenNotifier {
  AuthTokenNotifier._();

  static final AuthTokenNotifier instance = AuthTokenNotifier._();

  final StreamController<AuthTokenEvent> _controller =
      StreamController<AuthTokenEvent>.broadcast();
  int _version = 0;

  Stream<AuthTokenEvent> get changes => _controller.stream;

  void notifyChanged({required String reason}) {
    if (_controller.isClosed) return;
    _controller.add(AuthTokenEvent(reason: reason, version: ++_version));
  }
}
