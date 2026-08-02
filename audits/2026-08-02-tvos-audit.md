# Audit tvOS — Karamock
**Date :** 02 août 2026
**Auditeur :** GitHub Copilot (3 agents spécialisés tvOS)
**Périmètre :** Navigation Siri Remote, Layout grand écran, Couche Player

---

## 1. Tableau de bord

| Domaine | Note | Statut | Problème dominant |
|---------|------|--------|-------------------|
| Navigation / Focus Engine | 4.5/10 | 🔴 Critique | `.sheet()` inaccessible sur tvOS, `NavigationStack` imbriqués |
| Layout / Composants UI | 4.0/10 | 🔴 Critique | `.borderedProminent` iOS-only, composants trop petits |
| Couche Player | 4.0/10 | 🔴 Critique | Absence totale de `.onPlayPauseCommand()`, boutons prev/next vides |

**Note globale : 4.2 / 10**

> Le projet a une bonne architecture cross-platform (branches `#if os(iOS)`/`#else`, composants dédiés `MiniPlayerBarTV`, `FocusStepperTV`) mais souffre de **deux flows utilisateur entièrement cassés** (options de chanson depuis Discovery et Library), et d'une **absence totale de gestion Siri Remote** dans le player.

---

## 2. Problèmes critiques (bloquants)

### 🚨 C1 — `.sheet()` ignoré silencieusement sur tvOS
**Fichiers :** `PlaylistDetailView.swift`, `LibraryView.swift`

Sur tvOS, `.sheet()` ne s'affiche pas. L'utilisateur sélectionne une chanson, rien ne se passe. Toute la flow d'options (mode karaoké, tonalité, tempo, téléchargement, lecture) est **inaccessible**.

**Solution :** Remplacer par `navigationDestination(for: Song.self)` + une vue dédiée `SongOptionsView` (pas une sheet).

```swift
// PlaylistDetailView.swift / LibraryView.swift
#if os(tvOS)
NavigationLink(value: song) {
    SongRow(song: song)
}
#else
Button { selectedSong = song } label: { SongRow(song: song) }
.sheet(item: $selectedSong) { SongOptionsSheet(song: $0) }
#endif

// Dans DiscoveryView.swift et LibraryView.swift, ajouter :
.navigationDestination(for: Song.self) { song in
    SongOptionsView(song: song)  // vue pleine page tvOS
}
```

---

### 🚨 C2 — `NavigationStack` imbriqués sur tvOS
**Fichiers :** `RootTabView.swift` (ligne ~22), `DiscoveryView.swift` (ligne ~8)

`RootTabView` crée un `NavigationStack` sur tvOS, et `DiscoveryView` en crée un second à l'intérieur. Les `NavigationStack` imbriqués produisent un comportement **indéfini** — navigation qui plante ou s'exécute dans le mauvais stack.

**Solution :** Supprimer le `NavigationStack` de `RootTabView` côté tvOS. Chaque onglet (`DiscoveryView`, `LibraryView`) gère son propre stack.

```swift
// RootTabView.swift — branche tvOS
#else
tabs
    .overlay(alignment: .bottom) {
        if let song = player.currentSong, !player.isExpanded {
            MiniPlayerBarTV(song: song)
                .padding(.horizontal, 60)
                .padding(.bottom, 40)
                .focusSection()
        }
    }
#endif
// Pas de NavigationStack ici — DiscoveryView et LibraryView ont les leurs
```

---

### 🚨 C3 — Absence totale de `.onPlayPauseCommand()`
**Fichiers :** `FullScreenPlayerView.swift`, `MiniPlayerBarTV.swift`

La télécommande Siri Remote possède un **bouton physique Play/Pause**. Sans handler, il n'est mappé nulle part dans l'app. L'utilisateur ne peut pas contrôler la lecture depuis la télécommande.

**Solution :**

```swift
// FullScreenPlayerView.swift — sur le VStack principal
.onPlayPauseCommand { player.isPlaying.toggle() }
.onMoveCommand { direction in
    switch direction {
    case .left:  progress = max(0, progress - 10)
    case .right: progress = min(song.durationInSeconds, progress + 10)
    default: break
    }
}

// MiniPlayerBarTV.swift — sur le conteneur HStack
.onPlayPauseCommand { player.isPlaying.toggle() }
```

---

### 🚨 C4 — `MiniPlayerBar.swift` compile sur tvOS avec une API iOS-only
**Fichier :** `MiniPlayerBar.swift` (ligne 14)

```swift
// ❌ API iOS 18+ uniquement — compile error sur tvOS
@Environment(\.tabViewBottomAccessoryPlacement) private var placement
```

**Solution :**

```swift
#if os(iOS)
struct MiniPlayerBar: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    // ...
}
#endif
```

---

### 🚨 C5 — `.buttonStyle(.borderedProminent)` / `.bordered` iOS-only dans `SongOptionsSheet`
**Fichier :** `SongOptionsSheet.swift` (lignes 31, 35)

Ces styles n'existent pas de manière équivalente sur tvOS. Les boutons principaux ("Jouer maintenant", "Ajouter à la file") ont un rendu incorrect ou ne sont pas correctement focusables.

**Solution :**

```swift
#if os(tvOS)
Button("Ajouter à la file d'attente") { }
    .buttonStyle(.card)
    .frame(maxWidth: .infinity)

Button("Jouer maintenant") {
    viewModel?.playNow()
    dismiss()
}
.buttonStyle(.borderless)
.frame(maxWidth: .infinity)
#else
Button("Ajouter à la file d'attente") { }
    .buttonStyle(.borderedProminent).tint(.pink)
    .frame(maxWidth: .infinity)

Button("Jouer maintenant") {
    viewModel?.playNow()
    dismiss()
}
.buttonStyle(.bordered)
.frame(maxWidth: .infinity)
#endif
```

---

### 🚨 C6 — Boutons prev/next avec corps d'action vide dans FullScreenPlayerView
**Fichier :** `FullScreenPlayerView.swift`

```swift
// ❌ Ne fait rien
Button { } label: { Image(systemName: "backward.fill") }
Button { } label: { Image(systemName: "forward.fill") }
```

Ces boutons sont focusables et sélectionnables, mais l'action est vide. Sur tvOS, l'utilisateur peut les atteindre et cliquer — rien ne se passe.

**Solution :** Implémenter `playPrevious()` / `playNext()` dans `PlayerState` et les connecter :

```swift
// PlayerState.swift — à enrichir
func playNext() {
    guard hasNext else { return }
    currentIndex += 1
    currentTime = 0
}

func playPrevious() {
    if currentTime > 3 { currentTime = 0; return }
    guard hasPrevious else { return }
    currentIndex -= 1
    currentTime = 0
}

// FullScreenPlayerView.swift
Button { player.playPrevious() } label: {
    Image(systemName: "backward.fill").font(.title)
}
Button { player.playNext() } label: {
    Image(systemName: "forward.fill").font(.title)
}
```

---

## 3. Problèmes importants (UX dégradée)

### ⚠️ I1 — `.buttonStyle(.plain)` supprime le halo de focus tvOS
**Fichiers :** `PlaylistSection.swift`, `PlaylistDetailView.swift`, `LibraryView.swift`, `FocusStepperTV.swift`

Sur tvOS, `.buttonStyle(.plain)` désactive l'animation de focus native (scale, ombre, halo lumineux). L'utilisateur ne peut pas distinguer visuellement quel élément est sélectionné.

**Solution par contexte :**
- `NavigationLink` dans `PlaylistSection` → `.buttonStyle(.card)`
- Boutons de liste → supprimer `.buttonStyle(.plain)` ou utiliser `.borderless`
- `FocusStepperTV` → `.buttonStyle(.card)` avec `frame(width: 80, height: 80)`

---

### ⚠️ I2 — `LyricsView` non navigable sur tvOS
**Fichier :** `LyricsView.swift` (ligne 15)

Le `ScrollView` des paroles ne reçoit pas le focus sur tvOS. Le défilement automatique fonctionne, mais l'utilisateur ne peut pas naviguer manuellement dans les paroles.

**Solution :**

```swift
ScrollView {
    VStack(alignment: .leading, spacing: 10) {
        ForEach(lyrics) { line in
            Text(line.text)
                .font(line == currentLine ? .title2.bold() : .title3)
                .foregroundStyle(line == currentLine ? .primary : .secondary)
                .id(line.id)
                .padding(.vertical, 4)
        }
    }
}
#if os(tvOS)
.focusable()
#endif
```

---

### ⚠️ I3 — `fullScreenCover` vs `navigationDestination` pour le player
**Fichier :** `RootTabView.swift`

Actuellement tvOS utilise `navigationDestination(isPresented:)` pour ouvrir le player plein écran. Cela ajoute une `NavigationBar` avec un bouton Back — chrome non-musical, transition push au lieu d'une présentation immersive.

**Solution :** Utiliser `fullScreenCover` sur les deux plateformes :

```swift
#else
tabs.fullScreenCover(isPresented: $player.isExpanded) {
    if let song = player.currentSong {
        FullScreenPlayerView(song: song)
            .persistentSystemOverlays(.hidden)
    }
}
#endif
```

---

### ⚠️ I4 — Labels de temps hardcodés "0:00" dans FullScreenPlayerView
**Fichier :** `FullScreenPlayerView.swift`

```swift
// ❌ Toujours "0:00"
Text("0:00")
Text("-" + song.duration)
```

**Solution :**

```swift
Text(formatTime(progress))
Text("-" + formatTime(song.durationInSeconds - progress))
```

---

### ⚠️ I5 — `.refreshable` non supporté sur tvOS
**Fichier :** `LibraryView.swift`

Le "pull to refresh" est un geste iOS uniquement. Sur tvOS il est ignoré ou peut crasher.

**Solution :**

```swift
#if !os(tvOS)
.refreshable { await viewModel.refresh() }
#endif
```

---

### ⚠️ I6 — `StretchyView` inadaptée à la Siri Remote
**Fichier :** `StretchyView.swift`

Sur tvOS, le scroll Siri Remote est discret (pas continu). L'effet stretchy ne se déclenche pratiquement jamais et peut produire un layout figé.

**Solution :**

```swift
extension View {
    func stretchy() -> some View {
        #if os(iOS)
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)
            let scaleFactor = (currentHeight + positiveOffset) / currentHeight
            return effect.scaleEffect(x: scaleFactor, y: scaleFactor, anchor: .bottom)
        }
        #else
        self  // désactivé sur tvOS
        #endif
    }
}
```

---

### ⚠️ I7 — Composants trop petits pour le grand écran

Tailles actuelles vs recommandées tvOS :

| Composant | Taille actuelle | Recommandé tvOS |
|-----------|----------------|-----------------|
| `PlaylistCard` | 150×150 pt | 280×280 pt |
| Artwork `SongRow` | 50×50 pt | 80×80 pt |
| Artwork `SongHeader` | 60×60 pt | 100×100 pt |
| `FocusStepperTV` boutons | ~22 pt (title2) | 80×80 pt |
| Header `PlaylistCoverHeader` | minHeight 220 pt | minHeight 400 pt |

---

### ⚠️ I8 — `.font(.caption)` illisible à 3 mètres dans `SongHeader`
**Fichier :** `SongHeader.swift` (ligne 19)

`.caption` (~12pt) est la plus petite taille de texte sur iOS. Sur tvOS vu à 3 mètres, c'est illisible.

**Solution :** Remplacer par `.callout` minimum sur tvOS :

```swift
HStack(spacing: 16) {
    Label("\(song.year)", systemImage: "calendar")
    Label(song.duration, systemImage: "clock")
    Label(song.key, systemImage: "wrench.fill")
}
#if os(tvOS)
.font(.callout)
#else
.font(.caption)
#endif
```

---

### ⚠️ I9 — `PlayerState` trop anémique pour gérer prev/next et la progression
**Fichier :** `PlayerState.swift`

Il manque `currentTime`, `playlist`, `currentIndex`, `playNext()`, `playPrevious()`. La progression est dans un `@State` local de la View — perdue à chaque fermeture du player.

**Solution :**

```swift
@MainActor
@Observable
final class PlayerState {
    var playlist: [Song] = []
    var currentIndex: Int = 0
    var isPlaying = false
    var isExpanded = false
    var currentTime: TimeInterval = 0

    var currentSong: Song? { playlist.indices.contains(currentIndex) ? playlist[currentIndex] : nil }
    var hasPrevious: Bool { currentIndex > 0 }
    var hasNext: Bool { currentIndex < playlist.count - 1 }

    func playNext() {
        guard hasNext else { return }
        currentIndex += 1
        currentTime = 0
    }

    func playPrevious() {
        if currentTime > 3 { currentTime = 0; return }
        guard hasPrevious else { return }
        currentIndex -= 1
        currentTime = 0
    }
}
```

---

### ⚠️ I10 — Overlay `MiniPlayerBarTV` sans `.focusSection()`
**Fichier :** `RootTabView.swift`

Sans `.focusSection()`, le moteur de focus tvOS peut ne pas entrer dans la zone overlay du mini player lors de la navigation vers le bas.

**Solution :**

```swift
MiniPlayerBarTV(song: song)
    .padding(.horizontal, 60)
    .padding(.bottom, 40)
    .focusSection()  // ← permet au focus d'atteindre le mini player
```

---

## 4. Problèmes mineurs (polish)

| # | Problème | Fichier | Solution rapide |
|---|---------|---------|-----------------|
| M1 | `.buttonStyle(.plain)` sur `FocusStepperTV` — pas de focus glow | `FocusStepperTV.swift` | Supprimer, utiliser `.card` |
| M2 | `PlaylistCoverHeader` `.stretchy()` sur tvOS (no-op) | `PlaylistCoverHeader.swift` | `#if !os(tvOS)` |
| M3 | `SongRow` `.padding(.vertical, 4)` — lignes trop serrées | `SongRow.swift` | `#if os(tvOS) .padding(.vertical, 16)` |
| M4 | `PlaylistCard` taille fixe sans adaptation | `PlaylistCard.swift` | `#if os(tvOS) .frame(width: 280, height: 280)` |
| M5 | `ModeCard` — aucun `buttonStyle` (pas de focus) | `ModeCard.swift` | `.buttonStyle(.borderless)` sur tvOS |
| M6 | Labels de temps "Diminuer"/"Augmenter" vagues | `FocusStepperTV.swift` | "Reculer de 10s" / "Avancer de 10s" |
| M7 | `.padding(.bottom, 40)` mini player (safe area 60pt standard) | `RootTabView.swift` | `safeAreaInset(edge: .bottom)` |
| M8 | `VStack(spacing: 12)` dans `SongOptionsForm` — trop serré | `SongOptionsForm.swift` | `#if os(tvOS) spacing: 24` |
| M9 | `ListStyle.plain` dans `LibraryView` | `LibraryView.swift` | `#if os(tvOS) .listStyle(.insetGrouped)` |
| M10 | Bouton "Fermer" (chevron.down) superflu sur tvOS | `FullScreenPlayerView.swift` | `#if !os(tvOS)` |

---

## 5. Roadmap de corrections

### Sprint 1 — Bloquants (~3h)

| # | Tâche | Fichier(s) | Effort |
|---|-------|-----------|--------|
| 1 | Entourer `MiniPlayerBar.swift` de `#if os(iOS)` | `MiniPlayerBar.swift` | S |
| 2 | Supprimer `NavigationStack` de `RootTabView` côté tvOS | `RootTabView.swift` | S |
| 3 | Créer `SongOptionsView.swift` (vue pleine page tvOS) | Nouveau fichier | M |
| 4 | Remplacer `.sheet()` par `NavigationLink` dans `PlaylistDetailView` et `LibraryView` | 2 fichiers | M |
| 5 | Ajouter `.navigationDestination(for: Song.self)` dans `DiscoveryView` et `LibraryView` | 2 fichiers | S |
| 6 | Remplacer `.borderedProminent`/`.bordered` par `#if os(tvOS)` dans `SongOptionsSheet` | `SongOptionsSheet.swift` | S |

### Sprint 2 — Fonctionnalités media (~2h)

| # | Tâche | Fichier(s) | Effort |
|---|-------|-----------|--------|
| 7 | Ajouter `.onPlayPauseCommand()` dans `FullScreenPlayerView` | `FullScreenPlayerView.swift` | S |
| 8 | Ajouter `.onPlayPauseCommand()` dans `MiniPlayerBarTV` | `MiniPlayerBarTV.swift` | S |
| 9 | Ajouter `.onMoveCommand()` pour seek dans `FullScreenPlayerView` | `FullScreenPlayerView.swift` | S |
| 10 | Enrichir `PlayerState` : `currentTime`, `playlist`, `playNext()`, `playPrevious()` | `PlayerState.swift` | M |
| 11 | Connecter les boutons prev/next dans `FullScreenPlayerView` | `FullScreenPlayerView.swift` | S |

### Sprint 3 — UX tvOS (~2h)

| # | Tâche | Fichier(s) | Effort |
|---|-------|-----------|--------|
| 12 | Remplacer `.buttonStyle(.plain)` par `.card`/`.borderless` | 4 fichiers | M |
| 13 | Ajouter `.focusSection()` sur `MiniPlayerBarTV` overlay | `RootTabView.swift` | S |
| 14 | Remplacer `navigationDestination` par `fullScreenCover` pour le player tvOS | `RootTabView.swift` | S |
| 15 | Ajouter `.focusable()` sur `LyricsView` ScrollView | `LyricsView.swift` | S |
| 16 | Corriger les labels de temps dans `FullScreenPlayerView` | `FullScreenPlayerView.swift` | S |

### Sprint 4 — Polish grand écran (~2h)

| # | Tâche | Fichier(s) | Effort |
|---|-------|-----------|--------|
| 17 | Adapter tailles : `PlaylistCard` (280pt), `SongRow` artwork (80pt), `SongHeader` artwork (100pt) | 3 fichiers | M |
| 18 | Corriger `.font(.caption)` → `.callout` dans `SongHeader` | `SongHeader.swift` | S |
| 19 | Désactiver `StretchyView` sur tvOS | `StretchyView.swift` | S |
| 20 | Supprimer `.refreshable` sur tvOS dans `LibraryView` | `LibraryView.swift` | S |
| 21 | Agrandir `FocusStepperTV` boutons (80pt, `.largeTitle`) | `FocusStepperTV.swift` | S |
| 22 | Adapter spacings dans `SongOptionsForm` et `SongRow` | 2 fichiers | S |

---

## 6. Synthèse des forces

Malgré les problèmes, le projet a **une bonne base cross-platform** :

- ✅ `FocusStepperTV` existe — excellent remplacement du `Slider` iOS
- ✅ `MiniPlayerBarTV` composant dédié tvOS
- ✅ `#if os(iOS)` / `#else` utilisé dans plusieurs fichiers
- ✅ `NavigationLink(value:)` / `navigationDestination` — architecture correcte
- ✅ `ButtonStyle` iOS explicites bien identifiés (`.plain`, `.borderedProminent`)
- ✅ Architecture MVVM + UseCase solide — les VMs fonctionnent sur les deux plateformes
- ✅ padding `.horizontal, 60` respecté dans `RootTabView` (safe area tvOS)

---

*Rapport compilé à partir de 3 audits spécialisés : Navigation/Focus Engine, Layout/Composants UI, Couche Player.*
