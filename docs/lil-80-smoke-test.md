# Smoke test LIL-80 — Admin tracking + fiche livreur

À exécuter avant push origin/dev par un humain sur 1 Android + 1 iOS.

## Pré-requis
- Compte admin actif (`role = ADMIN`) sur l'instance backend
- Au moins 1 livreur (`role = LIVREUR`) en base
- Idéalement : 1 commande `EN_ROUTE` avec livreur assigné en cours

## Scénarios (cocher au fur et à mesure)

### Routing + accès
- [ ] Tap sur ligne livreur dans `DeliverersScreen` → ouvre `DelivererDetailScreen`
- [ ] Bouton "Suivre sur la carte" depuis fiche livreur → ouvre tracking
- [ ] (Si test non-admin) accès `/deliverers/:id` → écran 403

### Fiche livreur — `DelivererDetailScreen`
- [ ] Livreur sans mission : stats `—` ou 0 cohérentes, pas de section "Mission en cours"
- [ ] Livreur avec mission EN_TRANSIT : carte mission visible + CTA Suivre OK
- [ ] Filtre chips fonctionnel (chaque statut + Tout) — la liste se réinitialise
- [ ] Scroll infini : 2+ pages chargées
- [ ] Pull-to-refresh recharge stats + missions
- [ ] Bouton "Appeler" : si tel présent, ouvre composeur ; sinon Snackbar

### Tracking — `DeliveryTrackingScreen`
- [ ] Carte centrée + marker livreur + marker destination (placeholder Brazzaville)
- [ ] Tracking pendant ≥ 2 min : marker bouge, polyline s'étend
- [ ] Bandeau statut update temps réel (forcer côté backend ou attendre)
- [ ] Mise en arrière-plan 30s puis foreground : reconnexion auto
- [ ] Commande passe en LIVRER : banner "Livraison terminée"
- [ ] IconButton AppBar → fiche livreur

### Cross
- [ ] Bouton "Suivre" depuis liste commandes (statut EN_ROUTE) ouvre tracking
- [ ] Bouton "Suivre sur la carte" depuis détail commande (statut EN_ROUTE) ouvre tracking
- [ ] Logs Sentry visibles dans le dashboard (provoquer 1 erreur volontaire en mode dev)

## Vérifs automatiques
- [ ] `flutter analyze` : pas de nouveau warning vs branche dev
- [ ] `flutter test` : tous tests PASS

## Captures
Joindre dans le ticket Linear LIL-89 :
- Fiche livreur (header + stats + mission en cours)
- Tracking screen (carte + bandeau + bottom sheet)
- État 403 si non-admin

## Sign-off
- [ ] Android testé (modèle : _____)
- [ ] iOS testé (modèle : _____)
- [ ] Sentry verified
- [ ] OK pour merge production
