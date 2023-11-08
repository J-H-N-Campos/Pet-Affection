import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:pet_affection/MyLostPetList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/BreedService.dart';
import 'service/LostPetService.dart';
import 'service/PersonService.dart';
import 'service/UploadImageToServerService.dart';
import 'service/CloudVisionIAService.dart';
import 'utils/DialogUtils.dart';

class MyLostPetForm extends StatefulWidget {
  @override
  _MyLostPetFormState createState() => _MyLostPetFormState();
}

class _MyLostPetFormState extends State<MyLostPetForm> {
  File? _image;
  Location location = Location();
  LocationData? _locationData;
  String? _selectedBreed;
  List<String> breedOptions = [];
  String? _rg;
  String? _name;
  String? _gender;
  Color? _currentColor;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadBreedOptions();
  }

  Future<void> _loadPetPrimaryColor() async {
    if (_image != null && _currentColor == null) {
      final photoColor = _image;
      String imageBase64Color = '';
      String type = 'lostPet';
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
        _currentColor = predominantColorPrimary;
      });
    }
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

  Future<void> _getCurrentLocation() async {
    try {
      final currentLocation = await location.getLocation();
      setState(() {
        _locationData = currentLocation;
      });
    } catch (e) {
      print('Erro ao obter a localização: $e');
    }
  }

  void _getImage() async {
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
        _image = File(pickedImage.path);
        _currentColor = null;
      });

      await _loadPetPrimaryColor();
    }
  }

  Future<void> _submitForm() async {
    final dtRegister = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final photo = _image;
    String imageBase64 = '';
    String type = 'lostPet';
    final breedName = _selectedBreed ?? '';

    if (photo == null) {
      DialogUtils.showErrorDialog(context, 'Por favor, selecione uma foto.');
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

    String? imagePath = await UploadImageToServerService(uploadData);
    String imageWebPath = imagePath!.replaceAll(
        "/var/www/html/repository/", "http://177.44.248.73/repository/");

    String? finalImageWebPath = imageWebPath;

    final cloudVisionService = CloudVisionIAService();

    final resultado =
        await cloudVisionService.isAnimalImageService(finalImageWebPath);

    if (resultado) {
      BreedService breedService = BreedService();
      int? breedId = await breedService.getBreedIdByName(context, breedName);

      Map<String, dynamic> accountData = {
        'dtRegister': dtRegister,
        'breed_id': breedId,
        'person_id': personId,
        'photo': imagePath,
        'gender': _gender,
        'primary_color': _currentColor.toString(),
        'rg': _rg,
        'latitude': _locationData!.latitude,
        'longitude': _locationData!.longitude,
        'name': _name
      };

      LostPetService lostService =
          LostPetService(accountData: accountData, context: context);

      await lostService.createLostPet();
    } else {
      DialogUtils.showErrorDialog(context, 'Animal não identificado na foto');
    }
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar Cor Primária'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor ?? Colors.black,
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
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Capturar Foto do Pet Perdido'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyLostPetList(
                    lostPetService:
                        LostPetService(accountData: {}, context: context)),
              ),
            );
          },
        ),
      ),
      body: Form(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _image == null
                      ? Text('Nenhuma imagem selecionada.')
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Image.file(
                              _image!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                  SizedBox(height: 16),
                  _locationData != null
                      ? Text(
                          'Localização: ${_locationData!.latitude}, ${_locationData!.longitude}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      : Text(
                          'Localização não disponível.',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  ElevatedButton(
                    onPressed: _getImage,
                    child: Text('Tirar Foto'),
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
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      onChanged: (value) {
                        _name = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown),
                        ),
                        labelStyle: TextStyle(color: Colors.brown),
                      ),
                      style: TextStyle(fontSize: 15),
                      cursorColor: Colors.brown,
                      controller: TextEditingController(text: _name),
                    ),
                  ),
                  SizedBox(height: 20),
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
                  SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
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
                  ),
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      onChanged: (newValue) {
                        setState(() {
                          _gender = newValue;
                        });
                      },
                      items: ['Masculino', 'Feminino'].map((String gender) {
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
                  SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: GestureDetector(
                      onTap: _showColorPickerDialog,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.brown),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentColor != null
                              ? 'Cor Primária: ${_currentColor!.value.toRadixString(16)}'
                              : 'Selecionar Cor Primária',
                          style: TextStyle(
                            color: _currentColor ?? Colors.brown,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      _submitForm();
                    },
                    child: Text('Enviar Foto'),
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
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyLostPetList(
                              lostPetService: LostPetService(
                                  accountData: {}, context: context)),
                        ),
                      );
                    },
                    child: Text('Voltar'),
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
