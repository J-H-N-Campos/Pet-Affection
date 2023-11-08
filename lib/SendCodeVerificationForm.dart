import 'package:flutter/material.dart';
import 'VerificationCodeForm.dart';
import 'utils/DialogUtils.dart';
import 'utils/PhoneNumberFormatter.dart';

class SendCodeVerificationForm extends StatefulWidget {
  const SendCodeVerificationForm({Key? key}) : super(key: key);

  @override
  _SendCodeVerificationFormState createState() =>
      _SendCodeVerificationFormState();
}

class _SendCodeVerificationFormState extends State<SendCodeVerificationForm> {
  final TextEditingController _phoneController = TextEditingController();
  late PhoneNumberFormatter _phoneNumberFormatter;

  @override
  void initState() {
    super.initState();
    _phoneNumberFormatter = PhoneNumberFormatter(_phoneController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        _phoneNumberFormatter.formatPhoneNumber(value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Digite seu DDI, DDD e telefone.',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown),
                        ),
                        labelStyle: TextStyle(color: Colors.brown),
                      ),
                      style: TextStyle(fontSize: 15),
                      cursorColor: Colors.brown,
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_phoneController.text.trim().isEmpty) {
                        DialogUtils.showErrorDialog(
                            context, 'Campo de telefone não pode estar vazio');

                        return;
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VerificationCodeForm()),
                        );
                      }
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
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                    child: Text('Enviar SMS com o Código de Verificação'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
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
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                    child: Text('Voltar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
