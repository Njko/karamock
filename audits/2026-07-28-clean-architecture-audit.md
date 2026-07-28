# Audit Clean Architecture — Karamock
**Date :** 28 juillet 2026
**Auditeur :** GitHub Copilot (5 agents spécialisés iOS)
**Périmètre :** `Sources/Karamock/Karamock/` — Domain, Data, Présentation, DI, Concurrence Swift 6

---

## 1. Tableau de bord — État actuel

| Couche | Note | Statut | Problème dominant |
|--------|------|--------|-------------------|
| Domain | 4.5/10 | 🔴 Critique | Quasi-vide — entités métier dispersées dans `Views/` |
| Data (Repos/Services) | 6.0/10 | 🟠 Dégradé | DIP violé, protocoles définis dans la couche Data |
| Présentation (Views/VMs) | 6.5/10 | 🟠 Dégradé | `DiscoveryView` sans VM, `Container.shared` dans des Views |
| DI (FactoryKit) | 6.0/10 | 🟠 Dégradé | `MockSongDownloading` hardcodé en production |
| Concurrence Swift 6 | 6.5/10 | 🟠 Dégradé | Tasks orphelines → bug silencieux en prod |

**Note globale : 5.9 / 10**

> Le projet a de bonnes bases (`actor`, `@Observable`, typed throws, FactoryKit) mais souffre de deux pathologies majeures : les entités métier vivent dans `Views/`, et une Task orpheline peut marquer une chanson comme téléchargée même en cas d'annulation.

---

## 2. Top 10 des problèmes transversaux

### #1 🔴 Task orpheline dans `DownloadSongUseCase` — BUG PROD
**Fichiers :** `Domain/Use Case/DownloadSongUseCase.swift`, `ViewModels/SongDownloadViewModel.swift`

`repository.add(song)` est appelé inconditionnellement après la boucle, même si le téléchargement est annulé. Une chanson peut être marquée `.downloaded` sans que le téléchargement ait réussi. La Task dans `SongDownloadViewModel` n'est pas référencée → impossible à annuler.

```swift
// ACTUEL — dangereux
Task {
    for await progress in service.download(song) { continuation.yield(progress) }
    await repository.add(song)  // ← appelé même après annulation !
    continuation.finish()
}
```

**Correction :**
```swift
let task = Task {
    for await progress in service.download(song) {
        guard !Task.isCancelled else { break }
        continuation.yield(progress)
    }
    if !Task.isCancelled {
        await repository.add(song)
    }
    continuation.finish()
}
continuation.onTermination = { _ in task.cancel() }
```

---

### #2 🔴 `Song.id = UUID()` — Identité instable — BUG PROD
**Fichier :** `Views/Common/Model/Song.swift`

Chaque instanciation crée un nouvel UUID. `storage.contains(song)` dans `SimpleDownloadedSongsRepository` ne fonctionne jamais entre sessions. `Hashable` et `Equatable` sont sémantiquement cassés.

```swift
// ACTUEL — cassé
let id = UUID()  // UUID différent à chaque init → song1 != song2 même si mêmes données

// CORRECTION — identité déterministe
var id: String { "\(artist.lowercased())-\(title.lowercased())" }
```

---

### #3 🔴 `Playlist.gradientColors: [Color]` — SwiftUI dans le Domain
**Fichier :** `Views/Player/Model/Playlist.swift`

Une entité domaine importe SwiftUI. Couplage fort entre données métier et framework UI — rend tout test unitaire impossible, bloque la modularisation future.

**Correction :** Retirer `gradientColors` de `Playlist`, le résoudre côté View :
```swift
// Domain/Models/Playlist.swift — SANS import SwiftUI
struct Playlist: Identifiable, Hashable {
    let id: UUID
    let title: String
    let songs: [Song]
}

// Views — mapping côté UI uniquement
extension Playlist {
    var gradientColors: [Color] { ... }
}
```

---

### #4 🔴 Protocoles Domain définis hors du Domain — DIP Violation
**Fichiers :** `Repositories/CachedLyricsRepository.swift`, `Repositories/DownloadedSongsRepository.swift`, `Services/SongDownloading.swift`

`LyricsRepository`, `DownloadedSongsRepository`, `SongDownloading` sont définis dans les couches Data/Services. La couche Domain dépend d'eux sans les "posséder" — violation directe du Dependency Inversion Principle.

```
// ACTUEL (incorrect)
Domain (UseCase) ──depends on──▶ Data (protocole dans CachedLyricsRepository.swift)

// CORRECT (Clean Architecture)
Data (implémentation) ──implements──▶ Domain/Interfaces (protocole)
Domain (UseCase) ──depends on──▶ Domain/Interfaces (protocole)
```

---

### #5 🔴 `MockSongDownloading` hardcodé en production
**Fichier :** `KaramockContainer.swift`

```swift
var downloadSong: Factory<DownloadSongUseCase> {
    self { DownloadSongUseCase(service: MockSongDownloading(), ...) } // ← MOCK EN PROD
}
```

Aucune vraie implémentation de `SongDownloading` n'existe. `SongDownloading` n'est pas enregistré dans le container → non-swappable.

---

### #6 🟠 Entités métier dans `Views/`
**Fichiers :** `Views/Common/Model/Song.swift`, `Views/Common/Model/LyricsLine.swift`, `Views/Common/Model/KaraokeMode.swift`, `Views/Player/Model/Playlist.swift`

Le dossier `Domain/` ne contient qu'un seul modèle (`DownloadState`). Tous les vrais types métier vivent dans la couche UI. Toute modification d'une vue peut casser accidentellement une entité métier.

---

### #7 🟠 Dépendance Data → Views via `TimeUtilities.swift`
**Fichiers :** `Repositories/CachedLyricsRepository.swift`, `Views/Common/TimeUtilities.swift`

`CachedLyricsRepository` utilise `song.durationInSeconds` défini dans `Views/Common/TimeUtilities.swift`. La couche Data dépend de la couche Views — sens de dépendance interdit.

---

### #8 🟠 Logique de mapping métier dans `CachedLyricsRepository` — SRP Violation
**Fichier :** `Repositories/CachedLyricsRepository.swift`

Le calcul des timestamps (`Double(index) * (duration / lines.count)`) est de la logique métier dans un Repository. Un Repository récupère/stocke ; un Mapper transforme.

---

### #9 🟠 Code de test/mock dans le bundle de production
**Fichiers :** `Services/SongDownloading.swift` (`MockSongDownloading`), `Views/Common/Model/LyricsLine.swift` (`mockLyrics` global)

Des données de test polluent le bundle de production.

---

### #10 🟡 Couverture tests insuffisante + Container monolithique
Un seul ViewModel testé (`LibraryViewModel`). Les tests overrident au mauvais niveau (reconstruire le UseCase plutôt qu'overrider le Repository). `KaramockApp` sans `@MainActor` explicite.

---

## 3. Audit détaillé par couche

### 3.1 Couche Domain (4.5/10)

**Inventaire `Domain/` actuel :**
```
Domain/
├── Models/
│   └── DownloadState.swift   ← seul vrai modèle domaine ici
└── Use Case/
    ├── FetchLyricsUseCase.swift
    ├── DownloadSongUseCase.swift
    └── FetchDownloadedSongsUseCase.swift
```

**Entités mal placées :**
| Fichier actuel | Devrait être dans |
|---|---|
| `Views/Common/Model/Song.swift` | `Domain/Models/` |
| `Views/Common/Model/LyricsLine.swift` | `Domain/Models/` |
| `Views/Common/Model/KaraokeMode.swift` | `Domain/Models/` |
| `Views/Player/Model/Playlist.swift` | `Domain/Models/` (sans `[Color]`) |
| `Services/LyricsError.swift` | `Domain/Models/` |
| `Views/Common/TimeUtilities.swift` (extension Song) | `Domain/Extensions/` |

**Forces :**
- Pattern UseCase (`struct Sendable + nonisolated init + callAsFunction`) correct ✅
- `typed throws(LyricsError)` cohérent sur toute la pile ✅
- Gestion d'erreur exhaustive dans les ViewModels ✅

**Problèmes supplémentaires :**
- `Song.duration: String` — parsing fragile, retourne `0` silencieusement si mal formé
- Pas de protocole UseCase → ViewModels capturent les types concrets → non testables en isolation
- `DownloadSongUseCase` : fuite de Task (pas d'`onTermination`)

---

### 3.2 Couche Data — Repositories & Services (6/10)

**Inventaire :**
```
Repositories/
├── CachedLyricsRepository.swift   ← protocole LyricsRepository + actor (à séparer)
└── DownloadedSongsRepository.swift ← protocole + actor (à séparer)

Services/
├── LyricsError.swift              ← type Domain mal placé
├── LyricsFetching.swift           ← protocole + implémentation URLSession (à séparer)
└── SongDownloading.swift          ← protocole + MockSongDownloading (à séparer)
```

**Forces :**
- `actor` pour tous les repositories → thread-safety par conception ✅
- `typed throws` cohérent dans toute la chaîne ✅
- `Sendable` systématique sur tous les protocoles ✅
- Aucune dépendance circulaire ✅

**Problèmes :**
- Protocoles co-localisés avec leurs implémentations (DIP violation)
- Mapping texte→`[LyricsLine]` dans `CachedLyricsRepository` (SRP violation)
- `Song.id = UUID()` → `storage.contains(song)` ne fonctionne pas
- `MockSongDownloading` dans le bundle production
- `lyricsURL` free function au niveau module (encapsulation insuffisante)

---

### 3.3 Couche Présentation — Views/ViewModels (6.5/10)

**Inventaire ViewModels :**
```
ViewModels/
├── FullScreenPlayerViewModel.swift   @MainActor @Observable
├── LibraryViewModel.swift            @MainActor @Observable
└── SongDownloadViewModel.swift       @MainActor @Observable
```

**Views manquant un ViewModel :**
- `DiscoveryView` → données mockées hardcodées, aucun VM
- `SongOptionsSheet` → 5 `@State` locaux + logique métier inline

**Forces :**
- `@MainActor @Observable` cohérent sur tous les ViewModels ✅
- Injection via UseCases uniquement (jamais accès direct aux repositories) ✅
- `DownloadButton` 100% passif ✅
- Navigation type-safe avec `NavigationLink(value:)` ✅
- Accessibilité correctement annotée ✅

**Problèmes :**
- `FullScreenPlayerView` et `SongOptionsSheet` appellent `Container.shared` directement
- `SongOptionsSheet` : mutation de `PlayerState` directement depuis la View
- Timer de progression dans `FullScreenPlayerView` (appartient au ViewModel)
- `ViewModel?` optionnel avec fallback `mockLyrics` en prod
- Boutons prev/next sans action

---

### 3.4 Injection de Dépendances — FactoryKit (6/10)

**Inventaire `KaramockContainer.swift` :**
| Factory | Type | Scope | Problème |
|---|---|---|---|
| `lyricsFetching` | `LyricsFetching` | transient | scope trompeur |
| `lyricsRepository` | `LyricsRepository` | singleton | ✅ |
| `downloadedSongsRepository` | `DownloadedSongsRepository` | singleton | ✅ |
| `fetchLyrics` | `FetchLyricsUseCase` | transient | ✅ |
| `downloadSong` | `DownloadSongUseCase` | transient | ⚠️ MockSongDownloading hardcodé |
| `fetchDownloadedSongs` | `FetchDownloadedSongsUseCase` | transient | ✅ |
| `player` | `PlayerState` | singleton | ✅ |
| `fullScreenPlayerViewModel` | `ParameterFactory<Song, ...>` | transient | ✅ |
| `libraryViewModel` | `Factory` | transient | ✅ |
| `songDownloadViewModel` | `ParameterFactory<Song, ...>` | transient | ✅ |

**Forces :**
- Constructor injection systématique ✅
- `ParameterFactory` bien utilisé pour les VMs dépendant de `Song` ✅
- `.container` trait dans les tests pour isolation parallèle ✅
- Zéro dépendance circulaire ✅

**Problèmes :**
- `SongDownloading` absent du container → non-swappable en test
- `MockSongDownloading()` hardcodé dans la factory `downloadSong`
- Tests overrident au mauvais niveau (reconstruire UseCase vs overrider Repository)
- `LyricsFetching` protocol manque `nonisolated`
- Container monolithique → à éclater par feature/couche

---

### 3.5 Concurrence Swift 6 (6.5/10)

**Forces :**
- `@MainActor @Observable` sur tous les ViewModels ✅
- `actor` justifié pour les repositories (état mutable, hors MainActor) ✅
- Zéro `@unchecked Sendable` ni `nonisolated(unsafe)` ✅
- `typed throws` cohérent sur toute la pile ✅
- `nonisolated protocol : Sendable` correct ✅
- Tests `@MainActor` correctement annotés ✅

**Problèmes :**

| # | Sévérité | Fichier | Nature |
|---|---|---|---|
| 1 | 🔴 | `DownloadSongUseCase.swift` | Task orpheline, `add()` appelé après annulation |
| 2 | 🔴 | `SongDownloadViewModel.swift` | Task non trackée, pas de cancellation |
| 3 | 🔴 | `SongDownloading.swift` | `try?` avale `CancellationError` → boucle non stoppable |
| 4 | 🟠 | `*UseCase.swift` | `callAsFunction` implicitement `@MainActor` au lieu de `nonisolated` |
| 5 | 🟠 | `DownloadState` / `SongDownloadViewModel` | État `.failed` jamais atteint (SongDownloading non-throwing) |
| 6 | 🟡 | `MockDownloadedSongsRepository.swift` | Mock ne respecte pas le contrat de déduplication |
| 7 | 🟡 | `KaramockApp.swift` | `@MainActor` implicite via flag de build uniquement |

---

## 4. Roadmap de refactorisation en 3 phases

### ⚡ Phase 1 — Restructuration architecturale (~2–3h, risque zéro)
> Déplacer les fichiers aux bons endroits dans Xcode sans changer la logique.

| # | Tâche | Effort | Impact |
|---|-------|--------|--------|
| 1.1 | Créer `Domain/Interfaces/` et y extraire les 4 protocoles (`LyricsRepository`, `DownloadedSongsRepository`, `LyricsFetching`, `SongDownloading`) chacun dans son propre fichier | M | 🔴 |
| 1.2 | Déplacer `Song.swift`, `LyricsLine.swift`, `KaraokeMode.swift` → `Domain/Models/` | S | 🔴 |
| 1.3 | Déplacer `Playlist.swift` → `Domain/Models/` | S | 🔴 |
| 1.4 | Déplacer `LyricsError.swift` → `Domain/Models/` | S | 🟠 |
| 1.5 | Déplacer `PlayerState.swift` → `ViewModels/` | S | 🟡 |
| 1.6 | Déplacer `TimeUtilities.swift` → `Domain/Extensions/` (supprimer la dépendance Data→Views) | S | 🔴 |
| 1.7 | Renommer `SimpleDownloadedSongsRepository` → `InMemoryDownloadedSongsRepository` | S | 🟡 |
| 1.8 | Déplacer `MockSongDownloading` → `KaramockTests/Mocks/MockSongDownloading.swift` | S | 🟠 |
| 1.9 | Déplacer `mockLyrics` → `KaramockTests/Mocks/MockLyrics.swift` | S | 🟠 |
| 1.10 | Éclater `KaramockContainer.swift` → `DI/Container+Data.swift`, `DI/Container+Domain.swift`, `DI/Container+UI.swift` | S | 🟡 |

---

### 🔧 Phase 2 — Corrections fonctionnelles (~4–6h)
> Corriger les bugs réels qui affectent le comportement en production.

| # | Tâche | Effort | Impact |
|---|-------|--------|--------|
| 2.1 | **[BUG PROD]** Fixer `Song.id` : identifiant stable basé sur les données | M | 🔴 |
| 2.2 | **[BUG PROD]** Fixer la Task orpheline dans `DownloadSongUseCase` : `onTermination` + `Task.isCancelled` | S | 🔴 |
| 2.3 | **[BUG PROD]** Tracker la Task dans `SongDownloadViewModel` : `private var downloadTask`, `cancel()`, `deinit` | S | 🔴 |
| 2.4 | Enregistrer `SongDownloading` dans le container, créer `URLSessionSongDownloading` | M | 🔴 |
| 2.5 | Rendre `SongDownloading.download()` throwing → permettre à `.failed` d'être atteint | M | 🔴 |
| 2.6 | Supprimer `import SwiftUI` de `Playlist.swift` : remplacer `[Color]` par `[String]` | S | 🔴 |
| 2.7 | Extraire `LyricsMapper` dans `Domain/Mappers/LyricsMapper.swift` | M | 🟠 |
| 2.8 | Fixer `MockSongDownloading` (tests) : remplacer `try?` par gestion explicite `CancellationError` | S | 🟠 |
| 2.9 | Ajouter `@MainActor` à `KaramockApp` | S | 🟡 |
| 2.10 | Encapsuler `lyricsURL` comme méthode de `URLSessionLyricsFetching` | S | 🟡 |

---

### 🏗 Phase 3 — Améliorations qualité (~6–10h)

| # | Tâche | Effort | Impact |
|---|-------|--------|--------|
| 3.1 | Créer `DiscoveryViewModel`, brancher `DiscoveryView` dessus | M | 🟠 |
| 3.2 | Créer `SongOptionsViewModel`, extraire les 5 `@State` et la logique métier | M | 🟠 |
| 3.3 | Supprimer `Container.shared` direct des Views → injection via paramètre ou `@Environment` | M | 🔴 |
| 3.4 | Déplacer le Timer de progression vers `FullScreenPlayerViewModel` | M | 🟠 |
| 3.5 | Écrire les tests manquants : `DownloadSongUseCaseTests`, `SongDownloadViewModelTests`, `FullScreenPlayerViewModelTests` | L | 🔴 |
| 3.6 | Corriger les tests existants : override au niveau Repository (pas UseCase) | S | 🟡 |
| 3.7 | Ajouter `nonisolated` sur `LyricsFetching` protocol | S | 🟡 |
| 3.8 | Déduplication dans `InMemoryDownloadedSongsRepository` via `Set<Song.ID>` | S | 🟠 |
| 3.9 | Implémenter les boutons prev/next | M | 🟡 |
| 3.10 | Corriger le placement du `.sheet` (hors `ScrollView`) | S | 🟡 |

---

## 5. Architecture cible finale

```
Karamock/
├── Domain/
│   ├── Models/
│   │   ├── Song.swift                       ← id stable, durationInSeconds: TimeInterval
│   │   ├── LyricsLine.swift                 ← sans mockLyrics global
│   │   ├── Playlist.swift                   ← sans import SwiftUI, sans [Color]
│   │   ├── KaraokeMode.swift
│   │   ├── DownloadState.swift              ← déjà là ✅
│   │   └── LyricsError.swift                ← déplacé depuis Services/
│   │
│   ├── Interfaces/                          ← NOUVEAU
│   │   ├── LyricsRepository.swift           ← protocole extrait de Repositories/
│   │   ├── DownloadedSongsRepository.swift  ← protocole extrait de Repositories/
│   │   ├── LyricsFetching.swift             ← protocole extrait de Services/
│   │   └── SongDownloading.swift            ← protocole extrait de Services/
│   │
│   ├── UseCases/
│   │   ├── FetchLyricsUseCase.swift
│   │   ├── DownloadSongUseCase.swift        ← Task non-orpheline
│   │   └── FetchDownloadedSongsUseCase.swift
│   │
│   ├── Mappers/                             ← NOUVEAU
│   │   └── LyricsMapper.swift               ← logique texte→[LyricsLine] extraite du Repository
│   │
│   └── Extensions/
│       └── Song+Duration.swift              ← durationInSeconds déplacé depuis Views/
│
├── Data/
│   ├── Repositories/
│   │   ├── CachedLyricsRepository.swift         ← actor, sans mapping inline
│   │   └── InMemoryDownloadedSongsRepository.swift ← renommé
│   │
│   └── Services/
│       ├── URLSessionLyricsFetching.swift       ← lyricsURL encapsulée
│       └── URLSessionSongDownloading.swift      ← NOUVEAU (vraie implémentation)
│
├── Presentation/
│   ├── ViewModels/
│   │   ├── PlayerState.swift                    ← déplacé depuis Views/Player/Model/
│   │   ├── FullScreenPlayerViewModel.swift      ← Timer ici, sans fallback mockLyrics
│   │   ├── LibraryViewModel.swift
│   │   ├── SongDownloadViewModel.swift          ← Task trackée, cancel() exposé
│   │   ├── DiscoveryViewModel.swift             ← NOUVEAU
│   │   └── SongOptionsViewModel.swift           ← NOUVEAU
│   │
│   └── Views/
│       ├── KaramockApp.swift                    ← + @MainActor
│       ├── RootTabView.swift
│       ├── Common/
│       │   ├── StretchyView.swift
│       │   └── TimeFormatter.swift              ← formatTime() seulement
│       ├── Discovery/
│       │   ├── DiscoveryView.swift              ← consomme DiscoveryViewModel
│       │   └── PlaylistDetailView.swift
│       ├── Library/
│       │   └── LibraryView.swift                ← .sheet hors ScrollView
│       └── Player/
│           ├── FullScreenPlayerView.swift       ← sans Container.shared
│           ├── MiniPlayerBar.swift
│           └── SongOptionsSheet.swift           ← sans @State métier, sans Container.shared
│
├── DI/                                          ← NOUVEAU (éclaté depuis KaramockContainer.swift)
│   ├── Container+Data.swift
│   ├── Container+Domain.swift
│   └── Container+UI.swift
│
└── KaramockTests/
    ├── Mocks/                                   ← NOUVEAU
    │   ├── MockSongDownloading.swift            ← déplacé hors bundle prod
    │   ├── MockLyricsRepository.swift
    │   ├── MockDownloadedSongsRepository.swift  ← + déduplication correcte
    │   └── MockLyrics.swift                     ← mockLyrics déplacé depuis LyricsLine.swift
    ├── LibraryViewModelTests.swift              ← override au niveau Repository
    ├── DownloadSongUseCaseTests.swift           ← NOUVEAU
    ├── SongDownloadViewModelTests.swift         ← NOUVEAU
    └── FullScreenPlayerViewModelTests.swift     ← NOUVEAU
```

---

## 6. Ordre d'exécution recommandé

```
Phase 1 (restructuration fichiers)     ~2–3h  ← commencer ici, risque zéro
    ↓
Phase 2.1 + 2.2 + 2.3                  ~1h   ← bugs prod critiques en priorité absolue
    ↓
Phase 2.4 + 2.5                        ~2h   ← vraie implémentation SongDownloading
    ↓
Phase 2.6 → 2.10                       ~2h   ← nettoyage des violations restantes
    ↓
Phase 3.3 + 3.1 + 3.2                  ~3h   ← éliminer Container.shared, nouveaux VMs
    ↓
Phase 3.5 + 3.6                        ~3h   ← couverture tests
    ↓
Phase 3.4 + 3.7 → 3.10                 ~2h   ← polish final
```

**Quick wins (< 30 min chacun) :** 1.7 (renommage), 1.8 (MockSongDownloading → Tests), 1.9 (mockLyrics → Tests), 2.9 (`@MainActor` KaramockApp), 2.10 (lyricsURL encapsulation), 3.10 (.sheet placement).

---

*Rapport compilé à partir de 5 audits spécialisés : Domain, Data, Présentation, DI/FactoryKit, Concurrence Swift 6. Couvre 37 fichiers Swift.*
