/// What the simulator does with the next calls. Chosen in the scenario
/// panel (demo mode) or forced in tests.
enum MockScenario {
  normal('Normal', 'Réponses réalistes'),
  empty('Listes vides', 'Toutes les listes reviennent vides'),
  slow('Chargement lent', '3 à 5 s par appel'),
  serverError('Erreur serveur', 'Chaque appel échoue avec une 500'),
  offline('Réseau coupé', 'Chaque appel échoue : pas de connexion'),
  sessionExpired('Session expirée', 'Renouvellement refusé : vous êtes déconnecté'),
  rateLimited('Limite de débit', 'Chaque appel est refusé pendant 30 s'),
  validationRejected('Validation refusée', 'Chaque formulaire est rejeté');

  const MockScenario(this.label, this.description);
  final String label;
  final String description;
}
