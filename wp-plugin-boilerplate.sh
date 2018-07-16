#!/bin/bash


# ---------------------------------------------------------------------
# Bash script to scaffold a new plugin from WPPB.
#
# WordPress Plugin Boilerplate setup: a bash script to download and setup
# a new plugin derived from WordPress Plugin Boilerplate.
#
# Version 0.1.0
# Author: Codice Ovvio
# URL: https://github.com/codiceovvio/wp-plugin-boilerplate-setup
# License: GPLv2+
# (C) 2018 Codice Ovvio <codiceovvio@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
#     Test and validation steps needed to properly run the script
# ---------------------------------------------------------------------

#    - setup bash environment
set -eu -o pipefail

##
# Test dependencies first
#
# check if all needed programs are installed and available
# --------------------------------------------------------
test_dependencies() {

  echo "[+] Testing dependencies..." >&2
  if [[ ! -x $(which rename) ]] ||
     [[ ! -x $(which basename) ]] ||
     [[ ! -x $(which find) ]] ||
     [[ ! -x $(which cp) ]] ||
     [[ ! -x $(which sed) ]] ||
     [[ ! -x $(which git) ]] ||
     [[ ! -x $(which iconv) ]] ||
     [[ ! -x $(which sort) ]] ||
     [[ ! -x $(which rm) ]] ||
     [[ ! -x $(which wp) ]]; then
    echo "[-] Dependencies unmet.  Please verify that the following are installed, executable, and in the PATH:  rename, basename, find, cp, sed, git, iconv, sort, rm, wp" >&2
    exit 1
  fi

}

##
# Print script usage to stderr
# ----------------------------
print_usage() {

  echo "[!] Usage:" "Run this script from a WordPress install folder." >&2
  echo "    The remaining setup will be automatic." >&2

}

##
# Print script version & license to stdout
# ----------------------------------------
print_version() {

  echo "[#] $(basename $0):" >&1
  echo "    bash script to scaffold a new plugin from WPPB.." >&1
  echo "      - Version 0.1.0" >&1
  echo "      - License: GPLv2+" >&1
  echo "      - URL: https://github.com/codiceovvio/wp-plugin-boilerplate-setup" >&1
  echo "[#] (C) $(date +'%Y') - Codice Ovvio - <codiceovvio_at_gmail_dot_com>" >&1

}


# ---------------------------------------------------------------------
#                  WordPress Plugin Boilerplate setup:
# ---------------------------------------------------------------------

##
# Setup initial variables
# -----------------------
PLUGINS_DIR_PATH=$( wp plugin path 2>/dev/null || echo 'ERROR' )
CURRENT_DIR="$PWD"

##
# Validate arguments
# ------------------
validate_arguments() {

  #    - get the plugin folder path with wp cli

  echo "[+] Validating arguments..." >&2
  #    - check if we are in a WordPress install
  if [ "${PLUGINS_DIR_PATH}" == 'ERROR' ]; then
    echo ''
    echo '[!] Error: not a WordPress installation folder!!' >&2
    echo ''
    print_usage
    exit 1
  fi

}

##
# Get the plugin name
# -------------------
get_plugin_name() {

  read -r -p "Please enter the plugin name, e.g. 'My Plugin': " NEWNAME_ORIG

  #    - check if the plugin name is empty.
  if [[ -z "$NEWNAME_ORIG" ]]; then
    #  - keep asking for a name until provided
    while [[ "$NEWNAME_ORIG" == '' ]]; do
        read -p "[:] Please enter a name to use for your plugin, then press return: " NEWNAME_ORIG
    done
  fi

}

##
# Plugins folder check
# --------------------
plugins_folder_check() {

  if [ "${PLUGINS_DIR_PATH}" != "${CURRENT_DIR}" ]; then

    #    - prompt to proceed if folder is not empty
    echo -e  "\n[!] Warning: Current folder is not wp-content/plugins."
    echo -e  "    It is better to run this script from WordPress plugins folder."
    read -r -p "[?] Do you want to change folder to wp-content/plugins? [y/N]" proceed_step_1

    if [[ $proceed_step_1 =~ ^([yY][eE][sS]|[yY])$ ]]
    then
      #    - change folder to wp-content/plugins
      cd "${PLUGINS_DIR_PATH}"
    else
      read -r -p "[?] Do you want to continue in this folder? [y/N]" proceed_step_2

      if [[ $proceed_step_2 =~ ^([nN][oO]|[nN])$ ]]
      then
        #    - exit the script
        echo -e "[!] Aborted. Change folder and re-run this script.\n"
        exit
      fi
    fi
  fi

}

##
# Prepare new name search-replace
# -------------------------------
name_search_replace() {

  DEFAULTNAME='plugin-name'
  DEFAULTNAME_UND=$(echo "$DEFAULTNAME" | tr '-' '_')
  DEFAULTNAME_CAMEL_UND=$(echo "$DEFAULTNAME" | sed -r 's/([a-z]+)-([a-z])([a-z]+)/\1\U_\2\L\3/')
  DEFAULTNAME_UPPERCAMEL_UND="$(tr '[:lower:]' '[:upper:]' <<< ${DEFAULTNAME_CAMEL_UND:0:1})${DEFAULTNAME_CAMEL_UND:1}"
  DEFAULTNAME_UPPERCASE_UND="$(tr '[:lower:]' '[:upper:]' <<< ${DEFAULTNAME_UND})"
  DEFAULTNAME_UPPERCAMEL_SPA=$(echo "${DEFAULTNAME_UPPERCAMEL_UND}" | tr '_' ' ' )

  DEFAULTDIRNAME='WordPress-Plugin-Boilerplate'
  DEFAULTDIRNAME_SPA=$(echo "${DEFAULTDIRNAME}" | tr '-' ' ' )

  NEWNAME=$(echo ${NEWNAME_ORIG} | iconv -t ascii//translit | tr '[:upper:]' '[:lower:]' | tr ' ' '-' )
  NEWNAME_UND=$(echo "$NEWNAME" | tr '-' '_')
  NEWNAME_CAMEL_UND=$(echo "$NEWNAME_UND" | sed -r 's/(_)([a-z])/\1\U\2\L/g')
  NEWNAME_UPPERCAMEL_UND="$(tr '[:lower:]' '[:upper:]' <<< ${NEWNAME_CAMEL_UND:0:1})${NEWNAME_CAMEL_UND:1}"
  NEWNAME_UPPERCASE_UND="$(tr '[:lower:]' '[:upper:]' <<< ${NEWNAME_UND})"

}

##
# Last confirmation before the process begins
# -------------------------------------------
confirm_replacements() {

  echo -e "\nThe following replacements will be performed on the boilerplate:\n"

  echo -e "\tReplace \"${DEFAULTNAME}\" for \"${NEWNAME}\" in filenames and the plugin folder name"
  echo -e "\tReplace \"${DEFAULTNAME_UND}\" for \"${NEWNAME_UND}\" in variables and functions"
  echo -e "\tReplace \"${DEFAULTNAME_UPPERCAMEL_UND}\" for \"${NEWNAME_UPPERCAMEL_UND}\" in classes"
  echo -e "\tReplace \"${DEFAULTNAME_UPPERCASE_UND}\" for \"${NEWNAME_UPPERCASE_UND}\" in costants"
  echo -e "\tReplace \"${DEFAULTDIRNAME_SPA}\" for \"${NEWNAME_ORIG}\" as the name of the plugin in ${NEWNAME}.php"
  echo -e "\tReplace \"${DEFAULTNAME_UPPERCAMEL_SPA}\" for \"${NEWNAME_ORIG}\" at the 1st line of README.md"
  echo -e "\tReplace \"${DEFAULTNAME_UPPERCAMEL_SPA}\" for \"${NEWNAME_ORIG}\" at the 1st line of README.txt"
  echo ""

  read -r -p "[?] Do you want to proceed? [y/N]" continue_script

  if [[ $continue_script =~ ^([nN][oO]|[nN])$ ]]
  then
    #    - exit the script
    echo -e "[!] Aborted. Fix any errors in name and re-run this script.\n"
    exit
  fi

}

##
# Download the boilerplate
# ------------------------
download_boilerplate() {

  echo ""
  echo "[*] Downloading the boilerplate..."
  echo ""
  git clone https://github.com/DevinVinson/WordPress-Plugin-Boilerplate.git && \
  mv "${DEFAULTDIRNAME}" "${NEWNAME}" && \
  rm -rf "${NEWNAME}/.git" && \
  mv "${NEWNAME}/${DEFAULTNAME}/"* "${NEWNAME}" && \
  rm -rf "${NEWNAME:?}/${DEFAULTNAME}" && \
  cd "${NEWNAME}" && \
  mv "${DEFAULTNAME}.php" "${NEWNAME}.php"

}

##
# Rename the files
# ----------------
rename_files() {

  echo "[*] Renaming files..."
  find . -name "*${DEFAULTNAME}*" | while read FILE ; do
    NEWFILE=$(echo "${FILE}" | sed -e "s/${DEFAULTNAME}/${NEWNAME}/");
    echo "    Renaming \"${FILE}\" to \"${NEWFILE}\""
    mv "${FILE}" "${NEWFILE}";
  done
  echo ''

}

##
# Replace strings for variables, functions, classes, etc
# ------------------------------------------------------
replace_variables() {

  echo "[*] Renaming variables, functions, classes..."
  find . -type f -print0 | xargs -0 sed -i "s/${DEFAULTNAME}/${NEWNAME}/g"
  find . -type f -print0 | xargs -0 sed -i "s/${DEFAULTNAME_UND}/${NEWNAME_UND}/g"
  find . -type f -print0 | xargs -0 sed -i "s/${DEFAULTNAME_UPPERCAMEL_UND}/${NEWNAME_UPPERCAMEL_UND}/g"
  find . -type f -print0 | xargs -0 sed -i "s/${DEFAULTNAME_UPPERCASE_UND}/${NEWNAME_UPPERCASE_UND}/g"
  find . -type f -print0 | xargs -0 sed -i "s/${DEFAULTNAME_UPPERCASE_UND}/${NEWNAME_UPPERCASE_UND}/g"
  sed -i "1s/.*/# ${NEWNAME_ORIG}/" README.md
  sed -i "1s/.*/=== ${NEWNAME_ORIG} ===/" README.txt

}

##
# Enter various informations for the plugin header
# ------------------------------------------------
replace_plugin_header() {

  echo ""
  echo "[*] Replace plugin's name..."
  sed -i "s/${DEFAULTDIRNAME_SPA}/${NEWNAME_ORIG}/" "${NEWNAME}.php" && \
  echo "[+] Ok, done" || echo "[!] ERRORS replacing plugin's name in ${NEWNAME}.php"

  echo ""
  read -r -p "[?] Do you want to Fill plugin's header information? [y/N]" PLUGIN_HEADER
  if [[ $PLUGIN_HEADER =~ ^([yY][eE][sS]|[yY])$ ]]
  then

    #    - ask for the author's name
    echo ""
    read -r -p "[:] Please enter a name to use as author name: " AUTHOR_NAME
    if [[ -z "${AUTHOR_NAME}" ]]; then
      #  - keep asking for a name until provided
      while [[ "${AUTHOR_NAME}" == '' ]]; do
          read -p "[:] Please enter a name to use as author name, then press return: " AUTHOR_NAME
      done
    fi

    #    - ask for the author's URI
    echo ""
    read -r -p "[:] Please enter the author's URL: " AUTHOR_URI
    if [[ -z "${AUTHOR_URI}" ]]; then
      #  - keep asking for a name until provided
      while [[ "${AUTHOR_URI}" == '' ]]; do
          read -p "[:] Please enter the author's URL, then press return: " AUTHOR_URI
      done
    fi

    #    - ask for the plugin's URI
    echo ""
    read -r -p "[:] Please enter the plugin's URL: " PLUGIN_URI
    if [[ -z "${PLUGIN_URI}" ]]; then
      #  - keep asking for a name until provided
      while [[ "${PLUGIN_URI}" == '' ]]; do
          read -p "[:] Please enter the plugin's URL, then press return: " PLUGIN_URI
      done
    fi

    #    - ask for the plugin's URI
    echo ""
    read -r -p "[:] Please enter a short description for the plugin: " PLUGIN_DESC
    if [[ -z "${PLUGIN_DESC}" ]]; then
      #  - keep asking for a name until provided
      while [[ "${PLUGIN_DESC}" == '' ]]; do
          read -p "[:] Please enter the plugin's URL, then press return: " PLUGIN_DESC
      done
    fi

    sed -i "s/Author:            Your Name or Your Company/Author:            ${AUTHOR_NAME}/" "${NEWNAME}.php"
    sed -i "s#@link              http://example.com#@link              ${AUTHOR_URI}#" "${NEWNAME}.php"
    sed -i "s#Author URI:        http://example.com#Author URI:        ${AUTHOR_URI}#" "${NEWNAME}.php"
    sed -i "s#Plugin URI:        http://example.com/${NEWNAME}-uri#Plugin URI:        ${PLUGIN_URI}#" "${NEWNAME}.php"
    sed -i "s/Description:       This is a short description of what the plugin does. It's displayed in the WordPress admin area./Description:       ${PLUGIN_DESC}/" "${NEWNAME}.php"

    echo ""

  fi

}


# ---------------------------------------------------------------------
#     Runtime setup section: things to do to run the script
# ---------------------------------------------------------------------

##
# Run all previously declared functions.
#
# Each function gives a success or error message
#   depending from its exit status
# Comment out the functions you don't need to run
# -----------------------------------------------
main() {

  get_plugin_name
  plugins_folder_check
  name_search_replace
  confirm_replacements

  download_boilerplate && \
    echo '[+] OK, done! Boilerplate downloaded into proper folder.' || \
    echo -e "\n[!] ERRORS with Boilerplate download\n"
  rename_files && \
    echo '[+] OK, done! Files and folders properly renamed.' || \
    echo -e "\n[!] ERRORS with files and folders rename\n"
  replace_variables && \
    echo '[+] OK, done! Correctly replaced variables, functions, classes.' || \
    echo -e "\n[!] ERRORS replacing variables, functions, classes\n"

  replace_plugin_header && \
    echo "[+] OK, done! Plugin's header edited correctly." || \
    echo -e "\n[!] ERRORS while editing Plugin's headerinformations\n"

}

##
# Let's start the game...
# -----------------------
test_dependencies
# print_usage
# print_version
validate_arguments
main

sleep 1 && \
echo ''
echo '# ---------------------------------- #'
echo '#     Script execution complete!     #'
echo '# ---------------------------------- #'
echo ''
