# Karamock

Un projet iOS SwiftUI qui reproduit l'interface de l'application [KaraFun](https://www.karafun.com/) — construit comme terrain d'entraînement pratique, leçon après leçon, plutôt que comme un produit à publier.

Ce n'est **pas** l'app KaraFun officielle : aucune donnée réelle, aucun vrai moteur audio, aucun backend. Tout est mocké (voir [`MISSION.md`](MISSION.md) → *Out of scope*). L'objectif est d'apprendre SwiftUI, l'architecture en couches, les tests, l'accessibilité, la concurrence Swift 6 et le réseau, sur un cas concret et fidèle à un vrai produit.

## Comment ce repo fonctionne

Deux machines, un seul dépôt :

- **Le Mac** — le vrai projet Xcode (`Sources/Karamock/`) est écrit, buildé et exécuté ici par Nicolas.
- **Windows (Claude Code)** — les leçons pédagogiques (`lessons/*.html`) sont rédigées ici, à partir de l'état réel du code sur le Mac.

Git est le pont entre les deux : chaque machine pousse ses propres fichiers (le Mac pousse du code Swift, Windows pousse des leçons et de la documentation), et chaque session vérifie l'état de l'autre avant d'écrire quoi que ce soit. Voir [`AGENTS.md`](AGENTS.md) pour le détail des règles suivies par l'agent qui rédige les leçons.

## Structure du repo

| Chemin | Contenu |
|---|---|
| `Sources/Karamock/` | Le vrai projet Xcode (SwiftUI, Swift 6, iOS 26.5+) |
| `lessons/*.html` | Les leçons, dans l'ordre — chacune un fichier HTML autonome, en français |
| `MISSION.md` | Pourquoi ce projet existe, ce qui compte comme réussite, ce qui est hors périmètre |
| `NOTES.md` | Journal vivant : décisions, conventions, feuille de route des prochaines leçons |
| `RESOURCES.md` | Sources externes de confiance utilisées pour construire les leçons |
| `learning-records/*.md` | Décisions d'architecture et enseignements durables (équivalent d'ADR) |
| `audits/*.md` | Audits externes de l'architecture (ex. Clean Architecture, 2026-07-28) — lus pour ancrer les leçons, jamais rédigés ni modifiés depuis Windows |
| `reference/screenshots/` | Captures de référence de la vraie app KaraFun |
| `assets/` | `style.css`/`quiz.js` partagés par toutes les leçons |

## Le projet Xcode

- SwiftUI, Swift 6 (mode concurrence stricte, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), déploiement iOS 26.5+
- Architecture en couches : `Views` → `ViewModels` → `Domain/Use Case` → `Repositories`/`Services`
- Injection de dépendances via [FactoryKit](https://github.com/hmlongco/Factory) (`KaramockContainer.swift`)
- Tests avec [Swift Testing](https://developer.apple.com/documentation/testing) (`Sources/Karamock/KaramockTests/`)

Pour l'ouvrir : cloner ce dépôt sur un Mac avec Xcode 26+, ouvrir `Sources/Karamock/Karamock.xcodeproj`.

## Les leçons, par grand axe

| Axe | Leçons |
|---|---|
| Écrans de base (TabView, navigation, listes, lecteur) | 1 – 5 |
| Architecture en couches et DI (Domain/UseCase, Factory, tests) | 6 – 13 |
| Accessibilité (VoiceOver, Dynamic Type) | 14 – 17 |
| Interface avancée (header extensible, mini-lecteur, TabView bottom accessory) | 18, 20 – 21 |
| Concurrence Swift 6 | 19 |
| Réseau (URLSession, lyrics.ovh) | 22 |
| Gestion des erreurs typées (typed throws, SE-0413) | 23 |
| Nettoyage architecture post-audit | 24+ |

Le détail complet, à jour, est dans [`NOTES.md`](NOTES.md).

## Statut

Projet personnel d'apprentissage, non publié, sans licence associée — pas destiné à la redistribution.
