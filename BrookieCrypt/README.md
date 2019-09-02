**BrookieCrypt es un programa que sirve para comprimir, cifrar y crear sumas de comprobación
de un archivo o una carpeta, todo esto en conjunto.**

**Básicamente lo que hace BrookieCrypt es tomar el archivo o directorio que le indique, lo
comprime con el algoritmo "zip" y lo "protege" con la contraseña que usted le indique.
Luego, cifra el archivo comprimido con cifrado simétrico, utilizando el programa GnuPG (GPG)
que, se supone, debe tener instalado a "priori". Así, se le suma "una capa de protección más"
al archivo. Después de haber conseguido eso (si sucede algún error en el proceso BrookieCrypt le avisará)
crea tres archivos, correspondientes a sumas de comprobación: sha256 y sha512 y la firma GPG.
Por último "destruye" el archivo comprimido que inicialmente creó para antes del cifrado y, si así lo desea
también "destruye" el archivo que comprimió y cifró.**

**Algoritmo(s) de compresión utilizado(s):**
```
zip
```

**Método de cifrado:**
```
Simétrico
```

**Dependencias:**
```
zip
GnuPG (GPG)
GNU Core Utils
```

