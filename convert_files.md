# Conversión de Documentos con Pandoc

Este documento describe el proceso para convertir archivos Markdown a otros formatos como PDF y DOCX utilizando la herramienta `pandoc`.

## Pasos Realizados

1.  **Creación de Directorios**: Se crearon las carpetas `pdf` y `docx` para almacenar los archivos convertidos.
    ```bash
    mkdir pdf
    mkdir docx
    ```

2.  **Conversión a PDF**: Se utilizó `pandoc` para convertir todos los archivos `.md` a `.pdf` y guardarlos en la carpeta `pdf`.
    ```bash
    for file in *.md; do
      pandoc "$file" -o "pdf/${file%.md}.pdf"
    done
    ```

3.  **Conversión a Word (DOCX)**: Se repitió el proceso para convertir los archivos `.md` a `.docx` y guardarlos en la carpeta `docx`.
    ```bash
    for file in *.md; do
      pandoc "$file" -o "docx/${file%.md}.docx"
    done
    ```

## Requisitos e Instalación

A continuación se detallan los paquetes necesarios según el sistema operativo.

### En Debian/Ubuntu

Para que la conversión funcione correctamente, es necesario instalar los siguientes paquetes.

**1. Pandoc**: Es la herramienta principal de conversión.
```bash
sudo apt-get update
sudo apt-get install pandoc
```

**2. Motor de LaTeX (Para PDF)**: `pandoc` utiliza un motor de LaTeX para crear los archivos PDF.
```bash
# Paquete base esencial
sudo apt-get install texlive-latex-base

# Paquete adicional para funcionalidades extendidas (colores, etc.)
sudo apt-get install texlive-xetex
```

### En macOS (usando Homebrew)

En macOS, el gestor de paquetes recomendado es [Homebrew](https://brew.sh/).

**1. Pandoc**:
```bash
brew install pandoc
```

**2. Motor de LaTeX (MacTeX)**: La distribución recomendada es MacTeX, que incluye un motor completo de LaTeX.
```bash
brew install --cask mactex
```
*Nota: La instalación de MacTeX es grande, pero asegura tener todas las dependencias necesarias.*

## Comandos Habituales

Una vez instalado, el uso de `pandoc` es universal en cualquier sistema operativo.

-   **Markdown a PDF**:
    ```bash
    pandoc mi_archivo.md -o mi_archivo.pdf
    ```

-   **Markdown a Word**:
    ```bash
    pandoc mi_archivo.md -o mi_archivo.docx
    ```

-   **Markdown a HTML**:
    ```bash
    pandoc mi_archivo.md -o mi_archivo.html
    ```

-   **Word a Markdown**:
    ```bash
    pandoc mi_documento.docx -o mi_documento.md
    ```

## Personalización de PDF (Banderas)

Para personalizar la apariencia del PDF, se pueden usar variables con la bandera `-V`.

-   **Márgenes**: Se controla con la variable `geometry`.
    ```bash
    # Margen igual en todos los lados
    pandoc in.md -o out.pdf -V geometry:"margin=2cm"

    # Márgenes específicas
    pandoc in.md -o out.pdf -V geometry:"top=2cm, bottom=3cm, left=2.5cm, right=2.cm"
    ```

-   **Tamaño del Papel**:
    ```bash
    pandoc in.md -o out.pdf -V papersize:letter
    # Otros valores: a4, legal
    ```

-   **Tamaño de la Fuente**:
    ```bash
    pandoc in.md -o out.pdf -V fontsize:12pt
    # Valores comunes: 10pt, 11pt, 12pt
    ```

-   **Idioma del Documento**:
    ```bash
    pandoc in.md -o out.pdf -V lang:es
    ```

- **Convertir todo un directorio**:
```bash
for file in *.md; do
  pandoc "$file" \
    -o "pdf/${file%.md}.pdf" \
    -V geometry:"margin=1cm" \
    -V papersize:A4 \
    --pdf-engine=xelatex \
    -V lang=es \
    --wrap=auto \
    --highlight-style=tango
done
```

## Documentación Oficial

Para más información, opciones avanzadas y ejemplos, puedes consultar la documentación oficial de Pandoc.

-   **URL de la Documentación**: [https://pandoc.org](https://pandoc.org)
