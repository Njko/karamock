# Point de départ : Swift solide, théorie SwiftUI vue ailleurs, zéro pratique

Nicolas a une expérience Swift 5 en production (2019–2021, AXA Banque, UIKit/MVVM/RxSwift/Alamofire) et a suivi 8 leçons théoriques sur SwiftUI et Swift 6 dans un espace de travail séparé : mental model déclaratif, `@State`/`@Binding`/`@Environment`, `@Observable`, structured concurrency, accessibilité. Un quiz y a montré des lacunes encore actives sur struct/class/actor et Copy-on-Write (voir cette mission pour le détail).

**Ce qui est réellement nouveau ici** : ces leçons théoriques n'ont jamais couvert les composants UI concrets de SwiftUI — `TabView`, `NavigationStack`, `ScrollView`/`List`, présentation modale (`sheet`), `Slider`. Il ne faut pas supposer ces composants connus juste parce que `@State`/`@Binding` le sont : ce sont deux couches différentes (état vs. composants d'écran). Nicolas n'a par ailleurs jamais ouvert Xcode pour écrire du SwiftUI — cette mission est sa toute première pratique réelle sur la plateforme depuis 2021.

**Implications** : introduire chaque composant SwiftUI concret (TabView, NavigationStack, etc.) comme une nouveauté à part entière, avec son équivalent UIKit pour ancrage, même si l'état (`@State`) est déjà acquis en théorie. Ne pas re-expliquer `@State`/`@Binding`/`@Observable` en profondeur — juste les utiliser, avec un rappel bref si besoin.
