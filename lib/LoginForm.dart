import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PersonForm.dart';
import 'service/LocalDatabaseService.dart';
import 'service/PersonService.dart';
import 'utils/DialogUtils.dart';
import 'utils/PasswordHasher.dart';
import 'utils/PhoneNumberFormatter.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _phoneController = TextEditingController();
  late PhoneNumberFormatter _phoneNumberFormatter;
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
    _loadSavedPassword();
    _phoneNumberFormatter = PhoneNumberFormatter(_phoneController);
  }

  void _loadSavedPhone() async {
    try {
      final loginData = await LocalDatabaseService.getAllData(context);
      if (loginData.isNotEmpty) {
        setState(() {
          _phoneController.text = loginData[0]['phone'];
        });
      }
    } catch (e) {
      DialogUtils.showErrorDialog(
          context, 'Erro ao carregar a telefone salvo: $e');
    }
  }

  void _loadSavedPassword() async {
    try {
      final loginData = await LocalDatabaseService.getAllData(context);
      if (loginData.isNotEmpty) {
        setState(() {
          _passwordController.text = loginData[0]['password'];
        });
      }
    } catch (e) {
      DialogUtils.showErrorDialog(
          context, 'Erro ao carregar a senha salva: $e');
    }
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
                  Image.asset(
                    'assets/logo.png',
                    width: 250,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
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
                  SizedBox(height: 15),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown),
                        ),
                        labelStyle: TextStyle(color: Colors.brown),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: _obscureText ? Colors.brown : Colors.brown,
                          ),
                        ),
                      ),
                      obscureText: _obscureText,
                      cursorColor: Colors.brown,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _handleLogin,
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
                    child: Text('Login'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonForm(true),
                        ),
                      );
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
                    child: Text('Criar Conta'),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // buildLinkButton('Recuperar senha', () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) =>
                        //             SendCodeVerificationForm()),
                        //   );
                        // }),
                        // buildLinkButton('Política de Privacidade', () {
                        //   // Ação do botão Política de Privacidade
                        // }),
                        // buildLinkButton('Termos de Uso', () {
                        //   // Ação do botão Termos de Uso
                        // }),
                        const SizedBox(height: 5),
                        Text(
                          'Beta V. 1.0',
                          style: TextStyle(
                            color: Colors.brown[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLinkButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.brown[600],
            decoration: TextDecoration.underline,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    String phone = _phoneController.text;
    String phoneClean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    String password = _passwordController.text;

    if (phoneClean.isEmpty || password.isEmpty) {
      DialogUtils.showErrorDialog(context, 'Insira telefone e senha.');
      return;
    }

    PersonService personService =
        PersonService(accountData: {}, context: context);

    var personData = await personService.getPersonDataByPhone(phoneClean);

    if (personData != null) {
      String storedHashedPassword = personData['password'];

      final hasher = PasswordHasher();
      bool passwordMatch =
          await hasher.verifyPassword(password, storedHashedPassword);

      if (passwordMatch) {
        await LocalDatabaseService.insertData(context, phone, password);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setInt('personId', personData['id']);

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } else {
        DialogUtils.showErrorDialog(
            context, 'Credenciais inválidas. Tente novamente.');
      }
    } else {
      DialogUtils.showErrorDialog(context, 'Usuário não encontrado.');
    }
  }
}
