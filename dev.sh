#!/bin/bash
# cdev
# Console dev tools for Sublime editor
 
# Environment startup
if [ "$DEV_EDITOR" = "" ]
  then
    DEV_EDITOR="vim"
fi
if [ "$DEV_RESULT_LIMIT" = "" ]
  then
    DEV_RESULT_LIMIT=10
fi
if [ "$CHOTOT_HOME_PATH" = "" ]
  then
    CHOTOT_HOME_PATH="$HOME"
fi
# Path overwrite
if [ "$path_php" = "" ]
  then
    path_php='-path "./php/*"'
fi
if [ "$path_conf" = "" ]
  then 
    path_conf='-path "./conf/*"'
fi
if [ "$path_bconf" = "" ]
  then
    path_bconf='-path "./conf/bconf/*"'
fi
if [ "$path_sql" = "" ]
  then
    path_sql='-path "./scripts/db/plsql/*"'
fi
if [ "$path_c" = "" ]
  then
    path_c='-path "./modules/*" -o -path "./platform/*"'  
fi
if [ "$path_template" = "" ]
  then
    path_template='-path "./templates/*"' #@todo need to change filter here 
fi
if [ "$path_www" = "" ]
  then
    path_www='-path "./www/*"'
fi
if [ "$path_js" = "" ]
  then
    path_js='-path "./www/js/*"'
fi
if [ "$path_css" = "" ]
  then
    path_css='-path "./www/css/*"'
fi

# corlor vars
lgray='\e[1;30m'; green='\e[0;32m'; blue='\e[0;34m'; brown='\e[0;33m'; red='\e[0;31m';yellow='\e[1;33m';cyan='\e[0;36m';NC='\e[0m' # No Color ##########################################\n
### Please stay at project folder root ###\n
##########################################\n
STR_DIR_ERROR="Can not fild php, templates, conf, and scripts folders\n
Please change to project root folder"
STR_VAR_ERROR="Name is too short, try > 2 chars"
STR_SORRY="Not found"
STR_INPUT="Enter result file No. you want to open or q quit: "

showusage() {
  echo -e "${lgray}
###################################
# Chotot Console Dev Tools 1      #
###################################${NC}
  ${cyan}[usage] ${NC}$0 [-u usage of function] [-m method] [-e extension] search_string
          \t+ ${brown}search_string${NC}  string to search in extension:php method:function
          \t+ ${brown}Options:${NC}
          \t\t- [-u]  find usage of function
          \t\t+ [-m:]  method search
          \t\t\t- default  ${blue}function & class${NC}
          \t\t\t- ex:  sql, class
          \t\t+ [-e:]  file extension
          \t\t\t- default  ${blue}php${NC}
          \t\t\t- ex:  bconf, sql, php, html,...
          \t\t- ${blue}[-h]${NC}  display this usage information
          \t\t- ${blue}[-l:]${NC}  result limit
          \t${brown}Examles:${NC}
          \t- $0 bresponse
          \t- $0 -u bresponse #find usage of bresponse
          \t- $0 bres #same as bres*
          \t- $0 -o bres #auto open file
          \t- $0 -m class bres #class php
          \t- $0 -e sql accept #SP function name
          \t- $0 -e bconf category #bconf key and value find
          \t${brown}Export vars:${NC}
          \t- DEV_EDITOR: default $DEV_EDITOR
          \t- CHOTOT_HOME_PATH: default '$HOME'
          \t- DEV_RESULT_LIMIT: default 10
          "
  exit 1
}

# Default var options
method='both'
extension='php'
open=0
debug=0
usage=0
usage_str='uniq'
# Grep vars
surfix_grep=" "
mid_grep='.*'
nsur_grep='.*'
# Filter
cmd_function="function"
cmd_both="[class|function]+"
cmd_class="class"
cmd_sql="create"
cmd_template=""
cmd_conf=""
# Eval bash 3 surfix
sur_=" "
sur_template=" "
sur_function="("
sur_both="(|{"
sur_class="(|{"
sur_sql="(|{"
sur_conf=".|="
sur_js="{|(|="
# Get options
while getopts :m:e:u:l:dhou OPTIONS; do
    case $OPTIONS in
        m)
            method=$OPTARG;;
        e)
            extension=$OPTARG
            case "$extension" in
              sql)
                if [ $method=='function' ];then #wrong function
                  method='sql'
                fi
              ;;
              *)
                
              ;;
            esac;;
        o) 
            open=1;;
        u)
            usage=1;;
        h)
            showusage
            exit 1;;
        d)
            debug=1;;
        l)
            DEV_RESULT_LIMIT=$OPTARG;;
        ?)
            echo '?'
            showusage
            exit 1;;
        *) 
            echo '*'
            showusage
            exit 1;;
    esac
done
# Show dir error
show_error(){
  echo -e "${red}### "$1" ###${NC}"
}
# Check project root folder
check_root(){
  if [ ! -d "php" ] || [ ! -d "conf" ] || [ ! -d "modules" ] || [ ! -d "templates" ];then
    show_error "$STR_DIR_ERROR"
    exit 1
  fi
}

validate_var(){
  chk_string=$1
  if [ ${#chk_string} -lt 3 ];then
    show_error "$STR_VAR_ERROR"
    exit 1
  fi
}

main(){

  declare -i ii=0

  fileExtension=$extension;functionName=$1;filter=$method

  if [ $extension == "bconf" ] || [ $extension == "conf" ] ;then
    filter='conf'
  fi

  if [ $extension == "templates" ];then
    fileExtension='html'
  fi

  eval surfix_grep='$sur_'$filter
  if [ $usage == 0 ];then
    eval filter_str='$cmd_'$filter
  else
    filter_str=''
    usage_str=" grep -Ev function|class"
  fi

  eval filter_folder='$path_'$fileExtension
  fileExtension="-iname '*$fileExtension*'"
  if [ "$debug" == 1 ]; then
    echo "method|filter_str: "$filter_str
    echo "mid_grep: "$mid_grep
    echo "filter_folder: "$filter_folder
    echo "usage_str: "$usage_str
    echo "fileExtension: "$fileExtension
    echo "surfix_grep: "$surfix_grep
    echo "functionName: "$functionName
    echo "function DEV_RESULT_LIMIT: "$DEV_RESULT_LIMIT
    echo "CHOTOT_HOME_PATH: "$CHOTOT_HOME_PATH
    echo "open: "$open
    exit
  fi

  eval find . $fileExtension $filter_folder | xargs grep "$filter_str$mid_grep$functionName$nsur_grep[?$surfix_grep]" -rnisEl | $usage_str | head -n $DEV_RESULT_LIMIT | uniq | while read FILE
    do

      # File list
      echo -e "${cyan}[$ii] ${NC} ${blue}+ $FILE${NC}"
      # Function list
       eval grep --color='always' "\"$filter_str$mid_grep$functionName$nsur_grep[?$surfix_grep]\"" -niE $FILE| while read FUNC 
        do
          echo -e "\t - ${cyan}[$ii]${NC} $FUNC"
        done
      ((ii = ii+1)) # Num added
    done
         iresult=( $(eval find "." $fileExtension $filter_folder | xargs grep "$filter_str$mid_grep$functionName$nsur_grep[?$surfix_grep]" -rniEsl| $usage_str | head -n $DEV_RESULT_LIMIT | uniq) )
      if [[ "${#iresult[@]}" > 1 ]] # Many result
        then
          echo "$STR_INPUT";read line
          case "$line" in
            "q")
              exit
            ;; 
            *)
              if [ "${iresult["$line"]}" != ""  ]; then
                echo -e "${yellow}[OPEN]${NC} - ${iresult["$line"]}"
                $DEV_EDITOR ${iresult["$line"]} # (or other editing commands, eg awk... )
              else
                echo -e "${red}$STR_SORRY${NC}"
              fi
            ;;
          esac
      else # One result only
        if [ "${iresult[0]}" != "" ]; then
          if [ "$open" == 1 ]; then
            echo -e "${yellow}[OPEN]${NC} - ${iresult[0]}"
            $DEV_EDITOR ${iresult[0]} #open the first result
          fi
        else
          echo -e "${red}$STR_SORRY${NC}"
        fi
      fi
}

if [ $# -lt 1 ]
then
  showusage
fi
check_root
validate_var ${@: -1}
main ${@: -1}