import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:flutter/material.dart';
import '../utils/DialogUtils.dart';

class LocalDatabaseService {
  static Future<sqlite.Database> db(BuildContext context) async {
    try {
      return sqlite.openDatabase("login.db", version: 1,
          onCreate: (sqlite.Database database, int version) {
        database.execute(
            "CREATE TABLE login (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, phone INT, password TEXT)");
      });
    } catch (e) {
      DialogUtils.showErrorDialog(
          context, 'Erro ao abrir o banco de dados: $e');

      throw e;
    }
  }

  static Future<int> insertData(
      BuildContext context, String phone, String password) async {
    final db = await LocalDatabaseService.db(context);
    var values = {"phone": phone, "password": password};
    try {
      return await db.insert("login", values);
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao inserir os dados: $e');

      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllData(
      BuildContext context) async {
    final db = await LocalDatabaseService.db(context);
    try {
      return await db.query("login", orderBy: "id");
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao listar os dados: $e');

      throw e;
    }
  }

  static Future<int> updateData(
      BuildContext context, int id, String phone, String password) async {
    final db = await LocalDatabaseService.db(context);
    var values = {"phone": phone, "password": password};
    try {
      return await db.update("login", values, where: "id = ?", whereArgs: [id]);
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao atualizar os dados: $e');

      throw e;
    }
  }

  static Future<int> deleteData(BuildContext context, int id) async {
    final db = await LocalDatabaseService.db(context);
    try {
      return await db.delete("login", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao deletar os dados: $e');

      throw e;
    }
  }

  static Future<void> deleteAllLogin(BuildContext context) async {
    final db = await LocalDatabaseService.db(context);
    try {
      await db.delete("login");
    } catch (e) {
      DialogUtils.showErrorDialog(context, 'Erro ao deletar os dados: $e');

      throw e;
    }
  }
}
