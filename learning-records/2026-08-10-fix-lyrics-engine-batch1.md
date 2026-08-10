# Audit Correctif : Premier batch d'optimisation du moteur de paroles
**Date** : 2026-08-10  
**Symptômes** : Crash EXC_BAD_ACCESS (ligne 45 LyricsRenderEngine.swift) + défilement figé + cadre non pleine largeur + lag slider

---

## 1. Crash EXC_BAD_ACCESS — Use-after-free (CRITIQUE)

### Cause
`LyricsRenderEngine.swift:45` : `let rgba = Data(bytes: buffer.__dataUnsafe(), count: buffer.sizeInBytes())`

Exposait un pointeur brut `const uint8_t*` vers le `std::vector pixels_` interne du `PixelBuffer` C++. L'interop Swift/C++ matérialise un temporaire `PixelBuffer` pour l'appel puis le détruit en fin d'instruction → le pointeur devient pendant (dangling). Le `Data(bytes:count:)` lisait de la mémoire libérée (invisible tant que l'allocateur n'a pas réutilisé le bloc), fatal au teardown/destruction (EXC_BAD_ACCESS).

### Correctif
- **PixelBuffer.hpp** : Ajout signature `void copyPixels(std::uint8_t* destination, std::size_t capacity) const;`
- **PixelBuffer.cpp** : Implémentation avec `std::memcpy` — la copie s'effectue **à l'intérieur du C++** où `pixels_` reste valide toute la durée de l'appel
- **LyricsRenderEngine.swift** : Remplacé l'accès pointeur par une allocation `Data(count:)` remplie via `withUnsafeMutableBytes { buffer.copyPixels(dst, byteCount) }`. Aucun pointeur ne franchit la frontière Swift/C++.

**Résultat** : Pas de UAF, mémoire bien gérée.

---

## 2. Défilement figé — Backlog d'acteur

### Cause
`.task(id: request)` redémarrait ~60 fps. Chaque tick postait un `engine.frame` vers l'acteur `LyricsRenderEngine` sans annuler les appels en vol. L'acteur traitait en FIFO et accumulait un backlog → latence croissante entre rendus. En parallèle, chaque frame (~2 Mo de `Data` + un `CGImage`) saturait le MainActor → le slider se figeait puis « déversait » ses valeurs en rafale.

### Correctif
**Rendu coalescé dans LyricsEngineView.swift** :
- Nouvel état : `@State private var isRendering = false`, `@State private var pendingRequest: FrameRequest?`
- `renderCurrent()` : si un rendu est en cours, on ne fait qu'updater `pendingRequest` (la requête la plus récente) et on retourne. Après chaque rendu, on enchaîne avec `pendingRequest` (s'il existe) dans une boucle.
- **Invariant** : un seul `await engine.frame(…)` en vol à la fois.

**Résultat** : Plus de backlog ; le moteur rend toujours l'instant le plus récent à sa cadence max ; MainActor libre. Slider réactif.

---

## 3. Cadre pas pleine largeur

### Cause
`Image(decorative:)` sans `.resizable()` s'affichait à sa taille intrinsèque (quelques pixels) et se centralisait dans le `frame(maxWidth: .infinity)` → cadre restreint.

### Correctif
Ajout `.resizable()` dans la branche `if let image` de `LyricsEngineView.swift`.

**Résultat** : Image remplit toute la largeur du frame.

---

## 4. Padding moteur — Pleine largeur

### Cause
`.padding()` global sur le `VStack` appliquait un inset horizontal partout, y compris sur le `TimelineView` (moteur).

### Correctif
**FullScreenPlayerView.swift** :
- Retiré `.padding()` global
- Appliqué `.padding([.horizontal, .top])` sur le bouton fermer (inset haut conservé)
- Appliqué `.padding(.horizontal)` sur titre, slider, boutons
- Le `TimelineView` ne reçoit aucun padding → pleine largeur

**Résultat** : Moteur occupe 100 % de la largeur ; autres éléments indentés comme avant.

---

## Fichiers modifiés
- `Sources/Karamock/Karamock/Engine/PixelBuffer.hpp`
- `Sources/Karamock/Karamock/Engine/PixelBuffer.cpp`
- `Sources/Karamock/Karamock/Engine/LyricsRenderEngine.swift`
- `Sources/Karamock/Karamock/Views/Player/FullScreenPlayer/LyricsEngineView.swift`
- `Sources/Karamock/Karamock/Views/Player/FullScreenPlayer/FullScreenPlayerView.swift`

## Validation
- Build iOS Simulator Debug : ✅ SUCCESS
- Pas de régression observée au démarrage

## Points à surveiller (suite)
1. **Coût du moteur** : `TextRenderer` rasterise chaque glyphe à chaque frame. Si la cadence reste basse malgré le coalescence, évaluer un cache de glyphes / buffer réutilisé.
2. **Timer vs drag** : `.onReceive(timer)` (0,5 s) écrit `progress` même pendant un drag slider → pouce peut « sauter ». À prévoir si observé en test.
