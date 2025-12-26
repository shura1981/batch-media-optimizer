# 🎨 Media Optimization Scripts

Scripts de optimización de medios desarrollados en Bash para comprimir y optimizar imágenes y videos de manera eficiente.

## 📋 Descripción

Este repositorio contiene dos utilidades de línea de comandos diseñadas para la optimización automatizada de medios:

- **`optimizer-image.sh`**: Compresión, redimensionamiento y conversión de imágenes usando ImageMagick
- **`optimizer-video.sh`**: Compresión de videos con presets de resolución múltiples usando FFmpeg
- **`convert_audio.sh`**: Conversión de audio y extracción de audio desde video usando FFmpeg

Ambas herramientas están diseñadas para procesamiento por lotes con confirmación interactiva, reportes de ahorro de espacio y soporte para directorios personalizados.

## 🛠️ Stack Tecnológico

- **Lenguaje**: Bash (shell scripting puro)
- **Dependencias externas**:
  - [ImageMagick](https://imagemagick.org/) - Para procesamiento de imágenes
  - [FFmpeg](https://ffmpeg.org/) - Para procesamiento de videos
- **Sistema operativo**: Linux/Unix (compatible con macOS)

## 📦 Requisitos e Instalación

### Prerequisitos

Asegúrate de tener instaladas las siguientes herramientas:

#### Ubuntu/Debian
```bash
# Instalar ImageMagick
sudo apt update
sudo apt install imagemagick

# Instalar FFmpeg
sudo apt install ffmpeg
```

#### Fedora/RHEL/CentOS
```bash
# Instalar ImageMagick
sudo dnf install ImageMagick

# Instalar FFmpeg
sudo dnf install ffmpeg
```

#### macOS (usando Homebrew)
```bash
# Instalar ImageMagick
brew install imagemagick

# Instalar FFmpeg
brew install ffmpeg
```

#### Arch Linux
```bash
# Instalar ImageMagick
sudo pacman -S imagemagick

# Instalar FFmpeg
sudo pacman -S ffmpeg
```

### Verificar Instalación

```bash
# Verificar ImageMagick
convert --version

# Verificar FFmpeg
ffmpeg -version
```

### Configuración de Scripts

1. Clonar el repositorio:
```bash
git clone <url-del-repositorio>
cd scrips
```

2. Dar permisos de ejecución a los scripts:
```bash
chmod +x optimizer-image.sh
chmod +x optimizer-video.sh
chmod +x convert_audio.sh
```

## 🖼️ Uso: Optimizador de Imágenes

### Opciones Disponibles

| Alias Corto | Opción Larga | Descripción | Valor por Defecto |
|-------------|--------------|-------------|-------------------|
| `-q` | `--quality` | Nivel de calidad (1-100) | 85 |
| `-w` | `--width` | Ancho máximo en píxeles | Sin límite |
| `-f` | `--format` | Formato de salida (jpg, png, webp) | Original |
| `-i` | `--dir-input` | Directorio de entrada | Directorio actual |
| `-o` | `--dir-output` | Directorio de salida | `optimized/` |
| `-h` | `--help` | Mostrar ayuda | - |

### Formatos Soportados

- **Entrada**: JPG, JPEG, PNG
- **Salida**: JPG, JPEG, PNG, WebP

### Ejemplos de Uso

```bash
# Optimización básica con calidad 80
./optimizer-image.sh -q 80

# Convertir a WebP con calidad 90
./optimizer-image.sh -f webp -q 90

# Redimensionar y convertir a JPG
./optimizer-image.sh -f jpg -q 85 -w 1920

# Procesar imágenes de un directorio específico
./optimizer-image.sh -i public/img -f webp

# Personalizar directorio de salida
./optimizer-image.sh -i public/img -o public/optimized -f webp

# Uso completo con todas las opciones
./optimizer-image.sh -i source/images -o output/compressed -f webp -q 90 -w 1920
```

### Características Especiales

- **Conversión a WebP**: Optimización especial para formato WebP con excelente compresión
- **Compresión PNG**: Usa nivel máximo de compresión (9) sin pérdida
- **Eliminación de metadatos**: Automáticamente elimina metadatos EXIF con `-strip`
- **Preservación de aspecto**: El redimensionamiento mantiene la relación de aspecto original

## 🎬 Uso: Optimizador de Videos

### Opciones Disponibles

| Opción | Descripción | Valor por Defecto |
|--------|-------------|-------------------|
| `-q` | Calidad CRF (18-30, menor = mejor) | 23 |
| `-m` | Modo de resolución | `vertical` |
| `-f` | Fotogramas por segundo | 30 |
| `-b` | Bitrate de audio (kbps) | 96 |
| `-i` | Directorio de entrada | Directorio actual |
| `-o` | Directorio de salida | `videos_renderizados/` |
| `--overwrite` | Sobreescribir archivos existentes | `false` |
| `--delete-originals` | Eliminar originales tras comprimir | `false` |
| `-h` | Mostrar ayuda | - |

### Modos de Resolución

| Modo | Resolución | Relación de Aspecto | Uso Recomendado |
|------|-----------|---------------------|-----------------|
| `mobile` | 720x1280 | 9:16 | Contenido móvil |
| `vertical` | 1080x1920 | 9:16 | Redes sociales (Instagram, TikTok) |
| `desktop` | 1280x720 | 16:9 | Visualización en escritorio |
| `hd` | 1920x1080 | 16:9 | Full HD |
| `auto` | Original | Original | Mantiene dimensiones originales |

### Formatos Soportados

MP4, MKV, MOV, AVI, WebM, FLV, WMV, MPG, MPEG

### Ejemplos de Uso

```bash
# Comprimir videos para móvil
./optimizer-video.sh -m mobile -b 64

# Optimizar para redes sociales
./optimizer-video.sh -m vertical -q 20

# Full HD con 24 fps
./optimizer-video.sh -m hd -f 24

# Procesar directorio específico
./optimizer-video.sh -i ./originales -o ./comprimidos -m hd

# Eliminar originales después de comprimir
./optimizer-video.sh -m mobile -b 64 -i ./originales -o ./comprimidos --delete-originals

# Sobreescribir archivos existentes
./optimizer-video.sh -m hd -f 24 --overwrite

# Mantener resolución original con calidad específica
./optimizer-video.sh -m auto -q 20 -b 128
```

### Parámetros de Calidad CRF

- **18-20**: Calidad muy alta (archivos más grandes)
- **21-23**: Calidad alta (recomendado para la mayoría de casos)
- **24-26**: Calidad media-alta
- **27-30**: Calidad media (mayor compresión)

## 🎵 Uso: Convertidor de Audio

### Opciones Disponibles

| Alias Corto | Opción Larga | Descripción | Valor por Defecto |
|-------------|--------------|-------------|-------------------|
| `-f` | `--format` | Formato de salida (ogg, mp3) | `ogg` |
| `-i` | `--input` | Archivo o directorio de entrada | Directorio actual |
| `-o` | `--output` | Directorio de salida | `output_audio/` |
| `-e` | `--extensions` | Extensiones a buscar (solo modo directorio) | `wav` |
| `-h` | `--help` | Mostrar ayuda | - |

### Características

- **Conversión de Audio**: Convierte archivos de audio entre formatos soportados.
- **Extracción de Audio**: Extrae la pista de audio de archivos de video.
- **Modo Dual**: Funciona tanto con archivos individuales como con directorios completos.
- **Búsqueda Flexible**: Soporta múltiples extensiones y búsqueda insensible a mayúsculas.

### Ejemplos de Uso

```bash
# Convertir un archivo específico a MP3
./convert_audio.sh -i cancion.wav -f mp3

# Convertir todo un directorio a OGG (formato por defecto)
./convert_audio.sh -i ./musica

# Extraer audio de videos en una carpeta
./convert_audio.sh -i ./videos -e "mp4,mkv" -f mp3

# Convertir múltiples formatos de audio a la vez
./convert_audio.sh -i ./mezclado -e "wav,flac,m4a" -f ogg

# Especificar directorio de salida
./convert_audio.sh -i ./entrada -o ./salida_final -f mp3
```

## 📁 Estructura del Proyecto

```
scrips/
├── .git/                          # Control de versiones Git
├── .github/
│   ├── copilot-instructions.md    # Instrucciones para AI coding agents
│   └── prompts/
│       └── readme-blueprint-generator.prompt.md
├── .gitignore                     # Archivos ignorados por Git
├── convert_audio.sh               # Script de conversión de audio
├── optimizer-image.sh             # Script de optimización de imágenes
├── optimizer-video.sh             # Script de optimización de videos
├── public/                        # Directorio para archivos procesados (gitignored)
└── README.md                      # Este archivo
```

## 🔑 Características Principales

### Optimizador de Imágenes
- ✅ Compresión con control de calidad ajustable
- ✅ Redimensionamiento manteniendo relación de aspecto
- ✅ Conversión entre formatos (JPG, PNG, WebP)
- ✅ Eliminación automática de metadatos
- ✅ Procesamiento por lotes
- ✅ Directorios de entrada/salida personalizables
- ✅ Alias cortos para comandos rápidos
- ✅ Reporte de espacio ahorrado

### Optimizador de Videos
- ✅ Múltiples presets de resolución predefinidos
- ✅ Control de calidad mediante CRF
- ✅ Ajuste de FPS y bitrate de audio
- ✅ Detección automática de resolución original
- ✅ Soporte para múltiples formatos de entrada
- ✅ Salida estandarizada en MP4 (H.264 + AAC)
- ✅ Protección contra sobrescritura accidental
- ✅ Opción para eliminar archivos originales
- ✅ Reporte detallado de compresión

### Convertidor de Audio
- ✅ Conversión a formatos OGG y MP3
- ✅ Extracción de audio desde archivos de video
- ✅ Procesamiento de archivos individuales o directorios
- ✅ Soporte para múltiples extensiones de entrada
- ✅ Búsqueda insensible a mayúsculas/minúsculas
- ✅ Eliminación limpia de extensiones originales

## 🔒 Características de Seguridad

Ambos scripts incluyen características de seguridad para evitar pérdida de datos:

- **Confirmación interactiva**: Solicita confirmación antes de procesar archivos
- **Protección contra sobrescritura**: Por defecto, no sobrescribe archivos existentes
- **Eliminación controlada**: Los archivos originales solo se eliminan con flag explícito
- **Validación de argumentos**: Valida todos los parámetros de entrada
- **Verificación de directorios**: Comprueba que los directorios de entrada existen

## 📊 Flujo de Trabajo

### Para Imágenes

1. El script busca archivos de imagen en el directorio especificado
2. Muestra una lista de archivos a procesar y el tamaño total
3. Solicita confirmación del usuario
4. Crea el directorio de salida si no existe
5. Procesa cada imagen aplicando las transformaciones especificadas
6. Muestra el progreso de cada archivo
7. Calcula y reporta el espacio total ahorrado

### Para Videos

1. El script busca archivos de video en el directorio especificado
2. Muestra la configuración de compresión
3. Procesa cada video aplicando:
   - Escalado y padding según el modo seleccionado
   - Ajuste de FPS
   - Compresión con CRF especificado
   - Codec de audio AAC
4. Muestra el progreso de cada archivo
5. Opcionalmente elimina archivos originales
6. Calcula y reporta estadísticas de compresión

## 🎯 Casos de Uso

### Optimización Web
```bash
# Convertir todas las imágenes a WebP para web
./optimizer-image.sh -i assets/images -o assets/optimized -f webp -q 85 -w 1920
```

### Contenido para Redes Sociales
```bash
# Optimizar videos para Instagram/TikTok
./optimizer-video.sh -i raw_videos -o social_ready -m vertical -q 22 -b 128
```

### Preparación de Galería
```bash
# Redimensionar y comprimir imágenes para galería web
./optimizer-image.sh -i gallery_raw -o gallery_web -q 80 -w 1200
```

### Compresión de Archivo
```bash
# Comprimir videos antiguos para archivo
./optimizer-video.sh -i archive -o compressed_archive -m auto -q 26 --delete-originals
```

## 🧪 Estándares de Desarrollo

### Convenciones de Código

- **Indentación**: Espacios (no tabs)
- **Nombres de variables**: snake_case para variables globales, camelCase para locales
- **Validación**: Todos los parámetros de entrada deben ser validados
- **Mensajes de error**: Descriptivos y redirigidos a stderr
- **Ayuda**: Función `show_help()` completa con ejemplos

### Patrones de Validación

```bash
# Validación de número en rango
if [[ -n "$2" && "$2" =~ ^[0-9]+$ && "$2" -ge 1 && "$2" -le 100 ]]; then
    QUALITY="$2"
else
    echo "Error: --quality requiere un número entre 1 y 100." >&2
    exit 1
fi
```

### Cálculo de Tamaño Legible

```bash
human_readable() {
  local i=${1:-0} div=1 d=0
  local units=('B' 'KB' 'MB' 'GB' 'TB')
  while ((i > 512 && d < ${#units[@]})); do
    i=$((i / 1024))
    d=$((d + 1))
  done
  echo "$i ${units[$d]}"
}
```

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Al contribuir:

1. Mantén la compatibilidad hacia atrás
2. Valida todos los casos extremos de argumentos
3. Añade ejemplos a la función de ayuda
4. Prueba con diversos formatos de archivo
5. Documenta nuevas características en el README
6. Sigue los patrones de código existentes

### Áreas de Mejora Sugeridas

- Añadir barra de progreso para archivos grandes
- Soporte para procesamiento paralelo
- Modo silencioso (sin confirmación)
- Configuración mediante archivos de configuración
- Soporte para más formatos de imagen (GIF, TIFF, SVG)
- Estadísticas más detalladas por archivo

## 📝 Notas Técnicas

### ImageMagick
- Usa el comando `convert` con flag `-strip` para eliminar metadatos
- PNG: Compresión nivel 9 (`-define png:compression-level=9`)
- JPEG/WebP: Control de calidad mediante `-quality`
- Resize: Usa `-resize` con solo ancho para mantener aspecto

### FFmpeg
- Pipeline: `ffmpeg -i input -vf "scale,pad,fps" -c:v libx264 -crf CRF -c:a aac output`
- Video codec: libx264 (H.264)
- Audio codec: AAC
- Formato de salida: MP4
- Pixel format: yuv420p (máxima compatibilidad)

## 📄 Licencia

Este proyecto está disponible para uso libre. Consulta el archivo LICENSE para más detalles.

## 🔗 Enlaces Útiles

- [Documentación de ImageMagick](https://imagemagick.org/script/convert.php)
- [Guía de FFmpeg](https://ffmpeg.org/ffmpeg.html)
- [Guía CRF de FFmpeg](https://trac.ffmpeg.org/wiki/Encode/H.264#crf)
- [Especificación WebP](https://developers.google.com/speed/webp)

## 📞 Soporte

Para reportar problemas o sugerir mejoras, por favor abre un issue en el repositorio.

---

**Hecho con ❤️ para optimizar tus medios de manera eficiente**
