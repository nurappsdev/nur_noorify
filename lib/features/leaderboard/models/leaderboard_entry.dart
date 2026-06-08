/// One row of the leaderboard: a user from the `users` collection together
/// with their reward [points]. Built from the same document shape as the chat
/// people list, plus the `points` field awarded for sending check-in questions.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.points,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int points;

  /// Name to show, falling back to the email handle, then a generic label.
  String get resolvedName {
    final name = displayName.trim();
    if (name.isNotEmpty) return name;
    final handle = email.split('@').first.trim();
    if (handle.isNotEmpty) return handle;
    return 'Noorify user';
  }

  /// First letter for the avatar placeholder.
  String get initial {
    final source = resolvedName;
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final rawPoints = map['points'];
    final points = rawPoints is num ? rawPoints.toInt() : 0;
    return LeaderboardEntry(
      uid: uid,
      displayName: (map['display_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: () {
        final url = (map['photo_url'] ?? '').toString().trim();
        return url.isEmpty ? null : url;
      }(),
      points: points,
    );
  }
}
