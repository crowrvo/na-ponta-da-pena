enum HouseholdRole {
  member,
  owner;

  static HouseholdRole fromJson(Object? value) => switch (value) {
    'member' => HouseholdRole.member,
    'owner' => HouseholdRole.owner,
    _ => throw const FormatException('Invalid household role.'),
  };
}

class HouseholdSummary {
  const HouseholdSummary({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final HouseholdRole role;

  @override
  bool operator ==(Object other) =>
      other is HouseholdSummary &&
      other.id == id &&
      other.name == name &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, name, role);
}
