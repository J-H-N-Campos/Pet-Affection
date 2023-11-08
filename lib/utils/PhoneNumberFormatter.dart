import 'package:flutter/material.dart';
import 'dart:math';

class PhoneNumberFormatter {
  final TextEditingController _phoneController;

  PhoneNumberFormatter(this._phoneController);

  void formatPhoneNumber(String value) {
    if (value.isEmpty) {
      return;
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    final masked = _applyMask(cleaned);

    _phoneController.text = masked;
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: masked.length),
    );
  }

  String _applyMask(String cleaned) {
    final maxLength = 15;
    var masked = '';
    var i = 0;

    if (cleaned.startsWith('1')) {
      masked = '(';
      for (; i < cleaned.length && i < 4; i++) {
        masked += cleaned[i];
      }
      if (i < cleaned.length) {
        masked += ')';
      }
      if (i < cleaned.length) {
        masked += ' ';
      }
      for (; i < cleaned.length && i < 7; i++) {
        masked += cleaned[i];
      }
    } else {
      for (; i < cleaned.length && i < 2; i++) {
        masked += cleaned[i];
      }
      if (i < cleaned.length) {
        masked += ' ';
      }
      for (; i < cleaned.length && i < 7; i++) {
        masked += cleaned[i];
      }
    }

    if (i < cleaned.length) {
      masked += '-';
    }

    for (; i < cleaned.length; i++) {
      masked += cleaned[i];
    }

    return masked.substring(0, min(masked.length, maxLength));
  }
}
