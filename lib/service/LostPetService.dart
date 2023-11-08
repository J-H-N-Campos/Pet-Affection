import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import '../EditMapLocationForm.dart';
import '../MyLostPetList.dart';
import '../utils/DialogUtils.dart';
import 'CloudVisionIAService.dart';
import 'PersonService.dart';
import 'PostgreSQLService.dart';
import 'dart:math';

class LostPetService {
  final Map<String, dynamic> accountData;
  final BuildContext context;

  LostPetService({required this.accountData, required this.context});

  Future<void> createLostPet() async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      final String dtRegister =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final int breed_id = accountData['breed_id'];
      final int person_id = accountData['person_id'];
      final String photo = accountData['photo'];
      final String gender =
          accountData['gender'] != null ? accountData['gender'] : '';
      final String rg = accountData['rg'] != null ? accountData['rg'] : '';
      final String primary_color = accountData['primary_color'];
      final String name =
          accountData['name'] != null ? accountData['name'] : '';

      var lostPet = await connection.query(
        'INSERT INTO cad_photo_lost_pet (dt_register, latitude, longitude, breed_id, gender, rg, primary_color, photo, person_id, name, status) VALUES (@dt_register, @latitude, @longitude, @breed_id, @gender, @rg, @primary_color, @photo, @person_id, @name, @status) RETURNING id, latitude, longitude',
        substitutionValues: {
          'dt_register': dtRegister,
          'latitude': accountData['latitude'],
          'longitude': accountData['longitude'],
          'breed_id': breed_id,
          'gender': gender,
          'rg': rg,
          'primary_color': primary_color,
          'person_id': person_id,
          'photo': photo,
          'name': name,
          'status': "Perdido",
        },
      );

      if (lostPet.isEmpty) {
        DialogUtils.showErrorDialog(context, 'Erro ao gravar o pet');
        await postgresService.closeConnection();

        return;
      }

      int id = lostPet[0][0] as int;
      String latitude = lostPet[0][1] as String;
      String longitude = lostPet[0][2] as String;

      await postgresService.closeConnection();
      DialogUtils.showSuccessDialog(
        context,
        'Dados do pet enviado com sucesso!',
        () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditMapLocationForm(
                      id: id, latitude: latitude, longitude: longitude)));
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao gravar o pet: $e');
    }
  }

  Future<void> updateLostPet(Map<String, dynamic> updatedData) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      int lostPetId = updatedData['id'];
      updatedData.remove('id');

      var updateValues =
          updatedData.keys.map((key) => '$key = @${key}_value').join(', ');

      await connection.query(
        'UPDATE cad_photo_lost_pet SET $updateValues WHERE id = @lost_pet_id',
        substitutionValues: {
          'lost_pet_id': lostPetId,
          for (var entry in updatedData.entries)
            '${entry.key}_value': entry.value,
        },
      );

      await postgresService.closeConnection();
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> getLostPetsDataByPerson(
      int personId, int startIndex, int pageSize) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT * FROM cad_photo_lost_pet WHERE person_id = @person_id OFFSET @start_index LIMIT @page_size',
        substitutionValues: {
          'person_id': personId,
          'start_index': startIndex,
          'page_size': pageSize,
        },
      );

      var totalResults = await connection.query(
        'SELECT COUNT(*) FROM cad_photo_lost_pet WHERE person_id = @person_id',
        substitutionValues: {'person_id': personId},
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        List<Map<String, dynamic>> petDataList = [];

        for (var row in result) {
          var petData = {
            'id': row[0] as int,
            'dt_register':
                row[1] != null ? (row[1] as DateTime).toString() : null,
            'latitude': row[2] as String,
            'longitude': row[3] as String,
            'photo': row[4] as String,
            'person_id': row[5] as int,
            'breed_id': row[6] as int,
            'primary_color': row[7] as String,
            'rg': row[8] != null ? (row[8] as String) : null,
            'gender': row[9] != null ? (row[9] as String) : null,
            'name': row[10] != null ? (row[10] as String) : null,
            'status': row[11] as String,
          };

          petDataList.add(petData);
        }

        return {
          'data': petDataList,
          'totalResults': totalResults[0][0] as int,
        };
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar o(s) pet(s): $e');
    }

    return {'data': null, 'totalResults': 0};
  }

  Future<List<Map<String, dynamic>>> compareImagesToDatabase(
      int personId, String imagePath, LocationData locationData) async {
    List<Map<String, dynamic>> similarImages = [];

    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      final latitude = locationData.latitude;
      final longitude = locationData.longitude;

      var results = await connection.query(
        'SELECT * FROM cad_photo_lost_pet WHERE person_id != @personId AND status = \'Perdido\' AND (6371 * 2 * ASIN(SQRT(SIN(RADIANS(CAST(latitude AS NUMERIC) - @latitude) / 2) * SIN(RADIANS(CAST(latitude AS NUMERIC) - @latitude) / 2) + COS(RADIANS(@latitude)) * COS(RADIANS(CAST(latitude AS NUMERIC))) * SIN(RADIANS(CAST(longitude AS NUMERIC) - @longitude) / 2) * SIN(RADIANS(CAST(longitude AS NUMERIC) - @longitude) / 2)))) <= 100;',
        substitutionValues: {
          'personId': personId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      await postgresService.closeConnection();

      if (imagePath.isEmpty) {
        throw Exception('Erro ao carregar a imagem para comparação.');
      }

      if (results.isNotEmpty) {
        for (var row in results) {
          final databaseImagePath = row[4] as String;

          //foto enviada
          String imagePathFinalReplace = imagePath.replaceAll(
              "/var/www/html/repository/", "http://177.44.248.73/repository/");
          String finalImagePath = imagePathFinalReplace;

          //foto do banco
          String imagePathDatabaseFinalReplace = databaseImagePath.replaceAll(
              "/var/www/html/repository/", "http://177.44.248.73/repository/");
          String finalImagePathDatabase = imagePathDatabaseFinalReplace;

          // cor da imagem
          final predominantColorWeb =
              await CloudVisionIAService.getPredominantColor(finalImagePath);

          int red = predominantColorWeb['red'];
          int green = predominantColorWeb['green'];
          int blue = predominantColorWeb['blue'];

          Color predominantColorPrimary = Color.fromARGB(255, red, green, blue);

          // cor da imagem q vem do banco
          final predominantDatabaseColorWeb =
              await CloudVisionIAService.getPredominantColor(
                  finalImagePathDatabase);

          int r = predominantDatabaseColorWeb['red'];
          int g = predominantDatabaseColorWeb['green'];
          int b = predominantDatabaseColorWeb['blue'];

          Color predominantColorDatabasePrimary = Color.fromARGB(255, r, g, b);

          // Defina o limite
          final threshold = 150;

          if (areColorsSimilar(predominantColorPrimary,
              predominantColorDatabasePrimary, threshold)) {
            String finalPhoto = row[4].replaceAll("/var/www/html/repository/",
                "http://177.44.248.73/repository/");
            var finalName = row[10];

            int finalPersonId = row[5];
            PersonService personService =
                PersonService(accountData: {}, context: context);

            // Espera um curto período antes de chamar getPersonDataByPersonId
            await Future.delayed(Duration(milliseconds: 100));

            Map<String, dynamic>? personData =
                await personService.getPersonDataByPersonId(finalPersonId);

            similarImages.add({
              'photo': finalPhoto,
              'name': finalName,
              'person_name': personData!['name'],
              'phone': personData['phone'],
              'latitude': row[2],
              'longitude': row[3],
            });
          }
        }
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar os pet perdidos');
    }

    return similarImages;
  }

  // Função para calcular a distância euclidiana entre duas cores.
  double colorDistance(Color color1, Color color2) {
    final int r = (color1.red - color2.red);
    final int g = (color1.green - color2.green);
    final int b = (color1.blue - color2.blue);

    return sqrt(r * r + g * g + b * b);
  }

  // Função para verificar a semelhança entre duas cores com base em um limite.
  bool areColorsSimilar(Color color1, Color color2, int threshold) {
    final distance = colorDistance(color1, color2);

    return distance <= threshold;
  }

  Future<void> deleteLostPet(int petId) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var checkPetExists = await connection.query(
        'SELECT * FROM cad_photo_lost_pet WHERE id = @petId',
        substitutionValues: {'petId': petId},
      );

      if (checkPetExists.isEmpty) {
        DialogUtils.showSuccessDialog(
          context,
          'Pet não encontrado',
          () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyLostPetList(
                    lostPetService:
                        LostPetService(accountData: {}, context: context)),
              ),
            );
          },
        );

        await postgresService.closeConnection();

        return;
      }

      await connection.query(
        'DELETE FROM cad_photo_lost_pet WHERE id = @petId',
        substitutionValues: {'petId': petId},
      );

      await postgresService.closeConnection();

      DialogUtils.showSuccessDialog(
        context,
        'Pet excluído com sucesso',
        () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyLostPetList(
                  lostPetService:
                      LostPetService(accountData: {}, context: context)),
            ),
          );
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao atualizar o pet: $e');
    }
  }

  Future<void> ChangeStatusLostPet(int petId) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();
      await postgresService.openConnection();

      var connection = postgresService.connection;

      var checkPetExists = await connection.query(
        'SELECT * FROM cad_photo_lost_pet WHERE id = @petId',
        substitutionValues: {'petId': petId},
      );

      if (checkPetExists.isEmpty) {
        DialogUtils.showSuccessDialog(
          context,
          'Pet não encontrado',
          () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyLostPetList(
                  lostPetService:
                      LostPetService(accountData: {}, context: context),
                ),
              ),
            );
          },
        );

        await postgresService.closeConnection();

        return;
      }

      // Obtém o status atual do pet
      String currentStatus = checkPetExists.first[11];

      // Calcula o novo status com base no status atual
      String newStatus = currentStatus == 'Perdido' ? 'Encontrado' : 'Perdido';

      await connection.query(
        'UPDATE cad_photo_lost_pet SET status = @newStatus WHERE id = @petId',
        substitutionValues: {'petId': petId, 'newStatus': newStatus},
      );

      await postgresService.closeConnection();

      DialogUtils.showSuccessDialog(
        context,
        'Status trocado com sucesso',
        () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyLostPetList(
                lostPetService:
                    LostPetService(accountData: {}, context: context),
              ),
            ),
          );
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao atualizar o pet: $e');
    }
  }
}
