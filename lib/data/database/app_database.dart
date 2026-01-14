import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import '../../core/constants/app_constants.dart';
import 'tables/conversations_table.dart';
import 'tables/messages_table.dart';
import 'tables/settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Conversations, Messages, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations here
        },
      );

  /// Create encrypted database connection
  static LazyDatabase createEncrypted(String encryptionKey) {
    return LazyDatabase(() async {
      // Setup SQLCipher for Android
      if (Platform.isAndroid) {
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      }

      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, AppConstants.databaseName));

      return NativeDatabase.createInBackground(
        file,
        setup: (database) {
          // Set encryption key using PRAGMA
          database.execute("PRAGMA key = '$encryptionKey'");
        },
      );
    });
  }

  // ============ Conversation Operations ============

  /// Get all conversations ordered by most recent
  Future<List<Conversation>> getAllConversations() {
    return (select(conversations)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Watch all conversations for reactive updates
  Stream<List<Conversation>> watchAllConversations() {
    return (select(conversations)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get a single conversation by ID
  Future<Conversation?> getConversation(String id) {
    return (select(conversations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new conversation
  Future<void> insertConversation(ConversationsCompanion conversation) {
    return into(conversations).insert(conversation);
  }

  /// Update a conversation
  Future<void> updateConversation(ConversationsCompanion conversation) {
    return (update(conversations)..where((t) => t.id.equals(conversation.id.value)))
        .write(conversation);
  }

  /// Delete a conversation and its messages
  Future<void> deleteConversation(String id) async {
    await (delete(messages)..where((t) => t.conversationId.equals(id))).go();
    await (delete(conversations)..where((t) => t.id.equals(id))).go();
  }

  // ============ Message Operations ============

  /// Get all messages for a conversation
  Future<List<Message>> getMessagesForConversation(String conversationId) {
    return (select(messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// Watch messages for a conversation
  Stream<List<Message>> watchMessagesForConversation(String conversationId) {
    return (select(messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  /// Insert a new message
  Future<void> insertMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  /// Update a message
  Future<void> updateMessage(MessagesCompanion message) {
    return (update(messages)..where((t) => t.id.equals(message.id.value)))
        .write(message);
  }

  /// Delete a message
  Future<void> deleteMessage(String id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

  /// Get message count for a conversation
  Future<int> getMessageCount(String conversationId) async {
    final count = countAll();
    final query = selectOnly(messages)
      ..addColumns([count])
      ..where(messages.conversationId.equals(conversationId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============ Settings Operations ============

  /// Get a setting value
  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// Set a setting value
  Future<void> setSetting(String key, String value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) {
    return (delete(settings)..where((t) => t.key.equals(key))).go();
  }

  /// Clear all data (for reset)
  Future<void> clearAllData() async {
    await delete(messages).go();
    await delete(conversations).go();
    await delete(settings).go();
  }
}
