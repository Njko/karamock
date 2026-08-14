# Mission: Reproduire l'app KaraFun en SwiftUI — pratique iOS

## Why
Nicolas a une expérience Swift solide mais ancienne (production 2019–2021, UIKit/MVVM/RxSwift) et a suivi 8 leçons théoriques sur SwiftUI et les évolutions récentes du langage dans un espace de travail séparé — mais n'a **jamais écrit une ligne de SwiftUI dans un vrai projet Xcode**. Il veut reproduire l'interface de l'app mobile KaraFun (captures dans `reference/screenshots/`) pour retrouver un réflexe de développement iOS concret, et être capable de montrer et discuter du vrai code SwiftUI qu'il a écrit lui-même.

## Success looks like
- Un projet Xcode SwiftUI qui build et tourne sur son Mac, reproduisant fidèlement les écrans clés : "Découvrir" (playlists, quiz, styles en scroll horizontal), fiche chanson (choix Karaoké/Battle, chanteur, tonalité/tempo), lecteur plein écran avec paroles simulées et mini-lecteur persistant
- Usage correct et déclaratif de `TabView`, `NavigationStack`, `ScrollView`/`List`, présentation modale (`sheet`), `Slider`/`Toggle`, et animations SwiftUI de base
- Un état d'app structuré avec `@State`/`@Observable` — mise en pratique de ce qui a été vu en théorie ailleurs, pas une re-découverte
- Capacité à expliquer et modifier à la volée son propre code SwiftUI
- Une architecture en couches (Vue → ViewModel → Domain/UseCase → Repository/Service) introduite progressivement sur un cas concret (télécharger une chanson), pour être capable de discuter de structuration d'app à un niveau Tech Lead — pas juste des vues avec de la donnée mockée en dur
- Une fois l'architecture en place : couverture de tests (XCTest/Swift Testing) sur la logique extraite (ViewModel, UseCase), puis un passage accessibilité (VoiceOver, Dynamic Type) sur les écrans existants — dans cet ordre, décidé par Nicolas le 2026-07-23
- Une fois le cycle Nettoyage architecture bouclé (Leçons 24 à 30) : deux nouveaux axes décidés par Nicolas le 2026-07-31, dans cet ordre — (1) ajouter une target AppleTV au projet Xcode existant et faire tourner les écrans actuels tels quels dessus (mécaniques de build multi-plateforme : target, compilation conditionnelle, assets partagés — pas une exploration approfondie du Focus Engine/télécommande tvOS pour l'instant) ; (2) construire un mini moteur de paroles en C++, intégré au projet via l'interop Swift/C++, qui remplace la logique SwiftUI actuelle de gestion du karaoké — objectif pédagogique : la compatibilité d'un projet Xcode avec du code natif C++, pas un vrai moteur audio. Le moteur C++ garde le même modèle de timing simulé qu'aujourd'hui (répartition uniforme sur la durée), pour rester cohérent avec l'exclusion "vrai moteur audio" déjà actée ci-dessous.
- À partir de la Leçon 43 (incluse), décidé par Nicolas le 2026-08-14 : les leçons deviennent des leçons **bonus**. Elles ne font plus partie du socle pédagogique structuré ci-dessus — ce socle (Leçons 1 à 42) reste la référence pour l'apprentissage déclaratif SwiftUI, l'architecture en couches, les tests et l'interop C++. Les leçons bonus accompagnent la construction progressive d'un vrai produit, étape par étape, au fil des besoins réels qui se présentent (ex. l'audit de performance du 14 août 2026, `audits/2026-08-14-performance-audit-complet.md`) plutôt que suivre un programme pédagogique planifié à l'avance — plus proches d'un journal de bord technique que d'un curriculum.
- **Révision le 14 août 2026, même jour** : Nicolas suspend le format leçon (gabarit du skill `/teach` — quiz, `mission-tie`, etc.) pour cet axe bonus, jusqu'à nouvel ordre. Les Leçons 43-45 (frame-skip, cache de largeur/sizeInBytes, blend scanline) sont supprimées ; leur contenu technique est repris dans un guide de migration autonome (`audits/2026-08-14-guide-migration-performance.md`), pensé pour être suivi directement plutôt qu'enseigné. Le socle Leçons 1-42 n'est pas concerné par cette pause.

## Constraints
- Développement réel (build/run, Previews) fait sur un Mac séparé avec Xcode ; la rédaction des leçons et du code se fait ici, sous Windows/Claude Code → le pont entre les deux est Git (dépôt `karamock` sur GitHub).
- Pas de sprint : rythme libre, en parallèle du poste actuel.
- Toutes les leçons et documents en français.
- Ne pas ré-expliquer depuis zéro ce qui est déjà couvert en théorie ailleurs (mental model déclaratif, `@State`/`@Binding`/`@Environment`, `@Observable`, async/await) — ici on **met en pratique**, on ne réenseigne pas.

## Out of scope
- Vrai moteur audio (AVAudioEngine/CoreAudio), synchronisation parole-par-parole réelle sur un fichier audio, scoring vocal (mode Battle) — tout ceci est simulé avec des données et un état factices. Le futur moteur de paroles en C++ (voir "Success looks like") ne change pas cette limite : il reprend le même timing simulé, seule sa mise en œuvre change de langage.
- Vrai backend, vraie recherche de chansons, API KaraFun — données 100% mockées en local.
- Publication ou usage commercial : projet strictement personnel d'apprentissage, inspiré de l'app pour s'entraîner à la reproduire, pas pour la redistribuer.
