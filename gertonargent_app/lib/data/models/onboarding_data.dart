class OnboardingData {
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? profession;
  String? incomeRange;
  List<String> goals;
  List<String> categories;

  OnboardingData({
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.profession,
    this.incomeRange,
    this.goals = const [],
    this.categories = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'profession': profession,
      'income_range': incomeRange,
      'goals': goals,
      'spending_categories': categories,
    };
  }
}
