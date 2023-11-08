import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pet_affection/HomeScreen.dart';
import 'package:pet_affection/utils/PasswordHasher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/PersonService.dart';
import 'service/UploadImageToServerService.dart';
import 'utils/CpfCnpjValidator.dart';
import 'utils/DialogUtils.dart';
import 'utils/EmailValidator.dart';
import 'utils/PhoneNumberFormatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PersonForm extends StatefulWidget {
  final bool createPerson;

  PersonForm(this.createPerson);

  @override
  _PersonFormState createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cpfcnpjController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime? _selectedDate;
  final List<String> _genderOptions = ['Masculino', 'Feminino', 'Outro'];
  String? _selectedGender;
  File? _selectedImage;
  late PhoneNumberFormatter _phoneNumberFormatter;
  bool _obscureText = true;

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await showModalBottomSheet<XFile>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.brown[900]),
                title: Text('Escolher da Galeria'),
                onTap: () async {
                  Navigator.pop(context,
                      await picker.pickImage(source: ImageSource.gallery));
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.brown[900]),
                title: Text('Tirar Foto'),
                onTap: () async {
                  Navigator.pop(context,
                      await picker.pickImage(source: ImageSource.camera));
                },
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!widget.createPerson) {
      final ThemeData theme = Theme.of(context);

      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1940),
        lastDate: DateTime.now(),
        locale: const Locale('pt', 'BR'),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: Colors.brown[600],
                  onPrimary: theme.colorScheme.onBackground,
                ),
                dialogBackgroundColor: theme.dialogBackgroundColor),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneNumberFormatter = PhoneNumberFormatter(_phoneController);
    _selectedGender = _genderOptions[2];

    if (!widget.createPerson) {
      _loadPersonData();
    }
  }

  Future<void> _loadPersonData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? personId = prefs.getInt('personId');

    if (personId != null) {
      PersonService personService =
          PersonService(accountData: {}, context: context);

      // Espera um curto período antes de chamar getPersonDataByPersonId
      await Future.delayed(Duration(milliseconds: 100));

      Map<String, dynamic>? personData =
          await personService.getPersonDataByPersonId(personId);

      if (personData != null) {
        setState(() {
          _nameController.text = personData['name'] ?? '';
          _emailController.text = personData['email'] ?? '';
          _cpfcnpjController.text = personData['cpf_cnpj'] ?? '';
          _phoneController.text = personData['phone'] ?? '';
          _selectedDate = personData['birth_date'] != null
              ? DateTime.parse(personData['birth_date'])
              : null;
          _selectedGender = personData['gender'] ?? _selectedGender;
        });

        if (personData['photo'] != null) {
          String photolocal = personData['photo'].split('/').last;
          String imageUrl = 'http://177.44.248.73/repository/$photolocal';
          File downloadedImage = await _downloadImage(imageUrl);
          setState(() {
            _selectedImage = downloadedImage;
          });
        }
      }
    }
  }

  Future<File> _downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      String imageName = imageUrl.split('/').last;

      Directory appDir = await _requestAppDocumentsDirectory();
      final filePath = '${appDir.path}/$imageName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } else {
      throw Exception('Falha ao baixar a imagem');
    }
  }

  Future<Directory> _requestAppDocumentsDirectory() async {
    WidgetsFlutterBinding.ensureInitialized();
    Directory appDir = await getApplicationDocumentsDirectory();
    return appDir;
  }

  Future<void> _submitForm() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final dtRegister = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final cpfcnpj = _cpfcnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final gender = _selectedGender!;
    DateTime? birthdate;
    String? imageBase64;

    if (_selectedDate != null) {
      birthdate = _selectedDate;
    }

    if (_selectedImage != null) {
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      imageBase64 = base64Encode(imageBytes);
    }

    if (!CpfCnpjValidator.validate(cpfcnpj)) {
      DialogUtils.showErrorDialog(context, 'CPF/CNPJ inválido');
      return;
    }

    Map<String, dynamic> accountData = {
      'name': name,
      'cpf_cnpj': cpfcnpj,
      'email': email,
      'password': password,
      'phone': phone,
      'dtRegister': dtRegister,
      'gender': gender,
      'birthdate': birthdate,
      'photo': imageBase64,
    };

    if (widget.createPerson) {
      PersonService personService =
          PersonService(accountData: accountData, context: context);

      String validate = PasswordHasher.validate(password);

      if (validate.isNotEmpty) {
        return DialogUtils.showErrorDialog(context, validate);
      }
      //cria a pessoa
      await personService.createPerson();
    }
    //edição
    else {
      //pega sessão do usuario
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? personId = prefs.getInt('personId');

      if (personId != null) {
        PersonService personService =
            PersonService(accountData: accountData, context: context);

        // Obtém os dados da pessoa com o mesmo ID da sessão
        Map<String, dynamic>? personData =
            await personService.getPersonDataByPersonId(personId);

        if (personData != null) {
          // Atualiza os campos da pessoa com os novos dados

          personData['name'] = name;
          personData['cpf_cnpj'] = cpfcnpj;
          personData['email'] = email;
          personData['phone'] = phone;
          personData['gender'] = gender;
          personData['birth_date'] = birthdate;

          if (imageBase64 != null) {
            String type = 'imagePerson';

            Map<String, dynamic> uploadData = {
              'base64Image': imageBase64,
              'type': type,
              'id': personId,
              'token': personData['token'],
            };

            String? imagePath = await UploadImageToServerService(uploadData);

            if (imagePath != null) {
              personData['photo'] = imagePath;
              String photolocal = imagePath.split('/').last;
              String imageUrl = 'http://177.44.248.73/repository/$photolocal';
              File downloadedImage = await _downloadImage(imageUrl);
              setState(() {
                _selectedImage = downloadedImage;
              });
            } else {}
          }

          if (password.isNotEmpty) {
            String validate = PasswordHasher.validate(password);

            if (validate.isNotEmpty) {
              return DialogUtils.showErrorDialog(context, validate);
            }

            final bytes = utf8.encode(password);
            final hash = await sha256.convert(bytes);
            String hashedPassword = hash.toString();

            personData['password'] = hashedPassword;
          }

          // Atualiza a pessoa e o usuario no banco de dados
          await personService.updatePerson(personData);

          // Mostra a mensagem de sucesso e redireciona para a HomeScreen
          DialogUtils.showSuccessDialog(
            context,
            'Conta editada com sucesso!',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(),
                ),
              );
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(!widget.createPerson
            ? 'Edição dos seus Dados'
            : 'Cadastro dos seus Dados'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        automaticallyImplyLeading: !widget.createPerson,
        leading: !widget.createPerson
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(),
                    ),
                  );
                },
              )
            : null,
      ),
      body: Container(
        padding: EdgeInsets.only(top: 1),
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
                children: [
                  if (!widget.createPerson)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              )
                            : GestureDetector(
                                onTap: _pickImage,
                                child: Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.grey),
                              ),
                      ),
                    ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.brown),
                              ),
                              labelStyle: TextStyle(color: Colors.brown),
                            ),
                            style: TextStyle(fontSize: 15),
                            cursorColor: Colors.brown,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _cpfcnpjController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'CPF/CNPJ',
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.brown),
                              ),
                              labelStyle: TextStyle(color: Colors.brown),
                            ),
                            style: TextStyle(fontSize: 15),
                            cursorColor: Colors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'E-mail',
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.brown),
                              ),
                              labelStyle: TextStyle(color: Colors.brown),
                            ),
                            style: TextStyle(fontSize: 15),
                            cursorColor: Colors.brown,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          width: 150,
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
                      ),
                    ],
                  ),
                  Row(children: [
                    if (widget.createPerson)
                      Expanded(
                        child: SizedBox(
                          width: 150,
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
                                  color: _obscureText
                                      ? Colors.brown
                                      : Colors.brown,
                                ),
                              ),
                            ),
                            obscureText: _obscureText,
                            cursorColor: Colors.brown,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    if (!widget.createPerson)
                      Expanded(
                        child: SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Troque sua senha',
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
                                  color: _obscureText
                                      ? Colors.brown
                                      : Colors.brown,
                                ),
                              ),
                            ),
                            obscureText: _obscureText,
                            cursorColor: Colors.brown,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    SizedBox(width: 10),
                  ]),
                  Column(
                    children: [
                      if (!widget.createPerson)
                        SizedBox(
                          child: GestureDetector(
                            onTap: () {
                              _selectDate(context);
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _selectedDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_selectedDate!)
                                          .toString()
                                      : '',
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Data de Nascimento',
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.brown),
                                  ),
                                  labelStyle: TextStyle(color: Colors.brown),
                                ),
                                style: TextStyle(fontSize: 15),
                                cursorColor: Colors.brown,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 10),
                  if (!widget.createPerson)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                          items: _genderOptions.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender,
                                  style: TextStyle(color: Colors.black)),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: 'Gênero',
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.brown),
                            ),
                            labelStyle: TextStyle(color: Colors.brown),
                          ),
                          style: TextStyle(fontSize: 15, color: Colors.brown),
                        ),
                      ),
                    ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_phoneController.text.trim().isEmpty) {
                          DialogUtils.showErrorDialog(
                              context, 'Telefone não pode ser vazio');
                        } else if (widget.createPerson &&
                            _passwordController.text.trim().isEmpty) {
                          DialogUtils.showErrorDialog(
                              context, 'Senha não pode ser vazia');
                        } else if (_emailController.text.trim().isEmpty) {
                          DialogUtils.showErrorDialog(
                              context, 'E-mail não pode ser vazio');
                        } else if (_nameController.text.isEmpty) {
                          DialogUtils.showErrorDialog(
                              context, 'Nome não pode ser vazio');
                        } else if (_cpfcnpjController.text.isEmpty) {
                          DialogUtils.showErrorDialog(
                              context, 'CPF/CNPJ não pode ser vazio');
                        } else if (!CpfCnpjValidator.validate(
                            _cpfcnpjController.text)) {
                          DialogUtils.showErrorDialog(
                              context, 'CPF/CNPJ inválido');
                        } else if (!EmailValidator.isValidEmail(
                            _emailController.text)) {
                          DialogUtils.showErrorDialog(
                              context, 'E-mail inválido');
                        } else {
                          _submitForm();
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return const Color.fromRGBO(188, 170, 164, 1);
                            }
                            return Colors.brown[600]!;
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      child: Text(
                          widget.createPerson ? 'Criar conta' : 'Continuar'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.createPerson) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()));
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return const Color.fromRGBO(188, 170, 164, 1);
                            }
                            return Colors.brown[600]!;
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      child: Text('Voltar'),
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
}
