import '../../../core/routing/routing.dart';
import '../screens/signup_screen.dart';

final class SignupScreenRoute extends AppNoPayloadRouteConfig {
  SignupScreenRoute() : super(name: 'SignupScreen', path: '/signup', builder: () => const SignupScreen());
}
