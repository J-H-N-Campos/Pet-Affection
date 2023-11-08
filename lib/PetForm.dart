import 'dart:convert';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PetList.dart';
import 'service/BreedService.dart';
import 'service/PersonService.dart';
import 'service/PetService.dart';
import 'service/UploadImageToServerService.dart';
import 'utils/DialogUtils.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'service/CloudVisionIAService.dart';

class PetForm extends StatefulWidget {
  final bool isEditing;
  final int? petId;

  PetForm({required this.isEditing, this.petId});

  @override
  _PetFormState createState() => _PetFormState();
}

class _PetFormState extends State<PetForm> {
  // Campos da etapa 1
  TextEditingController _nameController = TextEditingController();
  String? _selectedBreed;
  List<String> breedOptions = [];
  File? _selectedImage;

  // Campos da etapa 2
  String? _gender;
  String? _type;
  String? _rg;
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  DateTime? _birthDate;
  Color? _selectedColor;
  Color? _currentColor;

  // Variáveis de controle para exibir/ocultar etapas
  bool _showStep1 = true;
  bool _showStep2 = false;

  @override
  void initState() {
    super.initState();
    _loadBreedOptions();

    if (widget.isEditing) {
      _loadPetData();
      _loadPetPrimaryColor();
    }
  }

  Future<void> _loadPetPrimaryColor() async {
    if (widget.petId != null) {
      int id = int.parse(widget.petId.toString());

      PetService petService = PetService(accountData: {}, context: context);

      await Future.delayed(Duration(milliseconds: 100));

      Map<String, dynamic>? petData = await petService.getPetById(id);

      if (petData != null) {
        Map<String, dynamic> firstPetData = petData;

        if (firstPetData['primary_color'] != null) {
          String colorString = firstPetData['primary_color'];
          RegExp colorRegExp = RegExp(r'0x([A-Fa-f0-9]+)');
          Match? match = colorRegExp.firstMatch(colorString);
          if (match != null && match.groupCount >= 1) {
            String hexColor = match.group(1)!;
            int colorValue = int.parse(hexColor, radix: 16);
            setState(() {
              _selectedColor = Color(colorValue);
              _currentColor = _selectedColor;
            });
          }
        }
      }
    } else {
      if (_selectedImage != null) {
        final photoColor = _selectedImage;
        String imageBase64Color = '';
        String type = 'imageMyPet';
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? personId = prefs.getInt('personId');

        if (personId == null) {
          DialogUtils.showErrorDialog(context, 'Sessão não iniciada');
          return;
        }

        PersonService personService =
            PersonService(accountData: {}, context: context);

        Map<String, dynamic>? personData =
            await personService.getPersonDataByPersonId(personId);

        List<int> imageBytesColor = await photoColor!.readAsBytes();
        imageBase64Color = base64Encode(imageBytesColor);

        Map<String, dynamic> uploadData = {
          'base64Image': imageBase64Color,
          'type': type,
          'id': personId,
          'token': personData!['token'],
        };

        String? imagePathColor = await UploadImageToServerService(uploadData);

        String imageWebPathColor = imagePathColor!.replaceAll(
            "/var/www/html/repository/", "http://177.44.248.73/repository/");

        String finalImageWebPathColor = imageWebPathColor;

        final predominantColor = await CloudVisionIAService.getPredominantColor(
            finalImageWebPathColor);

        int red = predominantColor['red'];
        int green = predominantColor['green'];
        int blue = predominantColor['blue'];

        Color predominantColorPrimary = Color.fromARGB(255, red, green, blue);

        setState(() {
          _selectedColor = predominantColorPrimary;
        });
      }
    }
  }

  Future<void> _loadPetData() async {
    if (widget.petId != null) {
      int id = int.parse(widget.petId.toString());

      PetService petService = PetService(accountData: {}, context: context);

      await Future.delayed(Duration(milliseconds: 100));

      Map<String, dynamic>? petData = await petService.getPetById(id);

      if (petData != null) {
        Map<String, dynamic> firstPetData = petData;
        File? downloadedImage;

        if (firstPetData['photo'] != null) {
          String photolocal = firstPetData['photo'].split('/').last;
          String imageUrl = 'http://177.44.248.73/repository/$photolocal';
          downloadedImage = await _downloadImage(imageUrl);
        }

        if (firstPetData['breed_id'] != null) {
          var options = await BreedService()
              .getBreedNameById(context, firstPetData['breed_id']);
          setState(() {
            _selectedBreed = options!['name'];
          });
        }

        setState(() {
          _nameController.text = firstPetData['name'] ?? '';
          _gender = firstPetData['gender'] ?? '';
          _rg = firstPetData['rg'] != null ? firstPetData['rg'].toString() : '';
          weightController.text = (firstPetData['weight'] ?? 0.0).toString();
          heightController.text = (firstPetData['height'] ?? 0.0).toString();
          _type = firstPetData['type'] ?? '';
          _birthDate = firstPetData['birth_date'] != null
              ? firstPetData['birth_date']
              : null;
          if (downloadedImage != null) {
            _selectedImage = downloadedImage;
          }
        });
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

  Future<void> _loadBreedOptions() async {
    try {
      final options = await BreedService().getBreedOptionsFromDatabase(context);

      setState(() {
        breedOptions = options;
      });
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar as raças: $e');
    }
  }

  Future<void> _submitForm() async {
    final name = _nameController.text;
    final breedName = _selectedBreed ?? '';
    final photo = _selectedImage;
    final dtRegister = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String imageBase64 = '';
    String type = 'imageMyPet';

    if (_gender == null) {
      DialogUtils.showErrorDialog(context, 'Por favor, selecione um gênero.');
      return;
    }

    if (_type == null) {
      DialogUtils.showErrorDialog(context, 'Por favor, selecione um tipo.');
      return;
    }

    if (photo == null) {
      DialogUtils.showErrorDialog(context, 'Por favor, selecione uma foto.');
      return;
    }

    if (name.isEmpty) {
      DialogUtils.showErrorDialog(context, 'Por favor, insira um nome.');
      return;
    }

    if (breedName.isEmpty) {
      DialogUtils.showErrorDialog(context, 'Por favor, selecione uma raça.');
      return;
    }

    List<int> imageBytes = await photo.readAsBytes();
    imageBase64 = base64Encode(imageBytes);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? personId = prefs.getInt('personId');

    if (personId == null) {
      DialogUtils.showErrorDialog(context, 'Sessão não iniciada');
      return;
    }

    PersonService personService =
        PersonService(accountData: {}, context: context);

    // Espera um curto período antes de chamar getPersonDataByPersonId
    await Future.delayed(Duration(milliseconds: 100));

    Map<String, dynamic>? personData =
        await personService.getPersonDataByPersonId(personId);

    Map<String, dynamic> uploadData = {
      'base64Image': imageBase64,
      'type': type,
      'id': personId,
      'token': personData!['token'],
    };

    try {
      String? imagePath = await UploadImageToServerService(uploadData);

      String imageWebPath = imagePath!.replaceAll(
          "/var/www/html/repository/", "http://177.44.248.73/repository/");

      final cloudVisionService = CloudVisionIAService();

      String? finalImageWebPath = imageWebPath;
      final resultado =
          await cloudVisionService.isAnimalImageService(finalImageWebPath);

      if (resultado) {
        BreedService breedService = BreedService();
        int? breedId = await breedService.getBreedIdByName(context, breedName);

        Map<String, dynamic> accountData = {
          'dtRegister': dtRegister,
          'name': name,
          'breed_id': breedId,
          'person_id': personId,
          'photo': imagePath,
          'gender': _gender,
          'primary_color': _selectedColor.toString(),
          'rg': _rg,
          'type': _type,
          'weight': double.tryParse(weightController.text) ?? 0.0,
          'height': double.tryParse(heightController.text) ?? 0.0,
          'birth_date': _birthDate,
        };

        PetService petService =
            PetService(accountData: accountData, context: context);

        if (widget.petId == null) {
          await petService.createPet();
        } else {
          int id = int.parse(widget.petId.toString());

          Map<String, dynamic> updatedData = {
            'id': id,
            'name': name,
            'breed_id': breedId,
            'person_id': personId,
            'photo': imagePath,
            'gender': _gender,
            'primary_color': _selectedColor.toString(),
            'rg': _rg,
            'type': _type,
            'weight': double.tryParse(weightController.text) ?? 0.0,
            'height': double.tryParse(heightController.text) ?? 0.0,
            'birth_date': _birthDate,
          };

          await petService.updatePet(updatedData);
        }
      } else {
        DialogUtils.showErrorDialog(context, 'Animal não identificado na foto');
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao criar/editar o pet: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
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
        _birthDate = pickedDate;
      });
    }
  }

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

      await _loadPetPrimaryColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    var heightMaskFormatter = new MaskTextInputFormatter(
      mask: '#.##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    var weightMaskFormatter = new MaskTextInputFormatter(
      mask: '##.##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Cadastro/Edição do seu Pet'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
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
                  SizedBox(height: 20),
                  // Campos da etapa 1
                  if (_showStep1)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 160,
                            height: 160,
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
                        SizedBox(
                          width: 300,
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
                        SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<String>(
                            value: _selectedBreed,
                            onChanged: (newValue) {
                              setState(() {
                                _selectedBreed = newValue;
                              });
                            },
                            items: breedOptions.map((String breed) {
                              return DropdownMenuItem<String>(
                                value: breed,
                                child: Text(
                                  breed,
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: 'Raça',
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.brown),
                              ),
                              labelStyle: TextStyle(color: Colors.brown),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            dropdownColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 15),
                        // Botões da etapa 1
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PetList(
                                        petService: PetService(
                                          accountData: {},
                                          context: context,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.pressed)) {
                                        return const Color.fromRGBO(
                                            188, 170, 164, 1);
                                      }
                                      return Colors.brown[600]!;
                                    },
                                  ),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                ),
                                child: Text('Voltar'),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showStep1 = false;
                                    _showStep2 = true;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.pressed)) {
                                        return const Color.fromRGBO(
                                            188, 170, 164, 1);
                                      }
                                      return Colors.brown[600]!;
                                    },
                                  ),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                ),
                                child: Text('Continuar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  // Campos da etapa 2
                  if (_showStep2)
                    Column(
                      children: [
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Campo Gênero
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                onChanged: (newValue) {
                                  setState(() {
                                    _gender = newValue;
                                  });
                                },
                                items: ['Masculino', 'Feminino']
                                    .map((String gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(
                                      gender,
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                decoration: InputDecoration(
                                  labelText: 'Gênero',
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.brown),
                                  ),
                                  labelStyle: TextStyle(color: Colors.brown),
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                                dropdownColor: Colors.white,
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _type,
                                onChanged: (newValue) {
                                  setState(() {
                                    _type = newValue;
                                  });
                                },
                                items: ['Cachorro', 'Gato', 'Outro']
                                    .map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                decoration: InputDecoration(
                                  labelText: 'Tipo',
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.brown),
                                  ),
                                  labelStyle: TextStyle(color: Colors.brown),
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                                dropdownColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height: 20),
                            Expanded(
                              child: TextFormField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [weightMaskFormatter],
                                decoration: InputDecoration(
                                  labelText: 'Peso',
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.brown),
                                  ),
                                  labelStyle: TextStyle(color: Colors.brown),
                                ),
                                style: TextStyle(fontSize: 15),
                                cursorColor: Colors.brown,
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextFormField(
                                controller: heightController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [heightMaskFormatter],
                                decoration: InputDecoration(
                                  labelText: 'Altura',
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.brown),
                                  ),
                                  labelStyle: TextStyle(color: Colors.brown),
                                ),
                                style: TextStyle(fontSize: 15),
                                cursorColor: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) {
                            _rg = value;
                          },
                          decoration: InputDecoration(
                            labelText: 'RG',
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.brown),
                            ),
                            labelStyle: TextStyle(color: Colors.brown),
                          ),
                          style: TextStyle(fontSize: 15),
                          cursorColor: Colors.brown,
                          controller: TextEditingController(text: _rg),
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Selecione a Cor Primária'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor:
                                          _currentColor ?? Colors.black,
                                      onColorChanged: (color) {
                                        setState(() {
                                          _currentColor = color;
                                        });
                                      },
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        setState(() {
                                          _selectedColor = _currentColor;
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.brown),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedColor != null
                                  ? 'Cor Primária: ${_selectedColor!.value.toRadixString(16)}'
                                  : 'Selecionar Cor Primária',
                              style: TextStyle(
                                color: _selectedColor ?? Colors.brown,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            _selectDate(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.brown),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _birthDate != null
                                  ? 'Data de Nascimento: ${DateFormat('dd/MM/yyyy').format(_birthDate!)}'
                                  : 'Selecionar Data de Nascimento',
                              style: TextStyle(
                                color: Colors.brown,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Botões da etapa 2
                  if (_showStep2)
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () {
                              _submitForm();
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return const Color.fromRGBO(
                                        188, 170, 164, 1);
                                  }
                                  return Colors.brown[600]!;
                                },
                              ),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                            ),
                            child: Text('Finalizar'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showStep1 = true;
                                _showStep2 = false;
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return const Color.fromRGBO(
                                        188, 170, 164, 1);
                                  }
                                  return Colors.brown[600]!;
                                },
                              ),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
