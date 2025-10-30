#!/bin/bash

# --- Default values ---
DEFAULT_QUALITY=85
DEFAULT_WIDTH=""
DEFAULT_FORMAT=""
DEFAULT_INPUT_DIR="."
DEFAULT_OUTPUT_DIR="optimized"

# --- Help function ---
show_help() {
    echo "Uso: ./optimizer.sh [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -q, --quality <num>      Establece el nivel de calidad para imágenes JPG/JPEG (1-100). Por defecto: $DEFAULT_QUALITY."
    echo "  -w, --width <num>        Establece el ancho máximo en píxeles para las imágenes, manteniendo la relación de aspecto."
    echo "  -f, --format <fmt>       Convierte las imágenes al formato especificado (jpg, jpeg, png, webp, etc.)."
    echo "                           Si no se especifica, mantiene el formato original."
    echo "  -i, --dir-input <path>   Directorio donde se encuentran las imágenes a optimizar. Por defecto: directorio actual."
    echo "  -o, --dir-output <path>  Directorio donde guardar las imágenes optimizadas. Por defecto: $DEFAULT_OUTPUT_DIR."
    echo "  -h, --help               Muestra esta ayuda y sale."
    echo ""
    echo "Ejemplos:"
    echo "  ./optimizer.sh -q 80 -w 1024"
    echo "  ./optimizer.sh --format webp --quality 90"
    echo "  ./optimizer.sh -f jpg -q 85 -w 800"
    echo "  ./optimizer.sh -i public/img -f webp"
    echo "  ./optimizer.sh --dir-input /home/user/images -q 90 -w 1920"
    echo "  ./optimizer.sh -i public/img -o public/optimized -f webp"
    echo "  ./optimizer.sh -o results -q 90"
}

# --- Argument parsing ---
QUALITY=$DEFAULT_QUALITY
WIDTH=$DEFAULT_WIDTH
FORMAT=$DEFAULT_FORMAT
INPUT_DIR=$DEFAULT_INPUT_DIR
OUTPUT_DIR=$DEFAULT_OUTPUT_DIR

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quality)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ && "$2" -ge 1 && "$2" -le 100 ]]; then
                QUALITY="$2"
                shift
            else
                echo "Error: --quality requiere un número entre 1 y 100." >&2
                exit 1
            fi
            ;;
        -w|--width)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                WIDTH="$2"
                shift
            else
                echo "Error: --width requiere un número." >&2
                exit 1
            fi
            ;;
        -f|--format)
            if [[ -n "$2" ]]; then
                FORMAT="$2"
                shift
            else
                echo "Error: --format requiere especificar un formato (jpg, jpeg, png, webp, etc.)." >&2
                exit 1
            fi
            ;;
        -i|--dir-input)
            if [[ -n "$2" ]]; then
                INPUT_DIR="$2"
                shift
            else
                echo "Error: --dir-input requiere especificar un directorio." >&2
                exit 1
            fi
            ;;
        -o|--dir-output)
            if [[ -n "$2" ]]; then
                OUTPUT_DIR="$2"
                shift
            else
                echo "Error: --dir-output requiere especificar un directorio." >&2
                exit 1
            fi
            ;;
        *)
            echo "Parámetro desconocido: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# --- Rest of the script ---

# Validar que el directorio de entrada existe
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: El directorio '$INPUT_DIR' no existe." >&2
    exit 1
fi

# Encuentra los archivos de imagen en el directorio especificado
files=$(find "$INPUT_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))

if [ -z "$files" ]; then
    echo "No se encontraron imágenes para optimizar en el directorio '$INPUT_DIR'."
    exit 0
fi

echo "Las siguientes imágenes se optimizarán y se guardarán en la carpeta '$OUTPUT_DIR':"
echo "$files" | sed "s|^$INPUT_DIR/||" | sed 's|^\./||' | while IFS= read -r file; do
    echo "- $file"
done

initial_size_bytes=$(du -bc $files 2>/dev/null | tail -n 1 | awk '{print $1}')
initial_size_human=$(du -h -c $files 2>/dev/null | tail -n 1 | awk '{print $1}')

echo
echo "Directorio de entrada: $INPUT_DIR"
echo "Directorio de salida: $OUTPUT_DIR"
echo "Nivel de calidad para JPG/JPEG: $QUALITY%"
if [ -n "$WIDTH" ]; then
    echo "Ancho de imagen: ${WIDTH}px"
fi
if [ -n "$FORMAT" ]; then
    echo "Formato de salida: $FORMAT"
else
    echo "Formato de salida: mantener original"
fi
echo "Tamaño total antes de la optimización: $initial_size_human"
echo

read -p "¿Deseas proceder con la optimización? (s/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Optimización cancelada."
    exit 1
fi

# Crea el directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"

echo "Optimizando imágenes..."

# Itera sobre cada archivo para procesarlo con 'convert'
echo "$files" | while IFS= read -r file; do
    # Obtener solo el nombre del archivo (sin la ruta del directorio)
    filename=$(basename "$file")
    base_name="${filename%.*}"
    
    # Definir extensión de salida
    if [ -n "$FORMAT" ]; then
        output_extension="$FORMAT"
        output_file="${base_name}.${FORMAT}"
    else
        output_file="$filename"
    fi
    
    # Define la ruta de salida
    output_path="$OUTPUT_DIR/$output_file"
    
    # Build the convert command
    convert_cmd="convert \"$file\" -strip"

    if [ -n "$WIDTH" ]; then
        convert_cmd="$convert_cmd -resize ${WIDTH}x"
    fi

    # Aplicar configuración de calidad según el formato final
    if [ -n "$FORMAT" ]; then
        case "${FORMAT,,}" in
            jpg|jpeg)
                convert_cmd="$convert_cmd -quality $QUALITY"
                ;;
            webp)
                # WebP usa un rango de calidad similar pero optimizado
                convert_cmd="$convert_cmd -quality $QUALITY"
                ;;
            png)
                # PNG es sin pérdida, pero podemos optimizar la compresión
                convert_cmd="$convert_cmd -define png:compression-level=9"
                ;;
        esac
    else
        # Mantener formato original, aplicar calidad si es JPEG
        if [[ "$file" == *.jpg ]] || [[ "$file" == *.jpeg ]] || [[ "$file" == *.JPG ]] || [[ "$file" == *.JPEG ]]; then
            convert_cmd="$convert_cmd -quality $QUALITY"
        fi
    fi

    convert_cmd="$convert_cmd \"$output_path\""

    eval $convert_cmd
    
    # Mostrar progreso
    echo "Procesado: $filename -> $output_file"
done

echo "Optimización completada. Las nuevas imágenes están en la carpeta '$OUTPUT_DIR'."

# Calcula el tamaño total de los archivos optimizados
final_size_bytes=$(du -bc "$OUTPUT_DIR"/* 2>/dev/null | tail -n 1 | awk '{print $1}')
final_size_human=$(du -h -c "$OUTPUT_DIR"/* 2>/dev/null | tail -n 1 | awk '{print $1}')

saved_bytes=$((initial_size_bytes - final_size_bytes))
saved_kb=$(echo "$saved_bytes" | awk '{printf "%.2f", $1 / 1024}')

echo
echo "Tamaño total después de la optimización: $final_size_human"
echo "Espacio total ahorrado: ${saved_kb} KB"