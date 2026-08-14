# Audit de performance — Karamock (complet)
**Date :** 14 août 2026
**Auditeur :** Claude (Sonnet 5)
**Périmètre :** Application entière — moteur de rendu C++ (`Engine/`), pont Swift/C++, boucle de rendu SwiftUI, couche Domain/Use Cases, Repositories, Views/listes.
**Méthode :** Lecture directe du code source actuel (aucune mesure Instruments), analyse de complexité algorithmique et de fréquence d'exécution par chemin critique.

> Cet audit remplace celui du 08/08/2026. Les problèmes P1 (rendu synchrone sur le thread UI), P2 (allocations non poolées) et P3 (absence de cache de glyphes) qu'il décrivait sont **corrigés** dans le code actuel (acteur `LyricsRenderEngine` hors MainActor, réutilisation de capacité dans `PixelBuffer`, cache de glyphes dans `TextRenderer`). Les constats ci-dessous partent de zéro sur l'état actuel du code.

> **Révision du 14 août 2026 (même jour, après relecture de la Leçon 43 tirée de cet audit) :** le §2 ci-dessous recommandait à l'origine un frame-skip basé sur l'état visuel (ne redessiner que si la ligne active ou la progression de transition changent). Nicolas a fait remarquer que cette hypothèse contredit un objectif produit explicite de Karamock : garder la capacité de rendu **temps réel**, pour de futurs arrière-plans animés (dégradés de couleur), des effets d'accentuation de la chanson en cours, et une animation continue de la progression de la ligne active — autant de cas où l'image change légitimement à *chaque* frame, pas seulement pendant les 0,5 s de transition entre deux lignes. Un frame-skip câblé sur l'énumération actuelle de ce qui anime (ligne + progression) casserait silencieusement tout futur effet continu oublié dans cette énumération. §2, le tableau de bord, la priorisation et la roadmap sont révisés en conséquence : la contrainte de rendu temps réel prime désormais sur la réduction du nombre de frames.

---

## 1. Tableau de bord

| Domaine | Note | Statut | Problème dominant |
|---|---|---|---|
| Boucle de rendu (Swift, orchestration des frames) | 6/10 | 🟡 À vérifier | Rendu continu à chaque tick assumé (contrainte temps réel) — budget par frame non mesuré à l'Instruments |
| Moteur de rendu C++ (texte/pixels) | 6/10 | 🟠 Moyen | Double parcours mesure+dessin, blend non vectorisé |
| Domain / Use Cases / Repositories | 7.5/10 | 🟡 Faible | Reparsing répété et recherche linéaire, impact marginal à l'échelle actuelle |
| Views / listes | 7/10 | 🟡 Faible | Une liste construite en dur (non lazy) sur l'écran de playlist |

**Note globale : 6/10** — Le travail par frame individuel est déjà bien optimisé (cache glyphes, pool mémoire, acteur hors MainActor). ~~Le point faible restant est algorithmique et architectural : le moteur refait tout le travail à chaque frame même quand rien ne change visuellement, ce qui domine largement les micro-inefficacités trouvées ailleurs.~~ *(Révisé — voir la note ci-dessus.)* Karamock veut garder la capacité de rendu temps réel (arrière-plans animés, effets, progression continue à venir) — le rendu continu à chaque tick est donc un choix assumé, pas un bug. Le vrai levier de performance est le **coût de chaque frame**, pas leur nombre : les correctifs C++ (§3, §4) restent la priorité, avec une vérification Instruments du budget par frame une fois appliqués.

---

## 2. 🟡 Rendu continu à haute cadence — un choix assumé, à budgétiser plutôt qu'à réduire

**Fichiers :** `FullScreenPlayerView.swift:35`, `LyricsEngineView.swift:30-44`, `LyricsRenderEngine.swift:36-58`

```swift
// FullScreenPlayerView.swift
TimelineView(.animation(minimumInterval: nil, paused: !player.isPlaying)) { _ in
    LyricsEngineView(lyrics: ..., currentTime: min(clock.currentTime(), song.durationInSeconds))
}
```

```swift
// LyricsEngineView.swift
private var request: FrameRequest {
    FrameRequest(timeMillis: Int((currentTime * 1000).rounded()), width: ..., height: ...)
}
...
.task(id: request) { await renderCurrent() }
```

`TimelineView(.animation)` déclenche une nouvelle valeur de `currentTime` à la cadence native de l'écran (jusqu'à 120 Hz sur ProMotion). `request` change donc à chaque tick puisqu'il encode le temps en millisecondes, ce qui relance `renderCurrent()` en continu pendant toute la lecture.

À chaque appel, `LyricsRenderEngine.frame(at:pixelWidth:pixelHeight:)` (`LyricsRenderEngine.swift:36-58`) :
1. Vide tout le buffer pixel par pixel (`PixelBuffer::fill`, O(largeur×hauteur)) ;
2. Recalcule la mesure et redessine les 3 lignes visibles ;
3. Copie l'intégralité du buffer C++ vers une `Data` Swift (`memcpy` complet) ;
4. Reconstruit un `CGDataProvider` + `CGImage`.

Le coalescing (`isRendering` / `pendingRequest`) évite bien l'empilement de rendus sur l'acteur — un seul `await engine.frame(…)` en vol à la fois, toujours l'instant le plus récent. C'est un mécanisme de *backpressure* (ne jamais accumuler de retard), et il reste valable et nécessaire quelle que soit la suite de cette section : sans lui, un rendu continu à haute cadence sous charge accumulerait un backlog exactement comme documenté dans le correctif du 10 août. Ce n'est pas ce mécanisme qui est remis en cause ici.

**Diagnostic initial (14 août, avant révision) :** en dehors des 0,5 s de transition entre deux lignes (`transitionDuration` dans `LyricsPage.cpp`), l'image affichée est aujourd'hui strictement identique d'un tick à l'autre — d'où la recommandation initiale d'un frame-skip basé sur l'état visuel (ligne active + progression de transition arrondie), pour ne redessiner que lorsque cette paire change.

**Pourquoi cette recommandation est révisée :** elle est correcte pour l'état *actuel* du produit, mais elle suppose implicitement que la liste des choses qui peuvent visuellement changer se limite à « ligne active + progression de transition » — une liste fermée, câblée en dur côté Swift. Karamock prévoit explicitement d'y ajouter des éléments qui changent *en continu*, à chaque frame, indépendamment de toute transition de ligne : arrière-plans animés (dégradés de couleur), effets d'accentuation de la chanson en cours, animation continue de la progression de la ligne active. Pour chacun de ces effets, l'image change à chaque tick — il n'y a plus d'« état visuel inchangé » à détecter. Un frame-skip câblé sur l'énumération actuelle continuerait de fonctionner pour la ligne active, mais **figerait silencieusement** tout futur effet continu que quelqu'un oublierait d'ajouter à cette énumération — un piège de maintenance plus coûteux, à terme, que le problème qu'il résout.

**Impact :** un rendu continu à chaque tick, tant que la lecture est active, redevient donc un choix assumé plutôt qu'un bug — c'est la seule architecture compatible avec les effets temps réel déjà prévus. La vraie question de performance n'est plus « combien de frames peut-on éviter de générer ? » mais « combien coûte une frame, et ce coût tient-il dans le budget (≈8,3 ms à 120 Hz, ≈16,6 ms à 60 Hz) ? ». C'est exactement la question que posent déjà §3 (double parcours mesure+dessin) et §4 (blend pixel par pixel) — ces deux correctifs deviennent la vraie priorité, puisqu'ils réduisent le coût par frame sans jamais dépendre de ce qui est en train d'animer.

**Solution révisée :**
1. Garder le rendu déclenché à chaque tick tant que `player.isPlaying` (le `paused:` de `TimelineView` reste le seul levier de réduction de fréquence sûr, parce qu'il ne dépend d'aucun contenu — pas de lecture, pas de rendu).
2. Appliquer §3 et §4 (coût par frame), qui bénéficient à un rendu continu comme à un rendu ponctuel — aucune régression à craindre de ce côté.
3. Une fois §3/§4 appliqués, mesurer avec Instruments (Time Profiler) si une frame complète (fill + mesure + dessin des 3 lignes + memcpy + CGImage) tient dans le budget sur l'appareil cible — pas en relisant le code.
4. Si la mesure montre un dépassement, le levier sûr est un plafond de fréquence explicite et uniforme, `TimelineView(.animation(minimumInterval: 1.0/60.0, paused: !player.isPlaying))` par exemple — un compromis produit assumé (limiter la fluidité pour tout le monde, y compris les futurs effets), jamais un skip qui devine ce qui a changé.

---

## 3. 🟠 Double parcours mesure + dessin à chaque frame

**Fichiers :** `LyricsPage.cpp:26-30`, `TextRenderer.cpp:45-104`

```cpp
void drawCentered(PixelBuffer& target, const Font& font, TextRenderer& renderer,
                   const std::string& text, int baselineY, float pixelHeight, Color color) {
    const int width = renderer.measureWidth(font, text, pixelHeight);  // passe 1 : tous les caractères
    const int x = (target.width() - width) / 2;
    renderer.drawText(target, font, text, x, baselineY, pixelHeight, color);  // passe 2 : tous les caractères
}
```

Appelé pour les 3 lignes visibles, à chaque frame tant que le rendu est déclenché (voir §2). `measureWidth` reparcourt tous les caractères du texte pour calculer une largeur qui **ne dépend que du texte et de `pixelHeight`**, deux valeurs constantes tant que l'index de ligne active ne change pas.

**Solution :** mémoriser la largeur mesurée par (texte, hauteur) — cache simple côté `LyricsPage` ou `TextRenderer`, invalidé uniquement quand l'index actif change — au lieu de la recalculer à chaque frame.

---

## 4. 🟠 Blend pixel par pixel, sans traitement par ligne

**Fichiers :** `TextRenderer.cpp:59-69`, `PixelBuffer.cpp:52-62`

```cpp
for (int gy = 0; gy < g.h; ++gy) {
    for (int gx = 0; gx < g.w; ++gx) {
        const std::uint8_t coverage = g.bitmap[gy * g.w + gx];
        if (coverage != 0) {
            target.blendPixel(xpos + g.ix0 + gx, baselineY + g.iy0 + gy, color.r, color.g, color.b, coverage);
        }
    }
}
```

Chaque pixel de chaque glyphe déclenche un appel de fonction (`blendPixel`) qui refait les bornes-checks (`x < 0 || y < 0 || ...`) et le calcul d'index individuellement, alors que toute une ligne de glyphe est contiguë en mémoire des deux côtés (bitmap source et buffer cible).

**Solution :** exposer une méthode `blendScanline(x, y, coverageRow, length, color)` sur `PixelBuffer` qui fait le clipping une fois par ligne puis boucle sur un pointeur brut, sans appel de fonction par pixel.

---

## 5. 🟡 `PixelBuffer::resize` / `sizeInBytes` incohérents après rétrécissement

**Fichiers :** `PixelBuffer.cpp:14-21`, `PixelBuffer.cpp:67`, `LyricsRenderEngine.swift:44-49`

```cpp
void PixelBuffer::resize(int width, int height) {
    width_ = width > 0 ? width : 0;
    height_ = height > 0 ? height : 0;
    const std::size_t needed = static_cast<std::size_t>(width_) * height_ * 4;
    if (pixels_.capacity() < needed) {
        pixels_.resize(needed);
    }
}
```

Si la nouvelle taille demandée est **inférieure ou égale à la capacité déjà allouée** (ex. rotation d'écran, redimensionnement de fenêtre), `pixels_.resize()` n'est pas appelé — `pixels_.size()` reste bloqué sur l'ancienne valeur, plus grande que `width_ * height_ * 4`. Or `sizeInBytes()` (`PixelBuffer.cpp:67`) renvoie `pixels_.size()`, pas `width_ * height_ * 4`.

Conséquence côté Swift (`LyricsRenderEngine.swift:44-49`) : `Data(count: byteCount)` alloue et `copyPixels` copie plus d'octets que ce que la frame courante contient réellement, à chaque frame suivante tant que le buffer ne regrandit pas. Le résultat visuel reste correct (`CGImage` ne lit que `bytesPerRow × height` depuis le début du buffer), mais c'est une allocation/copie inutilement grande, systématique après tout rétrécissement.

**Solution :** faire renvoyer à `sizeInBytes()` (et donc au calcul de `byteCount` côté Swift) `width_ * height_ * 4`, indépendamment de la capacité interne du vecteur :

```cpp
std::size_t PixelBuffer::sizeInBytes() const {
    return static_cast<std::size_t>(width_) * height_ * 4;
}
```

---

## 6. 🟡 `Song.durationInSeconds` reparse une chaîne à chaque accès, dans le chemin de rendu

**Fichiers :** `Song+Duration.swift:11-15`, `FullScreenPlayerView.swift:38`

```swift
extension Song {
    nonisolated var durationInSeconds: TimeInterval {
        let parts = duration.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}
```

Cette computed property refait un `split` + parsing `Double` à **chaque accès**, alors que `duration` (une `String` du type `"3:29"`) ne change jamais pour une chanson donnée. Elle est utilisée à l'intérieur du bloc `TimelineView(.animation)` :

```swift
currentTime: min(clock.currentTime(), song.durationInSeconds)
```

donc reparsée à la même cadence que le rendu (voir §2) — un travail répété pour une valeur qui pourrait être calculée une seule fois.

**Solution :** stocker `durationInSeconds` comme propriété calculée à l'initialisation de `Song`, ou la mémoriser en `let` local dans la vue plutôt que de la recalculer à chaque évaluation de `body`/closure.

---

## 7. 🟡 Recherche linéaire dans `InMemoryDownloadedSongsRepository`

**Fichier :** `InMemoryDownloadedSongsRepository.swift:19-22`

```swift
func add(_ song: Song) async {
    guard !storage.contains(song) else { return }
    storage.append(song)
}
```

`contains` sur un `[Song]` est O(n) et s'exécute à chaque téléchargement terminé. Impact négligeable à l'échelle actuelle (bibliothèque mock de quelques dizaines de titres), mais c'est un choix de structure de données qui ne passe pas à l'échelle : un `Set<Song.ID>` tenu en parallèle du tableau ramènerait la vérification à O(1).

---

## 8. 🟡 Liste non lazy dans `PlaylistDetailView`

**Fichier :** `PlaylistDetailView.swift:16-28`

```swift
ScrollView {
    VStack(spacing: 0) {
        PlaylistCoverHeader(playlist: playlist)
        ForEach(playlist.songs) { song in
            Button { selectedSong = song } label: { SongRow(song: song) }
        }
    }
}
```

`ForEach` est placé dans un `VStack` classique (pas un `LazyVStack`), à la différence de `LibraryView` qui utilise correctement `List`. Pour une playlist de ~50 chansons (cas réel dans `MockPlaylist.swift`), SwiftUI construit et met en layout toutes les `SongRow` dès l'affichage de l'écran, au lieu de les instancier à la demande pendant le scroll.

**Solution :** remplacer `VStack` par `LazyVStack` pour la section de liste (le header `PlaylistCoverHeader` peut rester hors du lazy stack).

---

## 9. Constats vérifiés sans problème identifié

Pour éviter toute impression d'audit incomplet, voici les zones examinées qui n'appellent **pas** de correction :

- `LyricsStore::indexAtTime` (`LyricsStore.cpp:39-47`) : recherche dichotomique correcte, O(log n).
- Cache de glyphes (`TextRenderer.cpp:17-43`) et cache de métriques horizontales (`hmetricsCache_`) : déjà en place et efficaces.
- `LyricsRenderEngine` : bien un `actor` hors `MainActor`, `Font`/`LyricsStore`/`TextRenderer`/`buffer` réutilisés entre les appels (pas de recréation par frame).
- `LibraryView`, `PlaylistSection`, `DiscoveryView` : utilisent `List` / `LazyHStack`, corrects.
- `CachedLyricsRepository` : cache par `Song.ID`, évite les re-fetches réseau.
- `URLSessionLyricsFetching`, `SimulatedSongDownloading`, Use Cases : logique séquentielle simple, pas de complexité inutile.

---

## 10. Priorisation

| # | Problème | Fichier(s) | Effort | Gain estimé | Ordre |
|---|---|---|---|---|---|
| 1 | Cache de largeur mesurée par (texte, hauteur) | `LyricsPage.cpp`, `TextRenderer.cpp` | S | Supprime une passe complète par ligne et par frame — bénéficie à un rendu continu comme à un rendu ponctuel | **1** |
| 2 | Blend vectorisé par scanline | `TextRenderer.cpp`, `PixelBuffer.cpp` | M | Réduit les appels de fonction par pixel — même bénéfice, indépendant de ce qui anime | **2** |
| 3 | ~~Frame-skip quand l'état visuel n'a pas changé~~ → Vérification Instruments du budget par frame | `LyricsEngineView.swift`, `FullScreenPlayerView.swift` | M | *(Révisé — incompatible avec les effets temps réel prévus, voir §2)* Mesurer le coût réel d'une frame après #1/#2 ; plafond `minimumInterval` seulement si la mesure le justifie | **3** |
| 4 | `LazyVStack` dans `PlaylistDetailView` | `PlaylistDetailView.swift` | S | Évite la construction/layout anticipés de toute la playlist | **4** |
| 5 | `durationInSeconds` mémorisé | `Song+Duration.swift` | S | Marginal mais gratuit, dans un chemin à haute fréquence | **5** |
| 6 | `sizeInBytes()` basé sur `width_*height_*4` | `PixelBuffer.cpp` | S | Supprime la copie/allocation surdimensionnée après rétrécissement | **6** |
| 7 | `Set` pour la déduplication | `InMemoryDownloadedSongsRepository.swift` | S | Négligeable à l'échelle actuelle, correct pour la montée en charge | **7** |

---

## 11. Roadmap

### Phase 1 — Réduire le coût par frame, pas leur nombre (immédiat)
```
Cache de largeur mesurée + blend par scanline
→ Rendu continu conservé (contrainte temps réel du produit) ; chaque frame coûte moins cher,
  quel que soit ce qui anime — bénéfice qui ne dépend d'aucune hypothèse sur le contenu
```

### Phase 1bis — Vérifier le budget, ne pas le deviner (dès Phase 1 appliquée)
```
Instruments Time Profiler sur un rendu continu à cadence native
→ Confirme (ou infirme) que le pipeline tient dans 8,3 ms (120 Hz) / 16,6 ms (60 Hz) par frame ;
  seulement si dépassement mesuré, plafonner via TimelineView(.animation(minimumInterval:))
  — un compromis produit explicite, jamais un skip basé sur le contenu
```

### Phase 2 — Nettoyage ciblé (court terme)
```
LazyVStack + fix sizeInBytes
→ Corrections locales, effort faible, pas de risque de régression visuelle
```

### Phase 3 — Polish (optionnel)
```
durationInSeconds mémorisé + Set de déduplication
→ Gains marginaux à l'échelle actuelle du mock, mais cohérents avec une montée en charge
```
