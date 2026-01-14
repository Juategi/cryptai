import 'package:drift/drift.dart';
import 'conversations_table.dart';

/// Table definition for messages
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get content => text()();
  TextColumn get role => text()(); // user, assistant, system
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('sent'))();
  IntColumn get tokenCount => integer().nullable()();
  IntColumn get generationTimeMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
