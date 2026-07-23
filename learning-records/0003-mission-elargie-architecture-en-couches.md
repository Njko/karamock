# La mission s'élargit : architecture en couches, puis tests, puis accessibilité

Après avoir couvert les 4 écrans de référence (Leçons 1 à 5), Nicolas a exprimé un besoin explicite : le code actuel n'a que des vues avec de la donnée mockée en dur (dossier `Views` unique), sans ViewModel, domaine/use case, ni repository/service — un manque qu'il veut combler en s'appuyant sur une fonctionnalité concrète (télécharger une chanson), avant d'enchaîner sur les tests puis l'accessibilité, dans cet ordre. `MISSION.md` a été mis à jour en conséquence (nouvelle section "Success looks like").

## Implications
- Les prochaines leçons (à partir de la Leçon 6) introduisent la couche architecture **progressivement** : ViewModel + Service d'abord (Leçon 6), Domain/UseCase seulement quand une vraie règle métier le justifiera (éviter l'abstraction prématurée) — ne pas empiler les 4 couches d'un coup.
- Les tests et l'accessibilité sont des axes confirmés pour après l'architecture, pas immédiatement — ne pas les avancer sans que Nicolas ne le redemande.
- Cet axe est cohérent avec le profil Tech Lead visé par [[MISSION.md]] : la capacité à discuter de structuration d'app compte davantage que la fidélité pixel des écrans, déjà bien couverte.
