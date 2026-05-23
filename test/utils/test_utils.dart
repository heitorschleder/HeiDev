import 'package:flutter_test/flutter_test.dart';

abstract final class TestUtils {
  static void expectText(String text, {Matcher matcher = findsOneWidget}) => expect(find.text(text), matcher);

  static void expectType<T>(Type type, {Matcher matcher = findsOneWidget}) => expect(find.byType(type), matcher);
}
