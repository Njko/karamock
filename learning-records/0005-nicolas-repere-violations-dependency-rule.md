---
name: nicolas-repere-violations-dependency-rule
description: Nicolas applique activement la Dependency Rule de la Clean Architecture pour repérer des incohérences dans le code généré, pas seulement pour le suivre passivement
metadata:
  type: user
---

Après la Leçon 7, Nicolas a repéré de lui-même que `SongDownloadViewModel` dépendait encore directement de `SongDownloading` (le Service) en plus de passer par `DownloadSongUseCase` — une incohérence que je n'avais pas signalée. Il a formulé la règle générale correctement ("un ViewModel devrait passer par un UseCase et un repository pour accéder à un service externe") et a demandé une leçon de nettoyage dédiée plutôt que d'accepter l'incohérence. Confirmé par recherche : c'est exactement la Dependency Rule de Robert C. Martin, largement reprise dans la littérature Clean Architecture iOS/MVVM.

## Implications
- Nicolas est maintenant au-delà du stade "suit les leçons" sur l'architecture en couches : il audite activement le code produit contre la règle de dépendance. Les prochaines leçons (Leçon 9 DI, futurs écrans) doivent rester rigoureuses sur ce point dès l'écriture, plutôt que de compter sur une correction a posteriori.
- Avant d'introduire une nouvelle dépendance dans un ViewModel à l'avenir, vérifier explicitement qu'elle pointe vers un UseCase (Domain), jamais directement vers un Service/Repository de la couche Data — cohérent avec [[0004-repository-ne-doit-pas-etre-mainactor]] qui montrait déjà une vigilance similaire sur l'isolation de concurrence.
