/// Every visible text, grouped by screen, in one place: translating the
/// app = providing these classes in another language (or moving them to
/// ARB files with `flutter gen-l10n`). Formats (dates, numbers) go
/// through `core/utils/formats.dart` and follow the locale (fr_FR).
library;

import 'dart:ui' show Locale;

/// The app's only language for now. Formats use [appLocaleTag].
const appLocale = Locale('fr', 'FR');
const appLocaleTag = 'fr_FR';

abstract final class CommonStrings {
  static const back = 'Retour';
  static const retry = 'Réessayer';
  static const cancel = 'Annuler';
  static const close = 'Fermer';
  static const save = 'Enregistrer';
  static const done = 'Terminé';
  static const search = 'Rechercher';
  static const notifications = 'Notifications';
  static const viewAll = 'Tout voir';
  static const copy = 'Copier';
  static const copied = 'Copié';
  static const loading = 'Chargement';
  static const loadMore = 'Afficher plus';
  static const showPassword = 'Afficher le mot de passe';
  static const hidePassword = 'Masquer le mot de passe';
  static const offlineTitle = 'Vous êtes hors ligne';
  static const offlineChecking = 'Vérification de la connexion…';
  static String offlineRetryIn(int s) =>
      'Données enregistrées affichées. Nouvel essai dans $s s.';
  static const offlineWritesDisabled =
      'Les modifications sont suspendues jusqu’au retour de la connexion.';
  static const today = 'Aujourd’hui';
  static const yesterday = 'Hier';
  static const justNow = 'À l’instant';
  static String minutesAgo(int n) => 'Il y a $n min';
  static String hoursAgo(int n) => 'Il y a $n h';
  static String daysAgo(int n) => 'Il y a $n j';
  static const notFoundTitle = 'Page introuvable';
  static const notFoundHeading = 'Ce lien ne fonctionne pas';
  static const notFoundBody = 'Il est peut-être incomplet ou obsolète.';
  static const goHome = 'Aller à l’accueil';
}

abstract final class NavStrings {
  static const home = 'Accueil';
  static const digitalId = 'Identité';
  static const activity = 'Activité';
  static const profile = 'Profil';
}

abstract final class AuthStrings {
  static const landingTitle = 'Votre quotidien\nVotre pays';
  static const landingBody =
      'Votre identité numérique, les élections, les pétitions et les services publics, au même endroit, en sécurité.';
  static const createAccount = 'Créer un compte';
  static const haveAccount = 'J’ai déjà un compte';
  static const signInTitle = 'Bon retour';
  static const signInBody = 'Connectez-vous pour accéder à votre identité numérique.';
  static const email = 'E-mail';
  static const emailHint = 'nom@exemple.fr';
  static const password = 'Mot de passe';
  static const signIn = 'Se connecter';
  static const forgotPassword = 'Mot de passe oublié ?';
  static const noAccount = 'Pas encore de compte ?';
  static const signUpLink = 'En créer un';
  static const demoTitle = 'Mode démo';
  static const demoBody = 'Utilisez un compte de démo (touchez pour remplir) :';
  static const signUpTitle = 'Créez votre compte';
  static const signUpBody =
      'Cela prend une minute. Votre identité est vérifiée ensuite.';
  static const firstName = 'Prénom';
  static const lastName = 'Nom';
  static const dateOfBirth = 'Date de naissance';
  static const dateOfBirthHint = 'Choisir une date';
  static const terms =
      'J’accepte les conditions d’utilisation et la politique de confidentialité.';
  static const signUp = 'Créer mon compte';
  static const haveAccountLink = 'Déjà inscrit ?';
  static const resetTitle = 'Réinitialiser le mot de passe';
  static const resetBody =
      'Saisissez votre e-mail. Si un compte existe, nous envoyons un lien de réinitialisation.';
  static const resetSend = 'Envoyer le lien';
  static const resetSentTitle = 'Consultez votre boîte mail';
  static const resetSentBody =
      'Si un compte existe pour cet e-mail, un lien de réinitialisation est en route. Il est valable 30 minutes.';
  static const backToSignIn = 'Retour à la connexion';
}

abstract final class HomeStrings {
  static const morning = 'Bonjour';
  static const afternoon = 'Bon après-midi';
  static const evening = 'Bonsoir';
  static const title = 'Votre quotidien\nVotre pays';
  static const documents = 'Documents';
  static const services = 'Services';
  static const elections = 'Élections';
  static const petitions = 'Pétitions';
  static const community = 'Votre commune';
  static const upcomingElection = 'PROCHAINE ÉLECTION';
  static String signatures(String n, String goal) => '$n signatures sur $goal';
  static const nothingNew = 'Rien de nouveau dans votre commune';
  static const nothingNewBody =
      'Les élections et pétitions près de chez vous apparaîtront ici.';
  static const savedCopy = 'Données enregistrées affichées';
}

abstract final class IdStrings {
  static const title = 'Identité numérique';
  static const cardLabel = 'CARTE D’IDENTITÉ NUMÉRIQUE';
  static const verified = 'Vérifiée';
  static const pending = 'En attente';
  static const suspended = 'Suspendue';
  static const tagline = 'Votre identité, toujours avec vous.';
  static const identityVerified = 'Identité vérifiée';
  static const identityPending = 'Vérification en cours';
  static const identitySuspended = 'Identité suspendue';
  static const openId = 'Ouvrir l’identité numérique';
  static const showCode = 'Afficher le code';
  static const shareId = 'Partager';
  static const verifyId = 'Vérifier une identité';
  static const personalDetails = 'Informations personnelles';
  static const manage = 'Gérer';
  static const fullName = 'Nom complet';
  static const dateOfBirth = 'Date de naissance';
  static const citizenNumber = 'N° de citoyen';
  static const email = 'E-mail';
  static const phone = 'Téléphone';
  static const address = 'Adresse';
  static const issued = 'Délivrée le';
  static const expires = 'Expire le';
  static const notProvided = 'Non renseigné';
  static const biometric = 'Protection biométrique';
  static String biometricOn(String label) => '$label : activé';
  static const biometricOff = 'Désactivée';
  static String biometricSwitch(String label) =>
      'Exiger $label pour afficher mon code';
  static const biometricBody =
      'Activée, personne ne peut afficher votre code sans votre visage ou votre empreinte, même téléphone déverrouillé.';
  static const biometricUnavailable =
      'La biométrie n’est pas disponible sur cet appareil. Votre code reste protégé par le verrouillage du téléphone.';
  static const codeTitle = 'Votre code d’identité';
  static const codeBody =
      'Présentez ce code à l’agent. Il change toutes les 2 minutes.';
  static String codeExpiresIn(int s) => 'Expire dans $s s';
  static const codeExpired = 'Ce code a expiré.';
  static const newCode = 'Nouveau code';
  static const codeHidden = 'Masqué pendant l’enregistrement de l’écran.';
  static const unlockToShow = 'Confirmez que c’est bien vous pour afficher le code.';
  static const confirm = 'Confirmer';
  static const shareTitle = 'Partager votre identité';
  static const shareBody =
      'Choisissez ce que l’autre personne verra. Le lien fonctionne 24 heures.';
  static const shareFullName = 'Nom complet';
  static const shareDob = 'Date de naissance';
  static const shareStatus = 'Statut de vérification';
  static const shareAddress = 'Adresse';
  static const createLink = 'Créer le lien';
  static const linkReady = 'Lien prêt';
  static String validUntil(String when) => 'Valable jusqu’au $when';
  static const copyLink = 'Copier le lien';
  static const verifyTitle = 'Vérifier une identité';
  static const verifyBody = 'Saisissez le code affiché sur le téléphone de l’autre personne.';
  static const verifyCode = 'Code';
  static const verifyHint = 'ex. SHR-482913';
  static const verify = 'Vérifier';
  static const verifyValid = 'Identité valide';
  static const verifyInvalid = 'Ce code n’est pas valide';
  static const verifyInvalidBody = 'Il a peut-être expiré. Demandez-en un nouveau.';
  static const verifyAnother = 'Vérifier un autre code';
  static const detailsTitle = 'Informations personnelles';
  static const detailsIdentity = 'Identité';
  static const detailsIdentityNote =
      'Le nom et la date de naissance viennent de l’état civil. Pour les corriger, contactez la mairie.';
  static const detailsContact = 'Coordonnées';
  static const detailsSaved = 'Vos coordonnées ont été enregistrées.';
}

abstract final class ActivityStrings {
  static const title = 'Activité';
  static const all = 'Tout';
  static const identity = 'Identité';
  static const civic = 'Citoyenneté';
  static const security = 'Sécurité';
  static const service = 'Services';
  static const emptyTitle = 'Aucune activité pour l’instant';
  static const emptyBody = 'Ce que vous faites avec votre identité apparaîtra ici.';
  static const reference = 'Référence';
  static const place = 'Lieu';
  static const when = 'Date';
  static const notYou =
      'Ce n’est pas vous ? Déconnectez-vous et changez votre mot de passe.';
}

abstract final class ProfileStrings {
  static const title = 'Profil';
  static const account = 'Compte';
  static const preferences = 'Préférences';
  static const security = 'Sécurité';
  static const support = 'Assistance';
  static const personalDetails = 'Informations personnelles';
  static const documents = 'Mes documents';
  static const pushNotifications = 'Notifications';
  static const pushNotificationsSub = 'Élections, pétitions et alertes d’identité';
  static const appearance = 'Apparence';
  static const system = 'Automatique';
  static const light = 'Clair';
  static const dark = 'Sombre';
  static const analytics = 'Partager les statistiques d’utilisation';
  static const analyticsSub = 'Anonymes, elles aident à améliorer l’app';
  static String appLock(String label) => 'Verrouiller avec $label';
  static const appLockSub = 'Demandé à l’ouverture de l’app';
  static const appLockUnavailable = 'Non disponible sur cet appareil';
  static const report = 'Signaler un problème';
  static const reportBody =
      'Décrivez ce qui s’est passé. Nous ajoutons la version de l’app, rien de personnel.';
  static const reportField = 'Que s’est-il passé ?';
  static const reportSend = 'Envoyer';
  static const reportSent = 'Merci, votre signalement est prêt à être envoyé.';
  static const reportFailed = 'Impossible d’ouvrir votre application mail.';
  static const reportSubject = 'Signalement de problème';
  static const about = 'À propos';
  static const devPanel = 'Scénarios de démo';
  static const devPanelSub = 'Forcer erreurs, listes vides, réseau lent…';
  static const signOut = 'Se déconnecter';
  static const signOutConfirm = 'Se déconnecter ?';
  static const signOutBody = 'Vos données enregistrées seront supprimées de ce téléphone.';
  static String version(String v) => 'Version $v';
}

abstract final class NotificationStrings {
  static const title = 'Notifications';
  static const markAllRead = 'Tout marquer comme lu';
  static const emptyTitle = 'Vous êtes à jour';
  static const emptyBody =
      'Les alertes sur votre identité et votre commune apparaîtront ici.';
  static const unread = 'Non lue';
}

abstract final class CivicStrings {
  static const elections = 'Élections';
  static const upcoming = 'À venir';
  static const past = 'Passées';
  static const pollingStation = 'Votre bureau de vote';
  static const notRegistered = 'Pas encore attribué';
  static const candidates = 'Candidats';
  static const independent = 'Sans étiquette';
  static const referendum = 'Question oui ou non';
  static const reminder = 'Me le rappeler la veille';
  static const reminderOn = 'Rappel activé';
  static const reminderOff = 'Rappel supprimé';
  static const closed = 'Terminée';
  static const electionsEmpty = 'Aucune élection prévue';
  static const electionsEmptyBody = 'Les prochaines élections de votre secteur apparaîtront ici.';
  static const petitions = 'Pétitions';
  static const petitionsEmpty = 'Aucune pétition pour l’instant';
  static const petitionsEmptyBody = 'Les pétitions de votre ville apparaîtront ici.';
  static const sign = 'Signer cette pétition';
  static const signed = 'Vous avez signé cette pétition';
  static const signedShort = 'Signée';
  static const municipal = 'Municipale';
  static const regional = 'Régionale';
  static const national = 'Nationale';
  static const referendumLevel = 'Référendum';
  static const election = 'Élection';
  static const signedSnack = 'Merci, votre signature a été ajoutée.';
  static const petitionClosed = 'Cette pétition est close';
  static const petitionSuccessful = 'Objectif atteint';
  static String by(String author) => 'Lancée par $author';
  static String endsOn(String date) => 'Se termine le $date';
  static String endedOn(String date) => 'Terminée le $date';
  static const confirmSignTitle = 'Signer cette pétition ?';
  static const confirmSignBody =
      'Votre nom sera comptabilisé. Une signature ne peut pas être retirée.';
}

abstract final class DocumentStrings {
  static const title = 'Documents';
  static const valid = 'Valide';
  static const expiringSoon = 'Expire bientôt';
  static const expired = 'Expiré';
  static const pending = 'En cours';
  static const unknown = 'Statut inconnu';
  static const issuer = 'Délivré par';
  static const number = 'Numéro';
  static const issued = 'Délivré le';
  static const expires = 'Expire le';
  static const noExpiry = 'Sans date d’expiration';
  static const status = 'Statut';
  static const emptyTitle = 'Aucun document';
  static const emptyBody = 'Les documents liés à votre identité apparaîtront ici.';
  static const renew = 'Renouveler ce document';
}

abstract final class ServiceStrings {
  static const title = 'Services';
  static String processing(int days) =>
      days <= 1 ? 'Environ 1 jour' : 'Environ $days jours';
  static const online = 'En ligne';
  static const inPerson = 'Sur place uniquement';
  static const inPersonBody =
      'Ce service demande de vous déplacer. Apportez votre pièce d’identité.';
  static const note = 'Note pour le service (facultatif)';
  static const noteHint = 'Ce qu’il faut savoir';
  static const request = 'Envoyer la demande';
  static const requestSent = 'Demande envoyée';
  static String requestReference(String r) =>
      'Votre référence : $r. Vous la retrouverez dans Activité.';
  static const emptyTitle = 'Aucun service disponible';
  static const emptyBody = 'Les services proposés par votre ville apparaîtront ici.';
}

abstract final class SearchStrings {
  static const hint = 'Élections, pétitions, services…';
  static const startTitle = 'Tout rechercher';
  static const startBody = 'Élections, pétitions, documents et services.';
  static const noResultTitle = 'Aucun résultat';
  static String noResultBody(String q) =>
      'Rien ne correspond à « $q ». Essayez un autre mot.';
  static const election = 'Élection';
  static const petition = 'Pétition';
  static const service = 'Service';
  static const document = 'Document';
}

abstract final class LockStrings {
  static const title = 'App verrouillée';
  static String unlockWith(String label) => 'Déverrouiller avec $label';
  static String turnOn(String label) => 'Activez $label pour ouvrir l’app';
  static const unlockPrompt = 'Déverrouiller l’app';
  static const faceId = 'Face ID';
  static const fingerprint = 'Empreinte digitale';
  static const deviceLock = 'Code de l’appareil';
}

abstract final class DevStrings {
  static const title = 'Scénarios de démo';
  static const body =
      'Change la façon dont le serveur simulé répond. Uniquement en mode démo.';
  static const expireToken = 'Faire expirer le jeton d’accès';
  static const expireTokenSub = 'Le prochain appel le renouvelle en silence';
  static const latency = 'Latence';
  static const badge = 'DÉMO';
  static const biometricTitle = 'Biométrie simulée';
  static const approve = 'Accepter';
  static const fail = 'Échouer';
}
