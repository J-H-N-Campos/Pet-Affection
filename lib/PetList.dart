import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomeScreen.dart';
import 'PetForm.dart';
import 'service/BreedService.dart';
import 'service/PetService.dart';
import 'utils/DialogUtils.dart';

class PetList extends StatefulWidget {
  final PetService petService;

  PetList({required this.petService});

  @override
  _PetListState createState() => _PetListState();
}

class _PetListState extends State<PetList> {
  List<Map<String, dynamic>> petDataList = [];
  List<File> downloadedImages = [];
  String nameFilter = '';
  String typeFilter = '';
  int pageSize = 10;
  int currentPage = 1;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPets();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200) {
      currentPage++;
      _loadPets();
    }
  }

  String _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    var age = currentDate.year - birthDate.year;

    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }

    return age.toString();
  }

  Future<void> _loadPets() async {
    try {
      if (petDataList.isNotEmpty) {
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int personId = prefs.getInt('personId') ?? 0;

      int startIndex = (currentPage - 1) * pageSize;
      int endIndex = startIndex + pageSize;

      var petsResponse = await widget.petService.getPetsDataByPerson(
        personId,
        startIndex,
        endIndex,
      );

      if (petsResponse != null) {
        final List<Map<String, dynamic>> pets =
            petsResponse as List<Map<String, dynamic>>;

        for (var pet in pets) {
          final photoUrl = pet['photo'] as String? ?? '';
          String photolocal = photoUrl.split('/').last;
          String imageUrl = 'http://177.44.248.73/repository/$photolocal';

          File downloadedImage = await _downloadImage(imageUrl);
          downloadedImages.add(downloadedImage);

          final breedId = pet['breed_id'] as int;
          final breedData =
              await BreedService().getBreedNameById(context, breedId);

          if (breedData != null) {
            final breedName = breedData['name'] as String;

            pet['breedName'] = breedName;
          }
        }

        setState(() {
          petDataList.addAll(pets);
        });
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao carregar os pets: $e');
    }
  }

  // Future<void> _loadPets() async {
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     int personId = prefs.getInt('personId') ?? 0;

  //     await Future.delayed(Duration(milliseconds: 100));

  //     var petsResponse = await widget.petService.getPetsDataByPerson(personId);

  //     if (petsResponse != null) {
  //       final List<Map<String, dynamic>> pets =
  //           petsResponse as List<Map<String, dynamic>>;

  //       for (var pet in pets) {
  //         final photoUrl = pet['photo'] as String? ?? '';
  //         String photolocal = photoUrl.split('/').last;
  //         String imageUrl = 'http://177.44.248.73/repository/$photolocal';

  //         File downloadedImage = await _downloadImage(imageUrl);
  //         downloadedImages.add(downloadedImage);

  //         final breedId = pet['breed_id'] as int;
  //         final breedData =
  //             await BreedService().getBreedNameById(context, breedId);

  //         if (breedData != null) {
  //           final breedName = breedData['name'] as String;

  //           pet['breedName'] = breedName;
  //         }
  //       }

  //       setState(() {
  //         petDataList = pets;
  //       });
  //     }
  //   } catch (e) {
  //     DialogUtils.showErrorDialog(context, 'Erro ao carregar os pets: $e');
  //   }
  // }

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

  List<Map<String, dynamic>> filterPetsByNameAndType(
      List<Map<String, dynamic>> pets, String nameFilter, String typeFilter) {
    return pets.where((pet) {
      final petName = (pet['name'] as String).toLowerCase();
      final petType = (pet['type'] as String).toLowerCase();
      final filterName = nameFilter.toLowerCase();
      final filterType = typeFilter.toLowerCase();

      return petName.contains(filterName) && petType.contains(filterType);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPets = [];
    if (nameFilter.isNotEmpty || typeFilter.isNotEmpty) {
      filteredPets =
          filterPetsByNameAndType(petDataList, nameFilter, typeFilter);
    } else {
      filteredPets = List.from(petDataList);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pets'),
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
                builder: (context) => HomeScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PetForm(isEditing: true),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Color.fromARGB(255, 214, 201, 171),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filtrar por nome',
                    ),
                    onChanged: (value) {
                      setState(() {
                        nameFilter = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filtrar por tipo',
                    ),
                    onChanged: (value) {
                      setState(() {
                        typeFilter = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    currentPage = 1;
                    _loadPets();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListView.builder(
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  final petData = filteredPets[index];
                  final name = petData['name'] as String;
                  final birthDate = petData['birth_date'] != null
                      ? petData['birth_date'] as DateTime
                      : null;
                  final age = birthDate != null ? _calculateAge(birthDate) : '';
                  final gender = petData['gender'];
                  final type = petData['type'];
                  final downloadedImage = downloadedImages[index];

                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    color: Color.fromARGB(255, 214, 201, 171),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: Image.file(
                          downloadedImage,
                        ).image,
                        radius: 30,
                      ),
                      title: Container(
                        width: double.infinity,
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Wrap(
                        spacing: 4,
                        children: [
                          Text(
                            'Raça: ' + petData['breedName'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Visibility(
                                visible: age.isNotEmpty,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Idade: $age Anos',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: gender != null && gender.isNotEmpty,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gênero: $gender',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: type != null && type.isNotEmpty,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tipo: $type',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.brown[900],
                            ),
                            onPressed: () {
                              final petDataId = petDataList[index]['id'];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PetForm(
                                      isEditing: true, petId: petDataId),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.brown[900],
                            onPressed: () {
                              _showDeleteConfirmationDialog(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirmação de Exclusão',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.brown[100],
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Tem certeza de que deseja excluir este pet?',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Confirmar',
                style: TextStyle(
                  color: Colors.brown[900],
                ),
              ),
              onPressed: () {
                _deletePet(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deletePet(int index) async {
    try {
      final petIdToDelete = petDataList[index]['id'];

      await widget.petService.deletePet(petIdToDelete);

      setState(() {
        petDataList.removeAt(index);
      });
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao excluir o pet: $e');
    }
  }
}
