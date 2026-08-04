import 'package:flutter_test/flutter_test.dart';
import 'package:ekaadh_mobile/main.dart';

void main() {
  testWidgets('Ekaadh app boots to splash or login', (tester) async {
    await tester.pumpWidget(const EkaadhApp());
    await tester.pump();
    expect(find.textContaining('Ekaadh'), findsWidgets);
  });
}
