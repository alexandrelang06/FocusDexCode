# FocusDex — Cahier des charges (v0.1)

> **STATUT (MVP construit et vérifié en simulateur)** : projet Xcode `FocusDex.xcodeproj` créé, build
> vert. Onboarding + accueil + focus + habitudes + dex (411 créatures) + boutique + paywall + réglages +
> compte + crédits, boucle œuf→éclosion→évolution→diplôme, 2 tons visuels. Décisions actées : nom
> **FocusDex**, freemium + IAP, MVP complet d'un coup, les 2 tons proposés (self-care « Cocon » /
> productivité « Focus »), roster **Tuxemon** (CC-BY-SA). Voir `README.md` pour build & capacités à activer.

> *Nom provisoire : FocusDex (autres pistes : Hatchly, Focusmon, Nestful, Habitmon, Zenlings). À trancher.*

App **iPhone** de **focus + habitudes** où chaque session de concentration et chaque habitude tenue
fait **éclore et évoluer des créatures** — on remplit un **dex** de 411 créatures (Tuxemon).
= **Finch** (chaleur / self-care) × **Forest** (sessions de concentration) × **la collection Pokémon**
(le hook que personne n'a dans le focus).

---

## 1. Pitch
« Concentre-toi, tiens tes habitudes → ton œuf éclot, ta créature grandit, évolue, et rejoint ton dex.
Attrape-les toutes en prenant soin de toi. »

## 2. Pourquoi ce concept (données marché réelles)
- **La mécanique pet + collection se vend à grande échelle quand le carburant est grand public** :
  - **Finch** (oiseau self-care) : ~**30-40 M$ ARR**, bootstrappé, freemium + abo.
  - **Forest** (focus, planter un arbre) : **2 M+ d'acheteurs**, **one-time 3,99 $**.
  - Widgetable 384k avis, Pocket Love 248k, My Talking Pet 174k… (tous free + IAP/abo).
- **Différenciateur clé** : Finch = **1** oiseau, Forest = des arbres. Nous = **collection de 411 créatures
  avec évolutions / types / shiny** → hook « gotta catch 'em all » **inédit** dans le focus/self-care.
- 100 % **iPhone-natif**, **aucune connexion de compte**, **zéro risque juridique** (carburant = tes
  propres sessions/habitudes, sur l'appareil).

## 3. Plateforme & tech
- **iOS 17+**, **SwiftUI** + **SpriteKit** (rendu des créatures animées, comme Duo Run).
- **Cœur de créatures** isolé dans un **Swift Package réutilisable** (moteur éclosion/évolution/dex +
  données/sprites Tuxemon + rendu) → réutilisé plus tard par l'app **Mac (tokens)**.
- **Persistance locale** (SwiftData/UserDefaults) ; sync iCloud (CloudKit) en option plus tard.

## 4. Boucle principale
1. Tu lances une **session de focus** (minuteur type Pomodoro) OU tu coches une **habitude / tâche**.
2. Réussite → **XP + bonbons (candy)** → l'**œuf actif** progresse.
3. L'œuf **éclot** → la créature **gagne des niveaux** et **évolue** (lignes d'évolution Tuxemon :
   `basic → stage1 → stage2`).
4. À maturité → la créature **rejoint le dex** ; un nouvel œuf démarre.
5. **Raretés** : communes rapides, rares plus longues ; **shiny** (couleur alternative) à faible proba.
6. **Bonbons** → **boutique** (œufs de rareté supérieure, cosmétiques, shiny charm, biomes/habitats).

## 5. Carburant (actif, 100 % on-device — la « magie » du produit)
- **Minuteur de focus** (Pomodoro) : la créature/œuf « se concentre avec toi » (abandon = pénalité douce,
  comme l'arbre qui meurt chez Forest).
- **Habitudes & tâches du jour** (façon Finch) : chaque check nourrit l'œuf.
- **Streaks / objectif quotidien** : bonus de croissance.
- (Option self-care plus tard : check-in d'humeur, respiration, gratitude → chaleur émotionnelle façon Finch.)

## 6. Créatures Tuxemon — dex, évolution, licence
- **411 créatures** avec **types**, **shapes** et **lignes d'évolution** déjà définies (données YAML).
- On réutilise **sprites + données d'évolution/type** ; **on écrit notre propre code** (ne pas copier le
  code GPLv3 de Tuxemon).
- **Licence de l'art : CC-BY-SA** → obligations : **créditer** (écran Crédits) + **partage à l'identique**
  (nos sprites dérivés restent CC-BY-SA ; le **code de l'app reste privé**). **Commercialisation OK.**
- À vérifier avant release : licence exacte des fichiers de **données** (YAML).

## 7. Fonctionnalités

### MVP (v1) — le minimum vendable
- [ ] **Minuteur de focus** (durées réglables) avec créature qui incube pendant la session.
- [ ] **Habitudes / tâches du jour** simples + streak.
- [ ] **Œuf → éclosion → évolution → dex** (moteur Tuxemon, ~30-50 créatures pour commencer).
- [ ] **Dex** : grille des créatures obtenues, indicateur shiny, fiche (type, niveau, date).
- [ ] **Bonbons + mini-boutique** (œufs communs/rares, 1-2 cosmétiques).
- [ ] Notifications (fin de session, éclosion, évolution, shiny !), widget d'accueil (créature + streak).
- [ ] 100 % local, sans compte.

### V2 — profondeur & rétention
- [ ] Roster élargi (vers les 411), **habitats/biomes** à débloquer, **shiny charm**, **mints** (re-roll nature).
- [ ] **Défis quotidiens/hebdo**, objectifs, récompenses.
- [ ] Statistiques (temps de focus, régularité), historique.
- [ ] Personnalisation (thèmes, terrarium).
- [ ] Live Activity / Dynamic Island pendant la session de focus.

### V3 — social & écosystème
- [ ] Partage de dex (image), amis, classement doux, « co-focus ».
- [ ] **App Mac (tokens)** en produit frère, **dex synchronisé** via CloudKit.

## 8. 💰 Monétisation (2 modèles prouvés)
| Modèle | Réf. | Comment | Pour nous |
|---|---|---|---|
| **One-time** | Forest 3,99 $, 2 M+ acheteurs | achat unique + cosmétiques | simple, sans « fatigue d'abo », dev-friendly |
| **Freemium + abo** | Finch ~30 M$ ARR | free généreux + soft paywall (abo + IAP 5,99→69,99 $) | plafond bien plus haut, exige contenu/rétention |

**Reco de départ** : **freemium + IAP cosmétiques/œufs** (la collection Tuxemon donne pile la matière à
vendre : œufs de rareté, skins d'habitat, shiny charm), **+ un petit abo « Pro »** ensuite (éclosion
accélérée, créatures/biomes exclusifs, meilleures probas shiny, thèmes). Soft paywall façon Finch
(free généreux → convertit mieux qu'un mur).
- **Prix indicatifs** : abo Pro ~2,99 €/mois ou ~19,99 €/an ; IAP cosmétiques 0,99–4,99 € ; pack d'œufs.
- **Éthique** : pas de pay-to-win agressif — la collection reste jouable en gratuit, l'argent accélère /
  personnalise (respecte le ton bienveillant qui fait le succès de Finch).

## 9. Différenciation (le moat)
- **La collection** (411 créatures, évolutions, types, shiny) dans un focus/self-care app → **personne
  ne le fait**. C'est LA raison de revenir chaque jour (compléter le dex).
- Ton bienveillant (Finch) + concentration efficace (Forest) + collectionnite (Pokémon).

## 10. Rétention
- Streaks, objectif quotidien, **œuf toujours en cours** (boucle ouverte), shiny surprise, défis,
  notifications douces, widget/Live Activity. Nouveauté régulière = nouvelles créatures/biomes.

## 11. Confidentialité (argument marketing)
- **Tout en local**, aucun compte requis, aucune donnée envoyée. (Sync iCloud opt-in plus tard.)

## 12. Roadmap
- **S1-2** : minuteur focus + habitudes + moteur œuf/éclosion (1 créature).
- **S3-4** : évolution Tuxemon + dex + shiny + boutique bonbons → **MVP**.
- **S5** : IAP cosmétiques + polish + notifications/widget → **beta TestFlight**.
- **S6** : soumission App Store + landing + Product Hunt.
- Ensuite : profondeur (V2), puis app Mac (tokens) partageant le cœur.

## 13. Lien avec l'app Mac « tokens » (produit frère)
- Même **cœur de créatures** (Swift Package) + mêmes sprites Tuxemon.
- Fuel différent : Mac = **tokens IA locaux** (Claude Code/Cursor), iPhone = **focus/habitudes**.
- **Dex partagé** (CloudKit) = argument « ta vie de dev + ta discipline nourrissent une seule
  collection » — à activer quand l'iPhone est validé.
- PRD Mac : voir `../../App desktop/TokenMon/PRD-TokenMon.md`.

## 14. Décisions à trancher (avant de coder)
1. **Nom** de l'app.
2. **Modèle** : freemium + IAP/abo (reco) vs one-time simple.
3. **Périmètre MVP** : focus **+** habitudes dès v1, ou focus seul d'abord ?
4. **Ton** : plutôt « self-care doux » (Finch) ou « productivité/focus » (Forest) — ça oriente le design.
5. On confirme **Tuxemon** (copyleft accepté) comme roster.
