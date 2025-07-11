class Group {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final int userCount;
  final DateTime dateCreated;
  final DateTime dateModified;
  final bool isActive;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.userCount,
    required this.dateCreated,
    required this.dateModified,
    required this.isActive,
  });

  Group copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? permissions,
    int? userCount,
    DateTime? dateCreated,
    DateTime? dateModified,
    bool? isActive,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      userCount: userCount ?? this.userCount,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
      'user_count': userCount,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      userCount: json['user_count'] as int? ?? 0,
      dateCreated: DateTime.parse(json['date_created'] as String),
      dateModified: DateTime.parse(json['date_modified'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static final Group empty = Group(
    id: '',
    name: '',
    description: '',
    permissions: const [],
    userCount: 0,
    dateCreated: DateTime.now(),
    dateModified: DateTime.now(),
    isActive: true,
  );
}
