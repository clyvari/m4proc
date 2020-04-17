#!/bin/bash
#
# m4proc - (c) Copyright Cyril Claverie - 2016
# 
# This tool allow for processing of files using a macro processor.
# Sometimes the syntax of the original files doesn't allow for macro instructions
# This tool is here to help achieve this goal
#

set -eu

declare -ri VERSION_MAJ=1
declare -ri VERSION_MIN=0
declare -r VERSION_BUILD='a'
declare -r VERSION="${VERSION_MAJ}.${VERSION_MIN}-${VERSION_BUILD}"

declare -r EXEC_NAME="m4proc"

function m4proc::show_help()
{
  cat <<EOF
${EXEC_NAME} - (c) Copyright Cyril Claverie - 2016
v${VERSION}

This tool parse an input file then send it to a macro processor.
This should work independently of the input file language.

OPTIONS:
    ${EXEC_NAME} --help
    ${EXEC_NAME} [--comment|-c <PATTERN>] [--m4-switch|-s <PATTERN>] [--input-file|-f <FILE>|-] [--no-m4|-n] [--pre-m4-comment|-p <PATTERN>] [--post-remove-unmarked|-r] [--macro-processor|-m <EXEC>] [<PROCESSOR_OPTIONS> [...]]

    --comment|-c:              What combination of characters serves as a single
                               line comment in the source language.
                     
    --m4-switch|-s:            Indicate the string immediatelly after the
                               --comment that indicate a macro directive
                     
    --input-file|-f:           The file to process, or - to read from stdin
     
    --no-m4|-n:                No macro processing. This will show you the file
                               that is going to be sent to the macro processor.
                               Useful for debugging.

    --pre-m4-comment|-p:       The single line comment characters in the macro
                               processor language, and/or additional characters
                               to mark input file lines that are not part of the
                               processors directives. This is especially usefull
                               if some input file language syntax could be
                               mis-interpreted by the macro processor. This is
                               mandatory with the -r option, or else output will
                               be empty.

    --post-remove-unmarked|-r: Remove lines that are unmarked (mark is given by
                               --pre-m4-comment). This can be usefull to "clean"
                               output, since a lot of empty space can be left by
                               the macro processor. WARNING: it FORCES you to
                               generate text from your macro that start with the
                               value of --pre-m4-comment, or else it WILL be
                               removed.

    --macro-processor|-m:      The macro processor to use.

    <PROCESSOR_OPTIONS>:       All options not recognized by ${EXEC_NAME} will
                               be passed to the macro processor. If processor
                               option is alreay taken by ${EXEC_NAME}, you can
                               pass it this way: " -x", with quotes and a
                               leading space.


INFORMATIONS:
    
    For this file to be useful, you nee to be working with an input file syntax that doesn't handle preprocessing directives.
    This script as been written with m4 in mind, though it should with any macro processor.
    
    The goal is to keep the input file syntaxically correct, but allow preprocessor directives anyway. You could then keep working on your file without having to process it every time with your macro processor.
    
    As an example, let's say we are working with a file whose syntax for comments is \`#'
    Let's use the symbol \`@' as the processor 'switch', to indicate to ${EXEC_NAME} that we are not ealing with an ordinary comment, but rather a macro:
    
        <example1.sh>
        #@define(SYMBOL,VALUE) dnl define is a valid m4 directive
      
    For this file to be processed by ${EXEC_NAME}, we nee these options:
      ${EXEC_NAME} --comment '#' --m4-switch '@' -f example1.sh
      
        <example2.sh>
        #@ifdef(\`RELEASE',\`
        version="v0.1-release"
        #@',\`
        version="v0.1-devel"
        #@')
    
    This file also gets processed with:
      ${EXEC_NAME} --comment '#' --m4-switch '@' -f example12.sh
      and
      ${EXEC_NAME} --comment '#' --m4-switch '@' -f example12.sh -DRELEASE
    Please note the lines ening in \` and the lines starting with ' as this is important to avoid errors if commas are present in the generated strings.
    
        <example3.php>
        //@ifdef(\`RELEASE',\`
        include('libs/db.php');
        //@',\`
        include('../libs-devel/db.php');
        //@')
    
//@',
int i = 5;
//@)


EOF
}

function m4proc::main()
{
  local comment
  comment='#'
  
  local m4_switch m4_opt m4_cmd
  m4_switch='@'
  m4_opt=""
  m4_cmd="m4"
  
  local no_m4
  no_m4="n"
  
  local pre_m4_comment
  pre_m4_comment=''
  
  local post_remove_unmarked
  post_remove_unmarked="n"
  
  while [[ $# -ne 0 ]]; do
    case "$1" in
      --help)
        m4proc::show_help
        exit
      ;;
      
      --comment|-c)
        comment="$2" ; shift
      ;;
      
      --m4-switch|-s)
        m4_switch="$2" ; shift
      ;;
      
      --input-file|-f)
        input_file="$2" ; shift
      ;;
      
      --no-m4|-n)
        #m4_cmd="cat"
        no_m4="y"
      ;;
      
      --pre-m4-comment|-p)
        pre_m4_comment="$2" ; shift
      ;;
      
      --post-remove-unmarked|-r)
        post_remove_unmarked="y"
      ;;
      
      --macro-processor|-m)
        m4_cmd="$2" ; shift
      ;;
      
      *)
        m4_opt="${m4_opt} $1"
      ;;
    esac
    shift
  done
  
  if [[ "${post_remove_unmarked}" == "y" && "${pre_m4_comment}x" == "x" ]]; then
    echo "ERROR: You can't use option --post-remove-unmarked without setting --pre-m4-comment."
    m4proc::show_help
    exit 1
  fi
  
  local sed_pre_mark_notm4 sed_pre_release_m4 sed_pre_command
  sed_pre_mark_notm4='/^'"${comment}${m4_switch}"'/! s/^/'"${pre_m4_comment}"'/'
  sed_pre_release_m4='s/^'"${comment}${m4_switch}"'//'
  sed_pre_command="${sed_pre_mark_notm4} ; ${sed_pre_release_m4}"
  
  local sed_post_remove_unmarked sed_post_unmark sed_post_command
  sed_post_remove_unmarked='/^'"${pre_m4_comment}"'/!d'
  sed_post_unmark='s/^'"${pre_m4_comment}"'//'
  sed_post_command="${sed_post_unmark}"
  if [[ "${post_remove_unmarked}" == "y" ]]; then
    sed_post_command="${sed_post_remove_unmarked} ; ${sed_post_command}"
  fi
  
  sed "${sed_pre_command}" "${input_file}" \
    | if [[ "${no_m4}" == "n" ]]; then
        "${m4_cmd}" $m4_opt \
          | sed "${sed_post_command}"
      else
        cat
      fi
}

m4proc::main "$@"
