class CpfCnpjValidator {
  static bool validate(String input) {
    final cleaned = input.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length == 11) {
      if (RegExp(r'^(\d)\1*$').hasMatch(cleaned)) {
        return false;
      }

      int sum = 0;
      for (int i = 0; i < 9; i++) {
        sum += int.parse(cleaned[i]) * (10 - i);
      }
      int digit1 = 11 - (sum % 11);
      if (digit1 >= 10) {
        digit1 = 0;
      }
      if (int.parse(cleaned[9]) != digit1) {
        return false;
      }

      sum = 0;
      for (int i = 0; i < 10; i++) {
        sum += int.parse(cleaned[i]) * (11 - i);
      }
      int digit2 = 11 - (sum % 11);
      if (digit2 >= 10) {
        digit2 = 0;
      }
      if (int.parse(cleaned[10]) != digit2) {
        return false;
      }

      return true;
    } else if (cleaned.length == 14) {
      if (RegExp(r'^(\d)\1*$').hasMatch(cleaned)) {
        return false;
      }

      int sum = 0;
      List<int> weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      for (int i = 0; i < 12; i++) {
        sum += int.parse(cleaned[i]) * weights[i];
      }
      int digit1 = sum % 11 < 2 ? 0 : 11 - sum % 11;
      if (int.parse(cleaned[12]) != digit1) {
        return false;
      }

      sum = 0;
      weights.insert(0, 6);
      for (int i = 0; i < 13; i++) {
        sum += int.parse(cleaned[i]) * weights[i];
      }
      int digit2 = sum % 11 < 2 ? 0 : 11 - sum % 11;
      if (int.parse(cleaned[13]) != digit2) {
        return false;
      }

      return true;
    } else {
      return false;
    }
  }
}
