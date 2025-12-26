#!/bin/bash

# Configuración por defecto
FORMAT="ogg"
INPUT_DIR="."
OUTPUT_DIR="./output_audio"
EXTENSIONS="wav" # Extensiones por defecto

# Función de ayuda
usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Convierte archivos de audio a formato $FORMAT usando ffmpeg."
    echo ""
    echo "Opciones:"
    echo "  -f, --format <fmt>    Formato de salida: 'ogg' o 'mp3'. (Por defecto: $FORMAT)"
    echo "  -i, --input <path>    Archivo o directorio de entrada. (Por defecto: directorio actual)"
    echo "  -o, --output <dir>    Directorio donde guardar los archivos convertidos. (Por defecto: $OUTPUT_DIR)"
    echo "  -e, --extensions <ext> Lista de extensiones a procesar (solo modo directorio). (Por defecto: $EXTENSIONS)"
    echo "                          Ejemplo: -e \"wav,mp3,flac\""
    echo "  -h, --help            Muestra este mensaje de ayuda."
    exit 0
}

# Parsear argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--format)
            if [[ -n "$2" ]]; then
                val=$(echo "$2" | tr '[:upper:]' '[:lower:]')
                if [[ "$val" == "ogg" || "$val" == "mp3" ]]; then
                    FORMAT="$val"
                    shift 2
                else
                    echo "Error: Formato '$2' no soportado. Use 'ogg' o 'mp3'."
                    exit 1
                fi
            else
                echo "Error: Falta el argumento para la opción $1"
                exit 1
            fi
            ;;
        -i|--input)
            if [[ -n "$2" ]]; then
                INPUT_DIR="$2"
                shift 2
            else
                echo "Error: Falta el archivo o directorio para la opción $1"
                exit 1
            fi
            ;;
        -o|--output)
            if [[ -n "$2" ]]; then
                OUTPUT_DIR="$2"
                shift 2
            else
                echo "Error: Falta el directorio para la opción $1"
                exit 1
            fi
            ;;
        -e|--extensions)
            if [[ -n "$2" ]]; then
                # Eliminar espacios y asignar
                EXTENSIONS=$(echo "$2" | tr -d ' ')
                shift 2
            else
                echo "Error: Falta la lista de extensiones para la opción $1"
                exit 1
            fi
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Opción desconocida: $1"
            echo "Use -h para ver la ayuda."
            exit 1
            ;;
    esac
done

# Comprobaciones previas
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: 'ffmpeg' no está instalado."
    exit 1
fi

if [ ! -e "$INPUT_DIR" ]; then
    echo "Error: La entrada '$INPUT_DIR' no existe."
    exit 1
fi

# Crear directorio de salida si no existe
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creando directorio de salida: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo crear el directorio de salida."
        exit 1
    fi
fi

files=()

# Lógica para archivo vs directorio
if [ -f "$INPUT_DIR" ]; then
    # Es un archivo único
    files+=("$INPUT_DIR")
    MODE="Archivo único"
elif [ -d "$INPUT_DIR" ]; then
    # Es un directorio
    MODE="Directorio"
    # Convertir lista de extensiones (coma) a regex (pipe) para find
    # wav,mp3 -> wav|mp3
    REGEX_EXTS=$(echo "$EXTENSIONS" | sed 's/,/|/g')

    # Usamos find con regex para soportar múltiples extensiones y case-insensitive (-iregex)
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$INPUT_DIR" -maxdepth 1 -type f -regextype posix-extended -iregex ".*\.($REGEX_EXTS)$" -print0 | sort -z)
else
    echo "Error: '$INPUT_DIR' no es un archivo regular ni un directorio."
    exit 1
fi

if [ ${#files[@]} -eq 0 ]; then
    echo "No se encontraron archivos para procesar en '$INPUT_DIR'."
    if [ "$MODE" == "Directorio" ]; then
        echo "Extensiones buscadas: $EXTENSIONS"
    fi
    exit 0
fi

echo "Iniciando conversión..."
echo "Modo:    $MODE"
echo "Entrada: $INPUT_DIR"
echo "Salida:  $OUTPUT_DIR"
echo "Formato: $FORMAT"
if [ "$MODE" == "Directorio" ]; then
    echo "Extensiones: $EXTENSIONS"
fi
echo "-----------------------------------"

count=0
total=${#files[@]}

for file in "${files[@]}"; do
    # Extraer solo el nombre del archivo sin ruta
    filename=$(basename "$file")
    # Eliminar la extensión original (cualquiera que sea)
    filename="${filename%.*}"
    
    output_path="$OUTPUT_DIR/$filename.$FORMAT"
    
    echo "[$((++count))/$total] Convirtiendo: $(basename "$file") -> $filename.$FORMAT"
    
    # Ejecutar conversión
    # -vn asegura que si la entrada es video, solo se extraiga el audio
    ffmpeg -i "$file" -vn "$output_path" -y -hide_banner -loglevel error
    
    if [ $? -eq 0 ]; then
        echo "   -> OK"
    else
        echo "   -> ERROR al convertir $file"
    fi
done

echo "-----------------------------------"
echo "Proceso finalizado. Archivos guardados en: $OUTPUT_DIR"
