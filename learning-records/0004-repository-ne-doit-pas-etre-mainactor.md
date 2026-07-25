# Un Repository ne doit pas être @MainActor — Nicolas a corrigé ce choix de conception

En Leçon 7, `DownloadedSongsRepository` avait été isolé à `@MainActor` par simplicité pédagogique. Nicolas a repoussé cette décision : forcer une couche donnée sur le thread principal n'est pas une bonne pratique (un vrai repository fait de l'I/O — réseau, disque — et bloquerait l'UI), et il voulait garder l'exercice réaliste plutôt que simplifié à tort. Correction appliquée : le protocole est devenu `Sendable` avec des méthodes `async`, et l'implémentation est un `actor` Swift ordinaire plutôt qu'une classe `@MainActor`. Confirmé par recherche (WWDC21 "Protect mutable state with Swift actors" : le main actor sert l'UI, le reste peut être `nonisolated` ou sur son propre acteur).

## Implications
- Règle à appliquer par défaut dans les prochaines leçons (Leçon 8 Bibliothèque, Leçon 9 DI, futurs repositories/services) : `@MainActor` réservé aux types qui alimentent directement l'UI (ViewModels, `PlayerState`) ; Repository/Service restent `nonisolated` ou sur un `actor` dédié.
- Conséquence directe pour la Leçon 8 : lire un repository-acteur n'est plus synchrone (`songs()` est `async`) — `LibraryView` devra `await` dans un `.task`, pas lire une propriété stockée.
- Nicolas surveille activement la qualité architecturale du code généré, pas seulement sa capacité à compiler — vérifier les choix de concurrence/isolation avec le même niveau d'exigence qu'un vrai code review avant de les enseigner.
