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

name="BrookieCrypt"
banner="
 ____                  _    _       ____                  _   
| __ ) _ __ ___   ___ | | _(_) ___ / ___|_ __ _   _ _ __ | |_ 
|  _ \\| '__/ _ \\ / _ \\| |/ / |/ _ \\ |   | '__| | | | '_ \\| __|
| |_) | | | (_) | (_) |   <| |  __/ |___| |  | |_| | |_) | |_ 
|____/|_|  \\___/ \\___/|_|\\_\\_|\\___|\\____|_|   \\__, | .__/ \\__|
                                              |___/|_|        
"

function print_banner()
{
        echo "$banner"
}

clear
print_banner

function min_info()
{
        echo "$name es un programa que (utiliza GPG y) se encarga de (des)cifrar un archivo,"
        echo "guardar su firma hash (sha256 y sha512) y su firma GPG."
}

function get_help()
{
        min_info
        echo -e "\nOpciones disponibles:\n"
        echo -e "-a\t\tMuestra más información sobre este programa y sale."
        echo -e "-c\t\tCifra un archivo."
        echo -e "-d\t\tDescifra un archivo."
        echo -e "-h\t\tMuestra esta página de ayuda y sale."
        echo -e "-f <archivo>\tArchivo a (des)cifrar. (Requerido)"
        echo -e "-p <ruta>\tAlmacena/lee todos los archivos de salida/entrada a/desde la ruta especificada."
        echo -e "-v\t\tModo verboso (Muestra información sobre los pasos que realiza).\n"
}

function get_info()
{
        min_info
        echo -e "\nNombre: $name\n"
        echo -e "Versión: 0.0.1\n"
        echo -e "Licencia: GNU GPL v2\n"
        echo -e "Autor(es): Lord Brookie\n"
        echo -e "Repositorio(s) del programa:"
        echo -e "GitHub: https://github.com/brookiestein/scripts/$name/"
        echo -e "GitLab: https://gitlab.com/LordBrookie/scripts/$name/\n"
}

function warning_confution()
{
        echo -e "\n$name: Confusión: Ha decidido cifrar y descifrar"
        echo -e "al mismo tiempo. Sólo puede utilizar uno.\n"
}

if [ $# -eq 0 ]; then
        get_help
        exit 0
fi

while getopts "f:p:acdhv" flags; do
        case "$flags" in
                a)
                        get_info
                        exit 0
                        ;;
                c)
                        if [ -z "$decrypt" ]; then
                                crypt="yes"
                        else
                                warning_confution
                                exit 1
                        fi
                        ;;
                d)
                        if [ -z "$crypt" ]; then
                                decrypt="yes"
                        else
                                warning_confution
                                exit 1
                        fi
                        ;;
                h)
                        get_help
                        exit 0
                        ;;
                f)
                        if [ -f "$OPTARG" ]; then
                                file="$OPTARG"
                        else
                                echo -e "\n$name: Error: El archivo especificado no existe.\n"
                                exit 1
                        fi
                        ;;
                p)
                        if [ -d "$OPTARG" ]; then
                                path="$OPTARG"
                        else
                                echo -e "\n$name: Error: La ruta especificada no es válida.\n"
                                exit 1
                        fi
                        ;;
                v)
                        if [ -z "$verbose" ]; then
                                if [ -z "$quiet" ]; then
                                        verbose="yes"
                                else
                                        echo -e "\n$name: Modo quieto habilitado. No se puede habilitar"
                                        echo -e "el modo verboso.\n"
                                fi
                        else
                                echo -e "\n$name: Modo verboso sólo es necesario uno. Ignorando los demás...\n"
                        fi
                        ;;
                \?)
                        echo -e "\n$name: Opción desconocida.\n"
                        exit 1
                        ;;
        esac
done

if [ -z "$file" ]; then
        echo -e "$name: Archivo a (des)cifrar no especificado.\n"
        exit 1
fi

if [[ -n "$path" && "${path:${#path}-1:${#path}}" != "/" ]]; then
        path+="/"
fi

if [ -n "$crypt" ]; then
        name_final="$file.gpg"

        if [ "$verbose" = "yes" ]; then
                echo -e "\nCifrando: $file ..."
        fi

        sleep 2

        if [ -n "$path" ]; then
                gpg -o "$path$name_final" -c "$file"
        else
                gpg -o "$name_final" -c "$file"
        fi

        if [ $? -eq 0 ]; then
                if [ "$verbose" = "yes" ]; then
                        echo -e "\nCifrado finalizado. Creando firma hash sha256..."
                fi
                sleep 2

                if [ -n "$path" ]; then
                        sha256="$(sha256sum $path$name_final)"
                else
                        sha256="$(sha256sum $name_final)"
                fi

                sha256="${sha256:0:64}"

                if [ -n "$path" ]; then
                        echo "$sha256" > "$path$name_final.sha256sum"
                else
                        echo "$sha256" > "$name_final.sha256sum"
                fi

                if [ "$verbose" = "yes" ]; then
                        echo -e "\nFirma hash sha256 creada con éxito. Creando firma sha512..."
                fi
                sleep 2

                if [ -n "$path" ]; then
                        sha512="$(sha512sum $path$name_final)"
                else
                        sha512="$(sha512sum $name_final)"
                fi

                sha512="${sha512:0:128}"

                if [ -n "$path" ]; then
                        echo "$sha512" > "$path$name_final.sha512sum"
                else
                        echo "$sha512" > "$name_final.sha512sum"
                fi

                if [ "$verbose" = "yes" ]; then
                        echo -e "\nFirma hash sha512 creada con éxito. Creando firma GPG..."
                fi
                sleep 2

                if [ -n "$path" ]; then
                        gpg -o "$path$name_final.asc" -abq "$path$name_final"
                else
                        gpg -o "$name_final.asc" -abq "$name_final"
                fi

                if [ $? -eq 0 ]; then
                        if [ "$verbose" = "yes" ]; then
                                echo -e "\nFirma GPG creada con éxito."
                        fi
                else
                        echo -e "\n$name: Ocurrió un error en la creación de la firma GPG.\n"
                        exit 1
                fi
        else
                echo -e "\n$name: Ocurrió un error en el cifrado de: $file\n"
                exit 1
        fi
else
        if [ "$verbose" = "yes" ]; then
                echo "Verificando firma hash sha256..."
        fi
        sleep 2

        sha256="$(sha256sum $file)"
        sha256="${sha256:0:64}"
        sha512="$(sha512sum $file)"
        sha512="${sha512:0:128}"
        sleep 2

        if [ -f "$file.sha256sum" ]; then
                tmp_hash="$(cat $file.sha256sum)"
                if [ "$tmp_hash" = "$sha256" ]; then
                        if [ "$verbose" = "yes" ]; then
                                echo -e "\n¡Firma hash sha256 verificada!"
                                echo "Verificando firma hash sha512..."
                        fi
                        sleep 2

                        if [ -f "$file.sha512sum" ]; then
                                tmp_hash="$(cat $file.sha512sum)"
                                if [ "$tmp_hash" = "$sha512" ]; then
                                        if [ "$verbose" = "yes" ]; then
                                                echo -e "\n¡Firma hash sha512 verificada!"
                                                echo "Verificando firma GPG..."
                                        fi
                                        sleep 2

                                        if [ -f "$file.asc" ]; then
                                                gpg --verify "$file.asc" "$file"
                                                if [ $? -eq 0 ]; then
                                                        if [ "$verbose" = "yes" ]; then
                                                                echo -e "\n¡Firma GPG verificada! Descifrando..."
                                                        fi
                                                        sleep 2

                                                        if [ -n "$path" ]; then
                                                                gpg -o "$path${file:0:${#file}-4}" -d "$file"
                                                        else
                                                                gpg -o "${file:0:${#file}-4}" -d "$file"
                                                        fi

                                                        if [ $? -eq 0 ]; then
                                                                if [ "$verbose" = "yes" ]; then
                                                                        echo -en "\n¡Archivo descifrado!"
                                                                fi
                                                        else
                                                                echo -e "\n$name: Ocurrió un error en el descifrado de: $file\n"
                                                                exit 1
                                                        fi
                                                else
                                                        echo -e "\n$name: La firma GPG no es válida. ¡Cuidado!\n"
                                                        exit 1
                                                fi
                                        else
                                                echo -e "\n$name: Error: El archivo: $file.asc no existe."
                                                echo -e "No se podrá continuar.\n"
                                                exit 1
                                        fi
                                else
                                        echo -e "\n$name: Las firmas hash sha512 son distintas. ¡Cuidado!\n"
                                        exit 1
                                fi
                        else
                                echo -e "\n$name: Error: El archivo: $file.sha512 no existe."
                                echo -e "No se podrá continuar.\n"
                                exit 1
                        fi
                else
                        echo -e "\n$name: Las firmas hash sha256 son distintas. ¡Cuidado!\n"
                        exit 1
                fi
        else
                echo -e "\n$name: Error: El archivo: $file.sha256sum no existe."
                echo -e "No se podrá continuar.\n"
                exit 1
        fi
fi

echo -e "\n¡Trabajo finalizado!\n"
exit 0

