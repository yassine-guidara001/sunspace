class AssociationModel {
  const AssociationModel({
    required this.id,
    required this.documentId,
    required this.name,
    required this.description,
    required this.email,
    required this.phone,
    required this.website,
    required this.adminName,
    required this.adminEmail,
    required this.adminId,
    required this.budgetValue,
    required this.currency,
    required this.budgetLabel,
    required this.verified,
    required this.membersCount,
  });

  final int id;
  final String documentId;
  final String name;
  final String description;
  final String email;
  final String phone;
  final String website;
  final String adminName;
  final String adminEmail;
  final int? adminId;
  final double budgetValue;
  final String currency;
  final String budgetLabel;
  final bool verified;
  final int membersCount;
}

class UserOption {
  const UserOption({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;
}

class AssociationFormPayload {
  const AssociationFormPayload({
    required this.name,
    required this.description,
    required this.email,
    required this.phone,
    required this.website,
    required this.budget,
    required this.adminId,
  });

  final String name;
  final String description;
  final String email;
  final String phone;
  final String website;
  final double budget;
  final int? adminId;

  Map<String, dynamic> toStrapiData() {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
      'website': website,
      'budget': budget,
    };

    if (adminId != null) {
      data['admin'] = adminId;
    }

    data.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    return data;
  }
}

class AssociationsLoadResult {
  const AssociationsLoadResult({
    required this.associations,
    required this.users,
  });

  final List<AssociationModel> associations;
  final List<UserOption> users;
}
