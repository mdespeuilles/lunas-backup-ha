# Lunas Backup Agent

Envoie les sauvegardes de Home Assistant vers un S3, pilotées par un contrôleur Lunas Backup.

L'app ne copie jamais `/config` pendant que Home Assistant tourne : elle envoie
les sauvegardes natives de Home Assistant (dossier `/backup`), les seules
cohérentes et restaurables directement depuis Home Assistant.

## Installation

1. Dans Home Assistant, active les sauvegardes automatiques :
   *Paramètres → Système → Sauvegardes*, une par jour, quelques copies gardées
   sur l'appareil. Garde la clé de chiffrement du *kit d'urgence* dans ton
   gestionnaire de mots de passe : sans elle, une sauvegarde chiffrée ne se
   restaure pas.
2. Dans Lunas Backup, *Cibles et agents* : crée une cible de type agent, puis
   clique sur *Enrôler*. Note le serveur, l'empreinte et le jeton de la
   commande `lunas-agent enroll --server … --ca-sha256 … --token …`.
3. Dans l'onglet *Configuration* de cette app, renseigne :
   - `server` : l'adresse des agents, par exemple `backup.example.com:7443` ;
   - `ca_sha256` : l'empreinte affichée après `--ca-sha256` ;
   - `token` : le jeton `lbe_…` (il ne sert qu'une fois, il expire après une heure).
4. Démarre l'app. Le journal doit afficher « Agent enrôlé » puis
   « agent démarré ». La cible passe *En ligne* dans Lunas.
5. Dans Lunas, crée une source *Fichiers* sur cette cible avec le chemin
   `/backup`, et planifie-la après l'heure des sauvegardes de Home Assistant.

## Fonctionnement

- Au démarrage, l'app télécharge l'agent depuis ton contrôleur : il a toujours
  sa version. Si le contrôleur est injoignable, la dernière version téléchargée
  est utilisée.
- L'agent ouvre une connexion sortante vers le contrôleur (TLS mutuel). Aucun
  port n'est ouvert sur Home Assistant.
- Les fichiers partent directement de Home Assistant vers le S3.
- Seule la recette *Fichiers* est autorisée.
- `download_url` (facultatif) : adresse web du contrôleur, si elle diffère de
  `https://` suivi de l'hôte de `server`.

## Restaurer

Depuis Lunas, une restauration vers cette cible dépose le fichier `.tar` dans
`/backup` : il apparaît alors dans *Paramètres → Système → Sauvegardes*.

Sur une installation neuve, sans Lunas : télécharge le `.tar` depuis le S3
(le chemin est dans `current/backup/` du dossier de la source), puis choisis
*Restaurer à partir d'une sauvegarde* à l'accueil de Home Assistant.

## Réenrôler

Pour rattacher l'app à une autre cible, révoque l'agent dans Lunas, supprime
puis réinstalle l'app (cela efface `/data`), et recommence l'étape 3.
