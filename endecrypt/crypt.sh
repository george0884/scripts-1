#!/bin/bash

function help()
{
        clear
        echo "Uso: El uso de este software es realmente sencillo. Sólo debe suministrar"
        echo "el nombre del archivo que desea cifrar y el nombre que desea, tengan los"
        echo "archivos finales. Los archivos se cifrarán con la técnica de cifrado simétrico"
        echo "y se crearán distintos archivos con sumas de comprobación para verificar la"
        echo "integridad de el archivo cifrado. Los algoritmos que se utilizarán son:"
        echo "Sha512, Sha256, MD5 y Firmado GPG."; echo
}

if [ $# -eq 0 ]; then
        echo; echo "Nada por hacer. Utilice: ./program.sh -h[--help] si desea información."
        echo; exit 0
elif [[ "$1" = "-h" || "$1" = "--help" ]]; then
        help
        exit 0
elif [[ -f "$1" ]]; then
        file="$1"
else
        echo; echo -n "Error: "
        if [ $# -eq 1 ]; then
                echo "La opción $1 no es válida."
        else
                echo "Las opciones $@ no son válidas."
        fi
        echo
        exit 1
fi

if [ -z $file ]; then
        read -p "Introduzca el nombre del archivo a cifrar: " file
        while [ ! -f "$name" ]; do
                echo; echo "El archivo indicado no existe."
                read -p "Introduzca un nombre de archivo a cifrar válido: " file
        done
fi

read -p "Introduzca el nombre que tendrán los archivos finales ($file por defecto): " name_final
if [ -z "$name_final" ]; then
        name_final=$file
fi

name_final+=".gpg"
name_dir="Product"

if [[ -d "$name_dir" ]]; then
        echo; echo "El directorio de salida ya existe. Utilizándolo..."
        sleep 1
elif [[ -f "$name_dir" ]]; then
        name_dir+="-dir"
        mkdir "$name_dir"
else
        mkdir "$name_dir"
fi

if [ $? -eq 0 ]; then
        cd "$name_dir"
        if [ $? -ne 0 ]; then
                echo; echo "Ha ocurrido un error al entrar al directorio de salida."
                echo; exit 1
        else
                cp "../$file" "$file"
                if [ $? -ne 0 ]; then
                        echo; echo "Ha ocurrido un error al crear copia de archivo."
                        echo; exit 1
                fi
        fi
else
        echo; echo "Ha ocurrido un error al crear el directorio de salida."
        echo; exit 1
fi

echo; echo "Cifrando archivo..."; echo
sleep 1
gpg -o $name_final --symmetric $file
if [ $? -eq 0 ]; then
        echo "Cifrado de archivo finalizado."
        echo "Creando suma de comprobación: sha256...";
        sleep 1
        tmp="$(sha256sum $name_final)"
        echo "${tmp:0:64}" > $name_final.sha256sum
        if [ $? -eq 0 ]; then
                echo; echo "Suma de comprobación: sha256 creada con éxito."
                echo "Creando suma de comprobación: sha512..."
                sleep 1
                tmp="$(sha512sum $name_final)"
                echo "${tmp:0:128}" > $name_final.sha512sum
                if [ $? -eq 0 ]; then
                        echo; echo "Suma de comprobración: sha512 creada con éxito."
                        echo "Creando suma de comprobación: MD5..."
                        sleep 1
                        tmp="$(md5sum $name_final)"
                        echo "${tmp:0:32}" > $name_final.md5sum
                        if [ $? -eq 0 ]; then
                                echo; echo "Suma de comprobación: md5 creada con éxito."
                                echo "Creando firma GPG..."
                                sleep 1
                                gpg -o $name_final.sig -abq $name_final
                                if [ $? -eq 0 ]; then
                                        echo; echo "Todos los trabajos han sido finalizados con éxito."; echo
                                else
                                        echo; echo "Ha ocurrido un error al crear las firmas GPG."; echo
                                fi
                        else
                                echo; echo "Ha ocurrido un error al crear la suma de comprobación MD5."; echo
                        fi
                else
                        echo; echo "Ha ocurrido un error al crear la suma de comprobación sha512."; echo
                fi
        else
                echo; echo "Ha ocurrido un error al crear la suma de comprobación sha256."; echo
        fi
else
        echo; echo "Ha ocurrido un error al cifrar el archivo."; echo
fi

if [ -f $file ]; then
        rm "$file"
fi

