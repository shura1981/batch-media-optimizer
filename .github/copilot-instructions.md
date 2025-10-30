# Media Optimization Scripts - AI Coding Instructions

## Project Overview
This repository contains two Bash utilities for media optimization:
- `optimizer-image.sh`: ImageMagick-based image compression and resizing
- `optimizer-video.sh`: FFmpeg-based video compression with multiple resolution presets

## Architecture & Dependencies
- **Pure Bash**: No frameworks, just shell scripting with external tools
- **Required tools**: ImageMagick (`convert`) for images, FFmpeg for videos
- **Output pattern**: Each script creates its own output directory (`optimized/`, `videos_renderizados/`)
- **File processing**: Batch processing with support for custom input directories
- **Default behavior**: Process files from current directory unless `--dir-input` is specified

## Key Development Patterns

### CLI Argument Parsing
Both scripts use comprehensive argument validation:
```bash
# Standard pattern for parameter validation
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --quality)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ && "$2" -ge 1 && "$2" -le 100 ]]; then
                QUALITY="$2"; shift
            else
                echo "Error: --quality requiere un número entre 1 y 100." >&2; exit 1
            fi ;;
    esac
    shift
done
```

### Video Resolution Presets
The video optimizer uses predefined resolution modes:
- `mobile`: 720x1280 (9:16) - for mobile content
- `vertical`: 1080x1920 (9:16) - for social media
- `desktop`: 1280x720 (16:9) - for desktop viewing  
- `hd`: 1920x1080 (16:9) - full HD
- `auto`: maintains original aspect ratio

### User Safety Features
- Interactive confirmation before processing: `read -p "¿Deseas proceder...?"`
- Overwrite protection with `--overwrite` flag
- Original file deletion only with explicit `--delete-originals` flag
- Comprehensive help with examples (`show_help()` functions)

### File Size Reporting
Both scripts calculate and display size savings:
```bash
# Pattern for human-readable size calculation
human_readable() {
  local i=${1:-0} div=1 d=0
  local units=('B' 'KB' 'MB' 'GB' 'TB')
  while ((i > 512 && d < ${#units[@]})); do
    i=$((i / 1024)); d=$((d + 1))
  done
  echo "$i ${units[$d]}"
}
```

## Tool-Specific Commands

### Image Optimization (ImageMagick)
- Uses `convert` with `-strip` to remove metadata
- Quality control via `-quality` parameter for JPEG/WebP
- Resize with aspect ratio preservation: `-resize ${WIDTH}x`
- Format conversion support: `--format webp|jpg|png`
- Input directory specification: `--dir-input <path>` (defaults to current directory)
- PNG compression: uses maximum compression level (9)

### Video Compression (FFmpeg)  
- Standard pipeline: `ffmpeg -i input -vf "scale,pad,fps" -c:v libx264 -crf CRF -c:a aac output`
- CRF quality range: 18-30 (lower = better quality)
- Audio: AAC codec with configurable bitrate (default 96k)

## File Structure
- Root scripts are executable utilities
- `public/` directory is gitignored (likely for processed files)
- No configuration files - all settings via CLI parameters

## Development Workflow
- Test with various file formats and parameter combinations
- Validate argument parsing edge cases (empty values, invalid ranges)
- Consider adding progress indicators for large batch operations
- Maintain backward compatibility when adding new features