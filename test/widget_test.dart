import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // On lance l'application MyApp au lieu de AltApp
    await tester.pumpWidget(const MyApp());
  });
}
