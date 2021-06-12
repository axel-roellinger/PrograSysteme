#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <utime.h>
#include <sys/stat.h>
#include <time.h>
#include <string.h> 
#include <libgen.h> //pour basename et dirname

void check_end_file_perm(char* file_path)
{
    char* pathcopy = strdup(file_path); //copie depuis le pointeur pour ne pas modifier la valeur pointée
        
    char* dir = dirname(pathcopy);
    
    struct stat dir_buf; //buffer pour analyser dir
    stat(dir, &dir_buf);
    
    if((dir_buf.st_mode & S_IXUSR) == 0) //Droit d'exécution sur le dossier
    {
        perror("Pas de droit d'exécution pour le dossier de création");
        exit(EXIT_FAILURE);
    }

    if((dir_buf.st_mode & S_IWUSR) == 0) //Droit d'écriture sur le dossier
    {
        perror("Pas de droit d'écriture pour le dossier de création");
        exit(EXIT_FAILURE);
    }

    if(!(dir_buf.st_uid & getuid())) //Même utilisateur
    {
        perror("Le fichier appartient à un autre utilisateur");
        exit(EXIT_FAILURE);
    }
    
    return; //return void s'il n'y a aucune condition ci-dessus de vérifiée
}

int main(int argc, char* argv[])
{   
	//flags utilisés pour distinguer les actions à effectuer en fonction des options, passe à 1 si présent en CLI
    int rflag = 0;
    int cflag = 0;

    char* end_file = NULL; //end_file : stocke le chemin du fichier à créer/à modifier
	char* ref = NULL; //ref : stocke le chemin du fichier de référence

	int option; //Option de getopt
    
    int change; //Permet de vérifier la validité du changement de dates

	while((option = getopt(argc, argv, "cr:")) != -1)
	{
		switch(option)
		{
			case 'r':
				rflag = 1;
				ref = optarg;
                break;
			
			case 'c':
				cflag = 1;
				break;

			case '?':
				perror("Option inconnue\n");
				exit(EXIT_FAILURE);
		}
	}


	if(argc == 1)
	{
		perror("Il n'y a pas d'arguments\n");
		exit(EXIT_FAILURE);
	}

	if(argc > 5)
	{
		perror("Il y a trop d'arguments\n");
		exit(EXIT_FAILURE);
	}

	end_file = argv[optind]; //optind : index du premier argument non lu par getopt(), ici le chemin du fichier à modifier/créer

	if(ref != NULL && strcmp(end_file, ref) == 0)
	{
		perror("Même fichier en entrée et en référence\n");
		exit(EXIT_FAILURE);
	}
	
	int fd; //descripteur de fichier pour les tests d'ouverture/de création

	switch(rflag)
	{
		case 0: //S'il n'y a pas de fichier de référence
            check_end_file_perm(end_file); //vérification des conditions d'accès au dossier de création

			//s'il n'y a rien, on continue
            
			if(access(end_file, F_OK) == -1)
            {
                switch(cflag)
                {
                    case 0: //Flag c non présent
                        fd = open(end_file, O_CREAT, 0777);
                        
                        if(fd == -1)
                        {
                            perror("Le fichier n'a pas pu être créé");
                            exit(EXIT_FAILURE);
                        }
                        
                        close(fd);
                        exit(EXIT_SUCCESS);
                        
                    case 1: //Flag c présent
                        exit(EXIT_SUCCESS);
                }
            }
            
            //Si le fichier existe déjà : modification des attributs de date
            
            struct utimbuf buffer; //Buffer pour stocker les nouvelles informations du fichier à changer
            time_t t; //timestamp
            buffer.actime = time(&t);
            buffer.modtime = time(&t);
            
            change = utime(end_file, &buffer); //Modification des dates via utime() à l'aide du buffer
            
            if(change == 0) //Changement réussi
            {
                exit(EXIT_SUCCESS);
            }
            
            else
            {
                perror("Erreur dans la modification des dates");
                exit(EXIT_FAILURE);
            }
            //break; //Pour ne pas avoir d'implicit fallthrough de signalé par le compilateur
    
        case 1: //Fichier de référence mentionné
            check_end_file_perm(end_file); //vérification des conditions d'accès au dossier de création

			//s'il n'y a rien, on continue
            
            if(access(ref, F_OK) == -1)
            {
                perror("Le fichier de référence n'existe pas");
                exit(EXIT_FAILURE);
            }
            
            if((access(end_file, F_OK) == -1) && cflag == 1)
            {
                exit(EXIT_SUCCESS);
            }
            
            else if((access(end_file, F_OK) == -1) && cflag == 0)
            {
                fd = open(end_file, O_CREAT, 0777);
                        
                if(fd == -1)
                {
                    perror("Le fichier n'a pas pu être créé");
                    exit(EXIT_FAILURE);
                }
                        
                close(fd);
            }
			
			if(access(end_file, F_OK) == -1)
            {
                switch(cflag)
                {
                    case 0:
                        fd = open(end_file, O_CREAT, 0777);
                        
                        if(fd == -1)
                        {
                            perror("Le fichier n'a pas pu être créé");
                            exit(EXIT_FAILURE);
                        }
                        
                        close(fd);
						break;
                        
                    case 1:
                        exit(EXIT_SUCCESS);
                }
            }
            
            struct utimbuf buf_end; //Buffer pour modifier les attributs de date du fichier en fin de commande
            struct stat buf_ref; //Buffer pour utiliser les attributs de dates du fichier de référence
            
            stat(ref, &buf_ref);
            
            buf_end.actime = buf_ref.st_atime;
            buf_end.modtime = buf_ref.st_mtime;
            
            change = utime(end_file, &buf_end);
            
            if(change == 0) //Changement de date réussi
            {
                exit(EXIT_SUCCESS);
            }
            
            else
            {
                perror("Erreur lors du changement de date");
                exit(EXIT_FAILURE);
            }
    }
}
