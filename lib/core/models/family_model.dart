class FamilyModel {
  final String id;
  final String? name;
  final String? inviteCode;
  final bool isOwner;
  final DateTime? createdAt;
  final DateTime? joinedAt;
  final String? ownerName;
  final int? memberCount;

  FamilyModel({
    required this.id,
    this.name,
    this.inviteCode,
    required this.isOwner,
    this.createdAt,
    this.joinedAt,
    this.ownerName,
    this.memberCount,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    // Extract owner name from nested owner object if present
    String? ownerName;
    if (json['owner'] != null && json['owner'] is Map) {
      ownerName = json['owner']['name'] as String?;
    } else if (json['ownerName'] != null) {
      ownerName = json['ownerName'] as String?;
    }
    
    return FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      inviteCode: json['inviteCode'] as String?,
      isOwner: json['isOwner'] as bool,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      ownerName: ownerName,
      memberCount: json['memberCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'isOwner': isOwner,
      'createdAt': createdAt?.toIso8601String(),
      'joinedAt': joinedAt?.toIso8601String(),
      'ownerName': ownerName,
      'memberCount': memberCount,
    };
  }
}

class CreateFamilyRequest {
  final String? name;

  CreateFamilyRequest({this.name});

  Map<String, dynamic> toJson() {
    return {
      if (name != null && name!.isNotEmpty) 'name': name,
    };
  }
}

class JoinFamilyRequest {
  final String inviteCode;

  JoinFamilyRequest({required this.inviteCode});

  Map<String, dynamic> toJson() {
    return {
      'inviteCode': inviteCode,
    };
  }
}
