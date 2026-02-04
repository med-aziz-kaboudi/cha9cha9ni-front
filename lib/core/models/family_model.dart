class FamilyMember {
  final String id;
  final String name;
  final String email;
  final bool isOwner;
  final bool hasPendingRemoval;
  final String? pendingRemovalRequestId;
  final String? pendingRemovalStatus;
  final String? profilePictureUrl;

  FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.isOwner,
    this.hasPendingRemoval = false,
    this.pendingRemovalRequestId,
    this.pendingRemovalStatus,
    this.profilePictureUrl,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['email'] as String,
      email: json['email'] as String,
      isOwner: json['isOwner'] as bool? ?? false,
      hasPendingRemoval: json['hasPendingRemoval'] as bool? ?? false,
      pendingRemovalRequestId: json['pendingRemovalRequestId'] as String?,
      pendingRemovalStatus: json['pendingRemovalStatus'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isOwner': isOwner,
      'hasPendingRemoval': hasPendingRemoval,
      'pendingRemovalRequestId': pendingRemovalRequestId,
      'pendingRemovalStatus': pendingRemovalStatus,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  /// Create a copy with updated profile picture and/or name
  FamilyMember copyWith({String? profilePictureUrl, String? name}) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      email: email,
      isOwner: isOwner,
      hasPendingRemoval: hasPendingRemoval,
      pendingRemovalRequestId: pendingRemovalRequestId,
      pendingRemovalStatus: pendingRemovalStatus,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}

class FamilyModel {
  final String id;
  final String? name;
  final String? inviteCode;
  final bool isOwner;
  final DateTime? createdAt;
  final DateTime? joinedAt;
  final String? ownerName;
  final int? memberCount;
  final List<FamilyMember>? members;

  FamilyModel({
    required this.id,
    this.name,
    this.inviteCode,
    required this.isOwner,
    this.createdAt,
    this.joinedAt,
    this.ownerName,
    this.memberCount,
    this.members,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    // Extract owner name from nested owner object if present
    String? ownerName;
    if (json['owner'] != null && json['owner'] is Map) {
      ownerName = json['owner']['name'] as String?;
    } else if (json['ownerName'] != null) {
      ownerName = json['ownerName'] as String?;
    }

    // Parse members list
    List<FamilyMember>? members;
    if (json['members'] != null && json['members'] is List) {
      members = (json['members'] as List)
          .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList();
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
      members: members,
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
      'members': members?.map((m) => m.toJson()).toList(),
    };
  }
}

class RemovalRequest {
  final String id;
  final String familyId;
  final String? familyName;
  final String ownerName;
  final DateTime createdAt;

  RemovalRequest({
    required this.id,
    required this.familyId,
    this.familyName,
    required this.ownerName,
    required this.createdAt,
  });

  factory RemovalRequest.fromJson(Map<String, dynamic> json) {
    return RemovalRequest(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      familyName: json['familyName'] as String?,
      ownerName: json['ownerName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
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
