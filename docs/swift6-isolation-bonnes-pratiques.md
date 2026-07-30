# Swift 6 — Isolation & Concurrence : Bonnes pratiques

> Référence rapide pour l'application des règles de concurrence Swift 6 dans ce projet.
> Contexte : `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — toute déclaration sans annotation explicite est implicitement `@MainActor`.

---

## Quoi annoter avec quoi

| Type de code | Annotation recommandée | Pourquoi |
|---|---|---|
| ViewModel, `@Observable` class | `@MainActor` | État mutable qui pilote l'UI — doit rester sur le thread principal |
| Repository avec état mutable partagé | `actor` | Protège l'état (cache, storage) sans bloquer le thread principal |
| UseCase struct sans état | `nonisolated func` | Aucun état à protéger, peut s'exécuter partout |
| Service réseau (URLSession) | `nonisolated func` | Opération I/O suspendue avec `await`, inutile de l'attacher au MainActor |
| DTO / struct de décodage (`Decodable`) | `nonisolated struct` | Pas d'état mutable, le confinement au MainActor n'a aucun sens |
| Protocole de frontière de couche | `nonisolated protocol : Sendable` | Permet aux `actor` et classes de se conformer librement |
| Modèle domaine (`Song`, `LyricsLine`) | Struct avec `let` → `Sendable` implicite | Valeur immutable, sans risque entre acteurs |
| Enum d'erreur (`LyricsError`) | Aucune (conforme implicite) | Enum sans associated values mutables est `Sendable` par nature |
| `init` d'un UseCase injecté via DI | `nonisolated init` | Le container DI crée les dépendances hors contexte MainActor |

---

## Anti-patterns à éviter

| Anti-pattern | Problème | Alternative |
|---|---|---|
| `@unchecked Sendable` | Contourne le compilateur, masque des data races réels | Rendre le type vraiment immutable ou utiliser un `actor` |
| `nonisolated(unsafe)` | Bypass total des garanties Swift 6 | Protéger l'état mutable avec un `actor` |
| `Task { }` sans référence stockée | Impossible à annuler, fuite mémoire potentielle | `private var task: Task<Void, Never>?` + `deinit { task?.cancel() }` |
| `try?` sur `Task.sleep` | Avale la `CancellationError`, la boucle continue après annulation | `try await Task.sleep(...)` dans un `do/catch` |
| `@MainActor` sur un service réseau | Exécute URLSession sur le thread UI, ralentit l'interface | `nonisolated func` — URLSession gère son propre threading |
| Protocole sans `nonisolated` | Implicitement `@MainActor`, empêche la conformance d'un `actor` | Toujours `nonisolated protocol : Sendable` pour les frontières de couche |

---

## Rappel des concepts clés

**Acteur** : boîte qui protège son état mutable — une seule tâche à la fois peut y accéder.

**`@MainActor`** : acteur global unique représentant le thread principal (UI).

**`nonisolated`** : code non associé à un acteur, exécutable sur n'importe quel thread.

**`Sendable`** : "passeport" permettant à une valeur de traverser la frontière entre deux acteurs en toute sécurité.
