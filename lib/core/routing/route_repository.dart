import '../../auth/presentation/routes/login_screen_route.dart';
import '../../auth/presentation/routes/signup_screen_route.dart';
import '../../home/presentation/routes/home_screen_route.dart';

abstract final class RouteRepository {
  static final loginScreen = LoginScreenRoute();
  static final signupScreen = SignupScreenRoute();
  static final homeScreen = HomeScreenRoute();
}
