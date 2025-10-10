class SharedUser {
  static String? firstName;
  static String? lastName;
  static String? email;
  static String? contactNumber;
  static String? profileId;
  static List<dynamic>? roles;
  static bool godAdmin = false;

  static void setUserDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String contactNumber,
    required String profileId,
    required List<dynamic> roles,
    required bool godAdmin,
  }) {
    SharedUser.firstName = firstName;
    SharedUser.lastName = lastName;
    SharedUser.email = email;
    SharedUser.contactNumber = contactNumber;
    SharedUser.profileId = profileId;
    SharedUser.roles = roles;
    SharedUser.godAdmin = godAdmin;
  }

  static void clear() {
    firstName = null;
    lastName = null;
    email = null;
    contactNumber = null;
    profileId = null;
    roles = null;
    godAdmin = false;
  }
}
