# Reproduire l'app KaraFun en SwiftUI — Resources

## Knowledge

- [Apple Developer: "SwiftUI Tutorials" (Landmarks)](https://developer.apple.com/tutorials/swiftui)
  Tutoriel officiel guidé, construit un projet complet et couvre `NavigationStack`, `List`, état et navigation en pratique. Meilleur point d'entrée avant la Leçon 1.
- [Hacking with Swift — "100 Days of SwiftUI" (Paul Hudson)](https://www.hackingwithswift.com/100/swiftui)
  Référence pratique la plus citée de la communauté. Utile en complément, jour par jour, pour chaque nouveau composant.
- [Apple Developer: `TabView`](https://developer.apple.com/documentation/swiftui/tabview)
  Doc officielle. Source primaire pour la Leçon 1 (barre d'onglets bas d'écran).
- [Apple Developer: `NavigationStack`](https://developer.apple.com/documentation/swiftui/navigationstack)
  Doc officielle. Remplace `NavigationView` (dépréciée depuis iOS 16). Source primaire pour la Leçon 1.
- [Apple Developer: `ScrollView`](https://developer.apple.com/documentation/swiftui/scrollview)
  Doc officielle, y compris le scroll horizontal (`.horizontal`) utilisé pour les rangées de playlists/quiz façon KaraFun.
- [Apple Developer: "SwiftUI essentials" — WWDC24 (session 10150)](https://developer.apple.com/videos/play/wwdc2024/10150/)
  Vue d'ensemble récente des fondamentaux, bon rappel avant de coder.
- [Apple Developer: `sheet(isPresented:onDismiss:content:)`](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:))
  Doc officielle pour la présentation modale — utilisée pour la fiche chanson (Karaoké/Battle, tonalité/tempo).
- [Apple Developer: `Slider`](https://developer.apple.com/documentation/swiftui/slider)
  Doc officielle — pour les réglages tonalité/tempo de la fiche chanson.
- [Apple Developer Human Interface Guidelines — "Tab bars"](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
  Bonnes pratiques Apple sur la structure d'une barre d'onglets — utile pour juger si notre reproduction respecte les conventions iOS plutôt que de copier bêtement le pixel.
- [Apple Developer Human Interface Guidelines — "Modality"](https://developer.apple.com/design/human-interface-guidelines/modality)
  Quand utiliser une feuille modale (`sheet`) plutôt qu'une navigation push — pertinent pour la fiche chanson et le lecteur plein écran.
- [Fatbobman — "SwiftUI Environment: Concepts and Practice"](https://fatbobman.com/en/posts/swiftui-environment-concepts-and-practice/)
  Article trouvé par Nicolas lui-même en debuggant la Leçon 4 (crash par confusion entre injection par type `.environment(_:)` et lecture par keypath `@Environment(\.key)`). Bonne référence de fond sur `@Environment`, à lire en entier avant d'introduire une clé personnalisée — mais dans ce projet, préférer systématiquement la forme par type pour tout objet `@Observable` (plus simple, pas de boilerplate `EnvironmentKey`).
- [Apple Developer: `ScrollViewReader`](https://developer.apple.com/documentation/swiftui/scrollviewreader)
  Doc officielle — défilement programmatique, utilisé en Leçon 5 pour synchroniser l'affichage des paroles avec la progression simulée.
- [Apple Developer: `Timer.TimerPublisher`](https://developer.apple.com/documentation/foundation/timer/timerpublisher)
  Doc officielle Combine — base de la simulation de progression de lecture en Leçon 5.

## Wisdom (Communities)

- [Swift Forums](https://forums.swift.org/)
  Forum officiel, haute confiance, catégorie "Using Swift" pour des questions pratiques SwiftUI.
- r/swift et r/iOSProgramming (Reddit)
  Communautés actives pour du troubleshooting concret (layout qui ne se comporte pas comme prévu, etc.).
- [Stack Overflow — tag `swiftui`](https://stackoverflow.com/questions/tagged/swiftui)
  Très haut volume de questions/réponses pratiques sur des comportements précis de composants (utile pour du dépannage ciblé, à croiser avec la doc officielle).

## Gaps

- Aucun gap identifié pour le moment.
