---
name: nicolas-suit-une-recommandation-argumentee-swinject-vers-factory
description: Nicolas a changé d'avis sur le choix d'une librairie de DI (Swinject → Factory) après une recommandation sourcée, plutôt que de s'en tenir à son idée initiale
metadata:
  type: user
---

Nicolas a proposé Swinject pour la Leçon 11 (librairie de DI la plus connue historiquement). Avant d'écrire la leçon, j'ai vérifié via recherche web plutôt que de me fier à ma connaissance paramétrique (résolution au runtime chez Swinject, vs compile-time safety et alignement Swift 6 strict concurrency chez Factory ; sources actuelles qui déconseillent Swinject pour du SwiftUI neuf). J'ai présenté le compromis honnêtement — Swinject a un vrai avantage pour lui (modèle container/module proche de Dagger/Koin, son expérience Android) mais un vrai défaut (pas de sécurité à la compilation, contraire à toute la rigueur Swift 6 déjà enseignée). Nicolas a choisi Factory après avoir vu l'argumentation, changeant sa demande initiale.

## Implications
- Nicolas valorise une recommandation sourcée et argumentée plus qu'une simple exécution de sa demande initiale — proposer une alternative avec preuves à l'appui est approprié même après une décision explicite de sa part, tant que c'est fait avant d'investir du travail (ici : avant d'écrire la leçon complète).
- Confirme [[0005-nicolas-repere-violations-dependency-rule]] et [[0006-nicolas-applique-dependency-rule-de-facon-preventive]] : Nicolas construit une compréhension active de l'architecture, pas une simple checklist à suivre — il est réceptif à des arguments qui contredisent sa propre proposition initiale.
