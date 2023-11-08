import 'package:flutter/material.dart';
import '../utils/DialogUtils.dart';
import 'PostgreSQLService.dart';

class BreedService {
  Future<List<String>> getBreedOptionsFromDatabase(BuildContext context) async {
    List<String> breedOptions = [];

    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      final results = await connection.query('SELECT name FROM cad_breed');

      breedOptions = results.map((row) => row[0] as String).toList();

      await postgresService.closeConnection();
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar as raças: $e');
    }

    return breedOptions;
  }

  Future<int?> getBreedIdByName(BuildContext context, String breedName) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT id FROM cad_breed WHERE name = @breedName',
        substitutionValues: {'breedName': breedName},
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        var row = result.first;

        var breedId = row[0] as int;

        return breedId;
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao obter o ID da raça: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getBreedNameById(
      BuildContext context, int breedId) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT * FROM cad_breed WHERE id = @breedId',
        substitutionValues: {'breedId': breedId},
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        var row = result.first;

        var breedData = {
          'id': row[0] as int,
          'dt_register': (row[1] as DateTime).toString(),
          'name': row[2] as String,
        };

        return breedData;
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar as raças: $e');
    }

    return null;
  }
}
