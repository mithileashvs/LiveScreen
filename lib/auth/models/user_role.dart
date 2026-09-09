/// The three roles LiveScreen currently supports (PART 11). Kept as a
/// plain enum — adding a real backend later only means swapping what
/// produces a [UserRole], never how the rest of the app consumes one.
enum UserRole { user, theatreAdmin, producer }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.theatreAdmin:
        return 'Theatre Admin';
      case UserRole.producer:
        return 'Producer';
    }
  }
}
