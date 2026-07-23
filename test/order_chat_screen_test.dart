import 'dart:typed_data';

import 'package:businesssajilo/core/errors/app_failure.dart';
import 'package:businesssajilo/core/l10n/app_localizations.dart';
import 'package:businesssajilo/data/repositories/messages_repository.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/member.dart';
import 'package:businesssajilo/domain/models/message.dart';
import 'package:businesssajilo/domain/models/session_state.dart';
import 'package:businesssajilo/features/auth/providers/auth_provider.dart';
import 'package:businesssajilo/features/chat/order_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedAuth extends AuthController {
  _FixedAuth(this.session);
  final SessionState session;

  @override
  AsyncValue<SessionState> build() => AsyncValue.data(session);
}

class _FakeMessages implements MessagesRepository {
  _FakeMessages({this.failSend = false});

  final bool failSend;
  final messages = <Message>[
    Message(
      id: 'msg-1',
      orderId: 'ord-1',
      businessId: 'biz',
      senderMemberId: 'other',
      body: 'Hello from customer',
      senderName: 'Cust',
      createdAt: DateTime.utc(2026, 7, 1, 10),
    ),
  ];

  @override
  Stream<List<Message>> watch(String orderId) => Stream.value(messages);

  @override
  Future<Message> sendText({
    required String orderId,
    required String senderMemberId,
    required String body,
  }) async {
    if (failSend) throw const AppFailure.permission(detail: 'forbidden');
    final msg = Message(
      id: 'msg-new',
      orderId: orderId,
      businessId: 'biz',
      senderMemberId: senderMemberId,
      body: body,
      createdAt: DateTime.now().toUtc(),
    );
    messages.add(msg);
    return msg;
  }

  @override
  Future<Message> sendImage({
    required String orderId,
    required String senderMemberId,
    required String businessId,
    required Uint8List bytes,
    required String fileName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> signedImageUrl(String? storagePath) async => null;
}

Widget _wrap({
  required MessagesRepository messages,
  required SessionState session,
}) {
  return ProviderScope(
    overrides: [
      messagesRepositoryProvider.overrideWithValue(messages),
      authProvider.overrideWith(() => _FixedAuth(session)),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: OrderChatScreen(orderId: 'ord-1'),
    ),
  );
}

const _session = SessionState(
  member: Member(
    id: 'me',
    businessId: 'biz',
    authUserId: 'auth-me',
    role: Role.owner,
    displayName: 'Owner',
  ),
);

void main() {
  testWidgets('order chat renders streamed messages', (tester) async {
    await tester.pumpWidget(
      _wrap(messages: _FakeMessages(), session: _session),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello from customer'), findsOneWidget);
    expect(find.text('Cust'), findsOneWidget);
  });

  testWidgets('order chat surfaces send failure snackbar', (tester) async {
    await tester.pumpWidget(
      _wrap(messages: _FakeMessages(failSend: true), session: _session),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Will fail');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('forbidden'), findsOneWidget);
  });
}
