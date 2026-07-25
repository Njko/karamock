---
name: nicolas-applique-dependency-rule-de-facon-preventive
description: Nicolas ne se contente plus de repérer les violations de la Dependency Rule après coup — il les anticipe avant même de commencer l'exercice
metadata:
  type: user
---

Avant de commencer la Leçon 9, Nicolas a demandé la révision de `LibraryViewModel` pour qu'il passe par un UseCase (`FetchDownloadedSongsUseCase`) plutôt que d'appeler `downloadedSongsRepository.songs()` directement — sans qu'aucune erreur n'ait encore été commise dans son propre code. C'est la même règle que [[0005-nicolas-repere-violations-dependency-rule]] (repérée après coup en Leçon 7/8), mais appliquée ici de façon préventive, par cohérence avec la leçon précédente.

## Implications
- La vigilance sur la Dependency Rule n'est plus ponctuelle : elle doit être appliquée dès l'écriture de toute nouvelle leçon introduisant un accès à une couche Data (Repository ou Service), sans attendre que Nicolas la corrige.
- Pattern à généraliser pour la suite de la mission : toute nouvelle fonctionnalité touchant `DownloadedSongsRepository` (ou un futur repository) doit prévoir un UseCase dédié à l'écriture ET un UseCase dédié à la lecture, jamais un accès direct au repository depuis un ViewModel.
