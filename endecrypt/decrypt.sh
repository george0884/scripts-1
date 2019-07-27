#!/bin/bash
# Script para verificar sumas de comprobación.

clear
function help()
{
        echo "Este script funciona bien si la estructura de sus archivos es de la siguiente forma:"
        echo "El archivo inicial tiene un nombre. Las firmas o sumas de comprobación tienen el mismo"
        echo "nombre que el archivo con la excepción de que estas terminan con extensión nombrada igual"
        echo "que su algoritmo. Dos ejemplos: file.gpg (Archivo original cifrado). file.gpg.sha512sum"
        echo "(Archivo con la suma de comprobación de file.gpg utilizando el algoritmo sha512sum)."
        echo "Una vez aclarado esto y si tiene la estructura de sus archivos así, puede continuar"
        echo "en caso contrario, se recomienda dejar una estructura igual a esa, de no ser así, este"
        echo "script no tendría utilidad. Nota: Este script comprueba: sha256, sha512, md5 y firma GPG."; echo
}

if [ -f "$1" ]; then
        name="$1"
elif [ -d "$1" ]; then
        echo; echo "El archivo indicado no es válido."; echo; exit 1
elif [[ "$1" = "-h" || "$1" = "--help" ]]; then
        help
        exit 0
else
        echo; echo "Las opciones \"$@\" son innecesarias, no se tomarán en cuenta."
        echo; sleep 1
fi

if [ -z "$name" ]; then
        read -p "Introduzca el nombre del archivo: " name
        while [ ! -f "$name" ]; do
                if [ -d "$name" ]; then
                        echo; echo "Lo que ha indicado es un directorio. Por favor,"
                        echo "introduzca un nombre de archivo válido."
                else
                        echo; echo "El archivo $name no existe. Por favor, introduzca un archivo existente."
                fi
                read -p "Introduzca el nombre del archivo: " name
        done
fi

# Verify sha256
echo; echo "Verificando suma de comprobación: sha256, por favor, espere..."
sleep 1
if [ -f "$name.sha256sum" ]; then
        sum1="$(cat "$name.sha256sum")"
        tmp="$(sha256sum "$name")"
        sum2="${tmp:0:64}"
        unset tmp
        if [ "$sum1" = "$sum2" ]; then
                echo; echo "¡Sha256 verificado! Coincidente."
                # Verify sha512
                echo; echo "Verificando suma de comprobación: sha512, por favor, espere..."
                sleep 1
                if [ -f "$name.sha512sum" ]; then
                        sum1="$(cat "$name.sha512sum")"
                        tmp="$(sha512sum "$name")"
                        sum2="${tmp:0:128}"
                        unset tmp
                        if [ "$sum1" = "$sum2" ]; then
                                echo; echo "¡Sha512 verificado! Coincidente."
                                # Verify MD5sum
                                echo; echo "Verificando suma de comprobación: md5, por favor, espere..."
                                sleep 1
                                if [ -f "$name.md5sum" ]; then
                                        sum1="$(cat "$name.md5sum")"
                                        tmp="$(md5sum "$name")"
                                        sum2="${tmp:0:32}"
                                        unset tmp
                                        if [ "$sum1" = "$sum2" ]; then
                                                echo; echo "¡MD5 verificado! Coincidente."
                                                unset sum1; unset sum2
                                                # Verify GPG Sig
                                                echo; echo "Verificando firma GPG, por favor, espere..."
                                                sleep 1
                                                if [ -f "$name.sig" ]; then
                                                        gpg --verify "$name.sig" "$name"
                                                        if [ $? = '0' ]; then
                                                                echo; echo "¡Firma GPG verificada! Coincidente."
                                                                echo "Parece que los archivos no ha sido modificados.";
                                                                read -p "¿Desea descrifrar el archivo? [S/n]: " ask
                                                                while [[ "$ask" != "s" && "$ask" != "si" && "$ask" != "n" && "$ask" != "no" ]]; do
                                                                        echo; echo "La respuesta $ask no es válida."
                                                                        read -p "¿Desea descrifrar el archivo? [S/n]: " ask
                                                                done

                                                                if [ "$ask" = "s" ]; then
                                                                        echo; echo "Descifrando archivo, por favor espere..."
                                                                        sleep 1
                                                                        gpg -o "$name-decrypt" -d "$name"
                                                                        if [ $? -eq 0 ]; then
                                                                                echo; echo "El archivo ha sido descrifrado."; echo
                                                                        else
                                                                                echo; echo "Ha ocurrido un error al descrifrar el archivo."
                                                                                echo
                                                                        fi
                                                                else
                                                                        echo; echo "¡Adiós!"; echo
                                                                fi
                                                        else
                                                                echo; echo "Ha ocurrido un error al verificar la firma GPG. ¡Cuidado!"; echo
                                                        fi
                                                else
                                                        echo; echo "El archivo $name.sig no existe. No se pudo comprobar la integridad."; echo
                                                fi
                                        else
                                                echo; echo "Ha ocurrido un error al verificar la suma de comprobación: MD5. ¡Cuidado!"; echo
                                        fi
                                else
                                        echo; echo "El archivo $name.md5sum no existe. No se pudo comprobar la integridad."; echo
                                fi
                        else
                                echo; echo "Ha ocurrido un error al verificar la suma de comprobación: Sha512. ¡Cuidado!"; echo
                        fi
                else
                        echo; echo "El archivo $name.sha512sum no existe. No se pudo comprobar la integridad."; echo
                fi
        else
                echo; echo "Ha ocurrido un error al verificar la suma de comprobación: Sha256. ¡Cuidado!"; echo
        fi
else
        echo; echo "El archivo $name.sha256sum no existe. No se pudo comprobar la integridad."; echo
fi

