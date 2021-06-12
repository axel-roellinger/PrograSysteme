#!/bin/sh

PROG="./mt"
TMP="/tmp/$$"

check_empty()
{
    if [ -s $1 ]; then return 1; fi
    return 0
}


test_1()
{
    echo "Test 1 - tests sur les arguments du programme"

    echo -n "Test 1.1 - sans argument.........................................."
    if $PROG                            > $TMP/test_11_stdout 2> $TMP/test_11_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if   check_empty $TMP/test_11_stderr                                             ; then echo "échec => stderr vide"             && return 1; fi
    if ! check_empty $TMP/test_11_stdout                                             ; then echo "échec => stdout non vide"         && return 1; fi
    echo "OK"

    echo -n "Test 1.2 - trop d'arguments......................................."
    if $PROG a b c d e                  > $TMP/test_12_stdout 2> $TMP/test_12_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if   check_empty $TMP/test_12_stderr                                             ; then echo "échec => stderr vide"             && return 1; fi
    if ! check_empty $TMP/test_12_stdout                                             ; then echo "échec => stdout non vide"         && return 1; fi
    echo "OK"

    echo -n "Test 1.3 - option inconnue........................................"
    if $PROG -a toto                    > $TMP/test_13_stdout 2> $TMP/test_13_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if   check_empty $TMP/test_13_stderr                                             ; then echo "échec => stderr vide"             && return 1; fi
    if ! check_empty $TMP/test_13_stdout                                             ; then echo "échec => stdout non vide"         && return 1; fi
    echo "OK"

    echo -n "Test 1.4 - syntaxe ok............................................."
    touch $TMP/toto
    #if ! $PROG -r $TMP/toto -c toto     > $TMP/test_14_stdout 2> $TMP/test_14_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_14_stderr                                             ; then echo "échec => stderr non vide"         && return 1; fi
    if ! check_empty $TMP/test_14_stdout                                             ; then echo "échec => stdout non vide"         && return 1; fi
    echo "OK"

    return 0
}

test_2()
{
    echo "Test 2 - tests sur actions du programme"

    echo -n "Test 2.1 - création d'un fichier.................................."
    if ! $PROG $TMP/fichier                  > $TMP/test_21_stdout 2> /dev/null           ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP-dir/test_21_stdout                                              ; then echo "échec => stdout non vide"         && return 1; fi
    if ! test -e $TMP/fichier                                                             ; then echo "échec => fichier non créé"        && return 1; fi
    echo "OK"

    echo -n "Test 2.2 - MAJ dates fichier existant............................."
    echo "salut" > $TMP/fichier ; touch -d "2 hours ago" $TMP/fichier
    if ! $PROG $TMP/fichier                  > $TMP/test_22_stdout 2> /dev/null           ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_22_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if test `date +%s` -ne `date -r $TMP/fichier +%s`                                     ; then echo "échec => dates non mises à jour"  && return 1; fi
    if test `cat $TMP/fichier` != "salut"                                                 ; then echo "échec => fichier a été modifié"   && return 1; fi
    echo "OK"

    echo -n "Test 2.3 - MAJ dates fichier existant à partir d'une référence...."
    touch -d "2 hours ago" $TMP/ref
    if ! $PROG -r $TMP/ref $TMP/fichier      > $TMP/test_23_stdout 2> /dev/null           ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_23_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if test `date -r $TMP/ref +%s` -ne `date -r $TMP/fichier +%s`                         ; then echo "échec => dates différentes"       && return 1; fi
    echo "OK"

    echo -n "Test 2.4 - MAJ dates à partir d'une ref et option -c.............."
    touch -d "5 hours ago" $TMP/ref
    if ! $PROG -c -r $TMP/ref $TMP/fichier   > $TMP/test_24_stdout 2> /dev/null           ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_24_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if test `date -r $TMP/ref +%s` -ne `date -r $TMP/fichier +%s`                         ; then echo "échec => dates différentes"       && return 1; fi
    echo "OK"

    echo -n "Test 2.5 - option -c et MAJ dates à partir d'une ref.............."
    touch -d "5 hours ago" $TMP/ref
    if ! $PROG -r $TMP/ref -c $TMP/fichier   > $TMP/test_25_stdout 2> /dev/null           ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_25_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if test `date -r $TMP/ref +%s` -ne `date -r $TMP/fichier +%s`                         ; then echo "échec => dates différentes"       && return 1; fi
    echo "OK"

    return 0
}

test_3()
{
    echo "Test 3 - tests avancés"

    echo -n "Test 3.1 - fichier dans répertoire sans droit x..................."
    mkdir $TMP/nonx ; touch $TMP/nonx/toto ; chmod -x $TMP/nonx
    if   $PROG $TMP/nonx/toto                > $TMP/test_31_stdout 2> $TMP/test_31_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_31_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if   check_empty $TMP/test_31_stderr                                                  ; then echo "échec => stderr vide"             && return 1; fi
    chmod +x $TMP/nonx
    echo "OK"

    echo -n "Test 3.2 - fichier appartenant à un autre utilisateur............."
    if   $PROG /tmp                          > $TMP/test_32_stdout 2> $TMP/test_32_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_31_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if   check_empty $TMP/test_31_stderr                                                  ; then echo "échec => stderr vide"             && return 1; fi
    echo "OK"

    echo -n "Test 3.3 - fichier inexistant et option -c........................"
    if ! $PROG -c $TMP/titi                  > $TMP/test_33_stdout 2> $TMP/test_33_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_33_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if ! check_empty $TMP/test_33_stderr                                                  ; then echo "échec => stderr non vide"         && return 1; fi
    if test -e $TMP/titi                                                                  ; then echo "échec => fichier créé malgré -c"  && return 1; fi
    echo "OK"

    echo -n "Test 3.4 - création d'un fichier dans répertoire sans droit w....."
    mkdir $TMP/dir ; chmod -w $TMP/dir
    if   $PROG $TMP/dir/fichier              > $TMP/test_34_stdout 2> $TMP/test_34_stderr ; then echo "échec => code de retour invalide" && return 1; fi
    if ! check_empty $TMP/test_34_stdout                                                  ; then echo "échec => stdout non vide"         && return 1; fi
    if   check_empty $TMP/test_34_stderr                                                  ; then echo "échec => stderr vide"             && return 1; fi
    chmod +w $TMP/dir
    echo "OK"

    return 0
}

test_4()
{
    echo -n "Test 4 - test mémoire............................................."
    valgrind --leak-check=full --error-exitcode=100 $PROG -c -r $TMP/ref $TMP/fichier > /dev/null 2> $TMP/test_4_stderr
    test $? = 100 && echo "échec => log de valgrind dans $TMP/test_4_stderr" && return 1
    echo "OK"

    return 0
}

# répertoire temp où sont stockés tous les fichiers et sorties du pg
mkdir $TMP

# Lance les 4 séries de tests
for T in $(seq 1 4)
do
	if test_$T; then
		echo "== Test $T : ok $T/4"
	else
		echo "== Test $T : échec"
		return 1
	fi
done
