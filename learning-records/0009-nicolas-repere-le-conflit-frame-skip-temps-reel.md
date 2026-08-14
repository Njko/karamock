---
name: nicolas-repere-le-conflit-frame-skip-temps-reel
description: Nicolas repère qu'une recommandation de l'audit de performance (frame-skip) contredit un objectif produit implicite de Karamock (rendu temps réel), avant toute implémentation
metadata:
  type: user
---

En lisant la Leçon 43 (14 août 2026, avant toute implémentation côté Sources/), Nicolas a repéré que le correctif proposé — un frame-skip basé sur l'état visuel (ligne active + progression de transition) — reposait sur une hypothèse implicite fausse : que la liste de ce qui peut visuellement changer dans le lecteur est fermée. Il a fait remarquer que Karamock prévoit des arrière-plans animés (dégradés), des effets d'accentuation de la chanson en cours, et une animation continue de la progression de la ligne active — autant de cas où l'image change à chaque frame, pas seulement pendant une transition de ligne. Un frame-skip câblé sur l'énumération actuelle aurait silencieusement figé n'importe lequel de ces futurs effets sans qu'aucune erreur de compilation ne le signale.

L'audit (`audits/2026-08-14-performance-audit-complet.md`) et la Leçon 43 ont été révisés le même jour en conséquence : le rendu continu à chaque tick redevient un choix assumé (contrainte temps réel), et le levier de performance se déplace du nombre de frames vers le coût de chaque frame (cache de largeur mesurée, blend par scanline — Leçons 44/45, inchangées).

## Implications
- Contrairement aux écarts déjà documentés dans ce projet (trouvés en comparant une leçon à du code déjà écrit par Nicolas, ex. Leçons 25, 29, 31, 34), celui-ci a été repéré **avant** toute implémentation — une catégorie de vigilance différente : pas « le code diverge de la leçon » mais « la leçon elle-même contredit un objectif produit non encore écrit noir sur blanc ».
- Généraliser pour toute future recommandation de performance touchant à la boucle de rendu du moteur C++ : vérifier explicitement si elle suppose une liste fermée de ce qui peut visuellement changer, et si oui, la confronter aux objectifs produit de Karamock (`MISSION.md` → "Success looks like") avant de l'enseigner — pas seulement après un retour de Nicolas.
- Principe technique à retenir au-delà de ce cas précis : un frame-skip basé sur le contenu (« je sais quand rien ne change ») est un anti-pattern pour un moteur qui doit un jour supporter des effets continus ; le levier sûr et indépendant du contenu est de réduire le coût d'une frame, pas leur nombre — un plafond de fréquence explicite (`minimumInterval`) reste le seul levier de réduction de fréquence qui ne devine rien sur le contenu.
