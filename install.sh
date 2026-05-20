#!/bin/bash
set -euo pipefail

DRY_RUN=false

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help              Show this help message and exit
  -n, --dry-run           Stow dry run
Examples:
  $(basename "$0") 
  $(basename "$0") --dry-run
  $(basename "$0") --help
EOF
}

# Parse command line arguments
while getopts ":hvo:f-:" opt; do
    case $opt in
        h)  # -h
            show_help
            exit 0
            ;;
        n)  # -n
            DRY_RUN=true
            ;;
        -)  # Long options (--help, --dry-run, etc.)
            case "$OPTARG" in
                help)
                    show_help
                    exit 0
                    ;;
                dry-run)
                    DRY_RUN=true
                    ;;
                *)
                    echo "Unknown option --$OPTARG" >&2
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
    esac
done

# Shift processed arguments
shift $((OPTIND - 1))

CONFIG_FILE="pkglist.txt"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "There is no $CONFIG_FILE"
    exit 1
fi

if ! command -v stow &> /dev/null; then
    echo "Stow isn't installed, not good"
    exit 1
fi

echo "Reading '$CONFIG_FILE' ..."
PACKAGES=()
while IFS= read -r line || [[ -n $line ]]; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    
    if [[ -z "$trimmed" ]] || [[ "$trimmed" =~ ^# ]]; then
        continue
    fi
    
    PACKAGES+=("$trimmed")
done < "$CONFIG_FILE"

echo "Finished reading config file"

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "Warning: No packages found in $CONFIG_FILE"
    exit 0
fi

echo "Started stowing packages"

for pkg in "${PACKAGES[@]}"; do
    if [[ ! -d "$pkg" ]]; then
        echo "Warning: Directory '$pkg' not found, skipping..." >&2
        continue
    fi
    
    echo "Stowing $pkg..."
    if [[ $DRY_RUN ]]; then
        echo "Dry run"
        stow --restow -n -v -t ~ "$pkg" || echo "Failed to restow $pkg" >&2
    else  
        stow --restow -v -t ~ "$pkg" || echo "Failed to restow $pkg" >&2
    fi
done

echo "Dotfiles stowed successfully!"
