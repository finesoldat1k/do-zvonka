class BigBreak {
  final int id;
  final int afterLesson; // After which lesson this big break starts (1-based)
  final int durationMinutes; // Duration in minutes
  final String? name; // Optional name (e.g., "обед", "большая перемена")

  BigBreak({
    required this.id,
    required this.afterLesson,
    required this.durationMinutes,
    this.name,
  });

  factory BigBreak.create({
    required int afterLesson,
    required int durationMinutes,
    String? name,
  }) {
    return BigBreak(
      id: DateTime.now().millisecondsSinceEpoch,
      afterLesson: afterLesson,
      durationMinutes: durationMinutes,
      name: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'afterLesson': afterLesson,
      'durationMinutes': durationMinutes,
      'name': name,
    };
  }

  factory BigBreak.fromJson(Map<String, dynamic> json) {
    return BigBreak(
      id: json['id'] as int,
      afterLesson: json['afterLesson'] as int,
      durationMinutes: json['durationMinutes'] as int,
      name: json['name'] as String?,
    );
  }

  BigBreak copyWith({
    int? id,
    int? afterLesson,
    int? durationMinutes,
    String? name,
  }) {
    return BigBreak(
      id: id ?? this.id,
      afterLesson: afterLesson ?? this.afterLesson,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      name: name ?? this.name,
    );
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return 'большая перемена после $afterLesson урока';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BigBreak && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}