# Optimizador de videos para web

Herramienta de línea de comandos basada en Bash y FFmpeg para preparar videos
destinados a sitios web. Puede trabajar con un archivo individual o con todos
los videos de un directorio, comprimirlos a MP4/H.264, conservar o cambiar su
resolución, eliminar audio, activar `fast start` y generar una portada WebP a
partir del primer fotograma clave.

La herramienta está especialmente preparada para videos de secciones **hero**,
pero también sirve para videos normales que deban conservar audio.

Versión documentada: **2.3.0**.

## Contenido

```text
tools/optimizar-videos/
├── optimizar-videos   Script ejecutable
└── README.md          Documentación
```

## Qué problema resuelve

Un archivo exportado desde una cámara o un editor puede tener uno o varios de
estos problemas:

- Resolución mayor de la necesaria.
- Contenedor o códec con compatibilidad limitada en navegadores.
- Bitrate demasiado alto.
- Pista de audio innecesaria en un hero silenciado.
- Índice interno `moov` al final del MP4.
- Ausencia de una portada ligera.
- Necesidad de recordar comandos FFmpeg extensos.

En su modo de compresión, el script produce:

```text
Contenedor:        MP4
Códec de video:    H.264 mediante libx264
Formato de color:  yuv420p
Etiqueta MP4:      avc1
Audio:             AAC o eliminado
Fast start:        activado
Portada opcional:  WebP
```

## Requisitos

El script necesita:

- Bash.
- FFmpeg con `libx264` y `libwebp`.
- FFprobe.
- `realpath`, `find`, `sort`, `grep`, `stat`, `cut` y `awk`.
- `numfmt` es opcional para mostrar tamaños legibles.

Comprobar las dependencias:

```bash
ffmpeg -version
ffprobe -version
```

En Ubuntu o Debian:

```bash
sudo apt update
sudo apt install ffmpeg
```

Comprobar la herramienta desde el proyecto:

```bash
./tools/optimizar-videos/optimizar-videos --version
./tools/optimizar-videos/optimizar-videos --help
```

## Permiso de ejecución

El archivo no necesita extensión `.sh`. La primera línea indica el intérprete:

```bash
#!/usr/bin/env bash
```

Debe tener permiso de ejecución:

```bash
chmod +x ./tools/optimizar-videos/optimizar-videos
```

## Instalación opcional como comando

La instalación mediante enlace simbólico debe realizarla el usuario. No es
necesaria para ejecutar el archivo directamente.

Una ubicación personal habitual es `~/.local/bin`:

```bash
ln -s \
  "/ruta/absoluta/al/proyecto/tools/optimizar-videos/optimizar-videos" \
  "$HOME/.local/bin/optimizar-videos"
```

Después:

```bash
optimizar-videos --help
```

Para una instalación destinada a todos los usuarios se recomienda
`/usr/local/bin`, no `/bin` ni `/usr/bin`:

```bash
sudo ln -s \
  "/ruta/absoluta/al/proyecto/tools/optimizar-videos/optimizar-videos" \
  "/usr/local/bin/optimizar-videos"
```

Esta herramienta no crea enlaces simbólicos automáticamente.

## Inicio rápido

### Hero de escritorio que necesita compresión

```bash
optimizar-videos ./portada.mov --hero --mode desktop --poster
```

Produce:

```text
videos_renderizados/
├── portada.mp4
└── portada-poster.webp
```

El MP4:

- Se convierte a H.264.
- Mide `1280x720`.
- Cubre el lienzo con un recorte centrado.
- Conserva los FPS originales.
- No contiene audio.
- Tiene `fast start`.

### Hero móvil que necesita compresión

```bash
optimizar-videos ./portada-mobile.mov --hero --mode mobile --poster
```

El resultado mide `720x1280`.

### Hero que conserva su resolución

```bash
optimizar-videos ./portada.mp4 --hero --poster
```

Sin `--mode`, se utiliza `auto`. Se conserva la resolución original. Si una
dimensión es impar, puede reducirse un píxel para mantener compatibilidad con
H.264 y `yuv420p`.

### Hero que ya tiene buen peso y resolución

```bash
optimizar-videos ./portada.mp4 --hero-copy --poster
```

Este modo:

- No recomprime los fotogramas.
- No cambia resolución, FPS ni calidad visual.
- Elimina el audio.
- Aplica `fast start`.
- Genera la portada si se solicitó.

`--hero-copy` se recomienda principalmente para MP4/H.264 ya optimizados.

### Carpeta completa

```bash
optimizar-videos ./mis-videos --hero --mode desktop
```

### Carpeta y subdirectorios

```bash
optimizar-videos ./mis-videos --recursive --hero --mode desktop
```

### Simular antes de ejecutar

```bash
optimizar-videos ./portada.mov \
  --hero \
  --mode desktop \
  --poster \
  --dry-run
```

`--dry-run` muestra las operaciones sin crear, borrar o modificar archivos.

## Elegir entre `--hero` y `--hero-copy`

| Estado de la entrada | Opción |
|---|---|
| Exportación original pesada | `--hero` |
| Video 4K que se usará a 720p | `--hero --mode desktop` |
| Archivo MOV, MKV, AVI o WebM | `--hero` |
| Códec desconocido | `--hero` |
| MP4/H.264 con buen peso y resolución | `--hero-copy` |
| Solo necesita `fast start` y eliminar audio | `--hero-copy` |

Si hay dudas, debe preferirse `--hero`, porque convierte la salida a un formato
predecible para web.

## Entradas admitidas

### Archivo individual

Ruta relativa:

```bash
optimizar-videos ./videos/portada.MOV --hero
```

Ruta absoluta:

```bash
optimizar-videos /home/usuario/Videos/portada.MOV --hero
```

Al recibir un archivo, FFprobe inspecciona su contenido. La validación no depende
únicamente de su extensión.

### Directorio

```bash
optimizar-videos ./videos --hero
```

Al procesar un directorio, busca:

```text
.mp4
.mkv
.mov
.m4v
.avi
.webm
.flv
.wmv
.mpg
.mpeg
```

La búsqueda no diferencia mayúsculas de minúsculas. También reconoce `.MP4`,
`.MOV`, `.WebM` y otras combinaciones.

Sin `--recursive`, procesa únicamente los archivos directamente contenidos en
la carpeta. Con `--recursive`, recorre sus subdirectorios.

### Pistas seleccionadas

En la compresión normal se utiliza:

- La primera pista de video.
- La primera pista de audio, si existe y no se elimina.

Las pistas de subtítulos y datos no se copian.

## Directorio de construcción

Si no se indica `--output`, los resultados se guardan en
`videos_renderizados`.

Para un archivo:

```text
/videos/portada.mov
    ↓
/videos/videos_renderizados/portada.mp4
```

Para un directorio:

```text
/videos/
├── portada.mov
└── producto.mp4
    ↓
/videos/videos_renderizados/
├── portada.mp4
└── producto.mp4
```

Salida personalizada:

```bash
optimizar-videos ./videos --output ./build/videos --hero
```

Las rutas relativas se interpretan desde el directorio actual. Antes de
procesar, el script convierte entrada y salida en rutas absolutas.

## Limpieza de construcción

Por defecto, antes de cada ejecución se elimina el contenido del directorio de
salida. Esto evita conservar resultados obsoletos.

La limpieza incluye protecciones:

- Entrada y salida no pueden ser el mismo directorio.
- `/` no puede ser la salida.
- El directorio personal completo no puede ser la salida.
- La salida no puede ser un enlace simbólico.
- La salida no puede contener al directorio de entrada.

Para conservar la construcción anterior:

```bash
optimizar-videos ./videos --no-clean
```

Con `--no-clean`, las salidas existentes se omiten. Para reemplazarlas:

```bash
optimizar-videos ./videos --no-clean --overwrite
```

La simulación `--dry-run` nunca limpia el directorio.

## Resolución

`--mode` o `-m` controla las dimensiones:

| Modo | Resolución | Uso |
|---|---:|---|
| `auto` | Original | Conservar dimensiones |
| `mobile` | 720x1280 | Hero vertical móvil |
| `vertical` | 1080x1920 | Vertical Full HD |
| `desktop` | 1280x720 | Hero horizontal ligero |
| `hd` | 1920x1080 | Horizontal Full HD |
| `fullhd` | 1920x1080 | Alias de `hd` |

Valor predeterminado: `auto`.

Ejemplo:

```bash
optimizar-videos ./portada-4k.mov --hero --mode desktop
```

Un original `3840x2160` se convierte en `1280x720`.

## Ajuste al lienzo

`--fit` controla cómo se adapta el video a una resolución fija.

### `cover`

```bash
optimizar-videos ./portada.mov --mode desktop --fit cover
```

- Llena completamente el lienzo.
- Conserva la proporción.
- Recorta de forma centrada lo que exceda.
- Evita franjas negras.
- Es el ajuste predeterminado de `--hero`.

### `contain`

```bash
optimizar-videos ./portada.mov --mode desktop --fit contain
```

- Muestra el video completo.
- Conserva la proporción.
- Agrega franjas negras si las proporciones no coinciden.

Las opciones se evalúan de izquierda a derecha. `--hero` establece `cover`.
Para cambiarlo, se escribe `--fit contain` después de `--hero`:

```bash
optimizar-videos ./portada.mov \
  --hero \
  --mode desktop \
  --fit contain
```

## Calidad de video: CRF

`--crf` o `-q` controla la calidad H.264:

```bash
optimizar-videos ./portada.mov --hero --crf 23
```

Un valor menor produce mayor calidad y normalmente más peso.

| CRF | Resultado aproximado |
|---:|---|
| 18-20 | Calidad muy alta, archivo grande |
| 21-23 | Alta calidad; recomendado para hero |
| 24-26 | Mayor compresión |
| 27 o más | Pérdida visual más evidente |

Valor predeterminado: `23`.

CRF se ignora con `--faststart-only` y `--hero-copy`.

## Fotogramas por segundo

`--fps` o `-f` controla los FPS:

```bash
optimizar-videos ./portada.mov --hero --fps 24
```

| Valor | Comportamiento |
|---|---|
| `source` | Conserva los FPS originales |
| `30` | Movimiento fluido habitual |
| `24` | Apariencia cinematográfica y posible menor peso |
| `15` | Menor peso y menor fluidez |

Valor predeterminado: `source`.

Reducir FPS puede disminuir el peso. Aumentarlos no crea movimiento real:
FFmpeg repite fotogramas.

FPS se ignora con `--faststart-only` y `--hero-copy`.

## Preset de compresión

`--preset` o `-p` controla el tiempo que x264 dedica a buscar una compresión
eficiente:

```bash
optimizar-videos ./portada.mov --hero --preset slow
```

Valores:

```text
ultrafast
superfast
veryfast
faster
fast
medium
slow
slower
veryslow
```

| Preset | Característica |
|---|---|
| `fast` | Rápido, archivo potencialmente mayor |
| `medium` | Equilibrio predeterminado |
| `slow` | Recomendado cuando importa reducir peso |

Con el mismo CRF, un preset lento suele producir un archivo más eficiente, pero
tarda más. No determina directamente la calidad.

El preset se ignora con `--faststart-only` y `--hero-copy`.

## Audio

En una compresión normal, la primera pista de audio se convierte a AAC.

`--audio-bitrate` o `-b` controla su bitrate:

```bash
optimizar-videos ./entrevista.mov --audio-bitrate 128
```

| Kbps | Uso |
|---:|---|
| 64 | Voz |
| 96 | Calidad general para web |
| 128 | Música |
| 192 | Mayor calidad y peso |

Valor predeterminado: `96`.

Eliminar audio:

```bash
optimizar-videos ./portada.mov --mute
```

`--hero` y `--hero-copy` eliminan el audio automáticamente. En esos casos,
`--audio-bitrate` no tiene efecto.

Con `--faststart-only`, el audio se copia sin recomprimir, salvo que también se
use `--mute`.

## Fast start, `moov` y `mdat`

Dos secciones importantes de un MP4 son:

- `mdat`: fotogramas y datos multimedia.
- `moov`: duración, tiempos e índice de fotogramas.

Sin optimización:

```text
[ mdat: datos ][ moov: índice ]
```

El navegador puede necesitar llegar al final para encontrar la información de
reproducción.

El script utiliza:

```text
-movflags +faststart
```

El resultado queda organizado así:

```text
[ moov: índice ][ mdat: datos ]
```

Esto permite iniciar antes mientras continúa la descarga. Todas las salidas MP4
reciben `fast start`. Después, el script verifica que `moov` esté antes de
`mdat`.

## Modo sin recompresión

`--faststart-only` copia el video:

```bash
optimizar-videos ./portada.mp4 --faststart-only
```

No modifica:

- Calidad visual.
- Resolución.
- FPS.
- Fotogramas.

Puede reorganizar el MP4, copiar el audio o eliminarlo con `--mute`.

`--hero-copy` representa el caso habitual:

```bash
--faststart-only --mute
```

Puede fallar si las pistas originales no son compatibles con MP4. En ese caso:

```bash
optimizar-videos ./archivo --hero
```

## Generación de portada

`--poster` extrae el primer fotograma clave del video resultante:

```bash
optimizar-videos ./portada.mov \
  --hero \
  --mode desktop \
  --poster
```

Genera:

```text
videos_renderizados/portada.mp4
videos_renderizados/portada-poster.webp
```

La portada se extrae después de procesar el video. Coincide con:

- La resolución final.
- El recorte `cover`.
- Las franjas de `contain`, si existen.
- El encuadre publicado.

Calidad WebP:

```bash
--poster-quality 82
```

| Calidad | Resultado |
|---:|---|
| 70-79 | Menor peso |
| 80-85 | Equilibrio recomendado |
| 86-95 | Mayor calidad y peso |

`--poster-quality` activa automáticamente `--poster`.

Ejemplo HTML:

```html
<video
  muted
  autoplay
  playsinline
  loop
  preload="auto"
  poster="/video/portada-poster.webp">
  <source src="/video/portada.mp4" type="video/mp4">
</video>
```

Si el video comienza con una pantalla negra, el primer fotograma clave también
puede ser negro.

## Procesamiento recursivo

```bash
optimizar-videos ./videos --recursive --hero
```

La estructura relativa se conserva:

```text
videos/
├── campañas/
│   └── portada.mov
└── productos/
    └── demo.mp4

videos/videos_renderizados/
├── campañas/
│   └── portada.mp4
└── productos/
    └── demo.mp4
```

El directorio de construcción se excluye para no reprocesar resultados.

## Temporales y validación

Cada salida se genera primero con un nombre temporal:

```text
portada.mp4.part-<PID>.mp4
```

Flujo:

1. FFmpeg genera el MP4 temporal.
2. FFprobe verifica que contenga video.
3. Se comprueba `moov` antes de `mdat`.
4. El temporal se mueve al nombre definitivo.
5. Si se pidió portada, se genera y valida el WebP.
6. Solo entonces puede eliminarse el original.

Las señales `INT` y `TERM` limpian el temporal en curso.

## Eliminación de originales

Por defecto, los originales no se modifican ni eliminan.

```bash
optimizar-videos ./videos --hero --delete-originals
```

`--delete-originals` elimina cada entrada solamente después de validar el video
y la portada solicitada. Debe utilizarse con cuidado.

## Simulación

```bash
optimizar-videos ./videos \
  --hero \
  --mode desktop \
  --poster \
  --dry-run
```

La simulación:

- No limpia la salida.
- No crea archivos.
- No ejecuta conversiones.
- Muestra comandos y rutas.
- Sí inspecciona las entradas.

## Referencia completa

| Opción | Descripción |
|---|---|
| `-i`, `--input RUTA` | Archivo o directorio |
| `-o`, `--output DIRECTORIO` | Directorio de construcción |
| `-q`, `--crf NUMERO` | Calidad H.264 de 0 a 51 |
| `-m`, `--mode MODO` | auto, mobile, vertical, desktop, hd o fullhd |
| `-f`, `--fps FPS` | FPS numéricos o `source` |
| `-b`, `--audio-bitrate KBPS` | Bitrate AAC |
| `-p`, `--preset PRESET` | Velocidad/eficiencia x264 |
| `--fit contain\|cover` | Ajuste al lienzo |
| `--hero` | H.264, sin audio, cover y fast start |
| `--hero-copy` | Copia video, elimina audio y aplica fast start |
| `--mute`, `--no-audio` | Elimina audio |
| `--faststart-only` | No recomprime fotogramas |
| `--poster` | Genera `<nombre>-poster.webp` |
| `--poster-quality NUMERO` | Calidad WebP de 1 a 100 |
| `-r`, `--recursive` | Incluye subdirectorios |
| `--overwrite` | Reemplaza salidas con `--no-clean` |
| `--no-clean` | Conserva la construcción anterior |
| `--delete-originals` | Elimina originales validados |
| `--dry-run` | Simula sin modificar |
| `-h`, `--help` | Muestra ayuda |
| `-V`, `--version` | Muestra versión |

## Ejemplos completos

### Hero horizontal con portada

```bash
optimizar-videos ./original.mov \
  --hero \
  --mode desktop \
  --crf 23 \
  --preset slow \
  --poster \
  --poster-quality 82
```

### Hero vertical

```bash
optimizar-videos ./original-vertical.MOV \
  --hero \
  --mode mobile \
  --crf 23 \
  --poster
```

### MP4 ya comprimido

```bash
optimizar-videos ./portada.mp4 --hero-copy --poster
```

### Video normal con audio

```bash
optimizar-videos ./entrevista.mov \
  --mode desktop \
  --audio-bitrate 128 \
  --crf 22
```

### Biblioteca completa

```bash
optimizar-videos /home/usuario/Videos \
  --recursive \
  --output /home/usuario/build/videos \
  --crf 24 \
  --preset slow
```

## Solución de problemas

### No se encontró FFmpeg

```bash
command -v ffmpeg
command -v ffprobe
```

Instalar las dependencias si no aparecen.

### No se encontró una pista de video válida

El archivo puede estar dañado, contener solo audio o utilizar un formato no
admitido por la instalación actual.

```bash
ffprobe -hide_banner ./archivo
```

### `--hero-copy` falla

Las pistas originales pueden ser incompatibles con MP4. Usar:

```bash
optimizar-videos ./archivo --hero
```

### El resultado pesa más

Posibles causas:

- Aumento de resolución.
- Aumento de FPS.
- Original ya muy comprimido.
- CRF bajo.
- Preset muy rápido.
- La portada cuenta en el total final.

Probar:

```bash
optimizar-videos ./archivo --hero --crf 25 --preset slow
```

### La portada está negra

El primer keyframe puede ser negro. Actualmente `--poster` lo respeta. Una
mejora futura permitirá seleccionar un tiempo o una escena.

### El hero tiene franjas negras

Usar `cover`:

```bash
optimizar-videos ./archivo --hero --mode desktop --fit cover
```

### El hero aparece recortado

Usar `contain`:

```bash
optimizar-videos ./archivo \
  --hero \
  --mode desktop \
  --fit contain
```

### Desapareció una construcción anterior

La limpieza es el comportamiento predeterminado. Para conservarla:

```bash
optimizar-videos ./videos --no-clean
```

### Dos entradas generan el mismo nombre

`portada.mov` y `portada.mp4` producirían ambos `portada.mp4`. El script detecta
el conflicto. Se debe renombrar una entrada o separarlas.

## Mejoras futuras

Estas mejoras son viables, pero no pertenecen a la versión actual.

### 1. Portada por tiempo

```bash
--poster-at 1.5
```

Extraería la portada a los 1.5 segundos para evitar un inicio negro.

### 2. Portada inteligente

Analizar varios fotogramas y seleccionar uno:

- No negro.
- Enfocado.
- Con contraste suficiente.
- Con rostro o producto visible.

También podría generarse una hoja de contacto.

### 3. Paquete responsive

```bash
--responsive-hero
```

Podría producir en una ejecución:

```text
portada-desktop.mp4
portada-desktop-poster.webp
portada-mobile.mp4
portada-mobile-poster.webp
```

### 4. Códecs modernos

Generar variantes:

- H.264/MP4 para compatibilidad.
- VP9/WebM.
- AV1/MP4 o AV1/WebM.
- HEVC para plataformas compatibles.

También podría generar el HTML con varios `<source>`.

### 5. Tamaño o bitrate objetivo

```bash
--target-size 2M
--video-bitrate 900k
--two-pass
```

CRF prioriza calidad constante, pero no garantiza un peso exacto. Dos pasadas
serían útiles con límites estrictos.

### 6. Decisión automática

```bash
--hero-auto
```

Podría analizar:

- Contenedor y códec.
- Resolución y FPS.
- Bitrate y peso por segundo.
- Posición de `moov`.
- Presencia de audio.

Después decidiría entre copiar o comprimir y explicaría la decisión.

### 7. Aceleración por hardware

Soporte opcional para:

- NVIDIA NVENC.
- Intel Quick Sync.
- VAAPI.
- Apple VideoToolbox.

Reduciría el tiempo, aunque podría producir archivos menos eficientes.

### 8. Procesamiento paralelo

```bash
--jobs 4
```

Procesaría varios archivos a la vez, protegiendo temporales, contadores y logs.

### 9. Informe JSON

```json
{
  "input": "portada.mov",
  "output": "portada.mp4",
  "input_size": 50331648,
  "output_size": 2097152,
  "resolution": "1280x720",
  "fps": 30,
  "codec": "h264",
  "faststart": true,
  "poster": "portada-poster.webp"
}
```

Esto facilitaría integración con Node.js y CI/CD.

### 10. HLS y MPEG-DASH

Para contenido largo:

- HLS con `.m3u8`.
- MPEG-DASH con `.mpd`.
- Variantes de resolución y bitrate.

No suele ser necesario para un hero corto.

### 11. Recorte temporal

```bash
--start 2
--duration 8
```

Permitiría crear un hero corto desde un video largo.

### 12. Audio avanzado

- Varias pistas.
- Normalización EBU R128.
- Conversión a mono.
- Detección de audio prescindible.

### 13. Pruebas automatizadas

- ShellCheck.
- Pruebas Bats.
- Videos sintéticos pequeños.
- Casos con rutas y espacios.
- Entradas corruptas.
- Interrupciones.
- Verificación de resolución, audio, portada y fast start.

### 14. Instalador y desinstalador

Un instalador separado podría gestionar el enlace en `~/.local/bin` o
`/usr/local/bin`, comprobar `PATH` y desinstalar de forma reversible. No debería
solicitar privilegios durante una conversión.

## Criterios para contribuciones futuras

1. No modificar originales por defecto.
2. Resolver rutas antes de limpiar.
3. Rechazar destinos peligrosos.
4. Generar primero archivos temporales.
5. Validar antes de publicar.
6. Mantener `fast start` en MP4.
7. Documentar cuándo se recomprime.
8. Conservar `--dry-run` sin efectos.
9. Admitir nombres con espacios.
10. Explicar cualquier decisión automática.

## Historial resumido

### 2.3.0

- Portada WebP mediante `--poster`.
- Calidad configurable con `--poster-quality`.
- Extracción desde el primer keyframe de la salida final.

### 2.2.1

- Documentación de CRF, FPS, audio y presets.

### 2.2.0

- Archivos individuales.
- Rutas relativas y absolutas.

### 2.1.0

- Separación entre `--hero` y `--hero-copy`.

### 2.0.0

- Rutas absolutas robustas.
- Limpieza segura.
- Compresión H.264.
- Fast start y verificación de `moov`.
- Recursividad, simulación y validación.
