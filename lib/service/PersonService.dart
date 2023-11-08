import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomeScreen.dart';
import '../utils/DialogUtils.dart';
import 'PostgreSQLService.dart';
import 'package:crypto/crypto.dart';

class PersonService {
  final Map<String, dynamic> accountData;
  final BuildContext context;

  PersonService({required this.accountData, required this.context});

  Future<void> createPerson() async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      // Abra a conexão antes de executar as consultas
      await postgresService.openConnection();

      // Acesse a conexão através do atributo 'connection'
      var connection = postgresService.connection;

      final String name = accountData['name'];
      final String cpfcnpj = accountData['cpf_cnpj'];
      final String email = accountData['email'];
      final String password = accountData['password'];

      final String phone = accountData['phone'];
      final String gender = accountData['gender'];
      final String dtRegister =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Criptografa a senha usando SHA-256
      final bytes = utf8.encode(password);
      final hash = await sha256.convert(bytes);
      String hashedPassword = hash.toString();

      // Verifica se o CPF/CNPJ já existe no banco de dados
      var checkDuplicityCpfCnjp = await connection.query(
        'SELECT * FROM cad_person WHERE cpf_cnpj = @cpf_cnpj',
        substitutionValues: {'cpf_cnpj': cpfcnpj},
      );

      if (checkDuplicityCpfCnjp.isNotEmpty) {
        DialogUtils.showErrorDialog(
            context, 'CPF/CNPJ já existe no banco de dados.');
        await postgresService.closeConnection();
        return;
      }

      // Verifica se o email já existe no banco de dados
      var checkDuplicityemail = await connection.query(
        'SELECT * FROM cad_person WHERE email = @email',
        substitutionValues: {'email': email},
      );

      if (checkDuplicityemail.isNotEmpty) {
        DialogUtils.showErrorDialog(
            context, 'E-mail já existe no banco de dados.');
        await postgresService.closeConnection();
        return;
      }

      // Verifica se o phone já existe no banco de dados
      var checkDuplicityphone = await connection.query(
        'SELECT * FROM cad_person WHERE phone = @phone',
        substitutionValues: {'phone': phone},
      );

      if (checkDuplicityphone.isNotEmpty) {
        DialogUtils.showErrorDialog(
            context, 'Telefone já existe no banco de dados.');
        await postgresService.closeConnection();
        return;
      }

      String token;
      do {
        token = generateRandomToken(30);
      } while (!await isTokenUnique(connection, token));

      // Grava a pessoa
      var person = await connection.query(
        'INSERT INTO cad_person (dt_register, name, cpf_cnpj, password, email, phone, gender, token) VALUES (@dt_register, @name, @cpf_cnpj, @password, @email, @phone, @gender, @token) RETURNING id',
        substitutionValues: {
          'dt_register': dtRegister,
          'name': name,
          'cpf_cnpj': cpfcnpj,
          'password': hashedPassword,
          'email': email,
          'phone': phone,
          'gender': gender,
          'token': token,
        },
      );

      if (person.isEmpty) {
        DialogUtils.showErrorDialog(context, 'Erro ao gravar a pessoa');
        await postgresService.closeConnection();
        return;
      }

      int personId = person[0][0] as int;

      // Cria a sessão
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('personId', personId);

      await postgresService.closeConnection();

      DialogUtils.showSuccessDialog(
        context,
        'Conta criada com sucesso!',
        () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        },
      );
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao criar a conta: $e');
    }
  }

  Future<bool> isTokenUnique(var connection, String token) async {
    var result = await connection.query(
      'SELECT COUNT(*) FROM cad_person WHERE token = @token',
      substitutionValues: {'token': token},
    );
    return result[0][0] == 0;
  }

  String generateRandomToken(int length) {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()_-+=<>?/[]{}|;:`~';
    Random rnd = Random();
    String token = '';

    for (int i = 0; i < length; i++) {
      token += chars[rnd.nextInt(chars.length)];
    }

    return token;
  }

  Future<Map<String, dynamic>?> getPersonDataByPhone(String phone) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT * FROM cad_person WHERE phone = @phone',
        substitutionValues: {'phone': phone},
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        var row = result.first;

        var personData = {
          'id': row[0] as int,
          'dt_register': (row[1] as DateTime).toString(),
          'name': row[2] as String,
          'cpf_cnpj': row[3] as String,
          'birth_date': row[4] != null ? (row[4] as DateTime).toString() : null,
          'gender': row[5] != null ? (row[5] as String) : null,
          'photo': row[6] != null ? (row[6] as String) : null,
          'password': row[7] as String,
          'email': row[8] as String,
          'phone': row[9] as String,
          'code_auth': row[10] != null ? (row[10] as int) : null,
        };

        return personData;
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao lsitar dados da conta: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> getPersonDataByPersonId(int personId) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      var result = await connection.query(
        'SELECT * FROM cad_person WHERE id = @personId',
        substitutionValues: {'personId': personId},
      );

      await postgresService.closeConnection();

      if (result.isNotEmpty) {
        var row = result.first;

        var personData = {
          'id': row[0] as int,
          'dt_register': (row[1] as DateTime).toString(),
          'name': row[2] as String,
          'cpf_cnpj': row[3] as String,
          'birth_date': row[4] != null ? (row[4] as DateTime).toString() : null,
          'gender': row[5] != null ? (row[5] as String) : null,
          'photo': row[6] != null ? (row[6] as String) : null,
          'password': row[7] as String,
          'email': row[8] as String,
          'phone': row[9] as String,
          'code_auth': row[10] != null ? (row[10] as int) : null,
          'token': row[11] as String,
        };

        return personData;
      }
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar dados da conta: $e');
    }

    return null;
  }

  Future<void> updatePerson(Map<String, dynamic> updatedData) async {
    try {
      PostgreSQLService postgresService = PostgreSQLService();

      await postgresService.openConnection();

      var connection = postgresService.connection;

      int personId = updatedData['id'];
      updatedData.remove('id');

      // Verifica se o CPF/CNPJ já existe no banco de dados
      if (updatedData.containsKey('cpf_cnpj')) {
        var checkDuplicityCpfCnpj = await connection.query(
          'SELECT * FROM cad_person WHERE cpf_cnpj = @cpf_cnpj AND id != @personId',
          substitutionValues: {
            'cpf_cnpj': updatedData['cpf_cnpj'],
            'personId': personId
          },
        );

        if (checkDuplicityCpfCnpj.isNotEmpty) {
          DialogUtils.showErrorDialog(
              context, 'CPF/CNPJ já existe no banco de dados.');
          await postgresService.closeConnection();
          return;
        }
      }

      // Verifica se o email já existe no banco de dados
      if (updatedData.containsKey('email')) {
        var checkDuplicityEmail = await connection.query(
          'SELECT * FROM cad_person WHERE email = @email AND id != @personId',
          substitutionValues: {
            'email': updatedData['email'],
            'personId': personId
          },
        );

        if (checkDuplicityEmail.isNotEmpty) {
          DialogUtils.showErrorDialog(
              context, 'E-mail já existe no banco de dados.');
          await postgresService.closeConnection();
          return;
        }
      }

      // Verifica se o phone já existe no banco de dados
      if (updatedData.containsKey('phone')) {
        var checkDuplicityPhone = await connection.query(
          'SELECT * FROM cad_person WHERE phone = @phone AND id != @personId',
          substitutionValues: {
            'phone': updatedData['phone'],
            'personId': personId
          },
        );

        if (checkDuplicityPhone.isNotEmpty) {
          DialogUtils.showErrorDialog(
              context, 'Telefone já existe no banco de dados.');
          await postgresService.closeConnection();
          return;
        }
      }

      var updateValues =
          updatedData.keys.map((key) => '$key = @${key}_value').join(', ');

      await connection.query(
        'UPDATE cad_person SET $updateValues WHERE id = @personId',
        substitutionValues: {
          'personId': personId,
          for (var entry in updatedData.entries)
            '${entry.key}_value': entry.value,
        },
      );

      await postgresService.closeConnection();
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao atualizar a conta: $e');
    }
  }
}
