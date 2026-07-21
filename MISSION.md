# Mission: Reproduire l'app KaraFun en SwiftUI — pratique iOS

## Why
Nicolas a une expérience Swift solide mais ancienne (production 2019–2021, UIKit/MVVM/RxSwift) et a suivi 8 leçons théoriques sur SwiftUI et les évolutions récentes du langage dans un espace de travail séparé — mais n'a **jamais écrit une ligne de SwiftUI dans un vrai projet Xcode**. Il veut reproduire l'interface de l'app mobile KaraFun (captures dans `reference/screenshots/`) pour retrouver un réflexe de développement iOS concret, et être capable de montrer et discuter du vrai code SwiftUI qu'il a écrit lui-même.

## Success looks like
- Un projet Xcode SwiftUI qui build et tourne sur son Mac, reproduisant fidèlement les écrans clés : "Découvrir" (playlists, quiz, styles en scroll horizontal), fiche chanson (choix Karaoké/Battle, chanteur, tonalité/tempo), lecteur plein écran avec paroles simulées et mini-lecteur persistant
- Usage correct et déclaratif de `TabView`, `NavigationStack`, `ScrollView`/`List`, présentation modale (`sheet`), `Slider`/`Toggle`, et animations SwiftUI de base
- Un état d'app structuré avec `@State`/`@Observable` — mise en pratique de ce qui a été vu en théorie ailleurs, pas une re-découverte
- Capacité à expliquer et modifier à la volée son propre code SwiftUI

## Constraints
- Développement réel (build/run, Previews) fait sur un Mac séparé avec Xcode ; la rédaction des leçons et du code se fait ici, sous Windows/Claude Code → le pont entre les deux est Git (dépôt `karamock` sur GitHub).
- Pas de sprint : rythme libre, en parallèle du poste actuel.
- Toutes les leçons et documents en français.
- Ne pas ré-expliquer depuis zéro ce qui est déjà couvert en théorie ailleurs (mental model déclaratif, `@State`/`@Binding`/`@Environment`, `@Observable`, async/await) — ici on **met en pratique**, on ne réenseigne pas.

## Out of scope
- Vrai moteur audio (AVAudioEngine/CoreAudio), synchronisation parole-par-parole réelle sur un fichier audio, scoring vocal (mode Battle) — tout ceci est simulé avec des données et un état factices.
- Vrai backend, vraie recherche de chansons, API KaraFun — données 100% mockées en local.
- Publication ou usage commercial : projet strictement personnel d'apprentissage, inspiré de l'app pour s'entraîner à la reproduire, pas pour la redistribuer.
