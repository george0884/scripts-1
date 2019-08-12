**Brookienergy es un programa que (con acpi) supervisa el estado de carga de la batería
y si detecta que está por debajo del 15% suspende el ordenador. ¿Para qué puede ser esto
útil? Pues como suelo decir: "Eso depende de ti". Este no es programa que pretende ser una
revolución, sino más bien, suplir una necesidad puntual y/o momentánea. Como es mi caso por
ejemplo. Utilizo Gentoo GNU/Linux como sistema operativo y, en ocasiones, suelo dejar mi
ordenador encendido en las noches compilando algunos programas que suelo denominar "gordos"
esos que se tiran unas cuántas horas de compilación. Entonces, ¿Qué pasa con eso? Pues que
me arriesgo a que, por ejemplo, se corte la energía eléctrica y mi laptop siga haciendo ese
trabajo con la energía de la batería, y, aunque esta le puede suplir mientras vuelve la energía
eléctrica, no me asegura que lo haga mucho tiempo, pues (si no lo sabes) compilar es un trabajo
que requiere de poder de procesamiento y mucho procesamiento requiere de mucha energía y ya te
podrás imaginar de ahí en adelante... Así que el trabajo de Brookienergy es, cada 15 segundos
verificar el estado/porcentaje de carga de la batería de mi laptop y, si detecta que está por
debajo del 15%, guarda un log (registro) dónde yo le indique (en caso de no hacerlo toma mi home)
diciendo que suspenderá el ordenador por escasa energía en la batería para así evitar que se apague
por falta de energía y se "pierda" el trabajo que, quién sabe, por cuánto tiempo estuvo realizando xD.**

**Como ya comenté: Brookienergy no pretende ser una revolución, sino más bien suplir una necesidad puntual
y/o momentánea, sin embargo, lo publico licenciado bajo GNU GPL v2 para qué, si quieres estudiar su funcionamiento,
modificarlo, redistribuirlo o todo lo anterior en conjunción lo hagas.**

**Dependencias:**
```
[ACPI](https://sourceforge.net/projects/acpiclient/)
[PM-UTILS](https://pm-utils.freedesktop.org/wiki/)
```

