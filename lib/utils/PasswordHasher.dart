import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  Future<String> hashPassword(String password) async {
    final bytes = utf8.encode(password);
    final hash = await sha256.convert(bytes);

    return hash.toString();
  }

  Future<bool> verifyPassword(
      String inputPassword, String storedHashedPassword) async {
    final inputHash = await hashPassword(inputPassword);

    return inputHash == storedHashedPassword;
  }

  static String validate(String password) {
    if (password.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'A senha deve conter pelo menos uma letra maiúscula';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'A senha deve conter pelo menos uma letra minúscula';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'A senha deve conter pelo menos um número';
    }

    return '';
  }
}
