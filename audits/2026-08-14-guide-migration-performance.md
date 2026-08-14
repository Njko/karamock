# Guide de migration — Performance du chemin chaud C++ / interop Swift

**Date :** 14 août 2026
**Périmètre :** uniquement le chemin exécuté à chaque frame de rendu des paroles — `LyricsRenderEngine.swift` (actor) et le moteur C++ qu'il pilote (`Engine/*.cpp`/`*.hpp`). Aucun point de ce guide ne touche à l'UI SwiftUI, aux Repositories, ou au reste de l'app.
**Prérequis :** ce guide s'édite/se build sur le Mac, dans Xcode. Applique et teste un point à la fois, dans l'ordre proposé ou non — chaque point est indépendant des autres.

## 0. Où on est déjà, où on va

Trois problèmes de performance plus anciens sont **déjà corrigés** dans le code actuel, pas la peine d'y retoucher :
- le rendu tourne déjà sur un `actor` hors `MainActor` (`LyricsRenderEngine`) ;
- `PixelBuffer` réutilise déjà sa capacité mémoire entre deux frames (`resize()` ne réalloue que si le buffer doit grandir) ;
- `TextRenderer` a déjà un cache de glyphes rasterisés (`glyphCache_`) et un cache de métriques horizontales (`hmetricsCache_`) ;
- `LyricsStore::indexAtTime` utilise déjà une recherche dichotomique (`std::upper_bound`), pas un scan linéaire.

Le rendu continu à chaque tick (jusqu'à 120 Hz sur un écran ProMotion) est un choix de produit assumé, pas un bug — Karamock veut garder la capacité d'animer des effets en continu plus tard (arrière-plans, accentuation). La vraie question de performance n'est donc pas "combien de frames peut-on éviter ?" mais **"combien coûte une frame ?"**. C'est ce que les 6 points ci-dessous réduisent, classés par impact estimé.

| # | Correctif | Fichier(s) | Impact |
|---|---|---|---|
| 1 | Réutiliser le buffer `Data` Swift entre deux frames | `LyricsRenderEngine.swift` | Élevé — évite une allocation heap à chaque frame |
| 2 | `sizeInBytes()` cohérent après un rétrécissement | `PixelBuffer.cpp/.hpp` | Moyen — combiné au point 1, évite une allocation surdimensionnée |
| 3 | Cache de largeur de texte (élimine aussi le kerning calculé deux fois) | `TextRenderer.cpp/.hpp` | Élevé — supprime une passe complète de mesure par ligne visible et par frame |
| 4 | Mémoriser les métriques verticales de la police | `LyricsPage.cpp/.hpp` | Faible mais gratuit |
| 5 | Blend par ligne plutôt que pixel par pixel | `PixelBuffer.cpp/.hpp`, `TextRenderer.cpp` | À mesurer — probablement déjà autovectorisé par le compilateur en Release |

---

## 1. Réutiliser le buffer `Data` Swift entre deux frames

**Fichier :** `LyricsRenderEngine.swift`

### Le problème

```swift
// AVANT
func frame(at time: Double, pixelWidth: Int, pixelHeight: Int) -> RenderedFrame? {
    guard fontLoaded, pixelWidth > 0, pixelHeight > 0 else { return nil }

    buffer.resize(Int32(pixelWidth), Int32(pixelHeight))
    buffer.fill(20, 20, 30)
    page.render(&buffer, font, &renderer, store, time)

    let byteCount = buffer.sizeInBytes()
    guard byteCount > 0 else { return nil }
    var rgba = Data(count: byteCount)
    rgba.withUnsafeMutableBytes { raw in
        if let dst = raw.bindMemory(to: UInt8.self).baseAddress {
            buffer.copyPixels(dst, byteCount)
        }
    }
    return RenderedFrame(
        rgba: rgba,
        width: Int(buffer.width()),
        height: Int(buffer.height()),
        bytesPerRow: Int(buffer.bytesPerRow())
    )
}
```

`Data(count: byteCount)` alloue un nouveau buffer sur le tas **à chaque appel de `frame()`**, potentiellement 30 à 120 fois par seconde tant que la lecture est active. Côté C++, `PixelBuffer` a déjà été corrigé pour éviter exactement ce piège (réutilisation de capacité) — mais côté Swift, ce même principe n'a jamais été appliqué au buffer final copié vers l'UI.

### Le correctif

Garde un buffer `Data` en propriété de l'acteur, et ne le réalloue que si sa taille doit changer (typiquement : jamais, sauf redimensionnement de l'écran) :

```swift
// APRÈS
actor LyricsRenderEngine {
    private var font = karamock.Font()
    private var fontLoaded = false
    private var store = karamock.LyricsStore()
    private var renderer = karamock.TextRenderer()
    private var page = karamock.LyricsPage()
    private var buffer = karamock.PixelBuffer()
    private var rgbaBuffer = Data()   // NOUVEAU — réutilisé entre les frames

    // ... loadFontIfNeeded, setLyrics inchangés ...

    func frame(at time: Double, pixelWidth: Int, pixelHeight: Int) -> RenderedFrame? {
        guard fontLoaded, pixelWidth > 0, pixelHeight > 0 else { return nil }

        buffer.resize(Int32(pixelWidth), Int32(pixelHeight))
        buffer.fill(20, 20, 30)
        page.render(&buffer, font, &renderer, store, time)

        let byteCount = buffer.sizeInBytes()
        guard byteCount > 0 else { return nil }

        if rgbaBuffer.count != byteCount {
            rgbaBuffer = Data(count: byteCount)
        }
        rgbaBuffer.withUnsafeMutableBytes { raw in
            if let dst = raw.bindMemory(to: UInt8.self).baseAddress {
                buffer.copyPixels(dst, byteCount)
            }
        }

        return RenderedFrame(
            rgba: rgbaBuffer,
            width: Int(buffer.width()),
            height: Int(buffer.height()),
            bytesPerRow: Int(buffer.bytesPerRow())
        )
    }
}
```

**Pourquoi ça marche sans risque de corruption d'image :** `Data` en Swift a une sémantique copy-on-write, comme `Array`. `RenderedFrame(rgba: rgbaBuffer, ...)` donne au code appelant sa propre référence à ce buffer. Au prochain appel de `frame()`, si ce buffer précédent est encore retenu ailleurs (par exemple le `CGImage` affiché à l'écran), Swift fait automatiquement **une** copie avant d'écrire dedans — jamais de corruption, jamais pire qu'avant. Si le buffer précédent n'est plus retenu (cas le plus fréquent), aucune copie n'a lieu : c'est le même bloc mémoire qui est réécrit. C'est un gain strict, jamais une régression.

### Vérifier

1. Build ⌘B sur iOS **et** tvOS (le moteur est partagé entre les deux cibles).
2. Lance l'app, ouvre le lecteur plein écran d'une chanson, vérifie que les paroles s'affichent et défilent normalement — aucun changement visuel attendu.
3. Redimensionne (rotation d'écran si applicable, ou simplement change d'appareil simulateur) pour vérifier que le chemin `rgbaBuffer.count != byteCount` réalloue bien correctement dans ce cas.
4. Optionnel, pour confirmer concrètement le gain : Xcode → Product → Profile (⌘I) → template **Allocations**, enregistre ~10 secondes de lecture. Avant ce correctif, tu verras une allocation `Data`/`__NSData` répétée à haute fréquence dans la timeline ; après, elle disparaît (sauf au premier appel et lors d'un redimensionnement).

---

## 2. `sizeInBytes()` incohérent après un rétrécissement du buffer

**Fichiers :** `PixelBuffer.cpp`, `PixelBuffer.hpp`

### Le problème

```cpp
// PixelBuffer.cpp — AVANT
void PixelBuffer::resize(int width, int height) {
    width_ = width > 0 ? width : 0;
    height_ = height > 0 ? height : 0;
    const std::size_t needed = static_cast<std::size_t>(width_) * height_ * 4;
    if (pixels_.capacity() < needed) {
        pixels_.resize(needed);
    }
}

std::size_t PixelBuffer::sizeInBytes() const { return pixels_.size(); }
```

`std::vector::resize()` n'est appelé que si la capacité actuelle est **insuffisante** (cas où le buffer grandit). Si le buffer rétrécit (ex. un écran plus petit après une rotation), `pixels_.size()` reste bloqué sur l'ancienne valeur, plus grande — c'est le comportement documenté de `std::vector` : la capacité n'est jamais réduite par un rétrécissement ([cppreference — `std::vector::resize`](https://en.cppreference.com/cpp/container/vector/resize)).

Résultat : `sizeInBytes()` renvoie la taille de l'ancien buffer plus grand, pas `width_ * height_ * 4` actuel. Combiné au point 1 ci-dessus, ça fait allouer et copier plus d'octets que nécessaire à chaque frame suivante, tant que le buffer ne regrandit pas. L'image affichée reste correcte (`bytesPerRow()`/`width()`/`height()` sont, eux, toujours justes), mais c'est un gaspillage systématique après tout rétrécissement.

### Le correctif

```cpp
// PixelBuffer.cpp — APRÈS
std::size_t PixelBuffer::sizeInBytes() const {
    return static_cast<std::size_t>(width_) * height_ * 4;
}
```

Une seule ligne — `sizeInBytes()` se recalcule depuis les dimensions logiques actuelles au lieu de lire la taille interne du `vector`. `resize()` n'a besoin d'aucun changement.

### Vérifier

Un test rouge/vert, sans avoir besoin de faire tourner l'app entière — `karamock.PixelBuffer` est directement utilisable depuis un test Swift Testing grâce à l'interop C++ :

```swift
// KaramockTests/PixelBufferTests.swift — NOUVEAU
import Testing
@testable import Karamock

struct PixelBufferSizeTests {
    @Test
    func sizeInBytesReflectsCurrentDimensionsAfterShrink() {
        var buffer = karamock.PixelBuffer()
        buffer.resize(200, 200)   // grandit d'abord, alloue une grande capacité
        buffer.resize(10, 10)     // rétrécit — la capacité interne reste grande

        #expect(buffer.sizeInBytes() == 10 * 10 * 4)
    }
}
```

Lance ce test **avant** le correctif : il doit échouer (`sizeInBytes()` renverra `200*200*4 = 160000` au lieu de `400`). Applique le correctif, relance : il doit passer. Pas de réglage de build particulier à faire pour ce fichier de test — `KaramockTests` est un target hébergé (`TEST_HOST` pointant vers `Karamock.app`), il importe le module `Karamock` déjà compilé plutôt que de compiler du C++ lui-même.

---

## 3. Largeur de texte recalculée à chaque frame (et kerning calculé deux fois)

**Fichiers :** `TextRenderer.cpp`, `TextRenderer.hpp`, appelé depuis `LyricsPage.cpp`

### Le problème

`LyricsPage::render` centre chaque ligne visible en mesurant sa largeur avant de la dessiner :

```cpp
// LyricsPage.cpp — inchangé, pour contexte
void drawCentered(PixelBuffer& target, const Font& font, TextRenderer& renderer,
                   const std::string& text, int baselineY, float pixelHeight, Color color) {
    const int width = renderer.measureWidth(font, text, pixelHeight);  // passe 1
    const int x = (target.width() - width) / 2;
    renderer.drawText(target, font, text, x, baselineY, pixelHeight, color);  // passe 2
}
```

Deux problèmes empilés :

1. **`measureWidth` reparcourt tout le texte à chaque frame**, pour un résultat qui ne dépend que de `(text, pixelHeight)` — deux valeurs qui ne changent que lorsque la ligne active change (une fois toutes les quelques secondes), pas à chaque frame.
2. **Le kerning est calculé deux fois par frame pour la même paire de caractères** : une fois dans `measureWidth` (`TextRenderer.cpp`, boucle de mesure), une fois dans `drawText` (boucle de dessin). Contrairement à l'avance/left-bearing (déjà mis en cache dans `hmetricsCache_`), l'appel `stbtt_GetCodepointKernAdvance` n'est mis en cache nulle part.

```cpp
// TextRenderer.cpp — AVANT
int TextRenderer::measureWidth(const Font &font, const std::string &text, float pixelHeight) const {
    if (!font.isValid()) {
        return 0;
    }

    const stbtt_fontinfo* fontInfo = static_cast<const stbtt_fontinfo*>(font.nativeHandle());
    const float scale = font.scaleForPixelsHeight(pixelHeight);
    float width = 0.0f;

    for (std::size_t k = 0; k < text.size(); ++k) {
        const int c = static_cast<unsigned char>(text[k]);

        auto it = hmetricsCache_.find(c);
        if (it == hmetricsCache_.end()) {
            int advance = 0, lb = 0;
            stbtt_GetCodepointHMetrics(fontInfo, c, &advance, &lb);
            it = hmetricsCache_.emplace(c, std::make_pair(advance, lb)).first;
        }
        width += it->second.first * scale;

        if (k + 1 < text.size()) {
            width += scale * stbtt_GetCodepointKernAdvance(fontInfo, c, static_cast<unsigned char>(text[k + 1]));
        }
    }
    return static_cast<int>(width);
}
```

### Le correctif

Un cache mémoïsé par `(texte, hauteur arrondie)` — pas besoin d'invalidation manuelle : dès que la ligne active change, le texte demandé change, donc la clé change, et l'ancienne entrée reste simplement inutilisée (le nombre d'entrées se stabilise autour de 2× le nombre de lignes de la chanson, largement négligeable en mémoire). Effet de bord recherché : sur un cache-hit, `measureWidth` ne recalcule plus rien du tout — le kerning n'est alors recalculé **qu'une seule fois par frame**, dans `drawText`, au lieu de deux.

```cpp
// TextRenderer.hpp — ajouter en tête de fichier
#include <map>

// TextRenderer.hpp — dans la classe, section private, à côté de hmetricsCache_
mutable std::map<std::pair<std::string, int>, int> widthCache_;
```

```cpp
// TextRenderer.cpp — APRÈS
int TextRenderer::measureWidth(const Font &font, const std::string &text, float pixelHeight) const {
    if (!font.isValid()) {
        return 0;
    }

    const int roundedHeight = static_cast<int>(pixelHeight + 0.5f);
    const auto key = std::make_pair(text, roundedHeight);
    const auto cached = widthCache_.find(key);
    if (cached != widthCache_.end()) {
        return cached->second;
    }

    const stbtt_fontinfo* fontInfo = static_cast<const stbtt_fontinfo*>(font.nativeHandle());
    const float scale = font.scaleForPixelsHeight(pixelHeight);
    float width = 0.0f;

    for (std::size_t k = 0; k < text.size(); ++k) {
        const int c = static_cast<unsigned char>(text[k]);

        auto it = hmetricsCache_.find(c);
        if (it == hmetricsCache_.end()) {
            int advance = 0, lb = 0;
            stbtt_GetCodepointHMetrics(fontInfo, c, &advance, &lb);
            it = hmetricsCache_.emplace(c, std::make_pair(advance, lb)).first;
        }
        width += it->second.first * scale;

        if (k + 1 < text.size()) {
            width += scale * stbtt_GetCodepointKernAdvance(fontInfo, c, static_cast<unsigned char>(text[k + 1]));
        }
    }

    const int result = static_cast<int>(width);
    widthCache_.emplace(key, result);
    return result;
}
```

`widthCache_` est `mutable` pour la même raison que `hmetricsCache_` juste au-dessus dans le même fichier : c'est un cache logique utilisé depuis une méthode `const` (`measureWidth`) — la classe reste conceptuellement immuable de l'extérieur, seul un détail d'implémentation interne change.

### Vérifier

Le texte affiché à l'écran doit être **strictement identique** avant/après — ce correctif change seulement la façon dont la largeur est calculée, jamais le résultat.

1. Avant le correctif : lance l'app, ouvre le lecteur plein écran, capture une image pendant l'affichage des paroles (⌘S dans le simulateur).
2. Applique le correctif, relance, reproduis exactement le même instant (même chanson, mets en pause pour figer la progression).
3. Compare les deux captures au pixel près (Aperçu → superposer les calques, ou tout outil de diff d'image) : elles doivent être identiques.
4. Build ⌘B sur iOS et tvOS.
5. Pour confirmer que le cache est bien utilisé (pas seulement que le résultat reste correct — un test de non-régression visuelle ne prouve jamais ça) : ajoute temporairement un compteur dans la branche cache-miss et affiche-le.

```cpp
// TextRenderer.cpp — instrumentation TEMPORAIRE, à retirer après vérification
#include <cstdio>
// ... dans measureWidth, juste avant `widthCache_.emplace(key, result);` :
std::printf("[widthCache] miss pour \"%s\" @ %dpx\n", text.c_str(), roundedHeight);
```

Tu dois voir ce message apparaître seulement au début de la lecture puis à chaque changement de ligne active — jamais à chaque frame une fois la ligne stabilisée.

---

## 4. Métriques verticales de la police recalculées à chaque frame

**Fichiers :** `LyricsPage.cpp`, `LyricsPage.hpp`

### Le problème

```cpp
// LyricsPage.cpp — AVANT, dans LyricsPage::render (appelé à chaque frame)
int ascent = 0, descent = 0, lineGap = 0;
font.verticalMetrics(&ascent, &descent, &lineGap);
const float lineAdvance = (ascent - descent + lineGap) * font.scaleForPixelsHeight(activeHeight);
```

`activeHeight` est une constante (`constexpr float activeHeight = 56.0f;`, définie juste au-dessus dans la même fonction), et `font` ne change jamais après le chargement initial (`loadFontIfNeeded` ne charge qu'une seule fois — `guard !fontLoaded else { return }` dans `LyricsRenderEngine.swift`). `lineAdvance` est donc en réalité **une valeur invariante sur toute la durée de vie de l'app**, recalculée en pure perte à chaque frame. Le coût unitaire de `verticalMetrics()` est faible (lecture de table de police), mais c'est un aller-retour gratuit à éliminer.

### Le correctif

```cpp
// LyricsPage.hpp — APRÈS
class LyricsPage {
public:
    void render(PixelBuffer& target, const Font& font, TextRenderer& renderer, const LyricsStore& lyrics, double currentTime) const;

private:
    mutable bool lineAdvanceCached_ = false;
    mutable float cachedLineAdvance_ = 0.0f;
};
```

```cpp
// LyricsPage.cpp — APRÈS, dans render()
float lineAdvance;
if (lineAdvanceCached_) {
    lineAdvance = cachedLineAdvance_;
} else {
    int ascent = 0, descent = 0, lineGap = 0;
    font.verticalMetrics(&ascent, &descent, &lineGap);
    cachedLineAdvance_ = (ascent - descent + lineGap) * font.scaleForPixelsHeight(activeHeight);
    lineAdvanceCached_ = true;
    lineAdvance = cachedLineAdvance_;
}
```

**Hypothèse dont dépend ce correctif, à garder en tête :** il suppose que la police ne change jamais après le premier chargement. C'est vrai aujourd'hui (une seule police, chargée une fois). Si une future fonctionnalité permet de changer de police en cours de vie de l'app (sélecteur de police, etc.), il faudra réinitialiser `lineAdvanceCached_ = false` au moment du rechargement — sinon `LyricsPage` continuera silencieusement à utiliser les métriques de l'ancienne police.

### Vérifier

Même principe qu'au point 3 : correctif invisible par construction, à vérifier par comparaison d'image avant/après (même scénario que décrit au point 3), plus un build croisé iOS/tvOS.

---

## 5. Blend pixel par pixel plutôt que par ligne (optionnel — à mesurer avant de l'appliquer)

**Fichiers :** `TextRenderer.cpp`, `PixelBuffer.cpp`, `PixelBuffer.hpp`

### Le problème

```cpp
// TextRenderer.cpp — AVANT, dans drawText
for (int gy = 0; gy < g.h; ++gy) {
    for (int gx = 0; gx < g.w; ++gx) {
        const std::uint8_t coverage = g.bitmap[static_cast<std::size_t>(gy) * g.w + gx];
        if (coverage != 0) {
            target.blendPixel(static_cast<int>(xpos) + g.ix0 + gx,
                              baselineY + g.iy0 + gy,
                              color.r, color.g, color.b, coverage);
        }
    }
}
```

```cpp
// PixelBuffer.cpp — AVANT
void PixelBuffer::blendPixel(int x, int y, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t coverage) {
    if (x < 0 || y < 0 || x >= width_ || y >= height_) {
        return;
    }
    const std::size_t i = (static_cast<std::size_t>(y) * width_ + x) * 4;
    const int inv = 255 - coverage;
    pixels_[i + 0] = static_cast<std::uint8_t>((r * coverage + pixels_[i + 0] * inv + 127) / 255);
    pixels_[i + 1] = static_cast<std::uint8_t>((g * coverage + pixels_[i + 1] * inv + 127) / 255);
    pixels_[i + 2] = static_cast<std::uint8_t>((b * coverage + pixels_[i + 2] * inv + 127) / 255);
}
```

Chaque pixel de chaque glyphe déclenche un appel de fonction qui refait le même bornes-check et le même calcul d'index individuellement — alors qu'une ligne entière de glyphe est contiguë en mémoire, aussi bien côté source (`g.bitmap`) que côté destination (`pixels_`).

**Contrairement aux points 1 à 4, celui-ci est une hypothèse d'optimisation, pas un problème confirmé** — un compilateur en Release autovectorise parfois déjà ce genre de boucle simple. Ne l'applique que si une mesure Instruments (voir §6) montre que le blend pèse effectivement dans le budget d'une frame.

### Le correctif

```cpp
// PixelBuffer.hpp — ajouter à la classe PixelBuffer
void blendScanline(int x, int y, const std::uint8_t* coverage, int length,
                    std::uint8_t r, std::uint8_t g, std::uint8_t b);
```

```cpp
// PixelBuffer.cpp — APRÈS
void PixelBuffer::blendScanline(int x, int y, const std::uint8_t* coverage, int length,
                                 std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    if (y < 0 || y >= height_ || length <= 0) {
        return;
    }

    // Clippe une seule fois pour toute la ligne, pas à chaque pixel.
    int startX = x;
    int startCov = 0;
    if (startX < 0) {
        startCov = -startX;
        startX = 0;
    }
    int endX = x + length;
    if (endX > width_) {
        endX = width_;
    }
    if (startX >= endX) {
        return;
    }

    std::uint8_t* row = pixels_.data() + (static_cast<std::size_t>(y) * width_ + startX) * 4;
    const std::uint8_t* cov = coverage + startCov;
    for (int px = startX; px < endX; ++px, row += 4, ++cov) {
        const std::uint8_t c = *cov;
        if (c == 0) continue;
        const int inv = 255 - c;
        row[0] = static_cast<std::uint8_t>((r * c + row[0] * inv + 127) / 255);
        row[1] = static_cast<std::uint8_t>((g * c + row[1] * inv + 127) / 255);
        row[2] = static_cast<std::uint8_t>((b * c + row[2] * inv + 127) / 255);
    }
}
```

```cpp
// TextRenderer.cpp — APRÈS, dans drawText : une seule boucle, un appel par ligne de glyphe
for (int gy = 0; gy < g.h; ++gy) {
    const std::uint8_t* row = &g.bitmap[static_cast<std::size_t>(gy) * g.w];
    target.blendScanline(static_cast<int>(xpos) + g.ix0, baselineY + g.iy0 + gy,
                          row, g.w, color.r, color.g, color.b);
}
```

Une fois vérifié qu'aucun appelant de `blendPixel` ne reste dans le code, retire-la de `PixelBuffer.hpp`/`.cpp` plutôt que de la laisser à côté de `blendScanline` — du code mort qui ne sert à rien d'entretenir.

### Vérifier

Correctif censé être **strictement invisible** (même résultat pixel, calculé différemment) : même scénario de comparaison d'image qu'aux points 3 et 4, plus build croisé iOS/tvOS.

---

## 6. Vérification finale : mesurer le budget par frame, pas le deviner

Une fois les points ci-dessus appliqués (au minimum 1 à 4, le point 5 étant optionnel) :

1. Xcode → Product → Profile (⌘I), sur un **appareil réel** si possible (le simulateur ne reflète pas fidèlement un budget CPU) — template **Time Profiler**.
2. Lance l'enregistrement, ouvre une chanson, lance la lecture, laisse tourner ~10 secondes sans interaction.
3. Arrête l'enregistrement. Dans le Call Tree, coche *Separate by Thread* et *Hide System Libraries*, cherche la branche menant à `LyricsRenderEngine.frame(at:pixelWidth:pixelHeight:)`.
4. Repère la durée moyenne d'un échantillon dans cette branche. Compare au budget de la cadence effective de l'appareil : **≈8,3 ms à 120 Hz** (écran ProMotion), **≈16,6 ms à 60 Hz** sinon.
5. Si le budget est tenu : rien de plus à faire, le rendu continu est viable tel quel.
6. Si le budget est dépassé : le levier sûr est un plafond de fréquence explicite, indépendant du contenu — `TimelineView(.animation(minimumInterval: 1.0/60.0, paused: !player.isPlaying))` côté `FullScreenPlayerView.swift`, un compromis produit assumé, jamais un skip qui devine ce qui a visuellement changé.

Source : [WWDC26 — Profile, fix, and verify: Improve app responsiveness with Instruments](https://developer.apple.com/videos/play/wwdc2026/268/).

---

## Hors périmètre de ce guide

Repéré en cours de relecture mais volontairement laissé de côté :

- **`PixelBuffer::fill()` et `blendPixel()`/`blendScanline()` ne renseignent jamais l'octet alpha** (`pixels_[i+3]`) — seul `fillTestPattern()` le fait. C'est un bug de correction (canal alpha non défini sur un buffer réellement utilisé), pas un problème de performance ; à traiter séparément si besoin.
- Trois autres points identifiés dans `audits/2026-08-14-performance-audit-complet.md` ne concernent pas le moteur C++ ni l'interop Swift : `Song.durationInSeconds` reparse une chaîne à chaque accès (`Song+Duration.swift`), une recherche linéaire dans `InMemoryDownloadedSongsRepository.add(_:)`, et un `VStack` non lazy dans `PlaylistDetailView`. Voir ce fichier directement si tu veux les traiter — ce guide ne couvre que le chemin chaud C++/Swift.
