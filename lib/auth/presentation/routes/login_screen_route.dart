import '../../../core/routing/routing.dart';
import '../screens/login_screen.dart';

final class LoginScreenRoute extends AppNoPayloadRouteConfig {
  LoginScreenRoute() : super(name: 'LoginScreen', path: '/login', builder: () => const LoginScreen());
}
