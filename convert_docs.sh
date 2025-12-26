#!/bin/bash

# Configuración por defecto
FORMAT="pdf"
INPUT_DIR="."
OUTPUT_DIR="./output_docs"
EXTENSIONS="md" # Extensiones por defecto a buscar
MARGIN="2cm"    # Margen por defecto para PDF

# Función de ayuda
usage() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Convierte documentos (Markdown) a otros formatos usando pandoc."
    echo ""
    echo "Opciones:"
    echo "  -f, --format <fmt>    Formato de salida: 'pdf', 'docx', 'html', 'odt'. (Por defecto: $FORMAT)"
    echo "  -i, --input <path>    Archivo o directorio de entrada. (Por defecto: directorio actual)"
    echo "  -o, --output <dir>    Directorio donde guardar los archivos convertidos. (Por defecto: $OUTPUT_DIR)"
    echo "  -e, --extensions <ext> Lista de extensiones a procesar (solo modo directorio). (Por defecto: $EXTENSIONS)"
    echo "  -m, --margin <size>   Tamaño del margen para PDF (ej: 1cm, 0.5in). (Por defecto: $MARGIN)"
    echo "  -h, --help            Muestra este mensaje de ayuda."
    echo ""
    echo "Ejemplos:"
    echo "  1. Convertir un archivo a PDF:"
    echo "     $0 -i README.md -f pdf"
    echo ""
    echo "  2. Convertir todo un directorio a Word (DOCX):"
    echo "     $0 -i ./docs -f docx"
    echo ""
    echo "  3. Convertir a PDF con márgenes personalizados:"
    echo "     $0 -i archivo.md -f pdf -m 1cm"
    echo ""
    echo "  4. Convertir archivos de texto (.txt) en lugar de Markdown:"
    echo "     $0 -i ./notas -e txt -f pdf"
    echo ""
    echo "  5. Especificar directorio de salida:"
    echo "     $0 -i ./docs -o ./mis_documentos -f pdf"
    echo ""
    echo "  6. Convertir a HTML:"
    echo "     $0 -i manual.md -f html"
    echo ""
    echo "  7. Convertir desde HTML a Markdown:"
    echo "     $0 -i pagina.html -f md"
    # echo ""
    # echo "  8. Convertir PDF a Markdown (experimental - deshabilitado):"
    # echo "     $0 -i documento.pdf -f md"
    exit 0
}

# Parsear argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--format)
            if [[ -n "$2" ]]; then
                FORMAT="$2"
                shift 2
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
                EXTENSIONS=$(echo "$2" | tr -d ' ')
                shift 2
            else
                echo "Error: Falta la lista de extensiones para la opción $1"
                exit 1
            fi
            ;;
        -m|--margin)
            if [[ -n "$2" ]]; then
                MARGIN="$2"
                shift 2
            else
                echo "Error: Falta el tamaño del margen para la opción $1"
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
if ! command -v pandoc &> /dev/null; then
    echo "Error: 'pandoc' no está instalado."
    echo "Instálalo con: sudo apt install pandoc (o equivalente)"
    exit 1
fi

# Si es PDF, verificar si existe un motor de latex (opcional pero recomendado avisar)
if [[ "$FORMAT" == "pdf" ]]; then
    if ! command -v pdflatex &> /dev/null && ! command -v xelatex &> /dev/null; then
        echo "Advertencia: No se detectó 'pdflatex' ni 'xelatex'. La conversión a PDF podría fallar."
        echo "Considera instalar: sudo apt install texlive-latex-base"
        # No salimos, dejamos que pandoc intente o falle
    fi
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
    REGEX_EXTS=$(echo "$EXTENSIONS" | sed 's/,/|/g')
    
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

echo "Iniciando conversión de documentos..."
echo "Modo:    $MODE"
echo "Entrada: $INPUT_DIR"
echo "Salida:  $OUTPUT_DIR"
echo "Formato destino: $FORMAT"
if [[ "$FORMAT" == "pdf" ]]; then
    echo "Margen:  $MARGIN"
fi
echo "-----------------------------------"

count=0
total=${#files[@]}

for file in "${files[@]}"; do
    filename=$(basename "$file")
    filename="${filename%.*}"
    output_path="$OUTPUT_DIR/$filename.$FORMAT"
    
    echo "[$((++count))/$total] Convirtiendo: $(basename "$file") -> $filename.$FORMAT"
    
    # Argumentos extra para pandoc
    PANDOC_ARGS=()

    # Configuración específica para PDF
    if [[ "$FORMAT" == "pdf" ]]; then
        # Usar xelatex si está disponible para mejor soporte Unicode
        if command -v xelatex &> /dev/null; then
            PANDOC_ARGS+=("--pdf-engine=xelatex")
        fi
        # Configurar márgenes (geometry)
        PANDOC_ARGS+=("-V" "geometry:margin=$MARGIN")
    fi

    # Verificar si la entrada es PDF (no soportado)
    if [[ "$file" == *.pdf ]]; then
        echo "   -> ADVERTENCIA: Formato de entrada PDF no soportado."
        echo "      Este script no realiza conversión desde PDF (OCR/Extracción)."
        continue
    fi

    # Ejecutar pandoc
    pandoc "$file" -o "$output_path" "${PANDOC_ARGS[@]}"
    
    if [ $? -eq 0 ]; then
        echo "   -> OK"
    else
        echo "   -> ERROR al convertir $file"
        if [[ "$FORMAT" == "pdf" ]]; then
            echo "      Nota: Para soporte de emojis/Unicode en PDF, asegúrate de tener 'texlive-xetex' instalado:"
            echo "      sudo apt install texlive-xetex"
        fi
    fi
done

echo "-----------------------------------"
echo "Proceso finalizado. Documentos guardados en: $OUTPUT_DIR"
