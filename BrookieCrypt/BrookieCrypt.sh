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
version="0.0.2"
github="https://github.com/brookiestein/scripts/tree/master/$name/"
gitlab="https://gitlab.com/LordBrookie/scripts/tree/master/$name/"
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
        echo -e "${colors[3]}$banner${colors[6]}"
}

function show_help
{
        echo -e "${colors[3]}Opciones disponibles:\n${colors[5]}"
        echo -e "-a\tVerifica una firma hash sha256. Ej: -a <archivo_con_firma> -f <archivo_firmado>"
        echo -e "-b\tVerifica una firma hash sha512. Ej: -b <archivo_con_firma> -f <archivo_firmado>"
        echo -e "-c\tCifra un archivo o directorio."
        echo -e "-d\tDescifra un archivo."
        echo -e "-f\tEspecifica el archivo o directorio a cifrar, descifrar o verificar firma hash. ${colors[0]}(Requerido)${colors[5]}"
        echo -e "-g\tVerifica una firma GPG. Ej: -g <archivo_con_firma> -f <archivo_firmado>"
        echo -e "-h\tMuestra esta página de ayuda y sale."
        echo -e "-i\tMuestra información sobre el programa y sale."
        echo -e "-v\tMuestra información sobre cada paso que realiza."
        echo -e "-y\tAsume que está de acuerdo con la eliminación del archivo fuente"
        echo -e "\tde cifrado o archivo comprimido (Dependiendo del caso).\n${colors[6]}"
}

function show_info
{
        echo -e "${colors[5]}$name es un programa encargado de comprimir un archivo o carpeta,"
        echo "cifrar el mismo, crear sumas de comprobación Sha256 y Sha512, además de una firma GPG "
        echo "del archivo cifrado, esto con el objetivo de verificar la integridad de los archivos "
        echo "posteriormente, si desea descifrarlo. Su uso es relativamente sencillo, consulte la"
        echo "opción -h para aprender sobre las opciones disponibles. $name se distribuye bajo los"
        echo -e "términos de la licencia pública general de GNU, en su versión 2 (GNU GPL v2).\n"
        echo -e "Nombre de software: $name\n"
        echo -e "Autor(es): Lord Brookie\n"
        echo -e "Versión: $version\n"
        echo -e "Licencia: GNU GPL v2\n"
        echo -e "Página(s) del proyecto:\n"
        echo "GitHub: $github"
        echo -e "GitLab: $gitlab${colors[6]}\n"
}

function warning
{
        echo -e "${colors[0]}$name: $1: Sólo es necesario uno.${colors[6]}\n"
}

function confution
{
        echo -e "${colors[0]}$name: $1${colors[6]}\n"
}

function error
{
        echo -e "${colors[0]}$name: Ocurrió un error en $1${colors[6]}\n"
}

function ask_agreement
{
        while true; do
                echo -ne "${colors[3]}$1"
                read -t 20 agreement
                if [ -z "$agreement" ]; then
                        agreement="yes"
                        break
                elif [[ "$agreement" != "s" && "$agreement" != "si" && "$agreement" != "y" &&
                        "$agreement" != "yes" && "$agreement" != "n" && "$agreement" != "no" ]]; then
                        echo -e "${colors[0]}La respuesta: \"$agreement\" no es válida."
                else
                        break
                fi
        done
}

# Espera 3 argumentos: 1) Nombre de archivo o carpeta; 2) Mensaje
# a imprimir en modo verboso; y, 3) Mensaje a imprimir en caso de error.
function destroy_files
{
        if [[ "$agreement" = "yes" || "$agreement" = "y" || "$agreement" = "s" || "$agreement" = "si" ]]; then
                if [ "$verbose" = "yes" ]; then
                        echo -e "\n${colors[4]}Destruyendo $2 ...${colors[6]}"
                fi

                if [[ "$directory" = "yes" && "$2" != "Archivo comprimido" ]]; then
                        find "$1" -type f -exec shred -zu file '{}' \; 2> /dev/null
                        rm -rf "$1"
                else
                        shred -zu "$1"
                fi

                if [ $? -ne 0 ]; then
                        error "$3"
                        exit 1
                elif [ "$verbose" = "yes" ]; then
                        echo -e "${colors[1]}¡$2 destruido(s) con éxito!${colors[6]}"
                fi
        fi

        if [ -z "$argument" ]; then
                unset agreement
        fi
}

# Primer parámetro: Archivo a verificar
# Segundo parámetro: Algoritmo a verificar para escribir un mensaje es caso de error.
function checks
{
        check="$(file "$1")"
        #check="${check:24:5}"
	check="${check:$((${#1}+2)):5}"

        if [ "$check" != "ASCII" ]; then
                echo -e "${colors[0]}$name: El archivo indicado para la suma de comprobación $2 no es válido.${colors[6]}\n"
                exit 1
        fi
}

function verify_sha256
{
        if [[ "$verbose" = "yes" || "$arg" = "yes" ]]; then
                echo -e "${colors[4]}Verificando suma de comprobación: sha256...${colors[6]}"
        fi

        checks "$1" "sha256"

        sha256="$(cat "$1")"
        tmp="$(sha256sum "$2")"
        tmp="${tmp:0:64}"

        if [ "$sha256" != "$tmp" ]; then
                echo -e "${colors[0]}Las sumas de comprobación sha256 no coinciden. ¡Cuidado!${colors[6]}\n"
                exit 1
        elif [[ "$verbose" = "yes" || "$arg" = "yes" ]]; then
                echo -e "${colors[1]}¡Suma de comprobación sha256 verificada!${colors[6]}\n"
        fi
}

function verify_sha512
{
        if [[ "$verbose" = "yes" || "$arg" = "yes" ]]; then
                echo -e "${colors[4]}Verificando suma de comprobación: sha512...${colors[6]}"
        fi

        checks "$1" "sha512"

        sha512="$(cat "$1")"
        tmp="$(sha512sum "$2")"
        tmp="${tmp:0:128}"

        if [ "$sha512" != "$tmp" ]; then
                echo -e "${colors[0]}Las sumas de comprobación sha512 no coincide. ¡Cuidado!${colors[6]}\n"
                exit 1
        elif [[ "$verbose" = "yes" || "$arg" = "yes" ]]; then
                echo -e "${colors[1]}¡Suma de comprobación sha512 verificada!${colors[6]}\n"
        fi
}

# Primer parámetro: Archivo con la firma.
# Segundo parámetro: Archivo firmado.
function verify_gpg
{
        if [[ "$verbose" = "yes" || "$arg" = "yes" ]]; then
                echo -e "${colors[4]}Verificando firma GPG...${colors[6]}"
        fi

        gpg --verify "$1" "$2"

        if [ $? -ne 0 ]; then
                echo -e "${colors[0]}La firma GPG no coinciden. ¡Cuidado!${colors[6]}\n"
                exit 1
        elif [[ "$verbose" = "yes" || "$arg" = "yes" ]]; then
                echo -e "${colors[1]}¡Firma GPG verificada!${colors[6]}\n"
        fi
}

clear
print_banner

while getopts "a:b:cdf:g:hivy" opt; do
        case "$opt" in
                a)
                        if [ -z "$hash256" ]; then
                                if [[ -n "$decrypt" || -n "$crypt" ]]; then
                                        confution "Ha decidido descifrar y verificar firma hash sha256. Sólo puede utilizar uno a la vez."
                                        exit 1
                                fi

                                if [ -f "$OPTARG" ]; then
                                        file256="$OPTARG"
                                else
                                        echo -e "${colors[0]}$name: El archivo ${colors[2]}[$OPTARG]${colors[0]} no existe.${colors[6]}\n"
                                        exit 1
                                fi
                                hash256="yes"
                                arg="yes"
                        else
                                warning "Verificación de firma hash sha256"
                        fi
                        ;;
                b)
                        if [ -z "$hash512" ]; then
                                if [[ -n "$decrypt" || -n "$crypt" ]]; then
                                        confution "Ha decidido descifrar y verificar firma hash sha512. Sólo puede utilizar uno a la vez."
                                        exit 1
                                fi

                                if [ -f "$OPTARG" ]; then
                                        file512="$OPTARG"
                                else
                                        echo -e "${colors[0]}$name: El archivo ${colors[2]}[$OPTARG]${colors[0]} no existe.${colors[6]}\n"
                                        exit 1
                                fi
                                hash512="yes"
                                arg="yes"
                        else
                                warning "Verificación de firma hash sha512"
                        fi
                        ;;
                c)
                        if [ -z "$decrypt" ]; then
                                if [ -n "$crypt" ]; then
                                        warning "Cifrado"
                                else
                                        if [[ -n "$hash256" || -n "$hash512" ]]; then
                                                confution "Ha decidido cifrar y verificar firma hash. Sólo puede utilizar uno."
                                                exit 1
                                        fi
                                        crypt="yes"
                                fi
                        else
                                confution "Ha decido cifrar y descifrar a la vez. Sólo puede utilizar uno."
                                exit 1
                        fi
                        ;;
                d)
                        if [ -z "$crypt" ]; then
                                if [ -n "$decrypt" ]; then
                                        warning "Descifrado"
                                else
                                        if [[ -n "$hash256" || -n "$hash512" ]]; then
                                                confution "Ha decidido descifrar y verificar firma hash a la vez. Sólo puede utilizar uno."
                                                exit 1
                                        fi
                                        decrypt="yes"
                                fi
                        else
                                confution "Ha decidido cifrar y descifrar a la vez. Sólo puede utilizar uno."
                                exit 1
                        fi
                        ;;
                f)
                        if [ -d "$OPTARG" ]; then
                                if [ -x "$OPTARG" ]; then
                                        file="$OPTARG"
                                        if [ "${file:${#file}-1:${#file}}" = "/" ]; then
                                                file="${file:0:${#file}-1}"
                                        fi
                                        directory="yes"
                                else
                                        echo -e "${colors[0]}$name: No se puede acceder a: ${colors[2]}[$OPTARG]${colors[6]}\n"
                                        exit 1
                                fi
                        elif [ -f "$OPTARG" ]; then
                                file="$OPTARG"
                        else
                                echo -e "${colors[0]}$name: El archivo: ${colors[2]}[$OPTARG]${colors[0]} no existe.${colors[6]}\n"
                                exit 1
                        fi
                        ;;
                g)
                        if [ -z "$sig_gpg" ]; then
                                if [[ -n "$decrypt" || -n "$crypt" ]]; then
                                        confution "Ha decidido descifrar y verificar firma hash sha256. Sólo puede utilizar uno a la vez."
                                        exit 1
                                fi

                                if [ -f "$OPTARG" ]; then
                                        filegpg="$OPTARG"
                                else
                                        echo -e "${colors[0]}$name: El archivo ${colors[2]}[$OPTARG]${colors[0]} no existe.${colors[6]}\n"
                                        exit 1
                                fi
                                sig_gpg="yes"
                                arg="yes"
                        else
                                warning "Verificación de firma GPG"
                        fi
                        ;;
                h)
                        show_help
                        exit 0
                        ;;
                i)
                        show_info
                        exit 0
                        ;;
                v)
                        if [ -z "$verbose" ]; then
                                verbose="yes"
                        else
                                warning "Modo verboso"
                        fi
                        ;;
                y)
                        if [ -z "$agreement" ]; then
                                agreement="yes"
                                argument="yes"
                        else
                                warning "Eliminación de archivo fuente"
                        fi
                        ;;
                \?)
                        echo -e "${colors[0]}Opción desconocida.${colors[6]}\n"
                        exit 1
                        ;;
        esac
done

if [[ -z "$crypt" && -z "$decrypt" && -z "$hash256" && -z "$hash512" && -z "$sig_gpg" ]]; then
        echo -e "${colors[0]}$name: ¿Qué desea hacer? Puede utilizar la opción: -h para obtener ayuda.${colors[6]}\n"
        exit 1
fi

if [ -z "$file" ]; then
        echo -e "${colors[0]}$name: No especificó archivo o directorio a cifrar, descifrar o verificar firma hash.${colors[6]}\n"
        exit 1
fi

if [ "$hash256" = "yes" ]; then
        verify_sha256 "$file256" "$file"
fi

if [ "$hash512" = "yes" ]; then
        verify_sha512 "$file512" "$file"
fi

if [ "$sig_gpg" = "yes" ]; then
        verify_gpg "$filegpg" "$file"
fi

if [ "$crypt" = "yes" ]; then
        name_zip="$file.zip"

        if [ "$verbose" = "yes" ]; then
                echo -e "${colors[4]}Comprimiendo: ${colors[2]}[$file] ${colors[4]}...${colors[6]}"
        fi

        if [ -n "$directory" ]; then
                zip -erq9 "$name_zip" "$file"
        else
                zip -eq9 "$name_zip" "$file"
        fi

        if [ $? -ne 0 ]; then
                error "la compresión de: ${colors[2]}[$file]"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Compresión de: ${colors[2]}[$file] ${colors[1]}completada con éxito!${colors[6]}"
                echo -e "\n${colors[4]}Cifrando...${colors[6]}"
        fi

        name_gpg="$name_zip.gpg"
        gpg -o "$name_gpg" -c "$name_zip"
        if [ $? -ne 0 ]; then
                error "el cifrado de: [$name_zip]"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Cifrado finalizado!${colors[6]}"
                echo -e "\n${colors[4]}Creando suma de comprobación: sha256...${colors[6]}"
        fi

        sha256="$(sha256sum $name_gpg)"

        if [ $? -ne 0 ]; then
                error "la creación de la suma de comprobación sha256"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Suma de comprobación sha256 creada con éxito!${colors[6]}"
                echo -e "\n${colors[4]}Creando suma de comprobación: sha512...${colors[6]}"
        fi

        sha256="${sha256:0:64}"
        echo "$sha256" > "$name_gpg.sha256sum"

        sha512="$(sha512sum $name_gpg)"

        if [ $? -ne 0 ]; then
                error "la creación de la suma de comprobación sha512"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Suma de comprobación sha512 creada con éxito!${colors[6]}"
                echo -e "\n${colors[4]}Creando firma GPG...${colors[6]}"
        fi

        sha512="${sha512:0:128}"
        echo "$sha512" > "$name_gpg.sha512sum"

        gpg -o "$name_gpg.asc" -abq "$name_gpg"
        if [ $? -ne 0 ]; then
                error "la creación de la firma GPG"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Firma GPG creada con éxito!${colors[6]}"
        fi


        if [ -z "$agreement" ]; then
                ask_agreement "\n¿Desea eliminar el archivo comprimido? [S/n] (Sí por defecto): "
        fi

        destroy_files "$name_zip" "Archivo(s) comprimido" "la destrucción de (los) archivo(s) comprimido."

        if [ -z "$agreement" ]; then
                ask_agreement "\n¿Desea eliminar el(los) archivo(s) fuente de cifrado? [S/n] (Sí por defecto): "
        fi

        destroy_files "$file" "Archivo(s) fuente de cifrado" "la destrucción del(los) archivo(s) fuente de cifrado."

        echo -e "\n${colors[4]}¡Trabajo finalizado!${colors[6]}\n"

elif [ "$decrypt" = "yes" ]; then
        verify_sha256 "$file"
        verify_sha512 "$file"
        verify_gpg "$file.asc" "$file"

        echo -e "\n${colors[4]}Descifrando...${colors[6]}"
        gpg -o "${file:0:${#file}-4}" -d "$file"

        if [ $? -ne 0 ]; then
                error "el descifrado de: ${colors[2]}[$file]"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Descifrado exitoso!${colors[6]}"
                echo -e "\n${colors[4]}Descomprimiendo...${colors[6]}"
        fi

        name_zip="${file:0:${#file}-4}"
        unzip -q "$name_zip"

        if [ $? -ne 0 ]; then
                error "la descompresión de: ${colors[2]}[$name_zip]"
                exit 1
        elif [ "$verbose" = "yes" ]; then
                echo -e "${colors[1]}¡Descompresión exitosa!${colors[6]}"
        fi

        if [ -z "$agreement" ]; then
                ask_agreement
        fi

        destroy_files "$name_zip" "Archivo(s) comprimido" "la destrucción del(los) archivo(s) comprimido(s)"

        echo -e "\n${colors[4]}¡Trabajo finalizado!${colors[6]}\n"
fi

exit 0
