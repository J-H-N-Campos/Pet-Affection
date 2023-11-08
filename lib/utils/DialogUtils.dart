import 'package:flutter/material.dart';

class DialogUtils {
  static void showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Ops, algo deu errado!',
            style: TextStyle(
              color: Colors.brown[600],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            errorMessage,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.brown[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return const Color.fromRGBO(188, 170, 164, 1);
                    }
                    return Colors.brown[600]!;
                  },
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  static void showSuccessDialog(
      BuildContext context, String successMessage, VoidCallback onContinue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sucesso!',
            style: TextStyle(
              color: Colors.brown[600],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            successMessage,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.brown[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          actions: [
            TextButton(
              onPressed: onContinue,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return const Color.fromRGBO(188, 170, 164, 1);
                    }
                    return Colors.brown[600]!;
                  },
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }
}
