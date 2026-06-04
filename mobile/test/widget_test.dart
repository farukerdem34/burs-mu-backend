import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:burs_mu/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BursApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
