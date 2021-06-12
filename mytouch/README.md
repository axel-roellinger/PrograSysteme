# mytouch

Le but de ce projet est de recréer le fonctionnement de la commande touch présente sur les plateformes UNIX.

Définition Wikipédia de touch : 
<p align="center"> touch est une commande Unix standard permettant de modifier le timestamp de dernier accès et de dernière modification d'un fichier. 
  Cette commande permet également de créer un fichier vide.</p> 
  
L'objectif fut de recréer ces fonctions à l'aide de primitives systèmes, sans employer d'allocation dynamique de mémoire.

Tout d'abord, j'ai défini les conditions de fonctionnement de la commande. Il est dit au sein du sujet PDF que deux options doivent être
utilisables : 
<ul>
  <li>-r, qui permet de désigner un fichier comme référence pour la modification des timestamps du fichier principal</li>
  <li>-c, qui indique que si le fichier principal n'existe pas, il ne doit pas être créé</li>
</ul>

De même, le nombre d'arguments est également une condition de fonctionnement. S'il n'y a pas d'argument autre que 
le nom du programme lui-même, celui-ci doit s'interrompre. De même, un nombre trop important d'arguments doit provoquer
un arrêt du programme. Ici, j'ai déterminé qu'il ne peut y avoir plus de 4 arguments autres que le nom du programme.

Schéma type de la commande : ./mytouch <-r /path/to/reference/file> <-c> /path/to/file
L'option -c peut également être positionnée avant l'option -r, mais pas entre -r et le path du fichier de référence.

Pour pouvoir les utiliser dans le code, j'ai employé la fonction getopt(), incluse dans le header unistd.h

Cette fonction permet de parser la ligne de commande, en détectant les options et leurs éventuels arguments.
L'usage sera :
  option = getopt(argc, argv, "cr:");
    option : est un entier, qui va stocker la valeur du caractère correspondant à l'option parsée.
    "cr:" : options valides, les ":" suivant le "r" indique qu'un argument suivant directement le "r" est attendu.
    Pour l'obtenir, on utilisera la variable optarg (option argument).
   
optarg nous permettra donc d'obtenir le path du fichier de référence s'il y en a un. Pour le fichier principal, j'ai 
employé la variable optind. Cette variable est un index, qui représente le premier argument de la table argv[] qui 
n'a pas été récupéré par optarg, ou ayant été utilisé pour l'activation d'un flag au sein du switch.

Dans notre cas, seul le fichier principal n'est pas utilisé dans ce switch, de ce fait, optind sera toujours l'index
le désignant dans la table argv.

J'ai tout de suite décidé d'opérer une comparaison entre le fichier principal et l'éventuel fichier de référence, 
signalant alors une opération inutile si ces fichiers sont les mêmes.

Une fonction a été définie pour vérifier différents points relatifs aux permissions du dossier incluant le fichier
principal et pour vérifier si le possesseur est la même personne que celle qui emploie la commande.
J'emploie une structure stat qui collecte les infos du dossier en question, et je compare la variable 
st_mode de cette structure avec S_IXUSR et S_IWUSR, qui sont des constantes POSIX permettant de vérifier si l'utilisateur
possède une permission, respectivement, d'exécution et d'écriture. 

Si toutes ces conditions sont vérifiées, alors le code peut se poursuivre.

A présent, nous rentrons dans le coeur du code. Pour distinguer les différents cas, j'ai donc, comme mentionné plus haut,
employé des flags, signalant l'usage ou non des options. Ces flags m'ont permis de construire des switch, 
afin de distinguer les différents cas.

Le premier switch concerne le rflag, car les opérations effectuées lorsqu'il y a un fichier de référence ou non sont
totalement différentes.

Premier choix possible : rflag = 0. Il n'y a pas de fichier de référence. A ce moment-là, deux actions sont possibles :
créer le fichier si nous n'avons pas l'option c, ou actualiser le timestamp du fichier s'il existe.

C'est pour distinguer ces différents cas que j'ai d'abord implémenté une condition, qui est celle de vérifier si le 
fichier principal peut s'ouvrir. Si ce n'est pas le cas, un switch autour du cflag intervient. 
On distingue alors le cas où le fichier sera créé, et le cas où le fichier n'existe pas et ne sera pas créé, tous 
deux occasionnant la fin du programme.

Si le fichier peut être ouvert, je vérifie tout d'abord que la personne qui utilise mon programme est propriétaire du fichier.
Si tel est le cas, alors un buffer de type struct utimbuf (venant de utime.h) sera utilisé pour actualiser
les dates de dernier accès et de dernière modification du fichier principal. L'objectif sera de stocker la date 
actuelle, obtenue via time(), assignée aux variables actime et modtime du buffer.
La fonction utime permet ensuite de changer les attributs de date du fichier principal.

Pour le second cas où nous avons un fichier de référence, il faut tout d'abord vérifier que le fichier de référence
existe. Si ce n'est pas le cas, le programme s'arrête. 
La suite du programme suit une structure similaire au case 0 du rflag. Il faut vérifier l'existence ou non du fichier principal, qui en est le propriétaire
s'il existe, décider de sa création ou non liée au cflag, mais cette fois-ci, le programme ne s'arrête pas une fois le fichier créé.

En effet, il faudra alors modifier les dates de dernier accès et de dernière modification du fichier, pré-existant
ou nouvellement créé, qui seront alors les mêmes que celles du fichier de référence.

Pour ceci, deux buffers différents seront requis : un buffer basé sur une structure utimbuf pour construire les futures
attributs de dates du fichiers principal, et un buffer basé sur une structure stat, qui permettra d'exploiter les 
attributs de dates du fichier de référence.

Le buffer du fichier de référence est rempli à l'aide de la commande stat(), qui récupère les informations du fichier
de référence.

<p align="center">
  buf_end.actime = buf_ref.st_atime;
  buf_end.modtime = buf_ref.st_mtime;
<p>
Les deux lignes ci-dessus permettent de remplir le buffer associé au fichier principal. 
Pour actualiser les informations du fichier de référence, on emploiera la fonction utime().
 






