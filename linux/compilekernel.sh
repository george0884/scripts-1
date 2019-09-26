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

name="Compile Kernel"
sources="/usr/src/linux/"
cores="$(cat /proc/cpuinfo | grep "cpu cores")"
cores="$((${cores:${#cores}-1:${#cores}}*2))"
# Colors in there order: Red, Green, Purple, Cyan and White.
colors=("\e[1;31m" "\e[1;32m" "\e[1;35m" "\e[1;36m" "\e[1;37m" "\e[0m")
banner="
  ____                      _ _        _  __                    _ 
 / ___|___  _ __ ___  _ __ (_) | ___  | |/ /___ _ __ _ __   ___| |
| |   / _ \| '_ \` _ \| '_ \| | |/ _ \ | ' // _ \ '__| '_ \ / _ \ |
| |__| (_) | | | | | | |_) | | |  __/ | . \  __/ |  | | | |  __/ |
 \____\___/|_| |_| |_| .__/|_|_|\___| |_|\_\___|_|  |_| |_|\___|_|
                     |_|                                          
"

function ShowBanner
{
        echo -e "${colors[2]}$banner${colors[5]}"
}

function GetHelp
{
        echo -e "${colors[2]}Opciones disponibles:${colors[4]}\n"
        echo -e "-h\tMuestra esta página de ayuda y sale."
        echo -e "-k\tAgrega soporte para LUKS al initramfs."
        echo -e "-l\tAgrega soporte para LVM al initramfs."
        echo -e "-p\tEspecifica la ruta de las fuentes. ${colors[0]}($sources por defecto.)${colors[4]}"
        echo -e "-t\tEspecifica qué cantidad de hilos utilizar"
        echo -e "\tpara la compilación ${colors[0]}($cores por defecto)${colors[5]}\n"
}

function Warning
{
        echo -e "${colors[0]}$name: $1: Sólo es necesario uno.${colors[5]}"
}

clear
ShowBanner

while getopts "hklt:" flag; do
        case "$flag" in
                h)
                        GetHelp
                        exit 0
                        ;;
                k)
                        if [ -z "$LUKS" ]; then
                                LUKS="--luks"
                        else
                                Warning "LUKS"
                        fi
                        ;;
                l)
                        if [ -z "$LVM" ]; then
                                LVM="--lvm"
                        else
                                Warning "LVM"
                        fi
                        ;;
                p)
                        if [ -d "$OPTARG" ]; then
                                if [ -x "$OPTARG" ]; then
                                        sources="$OPTARG"
                                else
                                        echo -e "${colors[0]}$name: No se puede acceder a: \"$OPTARG\".${colors[5]}\n"
                                        exit 1
                                fi
                        else
                                echo -e "${colors[0]}$name: El directorio: \"$OPTARG\" no existe.${colors[5]}\n"
                                exit 1
                        fi
                        ;;
                t)
                        echo "$OPTARG" | grep "[[:digit:]]" > /dev/null 2>&1
                        if [ $? -ne 0 ]; then
                                echo -e "${colors[0]}$name: La cantidad de hilos: \"$OPTARG\" no es válida.${colors[5]}\n"
                                exit 1
                        fi

                        threads=$OPTARG
                        if [ $threads -gt $cores ]; then
                                echo -e "${colors[0]}Ha decidido utilizar $threads hilos para la compilación."
                                echo "Sin embargo, su procesador sólo cuenta con $cores hilos."
                                echo -e "Se utilizarán los $cores hilos de su procesador.${colors[5]}"
                                threads=$cores
                        fi
                        ;;
                \?)
                        echo -e "${colors[0]}$name: Opción desconocida.${colors[5]}\n"
                        exit 1
                        ;;
        esac
done

if [ "${sources:${#sources}-1}:${#sources}" = "/" ]; then
        sources="${sources:${#sources}-1:${#sources}}"
fi

echo -en "${colors[1]}Trabando con las opciones: ${colors[2]}Hilos = $threads"
if [ -n "$LVM" ]; then
        echo -n "LVM = Sí, "
else
        echo -n "LVM = No, "
fi

if [ -n "$LUKS" ]; then
        echo -e "LUKS = Sí${colors[5]}\n"
else
        echo -e "LUKS = No${colors[5]}\n"
fi

echo -e "${colors[3]}Entrando en el directorio de las fuentes...${colors[5]}"
cd "$sources"
if [ $? -ne 0 ]; then
        echo -e "${colors[0]}$name: No se pudo acceder al directorio de las fuentes.${colors[5]}\n"
        exit 1
fi

echo -e "${colors[3]}\nBuscando archivo de configuración...${colors[5]}"
if [ ! -f "$sources/.config" ]; then
        echo -e "${colors[0]}$name: No se encontró archivo de configuración para compilar.${colors[5]}\n"
        exit 1
fi

echo -e "${colors[1]}Archivo de configuración encontrado.${colors[5]}"
echo -e "${colors[3]}\nVerificando estado de variable EXTRAVERSION...${colors[5]}"

value="$(grep "EXTRAVERSION = -gentoo" $sources/Makefile)"
if [[ -n "$value" && "$value" != "EXTRAVERSION = -brookie" ]]; then
        echo -e "${colors[3]}Cambiando valor de variable EXTRAVERSION...${colors[5]}"
        sed -i 's/EXTRAVERSION = -gentoo/EXTRAVERSION = -brookie/g' "$sources/Makefile"
fi

echo -e "${colors[3]}\nLa compilación iniciará en 5 segundos."
echo -e "Puede presionar (CTRL + C) para cancelar esto.${colors[5]}"
echo -en "${colors[0]}("
for ((i=5; i>=1; i--)); do
        if [ $i -gt 1 ]; then
                echo -ne "$i, "
        else
                echo -e "$i)${colors[5]}\n"
        fi
        sleep 1
done

make -j $threads
if [ $? -ne 0 ]; then
        echo -e "${colors[0]}$name: Ocurrió un error en la compilación.\n${colors[5]}"
        exit 1
fi

echo -e "${colors[1]}\nCompilación finalizada.${colors[5]}"
echo -e "${colors[3]}Instalando módulos...${colors[5]}\n"
make -j $threads modules_install
if [ $? -ne 0 ]; then
        echo -e "${colors[0]}$name: Ocurrió un error en la instalación de los módulos.\n${colors[5]}"
        exit 1
fi

echo -e "${colors[1]}\nMódulos instalados.${colors[5]}"
echo -e "${colors[3]}Instalando núcleo...${colors[5]}\n"
make -j $threads install
if [ $? -ne 0 ]; then
        echo -e "${colors[0]}$name: Ocurrió un error en la instalación del núcleo.\n${colors[5]}"
        exit 1
fi

echo -e "${colors[1]}\nNúcleo instalado.${colors[5]}"
echo -e "${colors[3]}(Re)Generando initramfs...${colors[5]}\n"
genkernel $LVM $LUKS --install initramfs
if [ $? -ne 0 ]; then
        echo -e "${colors[0]}$name: Ocurrió un error en la (re)generación del initramfs.\n${colors[5]}"
        exit 1
fi

echo -e "${colors[1]}\nInitramfs (re)generado.${colors[5]}"
echo -e "${colors[3]}(Re)Generando archivo de configuración de GRUB...\n${colors[5]}"
grub-mkconfig -o /boot/grub/grub.cfg
if [ $? -ne 0 ]; then
        echo -e "${colors[0]}$name: Ocurrió un error en la (re)generación del archivo"
        echo -e "de configuración de GRUB.\n${colors[5]}"
        exit 1
fi

echo -e "\n${colors[1]}¡Trabajo finalizado!${colors[5]}\n"
exit 0

