import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final String? website;
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final Map<String, dynamic> preferences;
  final List<String> circleIds;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    this.location,
    this.website,
    required this.joinedAt,
    this.lastSeen,
    this.isOnline = false,
    this.preferences = const {},
    this.circleIds = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoURL'],
      bio: data['bio'],
      location: data['location'],
      website: data['website'],
      joinedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['updatedAt'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] ?? false,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      circleIds: List<String>.from(data['circleIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoURL': photoUrl,
      'bio': bio,
      'location': location,
      'website': website,
      'createdAt': Timestamp.fromDate(joinedAt),
      'updatedAt': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
      'preferences': preferences,
      'circleIds': circleIds,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    String? location,
    String? website,
    DateTime? joinedAt,
    DateTime? lastSeen,
    bool? isOnline,
    Map<String, dynamic>? preferences,
    List<String>? circleIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
      circleIds: circleIds ?? this.circleIds,
    );
  }

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get initials {
    if (name.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get lastSeenText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen!.day}/${lastSeen!.month}/${lastSeen!.year}';
    }
  }

  // Preference helpers
  bool get darkMode => preferences['darkMode'] ?? false;
  bool get notificationsEnabled => preferences['notificationsEnabled'] ?? true;
  String get language => preferences['language'] ?? 'en';
  bool get showOnlineStatus => preferences['showOnlineStatus'] ?? true;
  bool get allowDirectMessages => preferences['allowDirectMessages'] ?? true;
}

// App preferences model
class AppPreferences {
  final String userId;
  final String theme; // 'light', 'dark', 'system'
  final String language;
  final bool showOnlineStatus;
  final bool allowDirectMessages;
  final bool autoDownloadMedia;
  final bool reducedMotion;
  final double fontSize;
  final bool soundEnabled;
  final bool vibrationEnabled;

  AppPreferences({
    required this.userId,
    this.theme = 'system',
    this.language = 'en',
    this.showOnlineStatus = true,
    this.allowDirectMessages = true,
    this.autoDownloadMedia = true,
    this.reducedMotion = false,
    this.fontSize = 1.0,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  factory AppPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppPreferences(
      userId: doc.id,
      theme: data['theme'] ?? 'system',
      language: data['language'] ?? 'en',
      showOnlineStatus: data['showOnlineStatus'] ?? true,
      allowDirectMessages: data['allowDirectMessages'] ?? true,
      autoDownloadMedia: data['autoDownloadMedia'] ?? true,
      reducedMotion: data['reducedMotion'] ?? false,
      fontSize: (data['fontSize'] ?? 1.0).toDouble(),
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'theme': theme,
      'language': language,
      'showOnlineStatus': showOnlineStatus,
      'allowDirectMessages': allowDirectMessages,
      'autoDownloadMedia': autoDownloadMedia,
      'reducedMotion': reducedMotion,
      'fontSize': fontSize,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  AppPreferences copyWith({
    String? theme,
    String? language,
    bool? showOnlineStatus,
    bool? allowDirectMessages,
    bool? autoDownloadMedia,
    bool? reducedMotion,
    double? fontSize,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return AppPreferences(
      userId: userId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      autoDownloadMedia: autoDownloadMedia ?? this.autoDownloadMedia,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      fontSize: fontSize ?? this.fontSize,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
