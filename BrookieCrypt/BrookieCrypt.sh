#!/bin/bash
# Copyright (C) 19aa Lord Brookie
# Este programa es software libre. Puede redistribuirlo y/o
# modificarlo bajo los términos de la Licencia Pública General
# de GNU según es publicada por la Free Software Foundation,
# bien de la versión 2 de dicha Licencia o bien --según su
# elección-- de cualquier versión posterior.
# Este programa se distribuye con la esperanza de que sea
# útil, pero SIN NINGUNA GARANTÍA, incluso sin la garantía
# MERCANTIL implícita o sin garantizar la CONVENIENCIA PARA UN
# PROPÓSITO PARTICULAR. Para más detalles, véase la Licencia
# Pública General de GNU.
# Debería haber recibido una copia de la Licencia Pública
# General junto con este programa. En caso contrario, escriba
# a la Free Software Foundation, Inc., en 675 Mass Ave,
# Cambridge, MA 02139, EEUU.

# Variables
name="BrookieCrypt"
# Colores: En este orden: Rojo, Verde, Naranja, Purpura, Cyan y Blanco.
colors=("\e[1;31m" "\e[1;32m" "\e[1;33m" "\e[1;35m" "\e[1;36m" "\e[1;37m" "\e[0m")
banner="
 ____                  _    _       ____                  _   
| __ ) _ __ ___   ___ | | _(_) ___ / ___|_ __ _   _ _ __ | |_ 
|  _ \| '__/ _ \ / _ \| |/ / |/ _ \ |   | '__| | | | '_ \| __|
| |_) | | | (_) | (_) |   <| |  __/ |___| |  | |_| | |_) | |_ 
|____/|_|  \___/ \___/|_|\_\_|\___|\____|_|   \__, | .__/ \__|
                                              |___/|_|        
"

function print_banner
{
        echo -e "${colors[3]}$banner"
}

function show_help
{
        echo -e "${colors[3]}Opciones disponibles:\n${colors[5]}"
        echo -e "-c\tCifra un archivo o directorio."
        echo -e "-d\tDescifra un archivo."
        echo -e "-f\tEspecifica el archivo a (des)cifrar."
        echo -e "-h\tMuestra esta página de ayuda y sale."
        echo -e "-v\tMuestra información sobre cada paso que realiza.\n${colors[6]}"
}

function warning
{
        echo -e "${colors[0]}$name: Confusión: $1: Sólo es necesario uno.${colors[6]}\n"
}

function confution
{
        echo -e "${colors[0]}$name: Ha decidio cifrar y descifrar a la vez. Sólo uno a la vez.${colors[6]}\n"
}

function error
{
        echo -e "${colors[0]}$name: Ocurrió un error en $1${colors[6]}\n"
}

clear
print_banner

while getopts "cdf:hv" opt; do
        case "$opt" in
                c)
                        if [ -z "$decrypt" ]; then
                                if [ -z "$crypt" ]; then
                                        crypt="yes"
                                else
                                        warning "Cifrado"
                                fi
                        else
                                confution
                                exit 1
                        fi
                        ;;
                d)
                        if [ -z "$crypt" ]; then
                                if [ -z "$decrypt" ]; then
                                        decrypt="yes"
                                else
                                        warning "Descifrado"
                                fi
                        else
                                confution
                                exit 1
                        fi
                        ;;
                f)
                        if [ -d "$OPTARG" ]; then
                                if [ -x "$OPTARG" ]; then
                                        file="$OPTARG"
                                        directory="yes"
                                else
                                        echo -e "${colors[0]}$name: No se puede acceder a: $OPTARG${colors[6]}\n"
                                        exit 1
                                fi
                        elif [ -f "$OPTARG" ]; then
                                file="$OPTARG"
                        else
                                echo -e "${colors[0]}$name: El archivo: \"$OPTARG\" no existe.${colors[6]}\n"
                                exit 1
                        fi
                        ;;
                h)
                        show_help
                        exit 0
                        ;;
                v)
                        if [ -z "$verbose" ]; then
                                verbose="yes"
                        else
                                warning "Modo verboso"
                        fi
                        ;;
                \?)
                        echo -e "Opción desconocida.\n"
                        exit 1
                        ;;
        esac
done

if [[ -z "$crypt" && -z "$decrypt" ]]; then
        echo -e "${colors[0]}$name: ¿Qué desea hacer? Puede utilizar la opción: -h para obtener ayuda.${colors[6]}\n"
        exit 1
fi

if [ -z "$file" ]; then
        echo -e "${colors[0]}$name: No especificó archivo a (des)cifrar.${colors[6]}\n"
        exit 1
fi

if [ "$crypt" = "yes" ]; then
        name_zip="$file.zip"

        if [ "$verbose" = "yes" ]; then
                echo -e "${colors[4]}Comprimiendo: ${colors[2]}\"$file\" ${colors[4]}...${colors[6]}"
        fi

        if [ -n "$directory" ]; then
                zip -erq9 "$name_zip" "$file"
        else
                zip -eq9 "$name_zip" "$file"
        fi

        if [ $? -ne 0 ]; then
                error "la compresión de: ${colors[2]}\"$file\""
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Compresión de: ${colors[2]}\"$file\" ${colors[1]}completada con éxito!${colors[6]}"
                echo -e "\n${colors[4]}Cifrando...${colors[6]}"
        fi

        name_gpg="$name_zip.gpg"
        gpg -o "$name_gpg" -c "$name_zip"
        if [ $? -ne 0 ]; then
                error "el cifrado de: $name_zip"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Cifrado finalizado!${colors[6]}"
                echo -e "\n${colors[4]}Creando suma de comprobación: sha256...${colors[6]}"
        fi

        sha256="$(sha256sum $name_gpg)"

        if [ $? -ne 0 ]; then
                error "la creación de la suma de comprobación sha256"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Suma de comprobación sha256 creada con éxito!${colors[6]}"
                echo -e "\n${colors[4]}Creando suma de comprobación: sha512...${colors[6]}"
        fi

        sha256="${sha256:0:64}"
        echo "$sha256" > "$name_gpg.sha256sum"

        sha512="$(sha512sum $name_gpg)"

        if [ $? -ne 0 ]; then
                error "la creación de la suma de comprobación sha512"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Suma de comprobación sha512 creada con éxito!${colors[6]}"
                echo -e "\n${colors[4]}Creando firma GPG...${colors[6]}"
        fi

        sha512="${sha512:0:128}"
        echo "$sha512" > "$name_gpg.sha512sum"

        gpg -o "$name_gpg.asc" -abq "$name_gpg"
        if [ $? -ne 0 ]; then
                error "la creación de la firma GPG"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Firma GPG creada con éxito!${colors[6]}"
        fi

        echo -e "\n${colors[4]}¡Trabajo finalizado!${colors[6]}\n"

elif [ "$decrypt" = "yes" ]; then
        if [ "$verbose" = "yes" ]; then
                echo -e "${colors[4]}Verificando suma de comprobación: sha256...${colors[6]}"
        fi

        sha256="$(cat "$file.sha256sum")"
        tmp="$(sha256sum "$file")"
        tmp="${sha256:0:64}"

        if [ "$sha256" != "$tmp" ]; then
                echo -e "${colors[0]}Las sumas de comprobación sha256 no coinciden. ¡Cuidado!${colors[6]}\n"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Suma de comprobación sha256 verificada!${colors[6]}"
                echo -e "\n${colors[4]}Verificando suma de comprobación: sha512...${colors[6]}"
        fi

        sha512="$(cat "$file.sha512sum")"
        tmp="$(sha512sum "$file")"
        tmp="${tmp:0:128}"

        if [ "$sha512" != "$tmp" ]; then
                echo -e "${colors[0]}Las sumas de comprobación sha512 no coincide. ¡Cuidado!${colors[6]}\n"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Suma de comprobación sha512 verificada!${colors[6]}"
                echo -e "\n${colors[4]}Verificando firma GPG...${colors[6]}"
        fi

        gpg --verify "$file.asc" "$file"

        if [ $? -ne 0 ]; then
                echo -e "${colors[0]}La firma GPG no coinciden. ¡Cuidado!${colors[6]}\n"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Firma GPG verificada!${colors[6]}"
                echo -e "\n${colors[4]}Descifrando...${colors[6]}"
        fi

        gpg -o "${file:0:${#file}-4}" -d "$file"

        if [ $? -ne 0 ]; then
                error "el descifrado de: \"$file\""
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Descifrado exitoso!${colors[6]}"
                echo -e "${colors[4]}Descomprimiendo...${colors[6]}"
        fi

        name_zip="${file:0:${#file}-4}"
        unzip -q "$name_zip"

        if [ $? -ne 0 ]; then
                error "la descompresión de: ${colors[3]}\"$name_zip\""
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "\n${colors[1]}¡Descompresión exitosa!${colors[6]}"
                echo -e "${colors[4]}¡Trabajo finalizado!${colors[6]}\n"
        fi
fi

