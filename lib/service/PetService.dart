import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../PetList.dart';
import '../utils/DialogUtils.dart';
import 'PostgreSQLService.dart';

class PetService {
  final Map<String, dynamic> accountData;
  final BuildContext context;

  PetService({required this.accountData, required this.context});

  Future<void> createPet() async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      final String dtRegister =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final String name = accountData['name'];
      final int breed_id = accountData['breed_id'];
      final int person_id = accountData['person_id'];
      final String photo = accountData['photo'];
      final String? birth_date = accountData['birth_date'] != null
          ? DateFormat('yyyy-MM-dd').format(accountData['birth_date'])
          : null;
      final String gender =
          accountData['gender'] != null ? accountData['gender'] : '';
      final String rg = accountData['rg'] != null ? accountData['rg'] : '';
      final String primary_color = accountData['primary_color'] != null
          ? accountData['primary_color']
          : '';
      final String type =
          accountData['type'] != null ? accountData['type'] : '';
      final double weight =
          accountData['weight'] != null ? accountData['weight'] : 0.0;
      final double height =
          accountData['height'] != null ? accountData['height'] : 0.0;

      if (rg.isNotEmpty) {
        var checkDuplicityRG = await connection.query(
          'SELECT * FROM cad_pet WHERE rg = @rg',
          substitutionValues: {'rg': rg},
        );

        if (checkDuplicityRG.isNotEmpty) {
          DialogUtils.showErrorDialog(
              context, 'RG já existe no banco de dados.');
          await postgresService.closeConnection();
          return;
        }
      }

      var pet = await connection.query(
        'INSERT INTO cad_pet (dt_register, name, breed_id, gender, rg, primary_color, type, weight, height, birth_date, photo, person_id) VALUES (@dt_register, @name, COALESCE(@breed_id, 0), COALESCE(@gender, \'\'), COALESCE(@rg, \'\'), COALESCE(@primary_color, \'\'), COALESCE(@type, \'\'), COALESCE(@weight, 0.0), COALESCE(@height, 0.0), @birth_date, @photo, @person_id) RETURNING id',
        substitutionValues: {
          'dt_register': dtRegister,
          'name': name,
          'breed_id': breed_id,
          'gender': gender,
          'rg': rg,
          'primary_color': primary_color,
          'type': type,
          'person_id': person_id,
          'photo': photo,
          'birth_date': birth_date,
          'weight': weight,
          'height': height,
        },
      );

      if (pet.isEmpty) {
        DialogUtils.showErrorDialog(context, 'Erro ao gravar o pet');
        await postgresService.closeConnection();

        return;
      }

      await postgresService.closeConnection();

      DialogUtils.showSuccessDialog(
        context,
        'Pet criado com sucesso!',
        () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetList(
                  petService: PetService(accountData: {}, context: context)),
            ),
          );
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao gravar o pet: $e');
    }
  }

  Future<void> updatePet(Map<String, dynamic> updatedData) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      int id = updatedData['id'];
      updatedData.remove('id');

      if (updatedData['rg'].isNotEmpty) {
        if (updatedData.containsKey('rg')) {
          var checkDuplicityRG = await connection.query(
            'SELECT * FROM cad_pet WHERE rg = @rg AND id != @id',
            substitutionValues: {'rg': updatedData['rg'], 'id': id},
          );

          if (checkDuplicityRG.isNotEmpty) {
            DialogUtils.showErrorDialog(
                context, 'RG já existe no banco de dados.');
            await postgresService.closeConnection();
            return;
          }
        }
      }

      var updateValues =
          updatedData.keys.map((key) => '$key = @${key}_value').join(', ');

      await connection.query(
        'UPDATE cad_pet SET $updateValues WHERE id = @id',
        substitutionValues: {
          'id': id,
          for (var entry in updatedData.entries)
            '${entry.key}_value': entry.value,
        },
      );

      await postgresService.closeConnection();
      DialogUtils.showSuccessDialog(
        context,
        'Conta editada com sucesso!',
        () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetList(
                  petService: PetService(accountData: {}, context: context)),
            ),
          );
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao atualizar o pet: $e');
    }
  }

  Future<Map<String, dynamic>?> getPetById(int petId) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT * FROM cad_pet WHERE id = @pet_id',
        substitutionValues: {'pet_id': petId},
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        var row = result.first;

        var petData = {
          'id': row[0] as int,
          'dt_register':
              row[1] != null ? (row[1] as DateTime).toString() : null,
          'name': row[2] as String,
          'breed_id': row[3] as int,
          'person_id': row[4] as int,
          'photo': row[5] as String,
          'birth_date': row[6] != null ? (row[6] as DateTime) : null,
          'gender': row[7] != null ? (row[7] as String) : null,
          'rg': row[8] != null ? (row[8] as String) : null,
          'weight': row[9] != null ? (row[9] as double) : null,
          'height': row[10] != null ? (row[10] as double) : null,
          'primary_color': row[11] != null ? (row[11] as String) : null,
          'type': row[12] != null ? (row[12] as String) : null,
        };

        return petData;
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao obter detalhes do pet: $e');
    }

    return null;
  }

  Future<List<Map<String, dynamic>>?> getPetsDataByPerson(
      int personId, int startIndex, int endIndex) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT * FROM cad_pet WHERE person_id = @person_id LIMIT @limit OFFSET @offset',
        substitutionValues: {
          'person_id': personId,
          'limit': endIndex - startIndex,
          'offset': startIndex
        },
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        List<Map<String, dynamic>> petDataList = [];

        for (var row in result) {
          var petData = {
            'id': row[0] as int,
            'dt_register':
                row[1] != null ? (row[1] as DateTime).toString() : null,
            'name': row[2] as String,
            'breed_id': row[3] as int,
            'person_id': row[4] as int,
            'photo': row[5] as String,
            'birth_date': row[6] != null ? (row[6] as DateTime) : null,
            'gender': row[7] != null ? (row[7] as String) : null,
            'rg': row[8] != null ? (row[8] as String) : null,
            'weight': row[9] != null ? (row[9] as double) : null,
            'height': row[10] != null ? (row[10] as double) : null,
            'primary_color': row[11] != null ? (row[11] as String) : null,
            'type': row[12] != null ? (row[12] as String) : null,
          };

          petDataList.add(petData);
        }

        return petDataList;
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar o(s) pet(s): $e');
    }

    return null;
  }

  Future<void> deletePet(int petId) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var checkPetExists = await connection.query(
        'SELECT * FROM cad_pet WHERE id = @petId',
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
                builder: (context) => PetList(
                    petService: PetService(accountData: {}, context: context)),
              ),
            );
          },
        );

        await postgresService.closeConnection();

        return;
      }

      await connection.query(
        'DELETE FROM cad_pet WHERE id = @petId',
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
              builder: (context) => PetList(
                  petService: PetService(accountData: {}, context: context)),
            ),
          );
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao atualizar o pet: $e');
    }
  }
}
