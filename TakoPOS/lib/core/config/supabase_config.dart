/// Supabase configuration
/// Replace these with your actual Supabase project credentials
class SupabaseConfig {
  /// Your Supabase project URL
  /// Find this at: https://app.supabase.com/project/<project-ref>/settings/api
  static const String url = 'https://jxhjdmhxbfdfjiwhfksm.supabase.co';

  /// Your Supabase anon/public key
  /// Find this at: https://app.supabase.com/project/<project-ref>/settings/api
  /// This key is safe to use in client apps
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4aGpkbWh4YmZkZmppd2hma3NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzOTU0MzcsImV4cCI6MjA4OTk3MTQzN30.rQ0mhnAQcrF53begpPmSnelHLqIwhmmg7xE82bG2cdw';

  /// Your Supabase service role key (DO NOT expose in client apps)
  /// Only use this in secure server-side code
  /// static const String serviceRoleKey = 'YOUR_SERVICE_ROLE_KEY';
}
