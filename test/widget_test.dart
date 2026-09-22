import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vesper/main.dart';

void main() {
  testWidgets('App launches and shows the nav shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VesperApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}