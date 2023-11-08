import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomeScreen.dart';
import 'MyLostPetForm.dart';
import 'service/LostPetService.dart';
import 'utils/DialogUtils.dart';
import 'package:http/http.dart' as http;

class MyLostPetList extends StatefulWidget {
  final LostPetService lostPetService;

  MyLostPetList({required this.lostPetService});

  @override
  _MyLostPetListState createState() => _MyLostPetListState();
}

class _MyLostPetListState extends State<MyLostPetList> {
  List<Map<String, dynamic>> lostPetDataList = [];
  List<File> downloadedImages = [];
  String statusFilter = '';
  int pageSize = 10;
  int currentPage = 1;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLostPets(currentPage);
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
      _loadLostPets(currentPage);
    }
  }

  Future<void> _loadLostPets(int page) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int personId = prefs.getInt('personId') ?? 0;

      int startIndex = (page - 1) * pageSize;

      var petsResponse = await widget.lostPetService
          .getLostPetsDataByPerson(personId, startIndex, pageSize);

      if (petsResponse['data'] is List) {
        List<Map<String, dynamic>> pets =
            (petsResponse['data'] as List).cast<Map<String, dynamic>>();

        for (var pet in pets) {
          final photoUrl = pet['photo'] as String? ?? '';
          String photolocal = photoUrl.split('/').last;
          String imageUrl = 'http://177.44.248.73/repository/$photolocal';

          File downloadedImage = await _downloadImage(imageUrl);
          downloadedImages.add(downloadedImage);
        }

        setState(() {
          if (page == 1) {
            lostPetDataList.clear();
          }
          lostPetDataList.addAll(pets);
        });
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao carregar os pets: $e');
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

  List<Map<String, dynamic>> filterPetsByStatus(
      List<Map<String, dynamic>> pets, String statusFilter) {
    return pets.where((pet) {
      final petStatus = (pet['status'] as String?)?.toLowerCase() ?? '';
      final filterStatus = statusFilter.toLowerCase();

      return petStatus.contains(filterStatus);
    }).toList();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Encontrado':
        return Icons.check;
      case 'Perdido':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Encontrado':
        return Colors.green;
      case 'Perdido':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPets = [];
    if (statusFilter.isNotEmpty) {
      filteredPets = filterPetsByStatus(lostPetDataList, statusFilter);
    } else {
      filteredPets = List.from(lostPetDataList);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Minha Lista de Pets Perdidos'),
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
                  builder: (context) => MyLostPetForm(),
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
                      hintText: 'Filtrar por status',
                    ),
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _loadLostPets(currentPage);
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
                  final status = petData['status'];
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
                      subtitle: Wrap(
                        spacing: 4,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Visibility(
                                visible: status != null && status.isNotEmpty,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      color: _getStatusColor(status),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '$status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.track_changes),
                            color: Colors.brown[900],
                            onPressed: () {
                              _showChangeStatusConfirmationDialog(index);
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

  Future<void> _showChangeStatusConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Trocar o status para encontrado',
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
                  'Tem certeza de que deseja trocar o status deste pet?',
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
                _changeStatusPet(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _changeStatusPet(int index) async {
    try {
      final petIdToChangeStatus = lostPetDataList[index]['id'];

      await widget.lostPetService.ChangeStatusLostPet(petIdToChangeStatus);

      setState(() {});
    } catch (e) {
      DialogUtils.showErrorDialog(
          context, 'Erro ao trocar o status do pet: $e');
    }
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
      final petIdToDelete = lostPetDataList[index]['id'];

      await widget.lostPetService.deleteLostPet(petIdToDelete);

      setState(() {
        lostPetDataList.removeAt(index);
      });
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao excluir o pet: $e');
    }
  }
}
