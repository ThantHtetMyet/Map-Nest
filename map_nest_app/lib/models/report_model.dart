class ReportModel {
  final String id;
  final String userId;
  final String? userEmail;
  final String description;
  final String? screenName;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.description,
    this.screenName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'description': description,
      'screenName': screenName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      description: map['description'] ?? '',
      screenName: map['screenName'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

