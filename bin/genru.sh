#!/bin/bash
# AWESOME GOOGLE TRANSLATE. This tool for access translate.google.com from terminal and additional English features.

#    Copyright (C) 2012 Vitalij Chepelev.

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# You can contact me there: 
# http://www.unix.com/shell-programming-scripting/196823-completed-command-line-google-translation-tool.html                       654321 - profile name

# main mirror https://github.com/Anoncheg1/Command-line-translator
# mirror http://pastebin.com/kPTYjY6W
# requirements: 
#	UTF-8 support for required languages
#	curl >= 7.21.0,
# 	Mozilla js shell (spidermonkey) >= 1.8.0, 
#	mpg123
#	html2text
#	forvo.com account
#features:
#- translated text, fixed text with highlight, language detection, dictionary, translit
# for english: 
#- phrases, ideom, word forms, transcription, audio pronunciation
#- cache for words
#- saving words to file for learning
#
#:) translate.google.com, thefreedictionary.com, lingvo-online.ru, www.forvo.com 

help=$(basename "$0")' [-s[2,3]] [-l] [-h] <text>
if text is LATIN_LANG, then target language is FIRST_LANG
otherwise, target language is LATIN_LANG
-s --sound Enable sound for one word
-l, --list List of languages
You can force the language with environment varibles by command:
export TLSOURCE=en TLTARGET=ru
but better configure "FIRST_LANG" and "LATIN_LANG" in script for auto detection of direction by the first character!
You neeed UTF-8 support for required languages.
'

# adjust to taste
declare -r FIRST_LANG=ru			#target language for request in LATIN_LANG		NOT in A-z latin alphabet
declare -r LATIN_LANG=en			#target for all not A-z latin requests			A-z latin alphabet will be detected!
declare -r flogin=121212 			#forvo.com login and pass REQUIRED!
declare -r fpass=121212
TERMINAL_C="WOB"				#Your terminal - white on black:WOB, black on white:BOW, anything other:O
#httpproxy="127.0.0.1:4444"		#proxy for long strings
#httpsproxy="--socks5 127.0.0.1:9050"	#socks5
#
declare -r words_buffer=4000		#4000 files max. there is removeing all files older than 20 days.
declare -r timeout=6
declare -r TRANSLIT_WORDS_MAX=10
declare -r SOUND_DOWNLOAD_AWS=1		# 1 - always. 0 - on demand.
declare -r useragent="Mozilla/5.0 (X11; Linux i686) AppleWebKit/534.34 (KHTML, like Gecko) QupZilla/1.3.1 Safari/534.34"
#
declare -r PR_DIR="$HOME/.translate"
[ ! -d "$PR_DIR" ] && mkdir "$PR_DIR"
[ ! -d "$PR_DIR"/cache ] && mkdir "$PR_DIR"/cache

declare -r TR_ENG_WORDS="$PR_DIR"/translated_words
declare -r FIXED_STRING="$PR_DIR"/fixed_string

declare -A ln_arr
ln_arr["af"]="Afrikaans"
ln_arr["sq"]="Albanian"
ln_arr["am"]="Amharic"
ln_arr["ar"]="Arabic"
ln_arr["hy"]="Armenian"
ln_arr["az"]="Azerbaijani"
ln_arr["eu"]="Basque"
ln_arr["be"]="Belarusian"
ln_arr["bn"]="Bengali"
ln_arr["bg"]="Bulgarian"
ln_arr["ca"]="Catalan"
ln_arr["zh-CN"]="Chinese (Simplified)"
ln_arr["zh"]="Chinese"
ln_arr["hr"]="Croatian"
ln_arr["cs"]="Czech"
ln_arr["da"]="Danish"
ln_arr["nl"]="Dutch"
ln_arr["en"]="English"
ln_arr["eo"]="Esperanto"
ln_arr["et"]="Estonian"
ln_arr["fo"]="Faroese"
ln_arr["tl"]="Filipino"
ln_arr["fi"]="Finnish"
ln_arr["fr"]="French"
ln_arr["gl"]="Galician"
ln_arr["ka"]="Georgian"
ln_arr["de"]="German"
ln_arr["el"]="Greek"
ln_arr["gu"]="Gujarati"
ln_arr["ht"]="Haitian Creole"
ln_arr["iw"]="Hebrew"
ln_arr["hi"]="Hindi"
ln_arr["hu"]="Hungarian"
ln_arr["is"]="Icelandic"
ln_arr["id"]="Indonesian"
ln_arr["ga"]="Irish"
ln_arr["it"]="Italian"
ln_arr["ja"]="Japanese"
ln_arr["kn"]="Kannada"
ln_arr["ko"]="Korean"
ln_arr["lo"]="Laothian"
ln_arr["la"]="Latin"
ln_arr["lv"]="Latvian"
ln_arr["lt"]="Lithuanian"
ln_arr["mk"]="Macedonian"
ln_arr["ms"]="Malay"
ln_arr["mt"]="Maltese"
ln_arr["no"]="Norwegian"
ln_arr["fa"]="Persian"
ln_arr["pl"]="Polish"
ln_arr["pt"]="Portuguese"
ln_arr["ro"]="Romanian"
ln_arr["ru"]="Russian"
ln_arr["sr"]="Serbian"
ln_arr["sk"]="Slovak"
ln_arr["sl"]="Slovenian"
ln_arr["es"]="Spanish"
ln_arr["sw"]="Swahili"
ln_arr["sv"]="Swedish"
ln_arr["ta"]="Tamil"
ln_arr["te"]="Telugu"
ln_arr["th"]="Thai"
ln_arr["tr"]="Turkish"
ln_arr["uk"]="Ukrainian"
ln_arr["ur"]="Urdu"
ln_arr["vi"]="Vietnamese"
ln_arr["cy"]="Welsh"
ln_arr["yi"]="Yiddish"

trap bashtrap INT
bashtrap()
{
	echo "Exit signal detected. Deleting cache files."
	rm "$cachefile" 2> /dev/null
	exit
}

if [[ $TERMINAL_C == "WOB" ]];then
	declare -r C_RED="$(tput bold)$(tput setaf 1)"		#highlight
	declare -r C_YELLOW="$(tput bold)$(tput setaf 3)"	#highlight
	declare -r C_GRAY="$(tput setaf 7)"	#language detected
	declare -r C_CYAN_RAW="\033[1;36m" 	#forms
	declare -r C_GRAY_RED_RAW="\033[1;35m"	#phrases
	declare -r C_DARK_BLUE_RAW="\033[34m"	#link for dictionary
	declare -r C_BLUE_RAW="\033[1;34m"	#dictionary and vform1
	declare -r C_BRIGHT_RAW="\033[1;37m"	#phrases, examples main part, vform2
	declare -r C_GREEN="\033[1;32m"		#t_result
elif [[ $TERMINAL_C == "BOW" ]];then
	declare -r C_RED="$(tput bold)$(tput setaf 1)"		#highlight
	declare -r C_YELLOW="$(tput setaf 3)"			#highlight
	declare -r C_GRAY="$(tput bold)$(tput setaf 5)"	#language detected
	declare -r C_CYAN_RAW="\033[1;36m" 		#forms
	declare -r C_GRAY_RED_RAW="\033[1;35m"		#phrases
	declare -r C_DARK_BLUE_RAW="$(tput setaf 7)"	#link for dictionary
	declare -r C_BLUE_RAW="\033[1;34m"		#dictionary and vform1
	declare -r C_BRIGHT_RAW="$(tput bold)"		#phrases, examples main part, vform2
	declare -r C_GREEN="$(tput bold)"		#t_result
else #universal
	declare -r C_RED="$(tput setaf 1)"		#highlight
	declare -r C_YELLOW="$(tput bold)"		#highlight
	declare -r C_GRAY=""			#language detected
	declare -r C_CYAN_RAW="" 		#forms
	declare -r C_GRAY_RED_RAW=""		#phrases
	declare -r C_DARK_BLUE_RAW=""		#link for dictionary
	declare -r C_BLUE_RAW=""		#dictionary and vform1
	declare -r C_BRIGHT_RAW="$(tput bold)"	#phrases, examples main part, vform2
	declare -r C_GREEN="$(tput bold)"	#t_result
fi
declare -r C_NORMAL="$(tput sgr0)"
declare -r C_NORMAL_RAW="\033[0m"

jsscript="var googlearr = eval(JSON.stringify(myJSONObject));
function translated_result(arr){
	var rsum=\"\"; //translated text
	if(typeof googlearr[0] !== 'undefined' && googlearr[0] !== null){ //summing sentences
		for (var i = 0; i < googlearr[0].length; i++){
			if(typeof googlearr[0][i][0] !== 'undefined' && googlearr[0][i][0] !== null){
				rsum=rsum+googlearr[0][i][0];
			}
		}
	}
	print(rsum);
}
function translit(arr){
	var rsum=\"\"; //translit
	if(typeof googlearr[0] !== 'undefined' && googlearr[0] !== null){ //summing sentences
		for (var i = 0; i < googlearr[0].length; i++){
			if(typeof googlearr[0][i][3] !== 'undefined' && googlearr[0][i][3] !== null){
				rsum=rsum+'\n'+googlearr[0][i][3];
			}
		}
	}
	print(rsum);
}
function dictionary(arr){ //dictionary output
	if(typeof arr[1] !== 'undefined' && arr[1] !== null){
		for (var a = 0; a < arr[1].length; a++){
			if(typeof arr[1][a][0] !== 'undefined' && arr[1][a][0] !== null){
				print(\"$C_BLUE_RAW\"+arr[1][a][0]+\"$C_NORMAL_RAW\");//part of speach
				for (var b = 0; b < arr[1][a][2].length; b++){//words
					num=parseFloat(arr[1][a][2][b][3]); //frequency
					num2=Math.round(num*100000)/10;//round
					if (num2 >= 10)
						num2=Math.round(num2/10)*10;
					print(arr[1][a][2][b][0]+' '+arr[1][a][2][b][1]+' '+num2);//word + variant of speach + frequency
					//variant1 print(arr[1][a][2][b][0]+' '+arr[1][a][2][b][1]+' '+Math.round(num*1000000)/1000000);//word + variant of speach + frequency
					//old print(arr[1][a][2][b][0]+' '+arr[1][a][2][b][1]);//word + variant of speach
				}
			}
		}
	}
}
function language_identification(arr){ //get detected languages
	if(typeof arr[8] !== 'undefined' && arr[8] !== null && typeof arr[8][0] !== 'undefined' && arr[8][0] !== null && typeof arr[8][0][0] !== 'undefined' && arr[8][0][0] !== null){
		print('Detected language: '+arr[8][0][0]); //detected language
	}
}
"

sound=0
volume=0.8
if [[ $1 = -h || $1 = --help ]]; then #help
	echo "$help"
	exit
fi
if [[ $1 == -s || $1 == --sound ]];then #sound varibles
	sound=1
	request=($*) #get array
	request[0]="" #remove first parameter
	request=${request[*]} #to string
else
	request="$*"
fi
if [[ $1 = -l || $1 = --list ]]; then #list
	for i in "${!ln_arr[@]}" ;do
		echo -e "$i\t${ln_arr[$i]}"
	done | sort -k2
	exit
fi

if [[ ${#request} -eq 0 ]];then #using saved fixed string without parameters
	if [[ -e $FIXED_STRING ]]; then
		request=$(cat $FIXED_STRING 2>/dev/null)
		echo -e "$(tput bold)$(tput setaf 3)$request$(tput sgr0)"
	else
		exit
	fi
fi
#rm $FIXED_STRING 2> /dev/null

tchar=${request:0:1} #language detection by the first character
tcharnum=$(printf "%d" "'${tchar}")
if [[ $tcharnum -ge 65 && $tcharnum -le 122 || (( $TLSOURCE == $LATIN_LANG && ! $TLTARGET )) ]]; then #if request is A-Za-z then it is LATIN_LANG... ("en,it" will not be detected here idk how to make it for now)
	# latin to first
	source="$LATIN_LANG" #english or latin alphabet
	target="$FIRST_LANG" #if text is english target language is FIRST_LANG
else 	# ANY language to latin
	source="$FIRST_LANG"
	target="$LATIN_LANG"
fi

[[ $TLSOURCE ]] && source=$TLSOURCE; 
[[ $TLTARGET ]] && target=$TLTARGET; # export TLSOURCE=en TLTARGET=ru; will force the language

eng_sound_download(){ 			# $cachefile, 
	[[ $(ls "$PR_DIR"/cache | wc -l) -gt $words_buffer ]] && find "$PR_DIR"/cache -mtime +20 -delete #cache cleaning. remove words older than 20 days.
	rm "$PR_DIR"/tmpcookie 2>/dev/null &
	curl -s -c "$PR_DIR"/tmpcookie --connect-timeout $timeout -m $timeout --user-agent "$useragent" $httpsproxy -x "$httpproxy" -d "login=$flogin&password=$fpass" http://ru.forvo.com/login/ -o/dev/null
	if [[ -e "$PR_DIR"/tmpcookie ]]; then
		slink=$(curl -s -b $PR_DIR/tmpcookie --connect-timeout $timeout -m $timeout --user-agent "$useragent" $httpsproxy -x "$httpproxy" http://ru.forvo.com/word/"$(echo $request | tr ' ' _ )"/ | grep -o '[^"]*/download/mp3/'"$(echo $request | tr ' ' _ )"'/en/[^"]*' |head -n 1 )
		if [[ ${#slink} -gt 5 ]];then
			 curl -s -b "$PR_DIR"/tmpcookie --connect-timeout $timeout -m $timeout --user-agent "$useragent" $httpsproxy -x "$httpproxy" http://ru.forvo.com"$slink" > "$cachefile".mp3
			return
		fi
	fi
	[ $sound -eq 1 ] && echo fail to get sound from forvo.com
}


#----------------------------------------------- MAIN PART ----------------------------------------------------------------

if [[ ${#request} -gt 300 ]]; then
	if ! result=$(curl -s -i --user-agent "$useragent" $httpsproxy -x "$httpproxy" -d "sl=$source" -d "tl=$target" --data-urlencode "text=$request" http://translate.google.com) && [[ $httpproxy != "" ]] #getting google respond for short sentence
	then	# second attempt without https proxy
		httpsproxy=""
		result=$(curl -s -i --user-agent "$useragent" $httpsproxy -x "$httpproxy" -d "sl=$source" -d "tl=$target" --data-urlencode "text=$request" http://translate.google.com)
	fi
	#encoding=$(awk '/Content-Type: .* charset=/ {sub(/^.*charset=["'\'']?/,""); sub(/[ "'\''].*$/,""); print}' <<<"$result")
	#iconv -f $encoding <<<"$result" | awk 'BEGIN {RS="<div"};/<span[^>]* id=["'\'']?result_box["'\'']?/ {sub(/^.*id=["'\'']?result_box["'\'']?(>| [^>]*>)([ \n\t]*<[^>]*>)*/,"");sub(/<.*$/,"");print}' | html2text -utf8
	#echo -e "\033[32;1m"$(iconv -f "$encoding" <<<"$result" |  awk 'BEGIN {RS="</div>"};/<span[^>]* id=["'\'']?result_box["'\'']?/' | html2text -utf8)"$C_NORMAL_RAW"
	echo -e "\033[32;1m"$(echo "$result" |  awk 'BEGIN {RS="</div>"};/<span[^>]* id=["'\'']?result_box["'\'']?/' | html2text -utf8)"$C_NORMAL_RAW"

else
	if [[ $r_words_count -le 4 ]];then 
		httpproxy="" ; httpsproxy=""  #don't wanna proxy for 4 words.
		request=$(echo "$request" | tr '[:upper:]' '[:lower:]') #lower request for short sentences
	fi
	cachefile="$PR_DIR/cache/$source-$target"_"$request"
	r_words_count=$(echo "$request"  |wc -w)
	if [[ ! -e "$cachefile" || (( $sound == 1 && ! -e "$cachefile".mp3 )) ]]; then

		if ! grespond=$(curl -s -i --user-agent "$useragent" $httpsproxy -x "$httpproxy" -m $timeout --data-urlencode "text=$request" "http://translate.google.com/translate_a/t?client=t&hl=$target&sl=$source&tl=$target&ie=UTF-8&oe=UTF-8&multires=1&ssel=0&tsel=0&sc=1") && [[ "$httpproxy" != "" ]] #getting google respond for short sentence
		then	# second attempt without https proxy
			#echo https proxy not working. using http proxy.
			httpsproxy=""
			grespond=$(curl -s -i --user-agent "$useragent" $httpsproxy -x "$httpproxy" -m $timeout --data-urlencode "text=$request" "http://translate.google.com/translate_a/t?client=t&hl=$target&sl=$source&tl=$target&ie=UTF-8&oe=UTF-8&multires=1&ssel=0&tsel=0&sc=1") #getting google respond for short sentence
		fi
		[[ ! $(echo "$grespond" | grep -o '\[.*\]') ]] && { echo "can't connect" ; exit; } #small connection check

		#echo -n "var myJSONObject = " > "$PR_DIR"/tmpjsobj2
		#echo [$(echo "$grespond" | grep -o '"[^"]*/i[^"]*"')"];" >> "$PR_DIR"/tmpjsobj2
		#echo [$(echo "$grespond" | grep -o '[^"]*/i[^"]*')"];"
		#echo -e "var googlearr = eval(JSON.stringify(myJSONObject));\n print(googlearr);" >> "$PR_DIR"/tmpjsobj2
		#js "$PR_DIR"/tmpjsobj2
		fl_raw=$(echo "$grespond" | grep -o '[^"]*/i[^"]*') #google correction from $grespond

		#Highlight
		declare difftest
		[[ $fl_raw ]] &&
			if [[ $r_words_count -le 2 ]];then #for 1-2 words
				fl=$(echo "$fl_raw" | sed 's/\\u003cb\\u003e\\u003ci\\u003e//g' | sed 's/\\u003c\/i\\u003e\\u003c\/b\\u003e//g' | sed 's/\\u0026//g' | sed "s/\#39;/'/g") #removing shit
				[[ $(echo "$fl" | tr -d "'") == "$request" ]] && fl="" # skip highlight for ' char
				difftest="$(cmp -l <(echo -n $request) <(echo -n $fl) 2>/dev/null)" #comparison
				if [[ $(echo "$difftest" | grep '[0-9]') ]];then
				echo "$fl" > $FIXED_STRING					
					#[[ $source != en ]]&& diffnum=$(($diffnum/2+$diffnum%2))   #MUST BE CHECKED FOR REQUIRED LANGUAGES
					#[[ ${fl:$diffnum-1:1} == ' ' ]] && let diffnum-- #white space correction
					for (( i=$(echo "$difftest" | wc -l); i>=1; i--)); do
						pos=$(($(echo "$difftest" | sed -n $i'p' | sed -E 's/(([^ ]+ )).*/\1/' ) - 1))
						fl=$(echo "$fl" | sed 's/^\(.\{'$pos'\}\).\(.*\)/\1'$C_RED"${fl:$pos:1}"$C_NORMAL$C_YELLOW'\2/') #highlight difference in one word
					done
				fi
				fl="$C_YELLOW$fl$C_NORMAL"
			else
				fl=$(echo "$fl_raw" | sed 's/\\u003cb\\u003e\\u003ci\\u003e/'$C_YELLOW'/g' | sed 's/\\u003c\/i\\u003e\\u003c\/b\\u003e/'$C_NORMAL'/g' | sed 's/\\u0026//g' | sed "s/\#39;/'/g" ) #google fixed text
				echo "$fl" > $FIXED_STRING
			fi
#echo $difftest
#echo $grespond | grep -o '\[.*\]'

		echo -n "var myJSONObject = " > "$PR_DIR"/tmpjsobj
		echo -n "$grespond" | grep -o '\[.*\]' >> "$PR_DIR"/tmpjsobj
		echo ";">> "$PR_DIR"/tmpjsobj
		echo -n "$jsscript" >> "$PR_DIR"/tmpjsobj

		cp -f "$PR_DIR"/tmpjsobj "$PR_DIR"/tmpjsobj2
		echo -n "language_identification(googlearr);" >> "$PR_DIR"/tmpjsobj2
		det_language=$(js "$PR_DIR"/tmpjsobj2 | tail -c3)		# detected language
		cp -f "$PR_DIR"/tmpjsobj "$PR_DIR"/tmpjsobj2
		echo -n "translated_result(googlearr);" >> "$PR_DIR"/tmpjsobj2
		t_result=$(js "$PR_DIR"/tmpjsobj2)				# translated text
		cp -f "$PR_DIR"/tmpjsobj "$PR_DIR"/tmpjsobj2
		echo -n "translit(googlearr);" >> "$PR_DIR"/tmpjsobj2
		translit=$(js "$PR_DIR"/tmpjsobj2)				# translit
		cp -f "$PR_DIR"/tmpjsobj "$PR_DIR"/tmpjsobj2
		echo -n "dictionary(googlearr);" >> "$PR_DIR"/tmpjsobj2
		dictionary=$(js "$PR_DIR"/tmpjsobj2)				# dictionary

		#Language detection
		[[ $det_language != $source && (( $TLSOURCE || $det_language != $ENGLISH_TARGET_LANG )) ]] && echo -e "$C_GRAY*	$det_language ${ln_arr[$det_language]}$C_NORMAL"

		if [[ $source != $det_language && ! $fl_raw && ((
				$(echo $request | sed 's/ //g' | tr '[:upper:]' '[:lower:]') ==  $(echo $t_result | sed 's/ //g' | tr '[:upper:]' '[:lower:]') || 
				$(echo $t_result | sed 's/ //g' | tr '[:upper:]' '[:lower:]') ==  $(echo $translit | sed 's/ //g' | tr '[:upper:]' '[:lower:]') ||
				${request:0:1} == ${t_result:0:1}
				)) && ! $dictionary ]]; then
			[[ $source != "auto" ]] && echo -e "trying with detected language" # I guess google "auto" is not working then we will do it by yourself mutely
			export TLSOURCE=$det_language #TLTARGET=en #source and target language for second attempt
			if [[ $sound == 1 ]]; then $0 -s "$request" ; else $0 "$request" ;fi #second attempt to translate with detected language  #sound will be quiet...
			exit
		fi

		[[ $source == "auto" ]] && { source=$det_language; cachefile="$PR_DIR/cache/$source-$target"_"$request"; } #auto in cachefile fix #not necessary





		declare trans
		if [[ $r_words_count -le 2 && ${#request} -gt 1 && $source == en && ! $(echo "$difftest" | wc -l) -gt 1 ]];then #special check( expample: advise advice)
		#transcription
			trans=$(curl -s --user-agent "$useragent" $httpsproxy -x "$httpproxy" http://lingvo-online.ru/en/Translate/en-"$target"/"$request" | grep -o '"[^"]*/transcription\.gif.Text=[^"]*"' | sed 's/.*=\(.*\)"/\1/'| echo -n -e $(sed 's/+/ /g; s/%/\\x/g')) #getting transcription
			[[ $? != 0 ]] &&  { echo "can't get transcription"; } #bashtrap;
		fi
		#"Dictionary part" for english only. but it can be extended for every required language
		if [[ $r_words_count -eq 1 && ${#request} -gt 1 && $source == en && (( ! $fl_raw || $trans )) ]]; then #dictionary
		
			echo -e "$C_GREEN$t_result$C_NORMAL_RAW" > "$cachefile" #google translated text to cache
			[[ $dictionary ]] && echo -e "$dictionary" >> "$cachefile" #google dictionary to cache

			#phrases, forms and a vform
			macmill=$(curl -s --user-agent "$useragent" $httpsproxy -x "$httpproxy" -m $timeout http://www.macmillandictionary.com/dictionary/british/"$(echo $request | tr '[:upper:]' '[:lower:]' | tr ' ' - )" )
			[[ $? != 0 ]] && { echo "cant get phrases" ; bashtrap; }
			#forms
			forms=$(echo $macmill | grep -o "id=\"wordsformslayer-head\".*End of DIV wordforms" | sed 's/INFLECTION-CONTENT/\n/g' | sed -e 's/.*INFLECTION-ENTRY\">\([^<]*\)<.*I-VARIANT-before\">\([^<]*\).*INFLECTION-ENTRY\">\([^<]*\).*/666\1\2\3,/' -e 's/.*INFLECTION-ENTRY\">\([^<]*\)<.*/666\1,/' | grep 666 | cut -c 4-)
			fwc=$(echo "$forms" | wc -l)
			firstf=$(echo "$forms" | head -n 1) #1
			last1f=$(echo "$forms" | tail -n 2 | head -n 1) #end-1
			lastf=$(echo "$forms" | tail -n 1) #end
			[[ (( fwc -eq 5 && (( ${firstf%?}"ed," != $lastf || ${firstf%?}"ed," != $last1f || $lastf != $last1f )) )) ||
			   (( fwc -eq 3 && (( ${firstf%?}"er," != $last1f  || ${firstf%?}"est," != $lastf )) )) ||
			   (( fwc -eq 2 && (( ${firstf%?}"s," != $lastf )) )) ||
			   (( fwc -eq 4 )) ]] && echo -e "$C_CYAN_RAW"forms:$C_NORMAL ${forms%?} >> "$cachefile"
			#vform
			vform=$(echo "$macmill" | grep -o "GREF-ENTRY-before.*</a>" | sed 's/<\/a>/<\/a>\n/g' | head -n 1 | sed 's/.*<a[^>]*>\([^<]*\).*/\1/')
			vform_desc=$(echo "$macmill" | grep "span class=\"GREF-TYPE\"" | sed 's/.*<span class=\"GREF-TYPE\">\([^<]*\)<.*/\1/')
			[[ $vform ]] && echo -e "$C_BLUE_RAW$vform_desc$C_NORMAL_RAW" "$C_BRIGHT_RAW$vform$C_NORMAL_RAW" >> "$cachefile"
			#phrases
			raw_phras=$(echo "$macmill" | grep -o '<li ID.*End of DIV SENSE--></li>' | sed 's/<.\?span[^>]*>//g')
			#div class="P-HEAD" #| sed 's/End of DIV SENSE--><\/li>/\n/g' \ -e 's/.*\"h2\">\([^<]*\).*\"EXAMPLE\">\([^<]*\).*\"EXAMPLE\">\([^<]*\).*/**\'$C_BRIGHT_RAW'\1'$C_NORMAL'\. \2<FUCKINGSHIT>\t\3/' \ | nl -s ' ' | sed -e 's/<FUCKINGSHIT>/\n/' -e 's/^ *//'
#-e 's/.*\"EXAMPLE\">\([^<]*\).*\"EXAMPLE\">\([^<]*\).*/**\1<FUCKINGSHIT>\t\2/' \
			phras=$(echo $raw_phras | sed -e 's/<a[^>]*>//g' -e 's/<\/a>//g' | sed -e 's/div class=\"P-HEAD\"/\n?????/g' | grep "?????" | grep -n . | sed 's/^[0-9]*:/&\n/' | sed 's/End of DIV EXAMPLES/\n/g' | sed '/^[0-9]*:/{h;d;};G; s/^\(.*\)\n\([0-9]*:\)/\2 \1/' | sed \
-e 's/^\([0-9]*\):.*\"h2\">\([^<]*\).*\"h2\">\([^<]*\).*\"EXAMPLE\">\([^<]*\).*/**\1 \'$C_BRIGHT_RAW'\2\3'$C_NORMAL'\. \4/' \
-e 's/^\([0-9]*\):.*\"h2\">\([^<]*\).*\"EXAMPLE\">\([^<]*\).*/**\1 \'$C_BRIGHT_RAW'\2'$C_NORMAL'\. \3/' \
-e 's/^\([0-9]*\):.*\"h2\">\([^<]*\).*\"h2\">\([^<]*\).*class=\"SENSE-BODY\">\([^<]*\).*/**\1 \'$C_BRIGHT_RAW'\2\3'$C_NORMAL'\. \4/' \
-e 's/^\([0-9]*\):.*\"h2\">\([^<]*\).*class=\"SENSE-BODY\">\([^<]*\).*/**\1 \'$C_BRIGHT_RAW'\2'$C_NORMAL'\. \3/' \
-e 's/^\([0-9]*\):.*\"EXAMPLE\">\([^<]*\).*/**\1 \2/' | grep -o "^\*\*[0-9].*" | sed 's/^\*\*//' ) # doubleh2+exmaple, h2+exmaple, doubleh2+sentence, h2+sentence, only example
			if [[ $phras ]]; then 	#phrases
				echo -e "$C_GRAY_RED_RAW"PHRASES:$C_NORMAL >> "$cachefile"
				echo -e "$phras" >> "$cachefile"
				#echo -e "$C_DARK_BLUE_RAW"http://www.macmillandictionary.com/dictionary/american/"$request"$C_NORMAL >> "$cachefile"
			else 			#second attempt examples
				phrases_2=$(echo "$macmill" | sed -e 's/<a[^>]*>//g' -e 's/<\/a>//g' | sed 's/<.\?span[^>]*>//g' | grep -o 'div class="SENSE".*End of DIV SENSE--' | sed 's/End of DIV SENSE--/\n/g' | grep -n . | sed 's/^.:/&\n/' | sed 's/End of DIV EXAMPLES/\n/g' | sed '/^[0-9]:/{h;d;};G; s/^\(.*\)\n\([0-9]:\)/\2 \1/' | grep "<strong>" | sed 's/^\([0-9]\).*<strong>\([^<]*\)<.*class=\"EXAMPLE\">\([^<]*\)<.*/\1 \'$C_BRIGHT_RAW'\2'$C_NORMAL'. \3/' | sed 's/^\([0-9]\).*<strong>\([^<]*\)<\/strong>\([^<]*\).*/\1 \'$C_BRIGHT_RAW'\2'$C_NORMAL'. \3/' | sed 's/\. / /')
				if [[ $phrases_2 ]];then
					echo -e "$C_GRAY_RED_RAW"EXAMPLES:$C_NORMAL >> "$cachefile"
					echo -e "$phrases_2" >> "$cachefile"
				fi
			fi
			
			#transcription
			[[ $trans ]] && echo "[$trans]" >> "$cachefile"

			cat "$cachefile" 2>/dev/null #output
			echo -e "$C_DARK_BLUE_RAW"http://oxforddictionaries.com/definition/english/$(echo "$request" | sed "s/'/%27/" )$C_NORMAL # just another good english dictionary

			if [[ ${#request} -gt 2 || $r_words_count -le 2 ]] ; then

				#saving words
				ted_words_file=$(cat "$TR_ENG_WORDS")
				ted_words_file=$(echo "$ted_words_file" | tail -n 70)
				if [[ ! $(echo "$ted_words_file" | grep "$request" 2>/dev/null) ]]; then
					echo -e "$ted_words_file\n""$request" > "$TR_ENG_WORDS"
					#echo -e "$request \t\t\t\t\t\t\t\t\t\t [$trans]" >> "$TR_ENG_WORDS"
				fi
				
				#getting sound from forvo.com
					[[ ! -e "$cachefile".mp3 ]] &&
						if [[ $sound == 1 || $SOUND_DOWNLOAD_AWS == 1 ]];then
							eng_sound_download &      # in background
						fi
						
			fi
		else #not english dictionary
			echo -e "$C_GREEN$t_result$C_NORMAL_RAW" 					#google translated text output
			[[ $source != en && $r_words_count -le $TRANSLIT_WORDS_MAX && $(echo $t_result | sed 's/ //g' | tr '[:upper:]' '[:lower:]') !=  $(echo $translit | sed 's/ //g' | tr '[:upper:]' '[:lower:]') ]] && echo -e "$translit" 				#google translit	output
			[[ $dictionary ]] && echo -e "$dictionary"  				#google dictionary 	output

			if [[ $source == en && ! $fl_raw && $r_words_count -le 4 ]]; then
				#phrases for 2 words
				if [[ $r_words_count -le 2 ]];then

					#getting sound from forvo.com
					[[ ! -e "$cachefile".mp3 ]] &&
						if [[ $sound == 1 || $SOUND_DOWNLOAD_AWS == 1 ]];then
							eng_sound_download &      # in background
						fi

					macmill=$(curl -s --user-agent "$useragent" $httpsproxy -x "$httpproxy" http://www.macmillandictionary.com/dictionary/british/"$(echo $request | tr ' ' - )" )
					[[ $? != 0 ]] && { echo "cant getmacmillandictionary.com phrases for string" ; bashtrap; }
					macmill=$(echo "$macmill" | grep -o 'div class="SENSE".*End of DIV SENSE--' | sed -e 's/<a[^>]*>//g' -e 's/<\/a>//g' | sed 's/End of DIV SENSE--/\n/g' | grep -n . | sed 's/^[0-9]*:/&\n/' | sed 's/End of DIV EXAMPLES/\n/g' | sed '/^[0-9]*:/{h;d;};G; s/^\(.*\)\n\([0-9]*:\)/\2 \1/' | sed \
-e's/^\([0-9]*\):.*p id=\"EXAMPLE\" class=\"EXAMPLE\">\([^<]*\)<.*/*\1 \2/' \
-e 's/^\([0-9]\).*span class=\"BASE\">\([^<]*\).*context=\"DEFINITION-before\"> <\/span>\([^<]*\).*/*\1 \'$C_BRIGHT_RAW'\2'$C_NORMAL'\. \3/' | grep -o "^\*[0-9].*" | sed 's/^*//')
				fi
				examples=$macmill
				if [[ $examples ]];then
					echo -e "$C_GRAY_RED_RAW"EXAMPLES:$C_NORMAL
					echo -e "$examples"
				fi

				#search for ideom for 2-4 words
				if [[ ! $phras2 ]]; then
					list=$(curl -s --user-agent "$useragent" $httpsproxy -x "$httpproxy" http://www.thefreedictionary.com/"$(echo $request | tr ' ' + )")
					[[ $? != 0 ]] && { echo "cant get thefreedictionary.com phrases for string" ; bashtrap; }
					list=$(echo "$list" | grep "[fF]ound in:")
					if [[ $list ]]; then
						ideomlink=$(echo "$list" | grep -o 'http://idioms[^"]*')
						if [[ $ideomlink ]]; then
							raw_ideoms=$(curl -s --user-agent "$useragent" $httpsproxy -x "$httpproxy" "$ideomlink" | grep -o 'div class="ds-single".*</div><div')

							ideom=$(echo "$raw_ideoms" | sed 's/<i>//' | sed 's/<\/i>//' | sed 's/.*ds-single\">\([^<]*\)<.*/\1/')
							illustration=$(echo "$raw_ideoms" | sed 's/.*class=illustration>\([^<]*\)<.*/\1/')
							if [[ $ideom ]]; then
								echo -e "$C_GRAY_RED_RAW"Ideom:$C_NORMAL
								echo $ideom
								[[ $illustration ]] && echo $illustration
							fi
						else
							ency_link=$(echo "$list" | grep -o 'http://encyclopedia2[^"]*')
							if [[ $ency_link ]]; then
								raw_ency=$(curl -s --user-agent "$useragent" $httpsproxy -x "$httpproxy" "$ency_link")								
								ency=$(echo "$raw_ency" | grep '<div class=hw>' | grep -o 'div>.*<br /' | sed -e 's/"//g' | sed -e 's/<b>/'$(tput bold)'/g' -e 's/<\/b>/'$C_NORMAL'/g' | sed 's/div>\([^<]*\).*/\1/')
								contr_ency=$(echo "$raw_ency" | grep "Contrast with" | sed 's/.*\">\([^<]*\)<\/a.*/\1/')
								if [[ $ency ]]; then
									echo -e "$C_GRAY_RED_RAW"Ideom:$C_NORMAL
									echo "$ency"
									[[ $contr_ency ]] && echo -e  Contrast with: "$C_BRIGHT_RAW"$contr_ency"$C_NORMAL"
								fi	
							fi
						fi
					fi
				fi
			fi

		fi #end of english dictionary
		[[ $fl_raw ]] && echo -e "$fl" #empty line... cant fix it (:'d		#google fixed text 	output
	else #cache output
		cat "$cachefile" #output
		[[ $source == en ]] && echo -e "$C_DARK_BLUE_RAW"http://oxforddictionaries.com/definition/english/"$request"$C_NORMAL
	fi

	#sound	
	if [[ $sound == 1 ]]; then
		wait
		if [[ -e "$cachefile".mp3 ]]; then
			if [[ $(stat -c%s "$cachefile".mp3) -ge 11000 ]]; then #if .mp3 is corrrect
				stat=$(mpg123 "$cachefile".mp3 2>&1)
#				echo "$stat"
				[[ ! $(echo "$stat" | grep -o 'Comment') ]] && rm "$cachefile".mp3
			else
				rm "$cachefile".mp3
				echo ".mp3 file is corrupt. try again."
			fi
		else
			#echo ".mp3 file not found."
			sleep 1 #to be able Ctrl+C to delete cache file
		fi
	fi
fi

exit


#rest languages for interface. not in list of source language
#hl=ak          Akan
#hl=bem         Bemba
#hl=bh          Bihari
#hl=xx-bork     Bork, bork, bork!
#hl=bs          Bosnian
#hl=br          Breton
#hl=km          Cambodian
#hl=chr         Cherokee
#hl=ny          Chichewa
#hl=zh-TW       Chinese (Traditional)
#hl=co          Corsican
#hl=xx-elmer    Elmer Fudd
#hl=ee          Ewe
#hl=fy          Frisian
#hl=gaa         Ga
#hl=gn          Guarani
#hl=xx-hacker   Hacker
#hl=ha          Hausa
#hl=haw         Hawaiian
#hl=ig          Igbo
#hl=ia          Interlingua
#hl=jw          Javanese
#hl=kk          Kazakh
#hl=rw          Kinyarwanda
#hl=rn          Kirundi
#hl=xx-klingon  Klingon
#hl=kg          Kongo
#hl=kri         Krio (Sierra Leone)
#hl=ku          Kurdish
#hl=ckb         Kurdish (Soranî)
#hl=ky          Kyrgyz
#hl=ln          Lingala
#hl=loz         Lozi
#hl=lg          Luganda
#hl=ach         Luo
#hl=mg          Malagasy
#hl=ml          Malayalam
#hl=mi          Maori
#hl=mr          Marathi
#hl=mfe         Mauritian Creole
#hl=mo          Moldavian
#hl=mn          Mongolian
#hl=sr-ME       Montenegrin
#hl=ne          Nepali
#hl=pcm         Nigerian Pidgin
#hl=nso         Northern Sotho
#hl=nn          Norwegian (Nynorsk)
#hl=oc          Occitan
#hl=or          Oriya
#hl=om          Oromo
#hl=ps          Pashto
#hl=xx-pirate   Pirate
#hl=pt-BR       Portuguese (Brazil)
#hl=pt-PT       Portuguese (Portugal)
#hl=pa          Punjabi
#hl=qu          Quechua
#hl=rm          Romansh
#hl=nyn         Runyakitara
#hl=gd          Scots Gaelic
#hl=sh          Serbo-Croatian
#hl=st          Sesotho
#hl=tn          Setswana
#hl=crs         Seychellois Creole
#hl=sn          Shona
#hl=sd          Sindhi
#hl=si          Sinhalese
#hl=so          Somali
#hl=es-419      Spanish (Latin American)
#hl=su          Sundanese
#hl=tg          Tajik
#hl=tt          Tatar
#hl=ti          Tigrinya
#hl=to          Tonga
#hl=lua         Tshiluba
#hl=tum         Tumbuka
#hl=tk          Turkmen
#hl=tw          Twi
#hl=ug          Uighur
#hl=uz          Uzbek
#hl=wo          Wolof
#hl=xh          Xhosa
#hl=yo          Yoruba
#hl=zu          Zulu

#comment="arr=googlearr;
#for (var c = 0; c < arr.length; c++){ //testing
#	if(typeof arr[c] !== 'undefined' && arr[c] !== null){ //dictionary output
#		for (var i = 0; i < arr[c].length; i++){
#			if(typeof arr[c][i] !== 'undefined' && arr[c][i] !== null){
#				for (var e = 0; e < arr[c][i].length; e++){
#					print(c);
#					print(arr[c][i][e]);
#					//print(arr[8][0][1]);
#				}
#			}
#		}
#	}
#}
#	frequency experiment	whitespace=' ' //for x.x and xxx format
#					num2=Math.round(num*10000)/10;
#					if (num2 < 10 && num2%1 == 0){
#						whitespace='   '; //for x format
#					}
#					if (num2 >= 10){
#						num2=Math.round(num2/10)*10;
#						if (num2 < 100){
#							whitespace='  '; //for xx format
#						}
#					}
#					print(num2+whitespace+arr[1][a][2][b][0]+' '+arr[1][a][2][b][1]);//frequency + word + variant of speach
#"
