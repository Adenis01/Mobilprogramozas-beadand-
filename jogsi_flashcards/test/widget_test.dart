import 'package:flutter_test/flutter_test.dart';
import 'package:jogsi_flashcards/main.dart';

void main() {
  testWidgets('JogsiFlashcardsApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JogsiFlashcardsApp());
    expect(find.byType(JogsiFlashcardsApp), findsOneWidget);
  });
}
