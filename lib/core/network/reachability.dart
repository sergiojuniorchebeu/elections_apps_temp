/// Can the back-end be reached right now? Used by the offline banner to
/// know when to come back online. Each implementation answers its way
/// (REST: `GET /health`, simulator: the "offline" scenario).
abstract interface class Reachability {
  Future<bool> check();
}
