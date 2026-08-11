import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Null keeps the complete application in local-only guest mode.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);
