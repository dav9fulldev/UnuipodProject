import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/onboarding_data.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(OnboardingData());

  void updateBasicInfo(
      String firstName, String lastName, String email, String password) {
    state = OnboardingData(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      profession: state.profession,
      incomeRange: state.incomeRange,
      goals: state.goals,
      categories: state.categories,
    );
  }

  void updateProfession(String profession) {
    state = OnboardingData(
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      password: state.password,
      profession: profession,
      incomeRange: state.incomeRange,
      goals: state.goals,
      categories: state.categories,
    );
  }

  void updateIncome(String incomeRange) {
    state = OnboardingData(
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      password: state.password,
      profession: state.profession,
      incomeRange: incomeRange,
      goals: state.goals,
      categories: state.categories,
    );
  }

  void updateGoals(List<String> goals) {
    state = OnboardingData(
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      password: state.password,
      profession: state.profession,
      incomeRange: state.incomeRange,
      goals: goals,
      categories: state.categories,
    );
  }

  void updateCategories(List<String> categories) {
    state = OnboardingData(
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      password: state.password,
      profession: state.profession,
      incomeRange: state.incomeRange,
      goals: state.goals,
      categories: categories,
    );
  }

  void reset() {
    state = OnboardingData();
  }
}
