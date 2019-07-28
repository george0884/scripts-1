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
old_sources_path="$sources-$(uname -r)"
old_modules_path="/lib/modules/$(uname -r)"
boot="/boot"
old_boot_config="$boot/config-$(uname -r)"
old_initramfs="$boot/initramfs-genkernel-$(uname -m)-$(uname -r)"
old_system_map="$boot/System.map-$(uname -r)"
old_vmlinuz="$boot/vmlinuz-$(uname -r)"

function welcome()
{
        echo "##############################################################################################"
        echo "##### Bienvenido al script de automatización del proceso de compilación del núcleo linux #####"
        echo "##############################################################################################"
}

function verify()
{
        cd "$sources"
        echo
        if [ ! -f ".config" ]; then
                echo "Archivo de configuración no encontrado."; echo
                sleep 2
                if [ -f "$sources-$(uname -r)/.config" ]; then
                        echo "Archivo de configuración anterior encontrado. Copiando a las nuevas fuentes..."
                        sleep 2
                        cp "$sources-$(uname -r)/.config" "$sources"
                        if [ $? != '0' ]; then
                                echo "No se ha encontrado el archivo de configuración para compilar las fuentes y no se ha podido"
                                echo "copiar desde las fuentes anteriores. Por favor, verifique la existencia de este archivo o"
                                echo "proceda a realizar la configuración correspondiente, p.e (make menuconfig/gconfig, etc.)"
                                echo; status=1
                        else
                                echo; echo "Sincronizando configuración anterior..."; echo
                                sleep 2
                                make olddefconfig
                                if [ $? = '0' ]; then
                                        echo; echo "Sincronización realizada exitosamente."; echo
                                        status=0
                                else
                                        echo; echo "Ha ocurrido un error al sincronizar las configuraciones anteriores con las nuevas."; echo
                                fi
                        fi
                else
                        echo "No se ha encontrado el archivo de configuración para compilar las fuentes en: $sources o"
                        echo "$sources-$(uname -r). Por favor, verifique la existencia de este archivo o proceda a realizar"
                        echo "la configuración correspondiente, p.e (make menuconfig/gconfig, etc.)"
                        echo; status=1
                fi
        else
                echo "Archivo de configuración encontrado."
                sleep 2
                status=0
        fi
}

function get_threads()
{
        echo -n "¿Cuántos hilos de su procesador desea utilizar para esta compilación? (1 por defecto): "
        read threads
        echo -en $threads | grep '[[:digit:]]' > /dev/null 2> /dev/null
        while [[ $? -ne 0 || $threads -le 0 ]]; do
                if [[ -z $threads ]]; then
                        threads=1
                        break
                else
                        echo; echo "La cantidad de hilos introducida no es válida."
                        echo -n "¿Cuántos hilos de su procesador desea utilizar para esta compilación? (1 por defecto): "
                        read threads
                        echo -en $threads | grep '[[:digit:]]' > /dev/null 2> /dev/null
                fi
        done
}

function get_info()
{
        echo; echo "A continuación dígame si desea que su initramfs tenga soporte para LVM y/o LUKS."
        # Ask by support for LUKS
        echo -n "$message LUKS? [S/n]: "
        read luks
        while [[ $luks != 's' && $luks != 'si' && $luks != 'n' && $luks != 'no' ]]; do
                echo "$answer"; echo -n "$message LUKS? [S/n]: "
                read luks
        done

        # Ask by support for LVM
        echo -n "$message LVM? [S/n]: "
        read lvm
        while [[ "$lvm" != 's' && "$lvm" != 'si' && "$lvm" != 'n' && "$lvm" != 'no' ]]; do
                echo "$answer"; echo -n "$message LVM? [S/n]: "
                read lvm
        done

        # Get the number of threads for the compilation
        cores=$(cat /proc/cpuinfo | grep "cpu cores")
        cores=${cores:${#cores}-2}
        get_threads

        while [ $threads -gt $((cores*2+1)) ]; do
                echo; echo "La cantidad de hilos que ha decidido utilizar es: $threads y su procesador"
                echo -n "cuenta con sólo $((cores*2)). Esto no es recomendable. ¿Desea continuar con esta configuración? [S/n]: "
                read confirm
                while [[ "$confirm" != 's' && "$confirm" != 'si' && "$confirm" != 'n' && "$confirm" != 'no' ]]; do
                        echo; echo "La respuesta introducida no es válida."
                        echo -n "¿Desea continuar con esta configuración? [S/n]: "
                        read confirm
                done

                if [[ "$confirm" = 's' || "$confirm" = 'si' ]]; then
                        echo; echo "Continuando con una configuración no recomendada."
                        sleep 2
                        break
                else
                        get_threads
                fi
        done

        if [ $threads -eq 1 ]; then
                echo "Seleccionado $threads hilo para compilar."
        else
                echo "Seleccionados $threads hilos para compilar."
        fi
}

if [ "$USER" = 'root' ]; then
        clear
        # Get information to work
        welcome
        verify
        if [ $status -eq 0 ]; then
                get_info
                # Start to work
                echo; echo "Bien. Ya tengo los datos necesarios para trabajar."
                echo -n "Trabajando con las opciones: "

                if [[ "$luks" = 's' || "$luks" = 'si' ]]; then
                        echo -n "LUKS = Sí, "
                else
                        echo -n "LUKS = No, "
                fi

                if [[ "$lvm" = 's' || "$lvm" = 'si' ]]; then
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
                                                if [[ "$lvm" = 's' || "$lvm" = 'si' && "$luks" = 's' || "$luks" = 'si' ]]; then
                                                        genkernel --lvm --luks --install initramfs
                                                        if [ $? = '0' ]; then
                                                                echo; echo -n "Generación de initramfs finalizada. "
                                                                echo -n "(Re)generando archivo de configuración de GRUB..."; echo
                                                                sleep 2
                                                                grub-mkconfig -o /boot/grub/grub.cfg
                                                                if [ $? -eq 0 ]; then
                                                                        echo; echo -n "Generación de archivo de configuración de "
                                                                        echo "GRUB finalizada con éxito."; sleep 2
                                                                else
                                                                        echo; echo -n "Ha ocurrido un error en la (re)generación del archivo "
                                                                        echo "de configuración de GRUB. Saliendo..."; sleep 2; exit 1
                                                                fi
                                                        else
                                                                echo; echo "Ha ocurrido un error en la generación del initramfs. Saliendo..."
                                                                sleep 2; exit 1
                                                        fi
                                                elif [[ "$lvm" = 's' || "$lvm" = 'si' && "$luks" = 'n' || "$luks" = 'no' ]]; then
                                                        genkernel --lvm --install initramfs
                                                        if [ $? -eq 0 ]; then
                                                                echo; echo -n "Generación de initramfs finalizada. (Re)generando archivo de "
                                                                echo "configuración de GRUB..."; sleep 2
                                                                grub-mkconfig -o /boot/grub/grub.cfg
                                                                if [ $? -eq 0 ]; then
                                                                        echo; echo -n "Generación de archivo de configuración de GRUB "
                                                                        echo "finalizada con éxito. "; sleep 2
                                                                else
                                                                        echo
                                                                        echo -n "Ha ocurrido un error en la (re)generación del archivo de "
                                                                        echo "configuración de GRUB. Saliendo..."; sleep 2; exit 1
                                                                fi
                                                        else
                                                                echo; echo "Ha ocurrido un error en la generación del initramfs. Saliendo..."
                                                                sleep 2; exit 1
                                                        fi
                                                elif [[ "$lvm" = 'n' || "$lvm" = 'no' && "$luks" = 's' || "$luks" = 'si' ]]; then
                                                        genkernel --luks --install initramfs
                                                        if [ $? -eq ]; then
                                                                echo; echo -n "Generación de initramfs finalizada. (Re)generando archivo de "
                                                                echo "configuración de GRUB..."; sleep 2
                                                                grub-mkconfig -o /boot/grub/grub.cfg
                                                                if [ $? = '0' ]; then
                                                                        echo; echo -n "Generación de archivo de configuración de GRUB "
                                                                        echo "finalizada con éxito."; sleep 2

                                                                else
                                                                        echo; echo -n "Ha ocurrido un error en la (re)generación del archivo de "
                                                                        echo "configuración de GRUB. Saliendo..."; sleep 2; exit 1
                                                                fi
                                                        else
                                                                echo; echo "Ha ocurrido un error en la generación del initramfs. Saliendo..."
                                                                sleep 2; exit 1
                                                        fi
                                                else
                                                        genkernel --install initramfs
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
        fi
else
        echo; echo "Se necesitan permisos de administrador para realizar las tareas."; echo
fi

