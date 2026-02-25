/// Minimal auth user abstraction for routing.
/// Replace with your own AuthUser when implementing API-based auth.
abstract class BaseAuthUser {
  bool get loggedIn;
  String? get uid;
}

/// A simple unauthenticated user stub.
class UnauthenticatedUser extends BaseAuthUser {
  @override
  bool get loggedIn => false;

  @override
  String? get uid => null;
}
