/// Every route of the app. No route string is written anywhere else.
abstract final class Routes {
  // Public
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const notFound = '/not-found';

  // Tabs
  static const home = '/home';
  static const digitalId = '/id';
  static const activity = '/activity';
  static const profile = '/profile';

  // Full screen
  static const personalDetails = '/id/details';
  static const notifications = '/notifications';
  static const search = '/search';
  static const elections = '/elections';
  static const petitions = '/petitions';
  static const documents = '/documents';
  static const services = '/services';

  /// Profile > My signature. [signatureThenBack] closes it once saved and
  /// hands the signature back (signing a petition).
  static const signature = '/signature';
  static const returnParam = 'return';
  static const signatureThenBack = '$signature?$returnParam=1';

  static String election(String id) => '$elections/${Uri.encodeComponent(id)}';
  static String petition(String id) => '$petitions/${Uri.encodeComponent(id)}';
  static String document(String id) => '$documents/${Uri.encodeComponent(id)}';
  static String service(String id) => '$services/${Uri.encodeComponent(id)}';

  /// Path patterns (go_router + analytics: screens are named by pattern,
  /// never by id).
  static const idParam = 'id';
  static const electionPattern = ':$idParam';

  static const public = {welcome, signIn, signUp, forgotPassword, notFound};

  /// Ids coming from links are checked before any call.
  static bool isValidId(String? id) =>
      id != null && RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id);
}
