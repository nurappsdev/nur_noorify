/// A lightweight view of a user document from the `users` collection,
/// used to render the chat people list.
class ChatUser {
  const ChatUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

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

  factory ChatUser.fromMap(String uid, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return ChatUser(
      uid: uid,
      displayName: (map['display_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: () {
        final url = (map['photo_url'] ?? '').toString().trim();
        return url.isEmpty ? null : url;
      }(),
    );
  }
}
