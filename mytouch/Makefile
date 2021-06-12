# Ce Makefile contient les cibles suivantes :
#
# all   : compile le programme
# test  : lance les tests

EXEC_FILE = mt
OBJECTS = mt.o

CFLAGS = -c -g -Wall -Wextra -Werror # obligatoires

.PHONY: all clean

all: $(EXEC_FILE)

$(OBJECTS): %.o: %.c
	$(CC) $< $(CFLAGS)

$(EXEC_FILE): $(OBJECTS)
	$(CC) $^ -o $@

test: $(EXEC_FILE)
	./test.sh

#clean:
#	rm -f $(EXEC_FILE) *.o
#	rm -f *.aux *.log *.out *.pdf
#	rm -f moodle.tgz

#moodle: sujet
#	@rm -rf moodle
#	mkdir moodle
#	cp test.sh moodle
#	cp tp1.pdf moodle
#	sed '/^moodle:/,$$d' Makefile > moodle/Makefile
#	tar czf moodle.tgz moodle
#	# rm -rf moodle

#sujet: tp1.tex
#	pdflatex tp1.tex
#	pdflatex tp1.tex

