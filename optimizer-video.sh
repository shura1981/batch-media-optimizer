#!/bin/bash

# Valores por defecto
q=23
mode="vertical"
fps=30
audio_bitrate=96
input_dir="."
output_dir="videos_renderizados"
overwrite=false
delete_originals=false

# Función para mostrar ayuda
show_help() {
  echo "Uso: $0 [opciones]"
  echo ""
  echo "Opciones:"
  echo "  -q calidad              Calidad de compresión (CRF). Valores típicos entre 18 y 30."
  echo "                          (por defecto: 23)"
  echo "  -m modo                 Modo de resolución. Valores aceptados:"
  echo "                            mobile       -> 720x1280 (9:16)"
  echo "                            vertical     -> 1080x1920 (9:16)"
  echo "                            desktop      -> 1280x720 (16:9)"
  echo "                            hd           -> 1920x1080 (16:9)"
  echo "                            auto         -> Ajusta al video original"
  echo "                          (por defecto: vertical)"
  echo "  -f fps                  Fotogramas por segundo. Ejemplos: 24, 15"
  echo "                          (por defecto: 30)"
  echo "  -b bitrate_audio        Bitrate del audio en kbps. Ejemplos: 64, 96, 128"
  echo "                          (por defecto: 96)"
  echo "  -i directorio_entrada   Carpeta con los videos a procesar"
  echo "                          (por defecto: .)"
  echo "  -o directorio_salida    Carpeta donde guardar los videos comprimidos"
  echo "                          (por defecto: videos_renderizados)"
  echo "  --overwrite             Sobreescribir archivos ya existentes"
  echo "  --delete-originals      Eliminar los videos originales después de comprimir"
  echo "  -h                      Muestra esta ayuda y termina"
  echo ""
  echo "Extensiones admitidas: .mp4, .mkv, .mov, .avi, etc."
  echo ""
  echo "Ejemplos:"
  echo "  $0 -m mobile -b 64 -i ./originales -o ./comprimidos --delete-originals"
  echo "  $0 -m hd -f 24 --overwrite"
  echo "  $0 -h"
  exit 0
}

# Procesar argumentos
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -q) q="$2"; shift ;;
    -m) mode="$2"; shift ;;
    -f) fps="$2"; shift ;;
    -b) audio_bitrate="$2"; shift ;;
    -i) input_dir="$2"; shift ;;
    -o) output_dir="$2"; shift ;;
    --overwrite) overwrite=true ;;
    --delete-originals) delete_originals=true ;;
    -h) show_help ;;
    *) echo "Parámetro desconocido: $1"; show_help; exit 1 ;;
  esac
  shift
done

# Validar modo y definir dimensiones
case "$mode" in
  mobile)
    target_width=720
    target_height=1280
    ;;
  vertical)
    target_width=1080
    target_height=1920
    ;;
  desktop)
    target_width=1280
    target_height=720
    ;;
  hd)
    target_width=1920
    target_height=1080
    ;;
  auto)
    target_width=-1
    target_height=-1
    ;;
  *)
    echo "Modo no válido: $mode"
    show_help
    ;;
esac

# Crear directorio de salida
mkdir -p "$output_dir"

# Inicializar contadores de tamaño
total_original=0
total_comprimido=0

echo "======================================================"
echo "Iniciando compresión de videos..."
echo "Calidad (CRF): $q"
if [ "$mode" == "auto" ]; then
  echo "Resolución objetivo: Mantener relación de aspecto original"
else
  echo "Resolución objetivo: ${target_width}x${target_height}"
fi
echo "FPS: $fps"
echo "Bitrate de audio: ${audio_bitrate}k"
echo "Carpeta de entrada: $input_dir"
echo "Carpeta de salida: $output_dir"
echo "Sobreescribir: $overwrite"
echo "Eliminar originales: $delete_originals"
echo "======================================================"

# Extensiones soportadas
extensions=("mp4" "mkv" "mov" "avi" "webm" "flv" "wmv" "mpg" "mpeg")

# Cambiar al directorio de entrada
cd "$input_dir" || { echo "No se puede acceder al directorio de entrada: $input_dir"; exit 1; }

# Función para convertir bytes a human-readable
human_readable() {
  local i=${1:-0} div=1 d=0
  local units=('B' 'KB' 'MB' 'GB' 'TB')
  while ((i > 512 && d < ${#units[@]})); do
    i=$((i / 1024))
    d=$((d + 1))
  done
  echo "$i ${units[$d]}"
}

# Procesar todos los archivos de video
for ext in "${extensions[@]}"; do
  for input_video in *.$ext; do
    if [ -f "$input_video" ]; then
      # Ruta completa del archivo original
      full_input="$input_dir/$input_video"
      # Nombre base sin extensión
      base_name="${input_video%.*}"
      # Archivo de salida
      output_video="$output_dir/${base_name}.mp4"

      # Si ya existe y no se permite sobreescribir, saltar
      if [ -f "$output_video" ] && [ "$overwrite" = false ]; then
        echo "Saltando: $input_video (ya existe en destino)"
        original_size=$(stat -c%s "$full_input" 2>/dev/null || echo 0)
        total_original=$((total_original + original_size))
        total_comprimido=$((total_comprimido + $(stat -c%s "$output_video" 2>/dev/null)))
        echo "------------------------------------------------------"
        continue
      fi

      echo "Procesando video: $input_video"

      # Detectar ancho y alto originales si es modo auto
      if [ "$mode" == "auto" ]; then
        eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=width,height "$full_input" | head -n2)
        original_width=${streams_stream_0_width}
        original_height=${streams_stream_0_height}
        target_width=$original_width
        target_height=$original_height
        scale_filter="scale=-1:${target_height}"
      else
        scale_filter="scale=-1:${target_height},pad=${target_width}:${target_height}:(ow-iw)/2:(oh-ih)/2"
      fi

      # Obtener tamaño original antes de comprimir
      original_size=$(stat -c%s "$full_input" 2>/dev/null || echo 0)
      total_original=$((total_original + original_size))

      # Comando FFmpeg
      ffmpeg -i "$full_input" \
             -vf "${scale_filter},setsar=1,fps=$fps" \
             -c:v libx264 -crf "$q" -preset fast -pix_fmt yuv420p \
             -c:a aac -b:a "${audio_bitrate}k" -ar 44100 \
             "$output_video" && \
      echo "Video comprimido guardado: $output_video"

      # Obtener tamaño comprimido
      compressed_size=$(stat -c%s "$output_video" 2>/dev/null || echo 0)
      total_comprimido=$((total_comprimido + compressed_size))

      # Eliminar original si se especificó
      if [ "$delete_originals" = true ]; then
        rm "$full_input"
        echo "Archivo original eliminado: $full_input"
      fi

      echo "------------------------------------------------------"
    fi
  done
done

# Mostrar informe final
echo "======================================================"
echo "✅ Todos los videos han sido procesados."

if (( total_original > 0 )); then
  ahorro=$((total_original - total_comprimido))
  porcentaje=$((100 - (total_comprimido * 100 / total_original)))

  hr_original=$(human_readable "$total_original")
  hr_comprimido=$(human_readable "$total_comprimido")
  hr_ahorro=$(human_readable "$ahorro")

  echo ""
  echo "📊 Informe de tamaño ahorrado:"
  echo "Tamaño original total: $hr_original"
  echo "Tamaño comprimido total: $hr_comprimido"
  echo "Ahorro total: $hr_ahorro"
  echo "Reducción promedio: $porcentaje%"
  echo ""
fi

echo "✅ Proceso completado."
