# jmRpt.sh

## Propósito

Este shell script tiene dos propósitos:

1. generar el reporte HTML usando el fichero generado por la ejecución de test de JMeter in modo CLI (Non-GUI).
2. archivar la información relevante al test

El script crea un directorio único (usando el sello del tiempo) donde se guardan los files requeridos para crear el reporte. Adicionalmente, el script copia los siguientes files al mencionado directorio:

1. ***.jmx** (jmeter script file)
2. ***.jtl** (jmeter log/bitácora file)
3. **jmeter.log** (jmeter run log file)
4. **errors.jtl** (log/bitácora de errores - opcional)

**NOTA 1:** El reporte será generado con una granularidad de 10 segundos. 

**NOTA 2:** Para obtener la bitácora de errores es necesario añadir el receptor [Simple Data Writer](https://jmeter.apache.org/usermanual/component_reference.html#Simple_Data_Writer). Este receptor debe ser configurado para solo capturar los errores.

## Uso

```
jmRpt.sh jtl-file
```

## Ejemplo

Primero, ejecutamos un test usando script JMeter llamado **escenario.jmx** (en modoCLI):

```
jmeter -n -t escenario.jmx -l escenario.jtl
```

**IMPORTANTE**: los nombres de los files deben usar **exactamente** el mismo prefijo.

Segundo, ejecutamos el script usando el file **jtl** como parámetro:
```
jmRpt.sh escenario.jtl
```

El script crea un directorio único con un sello del tiempo (por ejemplo: 2020-09-25_18:36:58.391). El listado del directorio será aproximadamente asi:

```
ls -l 2020-09-25_18:36:58.391
total 760
-rw-r--r--  1 carlos  staff   36657 Sep 26 19:05 escenario.jmx
-rw-r--r--  1 carlos  staff  293822 Sep 25 18:27 escenario.jtl
drwxr-xr-x  5 carlos  staff     160 Sep 25 18:37 content
-rw-r--r--@ 1 carlos  staff    9678 Sep 25 18:37 index.html
-rw-r--r--  1 carlos  staff    2598 Sep 25 18:34 jmeter.log
drwxr-xr-x  7 carlos  staff     224 Sep 25 18:37 sbadmin2-1.0.7
-rw-r--r--  1 carlos  staff     992 Sep 25 18:37 statistics.json
```

Finalmente, cambie de directorio y abra el reporte HTML en el browser:
```
open index.html
```

## Nota

Este script ha sido diseñado para ser ejecutado en Mac OS. Probablemente funcione en Linux.

## Disclaimer

This script come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause. 
