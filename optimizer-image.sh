#!/bin/bash

# --- Default values ---
DEFAULT_QUALITY=85
DEFAULT_WIDTH=""

# --- Help function ---
show_help() {
    echo "Uso: ./optimizer.sh [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --quality <num>  Establece el nivel de calidad para imágenes JPG/JPEG (1-100). Por defecto: $DEFAULT_QUALITY."
    echo "  --width <num>    Establece el ancho máximo en píxeles para las imágenes, manteniendo la relación de aspecto."
    echo "  -h, --help       Muestra esta ayuda y sale."
    echo ""
    echo "Ejemplo:"
    echo "  ./optimizer.sh --quality 80 --width 1024"
}

# --- Argument parsing ---
QUALITY=$DEFAULT_QUALITY
WIDTH=$DEFAULT_WIDTH

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --quality)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ && "$2" -ge 1 && "$2" -le 100 ]]; then
                QUALITY="$2"
                shift
            else
                echo "Error: --quality requiere un número entre 1 y 100." >&2
                exit 1
            fi
            ;;
        --width)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                WIDTH="$2"
                shift
            else
                echo "Error: --width requiere un número." >&2
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

# Directorio de salida para las imágenes optimizadas
OUTPUT_DIR="optimized"

# Encuentra los archivos de imagen en el directorio actual
files=$(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))

if [ -z "$files" ]; then
    echo "No se encontraron imágenes para optimizar en el directorio actual."
    exit 0
fi

echo "Las siguientes imágenes se optimizarán y se guardarán en la carpeta '$OUTPUT_DIR':"
echo "$files" | sed 's|^\./||' | while IFS= read -r file; do
    echo "- $file"
done

initial_size_bytes=$(du -bc $files 2>/dev/null | tail -n 1 | awk '{print $1}')
initial_size_human=$(du -h -c $files 2>/dev/null | tail -n 1 | awk '{print $1}')

echo
echo "Nivel de calidad para JPG/JPEG: $QUALITY%"
if [ -n "$WIDTH" ]; then
    echo "Ancho de imagen: ${WIDTH}px"
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
echo "$files" | sed 's|^\./||' | while IFS= read -r file; do
    # Define la ruta de salida
    output_path="$OUTPUT_DIR/$file"
    
    # Build the convert command
    convert_cmd="convert \"$file\" -strip"

    if [ -n "$WIDTH" ]; then
        convert_cmd="$convert_cmd -resize ${WIDTH}x"
    fi

    if [[ "$file" == *.jpg ]] || [[ "$file" == *.jpeg ]] || [[ "$file" == *.JPG ]] || [[ "$file" == *.JPEG ]]; then
        convert_cmd="$convert_cmd -quality $QUALITY"
    fi

    convert_cmd="$convert_cmd \"$output_path\""

    eval $convert_cmd
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