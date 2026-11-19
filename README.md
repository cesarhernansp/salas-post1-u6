# salas-post1-u6

## Descripción

Laboratorio de la Unidad 6 de Arquitectura de Computadores (post-contenido): instrucciones x86 y modos de direccionamiento, programados en NASM y verificados con DEBUG sobre DOSBox, en un único repositorio.

- **Estudiante:** Cesar Hernan Salas Peñaranda (cuenta de GitHub `cesarhernansp`)
- **Parte 1:** `lab6_instrucciones.asm`, programa `.COM` con las cuatro categorías de instrucciones (transferencia, aritmética, lógica y control de flujo), una variante factorial del bucle y un Bloque 5 que contrasta `ROL`/`ROR` con `SHL`/`SHR`.
- **Parte 2:** `lab6_modos.asm`, programa `.COM` que demuestra los modos de direccionamiento inmediato, directo, indirecto por registro e indexado, más un marco de pila con `BP` y el acceso a una matriz 3×3 con doble indexación.

## Entorno de trabajo

| Componente | Versión / detalle |
|---|---|
| Sistema anfitrión | Windows 11 Home, 16 GB de RAM |
| Emulador | DOSBox-X 2026.10.01 (ver nota) |
| Ensamblador | NASM 3.02 para DOS (`nasm.exe`, requiere el host DPMI `cwsdpmi.exe`) |
| Depurador | `DEBUG.EXE` de DOSBox-X (`Z:\DOS\DEBUG.EXE`) |
| Editor | VS Code / editor de texto plano; archivos `.asm` en ASCII sin BOM |

**Por qué DOSBox-X.** Los nombres de archivo del laboratorio (`lab6_instrucciones.asm`, `lab6_modos.asm`) exceden el formato 8.3 de DOS, que DOSBox 0.74 no admite. DOSBox-X con `lfn=true` (en `dosbox.conf`) sí los maneja, y además incluye un `DEBUG.EXE`, del que DOSBox 0.74 carece. `nasm.exe` y `cwsdpmi.exe` se copian a la raíz del proyecto (que se monta como `C:\`), pero no se versionan por ser binarios de terceros.

## Compilación y ejecución

```
Z:\> mount C C:\Users\Cesar\salas-post1-u6
Z:\> C:
C:\> cwsdpmi -p
C:\> nasm -v
C:\> nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com
C:\> nasm -f bin lab6_modos.asm -o lab6_modos.com
```

Para depurar, se carga el `.com` en DEBUG con el nombre corto que DOS asigna al archivo largo (`debug lab6_i~1.com`, `debug lab6_m~1.com`).
