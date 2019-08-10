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
sources="/usr/src/linux"
name="BrooCompile"
# Hilos
cores=$(cat /proc/cpuinfo | grep "cpu cores")
cores=${cores:${#cores}-1:${#cores}}
cores=$((cores*2))
# Colors: In there order: White, Red, Green, Cyan
colors=("1;37m" "1;31m" "1;32m" "1;36m")
# Banner's
vBanner="
   ____                   ______                      _ __
   / __ )_________  ____  / ____/___  ____ ___  ____  (_) /__
  / __  / ___/ __ \\/ __ \\/ /   / __ \\/ __ \`__ \\/ __ \\/ / / _ \ 
 / /_/ / /  / /_/ / /_/ / /___/ /_/ / / / / / / /_/ / / /  __/
/_____/_/   \\____/\\____/\\____/\\____/_/ /_/ /_/ .___/_/_/\\___/ 
                                            /_/
"

function banner()
{
        echo -e "\e[${colors[2]}$vBanner"
}

clear
banner

function warning()
{
        echo -e "\e[${colors[1]}$name: La cantidad de hilos que ha decidido utilizar es $threads, sin embargo su"
        echo "procesador solo cuenta con $cores hilos. Esta configuracion no se recomienda."
}

function warning_ignore()
{
        echo -e "\n\e[${colors[1]}$name: $1: Sólo uno es necesario. Ignorando los demás...\n"
}

function get_help()
{
        echo -e "\e[${colors[3]}BrooCompile es un script para compilar el núcleo linux, instalar los módulos, instalar el núcleo,"
        echo "(re)generar un archivo initramfs con o sin soporte para LUKS y/o LVM y (re)generar un archivo de "
        echo "configuración de GRUB."
        echo -e "\nOpciones disponibles:\n"
        echo -e "--luks\t\t\t\tCrea un initramfs con soporte para LUKS."
        echo -e "--lvm\t\t\t\tCrea un initramfs con soporte para LVM."
        echo -e "-a o --about\t\t\tMuestra información sobre este programa."
        echo -e "-h o --help\t\t\tMuestra esta página de ayuda."
        echo -e "-t o --threads <# hilos>\tRealiza la compilación del núcleo con la cantidad de hilos indicada. ($cores por defecto)"
        echo -e "-v o --verbose\t\t\tSi esta opción está habilitada BrooCompile informa el paso en el que va cada vez que"
        echo -e "\t\t\t\trealiza una tarea. En caso contrario, sólo muestra información sobre la salida"
        echo -e "\t\t\t\tdel programa utilizado para realizar la tarea. Esta regla sólo se rompe si se produce un error.\n"
        echo -e "Si no utiliza opción alguna BrooCompile trabajará con las opciones predeterminadas."
        echo -e "Estas son: LUKS = No, LVM = No, Hilos = $cores.\n"
}

function get_info()
{
        echo -e "\e[${colors[3]}Nombre: $name\n"
        echo -e "Versión: 0.0.1\n"
        echo -e "Licencia: GNU GPL v2\n"
        echo -e "Software utilizado para el desarrollo de este programa: VIM 8.1\n"
        echo -e "Autor: Lord Brookie\n"
        echo -e "Repositorio(s) del proyecto:\n"
        echo "Github: https://github.com/brookiestein/scripts/tree/master/$name/"
        echo -e "GitLab: https://gitlab.com/LordBrookie/scripts/tree/master/$name/\n"
}

function verify()
{
        cd "$sources"
        if [ $? -eq 0 ]; then
                if [ "$verbose" = "yes" ]; then
                        echo -e "\n\e[${colors[2]}Buscando archivo de configuración..."; sleep 2
                fi
                if [ ! -f ".config" ]; then
                        if [ "$verbose" = "yes" ]; then
                                echo -e "\n\e[${colors[2]}Archivo de configuración no encontrado.";
                                echo -e "Buscando en las fuentes antiguas..."
                        fi
                        sleep 2
                        if [ -f "$old_sources_path/.config" ]; then
                                if [ "$verbose" = "yes" ]; then
                                        echo -e "\n\e[${colors[2]}Archivo de configuración anterior encontrado.\nCopiando a las nuevas fuentes..."
                                fi
                                sleep 2
                                cp "$old_sources_path/.config" "$sources"
                                if [ $? -ne 0 ]; then
                                        echo -e "\e[${colors[1]}$name: No se ha podido copiar el archivo de configuración "
                                        echo "desde las fuentes anteriores."
                                        echo "Por favor, verifique la existencia de este archivo o proceda a realizar la"
                                        echo -e "configuración correspondiente, p.e (make menuconfig/gconfig, etc.)\n"
                                        status=1
                                else
                                        if [ "$verbose" = "yes" ]; then
                                                echo -e "\e[${colors[2]}Sincronizando configuración anterior...\n"
                                        fi
                                        sleep 2
                                        make olddefconfig
                                        if [ $? -eq 0 ]; then
                                                if [ "$verbose" = "yes" ]; then
                                                        echo -e "\n\e[${colors[2]}Sincronización realizada exitosamente.\n"
                                                fi
                                                status=0
                                        else
                                                echo -e "\n\e[${colors[1]}$name: Ha ocurrido un error al sincronizar las configuraciones "
                                                echo -e "anteriores con las nuevas.\n"
                                                status=1
                                        fi
                                fi
                        else
                                echo -e "\n\e[${colors[1]}No se ha encontrado el archivo de configuración para compilar las fuentes en: $sources o"
                                echo "$sources-$(uname -r). Por favor, verifique la existencia de este archivo o proceda a realizar"
                                echo -e "la configuración correspondiente, p.e (make menuconfig/gconfig, etc.)\n"
                                echo -e "\e[${colors[0]}Le ofrezco dos opciones:"
                                echo "1-Utilizar la herramienta Genkernel o"
                                echo "2-Ofrecerme la ruta en la que pueda "
                                echo "encontrar un archivo de configuración"
                                echo "válido para compilar su núcleo. Por favor, elija"
                                echo -e "con el número correspondiente a su elección.\n"
                                g="1-Genkernel"
                                d="2-Directorio"
                                options=("$g" "$d")
                                PS3=">>> Su elección: "
                                select opt in ${options[@]}; do
                                        if [ "$opt" = "$g" ]; then
                                                echo -e "\n\e[${colors[2]}Utilizando la herramienta Genkernel..."
                                                status=1
                                                break
                                        elif [ "$opt" = "$d" ]; then
                                                while true; do
                                                        echo -e "\n\e[${colors[0]}Introduzca la ruta en la que puedo encontrar un archivo"
                                                        read -p "de configuración válido: " path
                                                        if [ -z "$path" ]; then
                                                                echo -e "\n\e[${colors[1]}$name: No ha introducido nada.\n"
                                                        elif [ ! -d "$path" ]; then
                                                                echo -e "\n\e[${colors[1]}$name: El directorio: \"$path\" no existe."
                                                        else
                                                                dirs="$(ls -a1 "$path")"
                                                                for i in $dirs; do
                                                                        if [ "$i" = ".config" ]; then
                                                                                if [ -f "$path/$i" ]; then
                                                                                        echo -e "\n\e[${colors[2]}Archivo de configuración "
                                                                                        echo "encontrado."
                                                                                        echo "Copiando archivo a: $sources..."; sleep 2
                                                                                        cp "$path/$i" "$sources"
                                                                                        if [ $? -eq 0 ]; then
                                                                                                echo -ne "\n\e[${colors[2]}$name: "
                                                                                                echo "Copia realizada con éxito."
                                                                                                status=0
                                                                                                break
                                                                                        else
                                                                                                echo -ne "\n\e[${colors[1]}$name: Ha "
                                                                                                echo -e "ocurrido un error en la copia.\n"
                                                                                                exit 1
                                                                                        fi
                                                                                else
                                                                                        echo -e "\n\e[${colors[1]}$name: $i "
                                                                                        echo -e "no es un archivo de configuración.\n"
                                                                                        exit 1
                                                                                fi
                                                                        else
                                                                                status=404
                                                                        fi
                                                                done

                                                                if [ $((status)) -eq 0 ]; then
                                                                        break
                                                                else
                                                                        echo -e "\n\e[${colors[1]}$name: No se pudo encontrar un "
                                                                        echo "archivo de configuración en: \e[${colors[0]}$path"
                                                                fi
                                                        fi
                                                done
                                        else
                                                echo -e "\n\e[${colors[1]}$name: Opción no válida.\n"
                                        fi

                                        if [ $((status)) -eq 0 ]; then
                                                break
                                        fi
                                done
                        fi
                else
                        if [ "$verbose" = "yes" ]; then
                                echo -e "\n\e[${colors[2]}Archivo de configuración encontrado."
                        fi
                        sleep 2
                        status=0
                fi
        else
                echo -e "\n\e[${colors[1]}$name: Ha ocurrido un error al entrar en el directorio de las fuentes.\n"; exit 1
        fi
}

function get_threads()
{
        warning
        while true; do
                read -t 15 -p "¿Desea continuar con esta configuración? [S/n] (No por defecto): " ask
                if [[ "$ask" = "s" || "$ask" = "si" || "$ask" = "y" || "$ask" = "yes" ]]; then
                        next="yes"
                        return
                elif [ -z "$ask" ]; then
                        break
                elif [[ "$ask" != "s" && "$ask" != "si" && "$ask" != "y" && "$ask" != "yes" && "$ask" != "n" && "$ask" != "no" ]]; then
                        echo -e "\n\e[${colors[1]}$name: Respuesta: \"$ask\" no válida.\n"
                else
                        break
                fi
        done
        while true; do
                read -t 15 -p "¿Cuántos hilos de su procesador desea utilizar para esta compilación? ($cores por defecto): " threads
                if [ -z "$threads" ]; then
                        threads=$cores
                        echo; break
                fi
                echo $threads | grep "[[:digit:]]" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                        break
                else
                        echo -e "\n\e[${colors[1]}$name: La cantidad de hilos especificada no es válida.\n"
                fi
        done
}

function print_options()
{
        if [ "$verbose" = "yes" ]; then
                echo -e "\n\e[${colors[0]}$name: Trabajando con las opciones:"
                if [ "$lvm" = "yes" ]; then
                        echo -n "LVM = Sí, "
                else
                        echo -n "LVM = No, "
                fi

                if [ "$luks" = "yes" ]; then
                        echo -n "LUKS = Sí, "
                else
                        echo -n "LUKS = No, "
                fi

                echo -e "Hilos = $threads\n"
        fi
}

function work_with_genkernel()
{
        if [[ "$lvm" = "yes" && "$luks" = "yes" ]]; then
                genkernel --lvm --luks all
        elif [[ "$lvm" = "yes" && "$luks" = "no" ]]; then
                genkernel --lvm all
        elif [[ "$lvm" = "no" && "$luks" = "yes" ]]; then
                genkernel --luks all
        else
                genkernel all
        fi

        if [ $? -eq 0 ]; then
                if [ "$verbose" = "yes" ]; then
                        echo -e "\n\e[${colors[2]}$name: Trabajo finalizado.\n"
                fi
        else
                echo -e "\n\e[${colors[1]}$name: Ocurrió un error al realizar el trabajo con la herramienta: Genkernel.\n"
                exit 1
        fi
}

function verify_threads()
{
        echo "$1" | grep "[[:digit:]]" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
                threads=$1
                while [ $threads -gt $cores ]; do
                        get_threads
                        if [ "$next" = "yes" ]; then
                                break
                        fi
                done
                if [ $threads -le 0 ]; then
                        echo -e "\n\e[${colors[1]}$name: La cantidad de hilos especificada no es válida."
                        echo -e "\e[${colors[2]}Utilizando: $cores...\n"
                        threads=$cores
                fi
        else
                banner
                echo -e "\n\e[${colors[1]}$name: La cantidad de hilos especificada no es válida.\n"
                exit 1
        fi
}

while [ $# -ne 0 ]; do
        case "$1" in
                -a|--about)
                        get_info
                        exit 0
                        ;;
                -h|--help)
                        get_help
                        exit 0
                        ;;
                -v|--verbose)
                        if [ -z "$verbose" ]; then
                                verbose="yes"
                        else
                                warning_ignore "Modo verboso"
                        fi
                        ;;
                -t|--threads)
                        shift
                        if [ -z "$threads" ]; then
                                verify_threads "$1"
                        else
                                warning_ignore "Threads"
                        fi
                        ;;
                --lvm)
                        if [ -z "$lvm" ]; then
                                lvm="yes"
                        else
                                warning_ignore "LVM"
                        fi
                        ;;
                --luks)
                        if [ -z "$luks" ]; then
                                luks="yes"
                        else
                                warning_ignore "LUKS"
                        fi
                        ;;
                *)
                        echo -e "\e[${colors[1]}$name: Opción: $1 no válida.\n"
                        exit 1
                        ;;
        esac
        shift
done


if [ "$USER" != "root" ]; then
        echo -e "\e[${colors[1]}$name: Necesito permisos de administrador para poder trabajar.\n"
        exit 1
fi

if [ -z "$lvm" ]; then
        lvm="no"
fi

if [ -z "$luks" ]; then
        luks="no"
fi

if [ -z "$threads" ]; then
        threads=$cores
fi

if [ -z "$verbose" ]; then
        verbose="no"
fi

verify
if [ $status -eq 0 ]; then
        if [ "$verbose" = "yes" ]; then
                print_options
                echo -e "\e[${colors[2]}Entrando en el directorio..."
        fi
        sleep 2
        cd "$sources"
        if [ $? -eq 0 ]; then
                if [ "$verbose" = "yes" ]; then
                        echo -e "\e[${colors[2]}La compilación iniciará en 5 segundos. Puede presionar (CTRL + C) para cancelar esto."
                        echo -en "\e[${colors[1]}("
                        for ((i=5; i>=1; i--)); do
                                if [ $i -gt 1 ]; then
                                        echo -n "$i, "
                                else
                                        echo -e "$i)\n"
                                fi
                                sleep 1
                        done
                else
                        for ((i=5; i>=1; i--)); do
                                sleep 1
                        done
                fi

                make -j$threads
                if [ $? -eq 0 ]; then
                        if [ "$verbose" = "yes" ]; then
                                echo -e "\n\e[${colors[2]}Compilación del núcleo finalizada con éxito. Instalando módulos...\n"
                        fi
                        sleep 2
                        make modules_install
                        if [ $? -eq 0 ]; then
                                if [ "$verbose" = "yes" ]; then
                                        echo -e "\n\e[${colors[2]}Instalación de módulos finalizada con éxito. Instalando núcleo...\n"
                                fi
                                sleep 2
                                make install
                                if [ $? -eq 0 ]; then
                                        if [ "$verbose" = "yes" ]; then
                                                echo -e "\n\e[${colors[2]}Instalación de núcleo finalizada con éxito. (Re)generando initramfs..."
                                        fi
                                        sleep 2
                                        if [[ "$lvm" = "yes" && "$luks" = "yes" ]]; then
                                                genkernel --lvm --luks --install initramfs
                                        elif [[ "$lvm" = "no" && "$luks" = "yes" ]]; then
                                                genkernel --luks --install initramfs
                                        elif [[ "$lvm" = "yes" && "$luks" = "no" ]]; then
                                                genkernel --lvm --install initramfs
                                        else
                                                genkernel --install initramfs
                                        fi

                                        if [ $? -eq 0 ]; then
                                                if [ "$verbose" = "yes" ]; then
                                                        echo -e "\n\e[${colors[2]}(Re)generación de initramfs finalizada con éxito. "
                                                        echo -e "(Re)generando fichero de configuración de GRUB...\n"
                                                fi
                                                sleep 2
                                                grub-mkconfig -o "$boot/grub/grub.cfg"
                                                if [ $? -eq 0 ]; then
                                                        if [ "$verbose" = "yes" ]; then
                                                                echo -ne "\n\e[${colors[2]}(Re)generación de fichero de configuración "
                                                                echo -e "de GRUB finalizado con éxito.\n¡Trabajo finalizado!\n"
                                                        fi
                                                else
                                                        echo -ne "\n\e[${colors[1]}$name: Ocurrió un error en la "
                                                        echo -ne "(re)generación del fichero de "
                                                        echo -e "configuración de GRUB. Por lo que no se podrá continuar"
                                                        exit 1
                                                fi
                                        else
                                                echo -ne "\n\e[${colors[1]}$name: Ocurrió un error en la (re)generación "
                                                echo -ne "del initramfs por lo que no se podrá continuar.\n"
                                                exit 1
                                        fi
                                else
                                        echo -ne "\n\e[${colors[1]}$name: Ocurrió un error en la instalación "
                                        echo -e "del núcleo por lo que no se podrá continuar.\n"
                                        exit 1
                                fi
                        else
                                echo -ne "\n\e[${colors[1]}$name: Ocurrió un error en la instalación "
                                echo -e "de los módulos por lo que no se podrá continuar.\n"
                                exit 1
                        fi
                else
                        echo -ne "\n\e[${colors[1]}$name: Ocurrió un error en la compilación del núcleo por lo que "
                        echo -e "no se podrá continuar.\n"
                        exit 1
                fi
        else
                echo -ne "\n\e[${colors[1]}$name: No se pudo entrar en el directorio de las fuentes por lo que no se podrá continuar.\n"
                exit 1
        fi
else
        work_with_genkernel
fi

