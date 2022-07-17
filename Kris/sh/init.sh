#!/bin/bash
# set -x; exec 5>debug_output.txt; BASH_XTRACEFD="5"  # dane z debugowania zapisuje do pliku (set +x wyłącza debugowanie)
# set -u                                              # pokazuje miejsce błędu

# Cron               : https://wiki.mydevil.net/Cron
# Bash Guide przegląd: https://wiki-dev.bash-hackers.org/

#---------------------------------------------------------------------------------------------------
function Skladnia () {
  [ "$1" == "Err01" ] && echoError "Brakuje parametru 'funkcja'"
cat << ENDcat
Składnia: $(echo $0 | sed -e 's/.\///') funkcja [-q|--quiet] [-h, --help]
  Funkcje dostępne:
$(functionList| sed "s#^${2}#    ${2}#g")
  Parametry:
    +i[|-i], ++init[|--init]   - init docker compose before
    +d[|-d], ++debug[|--debug] - debug
    -q,      --quiet           - ciche wyjście
    -l,      --list            - lista funkcji
    -h,      --help            - pomoc
ENDcat
}

#---------------------------------------------------------------------------------------------------
showVals    () { s=""; while [ $# -ne 0 ]; do s=$s$(printf "$1:%s; " "$(eval echo '$'$1)"); shift; done; echo $s; }  # echo "$1:$(eval echo "$"$1)"  # wynik zmienna:wartość  # a="wartość a"; b="wartość b"; showVals a b; exit
showValsExit() { showVals $@; exit; }
showTab     () { declare -p $1; }            # (Tablica , Argument) -> Tablica: https://stackoverflow.com/questions/10953833/passing-multiple-distinct-arrays-to-a-shell-function ; a=(abc 'def ghi' jkl); declare -p a  # wynik: declare -a a=([0]="abc" [1]="def ghi" [2]="jkl")  # wyświetla zawartość tablicy w czytelnej formie
#---------------------------------------------------------------------------------------------------
readFromPipe() { result=""; if [ -p /dev/stdin ]; then result=$(cat); return 1; else return 0; fi;  } # Czyta dane z potoku stdin # if [ -p /dev/stdin ]; then result=$(cat); echo Parametry z stdin: TAK; else result=""; echo Parametry z stdin: nie; fi

#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
function Parametry () {
  p0=$1; p1=$2; p2=$3; p3=$4; params=$@;  															# p0=$1; p1=$2; p2=$3; shift; params=$@;

#  case "$p0" in
#   #"router")                        ;;
#    "-h"|"--help") Skladnia; exit $? ;;
#    *)             res=$(functionList| grep "$p0\$"); [ "$res" ] || { Skladnia "Err01"; exit $?; } ;;
#  esac

  parm_init=true; parm_debug=true; parm_quiet=false; parm_list=false; parm_other=()
  parH=([init]=true [debug]=true [quiet]=false [list]=false [toRun]= ); parm_other=()                                             #; declare -p parH; echo "parH_keys=${!parH[@]} ; parH_vals=${parH[@]} ; parH_n=${#parH[@]}" ### parH_str=$(declare -p parH); # associate Array -> string, żeby mogło przejść do pattern file. W pattern file import: eval "$parH_str"
  if [ "$#" == "0" ]; then Skladnia; exit $?; fi
  while [ $# -ne 0 ]; do                         													# czyta parametry z wiersza poleceń i przypisuje je do odpowiednich zmiennych
    case "$1" in
     #"--domain"|"-d") shift; parm_domain=$1; if [ "$1" == "" ]; then Skladnia; fi ;;
      -i|+i|--init|++init)   [[ $1 =~ -i|--init  ]] && parH[init]=false    ;;
      -d|+d|--debug|++debug) [[ $1 =~ -d|--debug ]] && parH[debug]=false   ;;
      --quiet|-q)            parH[quiet]=true                              ;;
      --list |-l)            parH[list]=true                               ;;
      -h|--help)             Skladnia; exit $?                            ;;
      *)                     parm_other+=("$1")                           ;;                                            # parametry pozostałe
    esac
    shift
  done
  res=$(functionList| grep "${parm_other[*]}\$");
  # shellcheck disable=SC2015
  [ "${#parm_other[@]}" == "1" ] && [ "$res" ] || { Skladnia "Err01"; exit $?; }
  parH[toRun]="$res"

  # echo -e "p0:$p0 p1:$p1 p2:$p2 p3:$p3 parm_othet=${parm_other[*]}"; #exit
  # for p in "${parm_other[@]}"; do echo $p; done

  # parH_str=$(declare -p parH); # associate Array -> string, żeby mogło przejść do pattern file. W pattern file import: eval "$parH_str"
}

#--- colors ------------------------------------------------------------------------------------------------------------
initColors() {
  RS="\033[0m"    # reset
  HC="\033[1m"    # hicolor
  UL="\033[4m"    # underline
  INV="\033[7m"   # inverse background and foreground
  FBLK="\033[30m" # foreground black
  FRED="\033[31m" # foreground red
  FGRN="\033[32m" # foreground green
  FYEL="\033[33m" # foreground yellow
}
echoError  () { echo -e "\033[31mError\033[0m: $*\n" ; }
echoWarning() { echo -e "\033[33mWarning\033[0m: $*\n" ; }
echoInfo   () { echo -e "\033[32mWarning\033[0m: $*\n" ; }

#--- funkcje -----------------------------------------------------------------------------------------------------------
functionList() { cat $0 | grep -o "^aws\w*"; }

funkcja1() {
  return
}

#---------------------------------------------------------------------------------------------------
funkcja2() {
  return
}

#===================================================================================================
#--- testyRun --------------------------------------------------------------------------------------
# testEchoWartosci
#--- set -------------------------------------------------------------------------------------------
#set -x                                                                                             # wypisuje polecenia przed uruchomieniem
#set -- --examples;                                                                                 # ustawia parametry wywołania skryptu: $@
#set -- -l eee       ;
#===================================================================================================

Parametry "$@";

#cd $(dirname "$0")																					                                                            # cd aktualny folder

${parH[quiet]} && exec > /dev/null 2>&1             # true|false && ...                                                                    # ukrywa wyjście echo w całym skrypcie
${parH[list]}  && { functionList       ; exit  ; }  # true|false && ...

return

#[ "$p0" ]   && { toRunFunction="$p0"; return; }
#exit


#case "${parm_array[0]}" in
#  "ssh"     )    sshRun      "ssh"     ;;
#  "sshfs"   )    sshRun      "sshfs"   ;;
#  "sshLocal")    sshRun      "sshLocal";;
#  "sshTor"  )    sshRun      "sshTor"  ;;
#  "sshfsTor")    sshRun      "sshfsTor";;
#  "umount"  )    sshRun      "umount"  ;;
#  "adb"     )    sshRun      "adb"     ;;
#  "rsync"   )    sshRun      "rsync"   ;;
#  "rsyncTor")    sshRun      "rsyncTor";;
#  "pcConfig")    pcConfigRun "pcConfig";;
#  *)                                   ;;
#esac

<<COMMENT1
 0. debugowanie:	bash -x ./skrypt.sh # pokazuje ślad wykonanania skryptu							# set parametry: http://linuxcommand.org/lc3_man_pages/seth.html
					bash -x -c ls		# szczegóły wykonania polecenia
					set -x				# w pliku skryptu od momentu w którym chcemy debugować
					set -x; exec 5>debug_output.txt; BASH_XTRACEFD="5"  # dane z debugowania zapisuje do pliku (set +x wyłącza debugowanie)
					set -u                                              # pokazuje miejsce błędu
						-e 												# Wyjdź natychmiast, jeśli polecenie zakończy się ze statusem niezerowym.
						-f 												# Wyłącz generowanie nazw plików ze znaków specjalnych np. '*'
 1. Bash triki: http://www.etalabs.net/sh_tricks.html
   return funkcji jako ciąg znaków: eval "$dest=\$foo"
   cytowanie dowolnych ciągów     : quote () { printf %s\\n "$1" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/" ; }

   diff <(ls /bin) <(ls /usr/bin)     > >> >>> > >() https://askubuntu.com/questions/678915/whats-the-difference-between-and-in-bash

   Parametry specjalne: https://javarevisited.blogspot.com/2011/06/special-bash-parameters-in-script-linux.html
	set -euo pipefail  # ułatwia testowanie skryptu w trakcie pracy nad nim. Jakikolwiek błąd powoduje wysypanie: http://redsymbol.net/articles/unofficial-bash-strict-mode/
	IFS=$'\n\t'

 2. Bash potoki						 		: https://catonmat.net/ftp/bash-redirections-cheat-sheet.pdf
 3. Bash prosty regex echo typu ${@:7:0}	: https://wiki.bash-hackers.org/syntax/pe , http://www.tldp.org/LDP/abs/html/parameter-substitution.html, https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
		a="as"; a=${a:-"wartość domyślna"}; echo "$a"	# wynik: as
		a=""  ; a=${a:-"wartość domyślna"}; echo "$a"	# wynik: wartość domyślna
		b=a   ; a=aaa; echo "${!b}"						# wynik: aaa				# przekierowanie
		b=a; a=abcde; echo "${!b^}"						# wynik: Abcde
		b=a; a=abcde; echo "${!b^^}"					# wynik: ABCDE
		a=ABCDE; echo "${a,,}"							# wynik: abcde
		a=AbCdE; echo "${a~~}"							# wynik: aBcDe
		b=a; b1=val_b1; b1x=val_b1x; echo "${!b@}"		# wynik: b b1 b1x			# lista zmiennych
		set -o pipefail; true|false|true; echo "${PIPESTATUS[2]} ${PIPESTATUS[1]} ${PIPESTATUS[0]}"
		  Wynik: 0 1 0

 4. while read line; do ... done       		: https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
		read: https://www.computerhope.com/unix/bash/read.htm
 5. sed w przykładach zaawansowane 			: http://www.elpro.pl/dokumentacje/80-sedwprzykladachczescdruga ; http://www.elpro.pl/dokumentacje/79-sedwprzykladachczescpierwsza
		sed multilines: https://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
			echo -e "Dog\nFox\nCat\nSnake\n" | sed -e '1h;2,$H;$!d;g' -re 's/([^\n]*)\n([^\n]*)\n/Quick \2\nLazy \1\n/g'
		perl zamiast sed w wyrażeniach regularnych to mniej kłopotów z wyrażeniami regularnymi: echo "$1"| perl -pe 's|<td[^>]*>|<td>|'
 6. mapfile wczytuje dane do tablicy Super	: https://www.computerhope.com/unix/bash/mapfile.htm
 7. Tablice kompleksowo 5: https://www.artificialworlds.net/blog/2013/09/18/bash-arrays/: , https://wiki.bash-hackers.org/syntax/arrays
		a=(abc 'def ghi' jkl); declare -p a				# wynik: declare -a a=([0]="abc" [1]="def ghi" [2]="jkl")  # wyświetla zawartość tablicy w czytelnej formie
		a=("a" "b b" c );            echo ${a[1]}		# wynik: b b
		a=(a b c d e f );            echo ${a[@]:1:4}	# wynik: b c d e
		s='(1 "b b" c )'; eval a=$s; echo ${a[1]}		# wynik: b b
	# funkcja przyjmuje 2 tablice jako argumenty: https://stackoverflow.com/questions/10953833/passing-multiple-distinct-arrays-to-a-shell-function
		demo_multiple_arrays() {
		  local -n _array_one=$1; local -n _array_two=$2
		  printf '1: %q\n' "${_array_one[@]}"
		  printf '2: %q\n' "${_array_two[@]}"
		}
		array_one=( "array one argument1" "array one argument2" )
		array_two=( "array two argument1" "array two argument2" )
		demo_multiple_arrays array_one array_two
	# wynik:
		1: array\ one\ argument1
		1: array\ one\ argument2
		2: array\ two\ argument1
		2: array\ two\ argument2

	# Pobranie tablicy jako parametru $: skrypt.sh "a b c" "2" lub $: a=("a" "b" "c"); skrypt.sh "$(echo ${a[@]})" "2" # pobranie ze skryptu: a=($1); b=$2
 7b Tablice asocjacyjne kompleksowo 5: https://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
   declare -A animals; animals=( ["moo"]="cow" ["woof"]="dog"); animals["cat"]="miau"; declare -p animals; echo ${animals[@]}
   Wynik:
     declare -A animals=([woof]="dog" [moo]="cow" [cat]="miau" )
     dog cow miau
   declare -A MAP; MAP[bar]="baz"; declare -x serialized_array=$(mktemp); declare -p MAP > "${serialized_array}"; source "${serialized_array}"; echo "map: ${MAP[@]}"; declare -p MAP
   wynik:
     map: baz
     declare -A MAP=([bar]="baz" )
   def_tab='declare -A tab=([a]=a1 [b]=b1)'; eval "$def_tab"; echo "${tab[@]}"; declare -p tab
   wynik:
     b1 a1
     declare -A tab=([b]="b1" [a]="a1" )
 8. Zmienne: [ -z ${var+x} ] && echo "zmienna nieustawiona"; var=; [ -z ${var} ] && echo "zmienna nieustawiona albo pusta"; [ -z ${var-x} ] && echo "zmienna ustawiona"; # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
	valName="wartosc"; declare -n ref="valName"; echo ref:"$ref"	# wynik: ref:wartosc	# dostęp do zmiennej przez nazwę jej
	SKŁADNIA
      declare [-afFrxi] [-p] [ nazwa [= wartość ]]
	OPCJE
      -a Każda nazwa jest zmienną tablicową.
      -f Używaj tylko nazw funkcji.
      -F Wstrzymaj wyświetlanie definicji funkcji; są tylko nazwa funkcji i atrybuty. (implikuje -f)
      -i Zmienna ma być traktowana jako liczba całkowita; ocena arytmetyczna jest wykonywana, gdy zmienna ma przypisaną wartość.
      -p Wyświetl atrybuty i wartości każdej nazwy. Gdy używane jest „-p”, dodatkowe opcje są ignorowane.
      -r Wpisz nazwę tylko do odczytu. Te nazwy nie mogą wtedy przypisać wartości przez kolejne instrukcje przypisania lub rozbrojony.
      -x Zaznacz każdą nazwę do eksportu do kolejnych poleceń przez środowisko.
 9. ripgrep jest kilkakrotnie szybszy od grep, obsługuje grupy w zmiennych, wiele lini, od Ubuntu 18.10 jest w repozytioriach:
		https://github.com/BurntSushi/ripgrep
		https://beyondgrep.com/feature-comparison/
    grep
		wyrażenia regularne								: http://www.linux.net.pl/~wkotwica/doc/grep/grep_6.html#SEC9
	echo here | grep -P "[\w]+"	# wynik: here			# używa wyrażeń regularnych perla
	find . -type f -exec grep -il 'foo' {} \;     		# print all filenames of files under current dir containing 'foo', case-insensitive
	grep -l -r 'main' *.c								# lista wszystkich plików rekurencyjnie, których zawartość zawiera 'main'
	echo "12345678"| grep -o -b "4"  wynik: 3:4		      # pokazuje pozycje dopasowania
	echo "12345678"| grep -n -b "4"  wynik:  1:0:12345678 # linia i pozycja dopasowania
	cat /etc/passwd | grep 'alain' - /etc/motd			# przeszukuje zarówno stdin jak i pliki
	-n													# poprzedza każdą linię wyjścia numerem linii z odpowiedniego pliku wejściowego.
	grep jest znacznie szybszy od innych do wyszukiwania: http://stackoverflow.com/questions/12629749/how-does-grep-run-so-fast
	grep wyrażenia regularne i opis szczegółowy opcji 	: http://www.linux.net.pl/~wkotwica/doc/grep/grep_6.html
	grep indexowanie i szybkość							: http://stackoverflow.com/questions/7734596/grep-but-indexable
	time cat /home/kris/Pobrane/plwiktionary/plwiktionary-20160601-pages-articles-multistream.xml| egrep "język polski}})"  # czas wyszukiwania za 2-gim razem (po wczytaniu pliku do pamięci) real 0m2.634s
	grep i Perl wyrażenia: # $ echo 'bla bla bla bla pattern' | grep -Po '(?<=^.{15}) pattern' #  Wynik: ' pattern' # To avoid this with GNU grep, you can use a perl expression with look behind. Eg: pattern
	wybieram linie z pliku bardzo szybko: sed -n '50000000,50000010p;57890010q' test.in  # http://unix.stackexchange.com/questions/47407/cat-line-x-to-line-y-on-a-huge-file
		s="\"aaa aaa\""; echo "$s"| grep -Po 'aaa' # wynik: # zwraca 2 linijki dopasować - można zapisać do tabeli regex[@]
			aaa
			aaa

	grep rozszerzone wzorce (ignoruj, szukaj przed, po): https://perldoc.perl.org/perlre.html#Extended-Patterns

	grep przed i po:
		grep -Po '(?<!\d)\d{4}(?!\d)' <<< 12345abc789d0123e4  	# wynik: 0123						# https://askubuntu.com/questions/538730/how-to-grep-for-groups-of-n-digits-but-no-more-than-n
		grep -Po "(?<=foo )bar(?= buzz)" <<< "foo bar buzz"		# wynik: bar
	echo -e "jeden\ndwa\ntrzy\ncztery"| grep -z -e jeden -e dwa	# -z \n ignoruje jako znak kończący
		jeden		# na czerwono
		dwa			# na czerwono
		trzy
		cztery

	echo "Here is a string" | grep -o -P '(?<=Here).*(?=string)' wynik: " is a "					# https://stackoverflow.com/questions/13242469/how-to-use-sed-grep-to-extract-text-between-two-words
	echo 'Here is a string, and Here is another string.' | grep -oP '(?<=Here).*(?=string)'  		# Greedy match
	 is a string, and Here is another
	echo 'Here is a string, and Here is another string.' | grep -oP '(?<=Here).*?(?=string)' 		# Non-greedy match (Notice the '?' after '*' in .*)
	 is a
	 is another




	echo 12345678 | pcregrep -o1 -o2 -o1 "123(4)567(8)"  # wynik: 484
	echo 12345678 | pcregrep --color  "123(4)567"        # koloruje wynik
		−M, −−multiline									 # Pozwól wzorom dopasować więcej niż jedną linię. Gdy ta opcja jest ustawiona, biblioteka PCRE2 jest wywoływana w trybie „wielowierszowym”
	nmap -sP 192.168.1.0/24| pcregrep -o1 -o2 --om-separator="·" " ([^ ]+) \(([\d.]+)\)$"

10. case regex: https://stackoverflow.com/questions/4554718/how-to-use-patterns-in-a-case-statement

11. printf
	s="ssh -p 22 pi@ElPi"; grep -Po '^ssh|-p\s+\d+|\w+@\w+' <<< "$s"						# wynik w osobnych liniach
	a=('-p 22' 'pi' 'ElPi');                printf "ssh %s %s@%s\n" "${a[@]}"  				# wynik: ssh -p 22 pi@ElPi
	s="'-p 22' 'pi' 'ElPi'"; eval a=("$s"); printf "ssh %s %s@%s\n" "${a[@]}"  				# wynik: ssh -p 22 pi@ElPi
	System=('s1' 's2' 's3' 's4 4 4'); ( IFS=$'\n'; echo "${System[*]}" )					# wynik: drukuje każdy wyraz w osobnej linii
	s="ssh -p 22 pi@ElPi"; a=($(grep -Po '^ssh|-p\s+\d+|\w+@\w+' <<< "$s")); declare -p b	# wynik: declare -a b=([0]="ssh" [1]="-p 22" [2]="pi@ElPi")
	s="sshfs -p 22 pi@ElPi:domoticz /mnt/ElPi/pi"; r="sshfs +-p +([0-9]+) +(\w+)@(\w+)(:([^ ]*) +([^ ]+))?$"; [[ $s =~ $r ]] && declare -p BASH_REMATCH
		wynik: declare -ar BASH_REMATCH=([0]="sshfs -p 22 pi@ElPi:domoticz /mnt/ElPi/pi" [1]="22" [2]="pi" [3]="ElPi" [4]=":domoticz /mnt/ElPi/pi" [5]="domoticz" [6]="/mnt/ElPi/pi")
11.	OpenOffice ODS:
	ods2txt ./chipList-v2.14.ods      Konwersja Open Office Calc (oo) do tekstu
	read oo calc in perl http://how-to.wikia.com/wiki/How_to_read_OpenOffice_OpenDocument_spreadsheets_in_Perl
	w bash https://andreasrohner.at/posts/Scripting/How-to-implement-part-of-the-Open-Document-Speadsheet-file-format-using-only-Bash/

	port knocking ręcznie w bash https://wiki.archlinux.org/index.php/Port_knocking
	pojedynczy pakiet http://www.cipherdyne.org/fwknop/


Lista ostatnio napisanych skryptów:
   Lp.	data		Nazwa				Uwagi
		2006-11-19	polec_a4.sh			si użycie m.in grep do przeszukiwania wiktionary i wikipedii chyba
	1	2019-10-27	odsToCsvRead.sh
	2				PcAccess.sh


COMMENT1

textWielolinijkowy=$(cat <<-END
    This is line one.
    This is line two.
    This is line three.
END
)



cat <<-ENDcat
pierwsza linia
druga linia
ENDcat



