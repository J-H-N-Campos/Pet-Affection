import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';

class PostgreSQLService {
  late PostgreSQLConnection _connection;

  Future<void> openConnection() async {
    await dotenv.load(fileName: '.env');

    _connection = PostgreSQLConnection(
      dotenv.env['DB_HOST']!,
      int.parse(dotenv.env['DB_PORT']!),
      dotenv.env['DB_NAME']!,
      username: dotenv.env['DB_USERNAME']!,
      password: dotenv.env['DB_PASSWORD']!,
    );

    await _connection.open();
  }

  PostgreSQLConnection get connection => _connection;

  Future<void> closeConnection() async {
    await _connection.close();
  }
}
