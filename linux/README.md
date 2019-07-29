**Este script se encarga de compilar el núcleo linux, instalar los módulos, instalar el núcleo, (re)generar el initramfs
con o sin soporte para LUKS y/o LVM (Eso queda a elección del usuario) y (re)genera el archivo de configuración de GRUB.**

**Nota: Este script tal cual está sólo funciona bien en Gentoo GNU/Linux debido a que para (re)generar el initramfs se
utiliza la herramienta "Genkernel" que fue creada para este sistema operativo. Esto no es un impedimento si deseas utilizarlo, pero si no utilizas este sistema operativo deberías de cambiar eso :D**

