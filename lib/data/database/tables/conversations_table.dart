import 'package:drift/drift.dart';

/// Table definition for conversations
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  TextColumn get systemPrompt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
