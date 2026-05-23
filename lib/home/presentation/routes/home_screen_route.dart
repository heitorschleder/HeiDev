import '../../../core/routing/routing.dart';
import '../screens/home_screen.dart';

final class HomeScreenRoute extends AppNoPayloadRouteConfig {
  HomeScreenRoute() : super(name: 'HomeScreen', path: '/home', builder: () => const HomeScreen());
}
