import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomeScreen.dart';
import 'MatchingPetsDisplayList.dart';
import 'service/CloudVisionIAService.dart';
import 'service/LostPetService.dart';
import 'service/PersonService.dart';
import 'service/UploadImageToServerService.dart';
import 'utils/DialogUtils.dart';

class FindMyPetForm extends StatefulWidget {
  @override
  _FindMyPetFormState createState() => _FindMyPetFormState();
}

class _FindMyPetFormState extends State<FindMyPetForm> {
  File? _photo;
  Color? _currentColor;
  Location location = Location();
  LocationData? _locationData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPetPrimaryColor();
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

  Future<void> _loadPetPrimaryColor() async {
    if (_photo != null && _currentColor == null) {
      final photoColor = _photo;
      String imageBase64Color = '';
      String type = 'findMyPet';

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
        _photo = File(pickedImage.path);
      });

      await _loadPetPrimaryColor();
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String imageBase64 = '';
      LocationData? locationData = _locationData;
      String type = 'findMyPet';

      if (_photo == null) {
        DialogUtils.showErrorDialog(context, 'Por favor, selecione uma foto.');
        return;
      } else {
        List<int> imageBytes = await _photo!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

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

      //envia a imagem para o servidor e retorna o caminho
      final resultado =
          await cloudVisionService.isAnimalImageService(finalImageWebPath);

      if (resultado) {
        String? imagePath = await UploadImageToServerService(uploadData);

        LostPetService lostPetService =
            LostPetService(accountData: {}, context: context);

        if (locationData == null) {
          DialogUtils.showErrorDialog(context,
              'Não foi possível encontrar a sua localizção, espere um pouco e envie a foto novamente');
        }

        List<Map<String, dynamic>> similarImages =
            await lostPetService.compareImagesToDatabase(
                personId, imagePath!, locationData as LocationData);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MatchingPetsDisplayList(similarPets: similarImages)));
      } else {
        DialogUtils.showErrorDialog(context, 'Animal não identificado na foto');
      }
    } catch (e) {
      throw Exception('Erro ao carregar a imagem para comparação.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Encontrar Pet Perdido'),
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
                  _photo == null
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
                              _photo!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                  if (!_isLoading)
                    ElevatedButton(
                      onPressed: _getImage,
                      child: Text('Tirar Foto'),
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
                    ),
                  SizedBox(height: 20),
                  if (_isLoading)
                    Center(
                      child: Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(148, 118, 10, 2)),
                          strokeWidth: 4.0,
                        ),
                      ),
                    ),
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
                          builder: (context) => HomeScreen(),
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
