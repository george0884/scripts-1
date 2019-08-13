**BrookieVerify es un programa que se encarga de verificar firmas hash. ¿Su utilidad?
Bueno, eso depende de ti :D. Lo desarrollé para cada vez que descargue un archivo
de algún servidor en internet o por torrent, verificar su correspondiente firma hash.**

**BrookieVerify soporta las siguientes firmas hash:**
```
MD5
Sha1
Sha224
Sha256
Sha384
Sha512
```
**Dependencias:**
```
GNU Core Utils
```

**Opciones disponibles**
```
-a [--md5] <hash>               Verifica la firma hash MD5 del archivo especificado.
-b [--sha1] <hash>              Verifica la firma hash Sha1 del archivo especificado.
-c [--sha224] <hash>            Verifica la firma hash Sha224 del archivo especificado.
-d [--sha256] <hash>            Verifica la firma hash Sha256 del archivo especificado.
-e [--sha384] <hash>            Verifica la firma hash Sha384 del archivo especificado.
-f [--sha512] <hash>            Verifica la firma hash Sha512 del archivo especificado.
-g [--file] <archivo>           Archivo a verificar. (Requerido)
-h [--help]                     Muestra esta página de ayuda y sale.
-i [--info]                     Muesta información sobre este programa y sale.
```
