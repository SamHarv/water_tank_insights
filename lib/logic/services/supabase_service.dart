// lib/logic/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String SUPABASE_URL = 'https://rjwoskagnmaqyiqcgegp.supabase.co';
  static const String SUPABASE_ANON_KEY =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqd29za2Fnbm1hcXlpcWNnZWdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1NjM0MTksImV4cCI6MjA2NDEzOTQxOX0.lHsiM7mfcVmzUz4EwJRMcPoyV4T256NWCDnycWt1VaM';

  // For connecting to external PostgreSQL database
  static const String DATABASE_CONNECTION_STRING =
      'postgresql://dbadmin:O66JL465EKHUObVPkRauZdTFQBSbhsFj@dpg-d0r4dj95pdvs73dlineg-a.singapore-postgres.render.com/ito5002_database';

  static Future<void> initialize() async {
    await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  }
}
