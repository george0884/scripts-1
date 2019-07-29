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
message="¿Desea tener soporte para"
answer="La respuesta introducida no es válida."
# Rutas
old_sources_path="$sources-$(uname -r)"
old_modules_path="/lib/modules/$(uname -r)"
boot="/boot"
old_boot_config="$boot/config-$(uname -r)"
old_initramfs="$boot/initramfs-genkernel-$(uname -m)-$(uname -r)"
old_system_map="$boot/System.map-$(uname -r)"
old_vmlinuz="$boot/vmlinuz-$(uname -r)"
# Hilos
tmp=$(cat /proc/cpuinfo | grep "cpu cores")
tmp=${tmp:${#tmp}-2:${#tmp}}
tmp=$((tmp*2))

function welcome()
{
        echo "##############################################################################################"
        echo "##### Bienvenido al script de automatización del proceso de compilación del núcleo linux #####"
        echo "##############################################################################################"
}

function verify()
{
        cd "$sources"
        if [ $? -eq 0 ]; then
                echo -e "\nBuscando archivo de configuración..."; sleep 2
                if [ ! -f ".config" ]; then
                        echo -e "\nArchivo de configuración no encontrado.";
                        echo -e "Buscando en las fuentes antiguas..."
                        sleep 2
                        if [ -f "$old_sources_path/.config" ]; then
                                echo "Archivo de configuración anterior encontrado. Copiando a las nuevas fuentes..."
                                sleep 2
                                cp "$old_sources_path/.config" "$sources"
                                if [ $? -ne 0 ]; then
                                        echo "No se ha podido copiar el archivo de configuración desde las fuentes anteriores."
                                        echo "Por favor, verifique la existencia de este archivo o proceda a realizar la"
                                        echo -e "configuración correspondiente, p.e (make menuconfig/gconfig, etc.)\n"
                                        status=1
                                else
                                        echo; echo "Sincronizando configuración anterior..."; echo
                                        sleep 2
                                        make olddefconfig
                                        if [ $? -eq 0 ]; then
                                                echo; echo "Sincronización realizada exitosamente."; echo
                                                status=0
                                        else
                                                echo -e "\nHa ocurrido un error al sincronizar las configuraciones anteriores con las nuevas.\n"
                                                status=1
                                        fi
                                fi
                        else
                                echo -e "\nNo se ha encontrado el archivo de configuración para compilar las fuentes en: $sources o"
                                echo "$sources-$(uname -r). Por favor, verifique la existencia de este archivo o proceda a realizar"
                                echo -e "la configuración correspondiente, p.e (make menuconfig/gconfig, etc.)\n"
                                echo "Le ofrezco dos opciones:"
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
                                                echo -e "\nUtilizando la herramienta Genkernel..."
                                                status=1
                                                break
                                        elif [ "$opt" = "$d" ]; then
                                                while true; do
                                                        echo -e "\nIntroduzca la ruta en la que puedo encontrar un archivo"
                                                        read -p "de configuración válido: " path
                                                        if [ -z "$path" ]; then
                                                                echo -e "\nNo ha introducido nada.\n"
                                                        elif [ ! -d "$path" ]; then
                                                                echo -en "\nEl directorio: \"$path\" no existe.\n"
                                                        else
                                                                if [ "${path:${#path}-1}" != "/" ]; then
                                                                        path+="/"
                                                                fi

                                                                dirs="$(ls -a1 "$path")"
                                                                for i in $dirs; do
                                                                        if [ "$i" = ".config" ]; then
                                                                                if [ -f "$path$i" ]; then
                                                                                        echo -e "\nArchivo de configuración encontrado."
                                                                                        echo "Copiando archivo a: $sources..."; sleep 2
                                                                                        cp "$path$i" "$sources"
                                                                                        if [ $? -eq 0 ]; then
                                                                                                echo -e "\nCopia realizada con éxito."
                                                                                                status=0
                                                                                                break
                                                                                        else
                                                                                                echo -e "\nHa ocurrido un error en la copia.\n"
                                                                                                exit 1
                                                                                        fi
                                                                                else
                                                                                        echo -e "\n$i no es un archivo de configuración.\n"
                                                                                        exit 1
                                                                                fi
                                                                        else
                                                                                status=404
                                                                        fi
                                                                done

                                                                if [ $((status)) -eq 0 ]; then
                                                                        break
                                                                else
                                                                        echo -e "\nNo se pudo encontrar un archivo de configuración en:"
                                                                        echo -e "$path"
                                                                fi
                                                        fi
                                                done
                                        else
                                                echo -e "\nOpción no válida.\n"
                                        fi

                                        if [ $((status)) -eq 0 ]; then
                                                break
                                        fi
                                done
                        fi
                else
                        echo -e "\nArchivo de configuración encontrado."
                        sleep 2
                        status=0
                fi
        else
                echo -e "\nHa ocurrido un error al entrar en el directorio de las fuentes.\n"; exit 1
        fi
}

function get_threads()
{
        while true; do
                read -t 5 -p "¿Cuántos hilos de su procesador desea utilizar para esta compilación? ($tmp por defecto): " threads
                if [ -z "$threads" ]; then
                        threads=$tmp
                        echo; break
                fi
                echo $threads | grep "[[:digit:]]" > /dev/null 2> /dev/null
                if [ $? -eq 0 ]; then
                        if [ $threads -gt $tmp ]; then
                                echo; echo "La cantidad de hilos que ha decidido utilizar para esta compilación"
                                echo "ha sido $threads, sin embargo su procesador sólo cuenta con $tmp hilos."
                                echo "Esta configuración no se recomienda, pero (evidentemente) usted decide si continuar..."
                                read -t 5 -p "¿Desea continuar con esta configuración? [S/n]: (No por defecto): " confirm
                                if [ -n "$confirm" ]; then
                                        if [[ "$confirm" = "s" || "$confirm" = "si" ]]; then
                                                echo; echo "Continuando con una configuración no recomendada."
                                                sleep 2; break
                                        elif [[ "$confirm" != "n" || "$confirm" != "no" ]]; then
                                                echo -e "\n\nLa respuesta \"$confirm\" no es válida.\n"
                                        fi
                                else
                                        echo -e "\n"
                                fi
                        elif [ $threads -le 0 ]; then
                                echo -e "\nLa cantidad de hilos \"$threads\" no es válida.\n"
                        else
                                break
                        fi
                fi
        done
        if [ $threads -eq 1 ]; then
                echo "Seleccionado $threads hilo para compilar."
        else
                echo "Seleccionados $threads hilos para compilar."
        fi
}

function get_support()
{
        while true; do
                if [ "$2" = "luks" ]; then
                        read -t 5 -p "$1" luks
                        if [ -z "$luks" ]; then
                                luks="n"
                                echo -e "\n\nSeleccionado \"No\" por defecto."; break
                        elif [[ "$luks" = "s" || "$luks" = "si" || "$luks" = "n" || "$luks" = "no" ]]; then
                                break
                        else
                                echo; echo "La respuesta \"$luks\" no es válida."
                        fi
                else
                        read -t 5 -p "$1" lvm
                        if [ -z "$lvm" ]; then
                                lvm="n"
                                echo -e "\n\nSeleccionado \"No\" por defecto."; break
                        elif [[ "$lvm" = "s" || "$lvm" = "si" || "$lvm" = "n" || "$lvm" = "no" ]]; then
                                break
                        else
                                echo; echo "La respuesta \"$lvm\" no es válida."
                        fi
                fi
        done
        echo
}

function get_info()
{
        echo; echo "A continuación dígame si desea que su initramfs tenga soporte para LVM y/o LUKS."
        # Ask by support for LUKS
        get_support "$message LUKS? [S/n] (No por defecto): " "luks"
        # ASk by support for LVM
        get_support "$message LVM? [S/n] (No por defecto): " "lvm"
        # Get the number of threads for the compilation
        if [ "$1" != "genkernel" ]; then
                get_threads
        fi
}

if [ "$USER" = "root" ]; then
        clear
        # Verify that everything is correct.
        welcome
        verify
        if [ $((status)) -eq 0 ]; then
                # Getting the information needed for work.
                get_info
                # Start to work
                echo; echo "Bien. Ya tengo los datos necesarios para trabajar."
                echo -n "Trabajando con las opciones: "

                if [[ "$luks" = "s" || "$luks" = "si" ]]; then
                        echo -n "LUKS = Sí, "
                else
                        echo -n "LUKS = No, "
                fi

                if [[ "$lvm" = "s" || "$lvm" = "si" ]]; then
                        echo -n "LVM = Sí, "
                else
                        echo -n "LVM = No, "
                fi

                echo "Hilos = $threads"
                echo "Entrando en el directorio..."; echo
                sleep 2

                cd "$sources"
                if [ $? -eq 0 ]; then
                        echo "La compilación del núcleo iniciará en 5 segundos. Puede presionar (CTRL + C) para cancelar esto."
                        echo -n "("
                        for ((i=5; i>=1; i--)); do
                                if [ $i -gt 1 ]; then
                                        echo -n "$i, "
                                else
                                        echo "$i)"; echo
                                fi
                                sleep 1
                        done

                        make -j$threads
                        if [ $? -eq 0 ]; then
                                echo; echo "Compilación finalizada. Instalando módulos..."; echo
                                sleep 2
                                make modules_install
                                if [ $? -eq 0 ]; then
                                        echo; echo "Instalación de módulos finalizada. Instalando núcleo..."; echo; sleep 2
                                        make install
                                        if [ $? -eq 0 ]; then
                                                echo; echo "Instalación del núcleo finalizada. Generando initramfs..."; echo; sleep 2
                                                if [[ "$lvm" = "s" || "$lvm" = "si" && "$luks" = "s" || "$luks" = "si" ]]; then
                                                        genkernel --lvm --luks --install initramfs
                                                elif [[ "$lvm" = "s" || "$lvm" = "si" && "$luks" = "n" || "$luks" = "no" ]]; then
                                                        genkernel --lvm --install initramfs
                                                elif [[ "$lvm" = "n" || "$lvm" = "no" && "$luks" = "s" || "$luks" = "si" ]]; then
                                                        genkernel --luks --install initramfs
                                                else
                                                        genkernel --install initramfs
                                                fi

                                                if [ $? -eq 0 ]; then
                                                        echo; echo -n "Generación de initramfs finalizada. (Re)generando archivo de "
                                                        echo "configuración de GRUB..."; sleep 2
                                                        grub-mkconfig -o /boot/grub/grub.cfg
                                                        if [ $? -eq 0 ]; then
                                                                echo; echo -n "Generación de archivo de configuración de GRUB "
                                                                echo "finalizada con éxito."; sleep 2
                                                        else
                                                                echo; echo -n "Ha ocurrido un error en la (re)generación del archivo de "
                                                                echo "configuración de GRUB. Saliendo..."; sleep 2; exit 1
                                                        fi
                                                else
                                                        echo; echo "Ha ocurrido un error en la generación del initramfs. Saliendo..."
                                                        sleep 2; exit
                                                fi

                                                c=0
                                                dirs="$(ls -1 ${sources:0:${#sources}-5})"
                                                name="${sources:${#sources}-5:${#sources}}"

                                                for i in $dirs; do
                                                        if [ "${i:0:5}" = "$name" ]; then
                                                                ((c++))
                                                        fi
                                                done

                                                if [ $c -gt 2 ]; then
                                                        if [ -d "$old_sources_path" ]; then
                                                                old_sources="s"
                                                        fi

                                                        if [ -d "$old_modules_path" ]; then
                                                                old_modules="s"
                                                        fi

                                                        if [[ -f "$old_boot_config" && -f "$old_initramfs" \
                                                                && -f "$old_system_map" && -f "$old_vmlinuz" ]]; then
                                                                old_files="s"
                                                        fi

                                                        if [[ -n "$old_sources" && -n "$old_modules" && -n "$old_files" ]]; then
                                                                ask_confirm="¿Desea eliminar los archivos y directorios de su núcleo antiguo?"
                                                                echo; read -t 5 -p "$ask_confirm [S/n] (Sí por defecto): " confirm

                                                                if [ -z "$confirm" ]; then
                                                                        confirm="s"
                                                                else
                                                                        while [[ "$confirm" != "s" && "$confirm" != "si" \
                                                                                && "$confirm" != "n" && "$confirm" != "no" ]]; do
                                                                                echo; echo "La respuesta \"$confirm\" no es válida."
                                                                                read -t 5 -p "$ask_confirm (No por defecto): "
                                                                                if [ -z "$confirm" ]; then
                                                                                        confirm="s"
                                                                                fi
                                                                        done
                                                                fi

                                                                if [[ "$confirm" = "s" || "$confirm" = "si" ]]; then
                                                                        rm -rf "$old_sources_path" "$old_modules_path" "$old_boot_config" \
                                                                                "$old_initramfs" "$old_system_map" "$old_vmlinuz"
                                                                fi
                                                       fi
                                                fi

                                                echo; echo "Eliminado archivos antiguos..."; echo
                                                c=0
                                                if [ -f "$old_boot_config.old" ]; then
                                                        rm -f "$old_boot_config.old"
                                                        if [ $? -eq 0 ]; then
                                                                echo "Archivo: $old_boot_config.old eliminado."
                                                                ((c++))
                                                        else
                                                                echo "No se pudo eliminar el archivo: $old_boot_config.old"
                                                        fi
                                                fi

                                                if [ -f "$old_initramfs.old" ]; then
                                                        rm -f "$old_initramfs.old"
                                                        if [ $? -eq 0 ]; then
                                                                echo "Archivo: $old_initramfs.old eliminado."
                                                                ((c++))
                                                        else
                                                                echo "No se pudo eliminar el archivo: $old_initramfs.old"
                                                        fi
                                                fi

                                                if [ -f "$old_system_map.old" ]; then
                                                        rm -f "$old_system_map.old"
                                                        if [ $? -eq 0 ]; then
                                                                echo "Archivo: $old_system_map.old eliminado."
                                                                ((c++))
                                                        else
                                                                echo "No se pudo eliminar el archivo: $old_system_map.old"
                                                        fi
                                                fi

                                                if [ -f "$old_vmlinuz.old" ]; then
                                                        rm -f "$old_vmlinuz.old"
                                                        if [ $? -eq 0 ]; then
                                                                echo "Archivo: $old_vmlinuz.old eliminado."
                                                                ((c++))
                                                        else
                                                                echo "No se pudo eliminar el archivo: $old_vmlinuz.old"
                                                        fi
                                                fi

                                                if [ $c -gt 0 ]; then
                                                        echo "Los archivos antiguos han sido eliminados."
                                                else
                                                        echo "No se eliminaron los archivos antiguos."
                                                fi

                                                echo; echo "Trabajo finalizado."; echo
                                        else
                                                echo; echo "Ha ocurrido un error en la instalación del núcleo."
                                                echo "Saliendo..."; sleep 2
                                        fi
                                else
                                        echo; echo "Ha ocurrido un error en la instalación de los módulos. Saliendo..."; sleep 2
                                fi
                        else
                                echo; echo "Ha ocurrido un error en la compilación del kernel. Saliendo..."; echo; sleep 2
                        fi
                else
                        echo; echo "No se ha podido acceder al directorio. Saliendo..."; echo; sleep 2
                fi
        else
                get_info "genkernel"
                echo; echo "Bien. Ya tengo los datos necesarios para trabajar."
                echo -n "Trabajando con las opciones: "

                if [[ "$luks" = "s" || "$luks" = "si" ]]; then
                        echo -n "LUKS = Sí, "
                else
                        echo -n "LUKS = No, "
                fi

                if [[ "$lvm" = "s" || "$lvm" = "si" ]]; then
                        echo -e "LVM = Sí\n"
                else
                        echo -e "LVM = No\n"
                fi

                if [[ "$luks" = "s" || "$luks" = "si" && "$lvm" = "s" || "$lvm" = "si" ]]; then
                        genkernel --luks --lvm all
                elif [[ "$luks" = "s" || "$luks" = "si" && "$lvm" = "n" || "$lvm" = "no" ]]; then
                        genkernel --luks all
                elif [[ "$luks" = "n" || "$luks" = "no" && "$lvm" = "s" || "$lvm" = "si" ]]; then
                        genkernel --lvm all
                else
                        genkernel all
                fi

                if [ $? -eq 0 ]; then
                        echo -e "\nTrabajo finalizado.\n"
                else
                        echo -e "\nOcurrió un error en el proceso con Genkernel.\n"
                fi
        fi
else
        echo; echo "Se necesitan permisos de administrador para realizar las tareas."; echo
fi

