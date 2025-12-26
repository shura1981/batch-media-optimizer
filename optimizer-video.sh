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
# cd "$input_dir" || { echo "No se puede acceder al directorio de entrada: $input_dir"; exit 1; }

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
  # Buscar archivos en el directorio de entrada sin cambiar de directorio
  # Usamos process substitution < <() para evitar subshells y mantener los contadores globales
  while IFS= read -r -d '' full_input; do
    if [ -f "$full_input" ]; then
      # Nombre del archivo (basename)
      input_video=$(basename "$full_input")
      
      # Nombre base sin extensión
      base_name="${input_video%.*}"
      
      # Archivo de salida
      output_video="$output_dir/${base_name}.mp4"

      echo "Procesando video: $input_video"

      # Si ya existe y no se permite sobreescribir, saltar
      if [ -f "$output_video" ] && [ "$overwrite" = false ]; then
        echo "Saltando: $input_video (ya existe en destino)"
        
        # Sumar al total aunque se salte (para estadísticas)
        original_size=$(stat -c%s "$full_input" 2>/dev/null || echo 0)
        compressed_size=$(stat -c%s "$output_video" 2>/dev/null || echo 0)
        
        total_original=$((total_original + original_size))
        total_comprimido=$((total_comprimido + compressed_size))
        
        echo "------------------------------------------------------"
        continue
      fi

      # Obtener tamaño original
      original_size=$(stat -c%s "$full_input" 2>/dev/null || echo 0)

      # Construir filtro de video
      if [ "$mode" == "auto" ]; then
        vf="fps=$fps"
      else
        vf="scale=$target_width:$target_height:force_original_aspect_ratio=decrease,pad=$target_width:$target_height:(ow-iw)/2:(oh-ih)/2,fps=$fps"
      fi

      # Ejecutar ffmpeg
      # -nostdin es CRUCIAL cuando se ejecuta ffmpeg dentro de un bucle while read
      # Evita que ffmpeg "robe" la entrada estándar y rompa el bucle
      ffmpeg -nostdin -i "$full_input" -vf "$vf" -c:v libx264 -crf "$q" -preset medium -c:a aac -b:a "${audio_bitrate}k" "$output_video" -y -hide_banner -loglevel error

      if [ $? -eq 0 ]; then
        compressed_size=$(stat -c%s "$output_video" 2>/dev/null || echo 0)
        
        # Actualizar totales globales
        total_original=$((total_original + original_size))
        total_comprimido=$((total_comprimido + compressed_size))

        # Calcular ahorro individual
        saved=$((original_size - compressed_size))
        if [ $original_size -gt 0 ]; then
            percent=$(( (saved * 100) / original_size ))
        else
            percent=0
        fi

        echo "Completado: $input_video"
        echo "Original:   $(human_readable $original_size)"
        echo "Comprimido: $(human_readable $compressed_size)"
        echo "Ahorro:     $(human_readable $saved) ($percent%)"

        if [ "$delete_originals" = true ]; then
          rm "$full_input"
          echo "Original eliminado."
        fi
      else
        echo "Error al procesar $input_video"
      fi
      echo "------------------------------------------------------"
    fi
  done < <(find "$input_dir" -maxdepth 1 -name "*.$ext" -print0)
done

echo "======================================================"
echo "✅ Todos los videos han sido procesados."

if (( total_original > 0 )); then
  ahorro=$((total_original - total_comprimido))
  if [ $total_original -gt 0 ]; then
      porcentaje=$((100 - (total_comprimido * 100 / total_original)))
  else
      porcentaje=0
  fi

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

echo "Videos guardados en: $output_dir"
echo "======================================================"



