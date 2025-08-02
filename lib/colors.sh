#!/bin/bash

# Módulo de cores e formatação de texto
# Este arquivo contém as definições de cores e tags coloridas

# Definição de cores para saída
export RED='\033[31m'
export YELLOW='\033[33m'
export GREEN='\033[32m'
export BLUE='\033[34m'
export MAGENTA='\033[35m'
export CYAN='\033[36m'
export WHITE='\033[37m'
export RESET='\033[0m'

# Tags coloridas para uso em mensagens
export ERRO_TAG="${RED}[ERRO]${RESET}"
export AVISO_TAG="${YELLOW}[AVISO]${RESET}"
export SUCESSO_TAG="${GREEN}[SUCESSO]${RESET}"
export INFO_TAG="${BLUE}[INFO]${RESET}"
export DEBUG_TAG="${CYAN}[DEBUG]${RESET}"
