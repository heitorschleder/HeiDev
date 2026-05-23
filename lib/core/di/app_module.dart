import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';

@module
abstract class AppModule {
  @singleton
  SupabaseClient get supabaseClient => SupabaseConfig.client;
}
