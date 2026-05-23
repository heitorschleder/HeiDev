import '../../../core/routing/routing.dart';
import '../screens/bill_templates_screen.dart';

final class BillTemplatesScreenRoute extends AppNoPayloadRouteConfig {
  BillTemplatesScreenRoute()
    : super(name: 'BillTemplatesScreen', path: 'templates', builder: () => const BillTemplatesScreen());
}
