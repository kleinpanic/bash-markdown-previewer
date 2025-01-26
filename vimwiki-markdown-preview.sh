#!/usr/bin/env bash

# ============================
# Exit Status Codes
# ============================
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_DEPENDENCY=2
EXIT_CONVERSION=3

# ============================
# Shell Options
# ============================
# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error,
# Prevent errors in a pipeline from being masked
set -euo pipefail

# ============================
# Color Definitions
# ============================
RESET='\033[0m'          # No Color
BOLD='\033[1m'

# Regular Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# ============================
# Configuration Constants
# ============================

# Absolute paths ensure the script can be run from any directory
SOURCE_DIR="$HOME/vimwiki"                   # Source Vimwiki directory
TEMP_DIR="/tmp/vimwikihtml"                  # Temporary HTML output directory
CSS_FILE="$HOME/.local/share/nvim/style.css" # Path to the CSS file for styling
CONCURRENT_JOBS=4                            # Number of concurrent pandoc processes
LOG_FILE="$TEMP_DIR/conversion.log"          # Log file to track conversions
ERROR_LOG_FILE="$TEMP_DIR/error.log"         # Log file to track errors
VERSION="1.0.0"                               # Script version

# ============================
# Dependencies
# ============================

DEPENDENCIES=("pandoc" "sed" "qutebrowser" "find" "rsync" "grep" "mkdir" "basename" "diff")

# ============================
# Logging Functions
# ============================

# Function to log INFO messages
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${RESET} $message"
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Function to log SUCCESS messages
log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${RESET} $message"
    echo "[SUCCESS] $(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Function to log WARNING messages
log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${RESET} $message"
    echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Function to log ERROR messages
log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${RESET} $message" | tee -a "$ERROR_LOG_FILE"
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$ERROR_LOG_FILE"
}

# Function to handle errors with context and exit with specific code
handle_error() {
    local message="$1"
    local exit_code="${2:-$EXIT_FAILURE}"
    local func="${FUNCNAME[1]}"
    local line="${BASH_LINENO[0]}"
    log_error "In function '$func' at line $line: $message"
    exit "$exit_code"
}

# ============================
# Filename Validation Function
# ============================

# Function to check if a filename contains only allowed characters
is_valid_filename() {
    local filename="$1"
    if [[ "$filename" =~ ^[A-Za-z0-9._-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============================
# Bash Availability Check
# ============================

# Function to ensure that Bash is available
check_bash() {
    if ! command -v bash &>/dev/null; then
        echo -e "${RED}[ERROR]${RESET} Bash is not installed. Please install Bash to run this script."
        exit "$EXIT_FAILURE"
    fi
}

# ============================
# Path Validation Function
# ============================

# Function to validate and sanitize input paths
validate_paths() {
    log_info "Validating input paths..."

    # Check that SOURCE_DIR is an absolute path
    if [[ "$SOURCE_DIR" != /* ]]; then
        handle_error "SOURCE_DIR ('$SOURCE_DIR') is not an absolute path." "$EXIT_FAILURE"
    fi

    # Check that TEMP_DIR is an absolute path and under /tmp
    if [[ "$TEMP_DIR" != /tmp/* ]]; then
        handle_error "TEMP_DIR ('$TEMP_DIR') must be under /tmp." "$EXIT_FAILURE"
    fi

    # Check that SOURCE_DIR exists and is a directory
    if [[ ! -d "$SOURCE_DIR" ]]; then
        handle_error "SOURCE_DIR ('$SOURCE_DIR') does not exist or is not a directory." "$EXIT_FAILURE"
    fi

    # Check if TEMP_DIR exists; if not, it will be created later
    # If it exists, ensure it's a directory
    if [[ -e "$TEMP_DIR" && ! -d "$TEMP_DIR" ]]; then
        handle_error "TEMP_DIR ('$TEMP_DIR') exists but is not a directory." "$EXIT_FAILURE"
    fi

    log_success "Input paths are valid."
}

# ============================
# Function Definitions
# ============================

# Function to check if all dependencies are installed
check_dependencies() {
    log_info "Checking for required dependencies..."
    local missing_dependencies=()

    for cmd in "${DEPENDENCIES[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_dependencies+=("$cmd")
        fi
    done

    if [[ ${#missing_dependencies[@]} -ne 0 ]]; then
        for cmd in "${missing_dependencies[@]}"; do
            handle_error "Dependency '$cmd' is not installed. Please install it and retry." "$EXIT_DEPENDENCY"
        done
    fi

    log_success "All dependencies are satisfied."
}

# Function to extract the title from Markdown using YAML frontmatter or fallback to filename
extract_title() {
    local md_file="$1"
    # Attempt to extract title from YAML frontmatter
    local title
    title=$(grep -m1 '^title:' "$md_file" | sed 's/title: //') || true
    if [[ -z "$title" ]]; then
        # If no title found, use the filename without extension
        title=$(basename "$md_file" .md.old)
    fi
    echo "$title"
}

# Function to convert a single Markdown file to HTML atomically
convert_md_to_html() {
    local md_old_file="$1"  # Path to the .md.old file
    # Determine the relative path from TEMP_DIR
    local relative_path="${md_old_file#$TEMP_DIR/}"
    # Remove .md.old extension
    relative_path="${relative_path%.md.old}"
    # Determine the output HTML file path
    local html_file="$TEMP_DIR/${relative_path}.html"
    # Determine the temporary HTML file path
    local temp_html_file="${html_file}.tmp"
    # Create the necessary directories for the HTML file
    mkdir -p "$(dirname "$html_file")"

    # Extract the title for the HTML document
    local title
    title=$(extract_title "$md_old_file")

    log_info "Converting '$md_old_file' to '$html_file'..."

    # Use pandoc to convert Markdown to HTML with CSS and metadata
    if [[ -f "$CSS_FILE" ]]; then
        if ! pandoc -f markdown -s --css="$CSS_FILE" --metadata title="$title" "$md_old_file" -o "$temp_html_file"; then
            handle_error "Failed to convert '$md_old_file' to HTML." "$EXIT_CONVERSION"
        fi
    else
        log_warning "CSS file '$CSS_FILE' not found. Skipping CSS for '$md_old_file'."
        if ! pandoc -f markdown -s --metadata title="$title" "$md_old_file" -o "$temp_html_file"; then
            handle_error "Failed to convert '$md_old_file' to HTML." "$EXIT_CONVERSION"
        fi
    fi

    # Debug: Print a snippet of the HTML file before running sed
    log_info "Snippet before sed in '$temp_html_file':"
    head -n 5 "$temp_html_file" || true
    echo "..."

    # Adjust internal href links:
    # 1. Replace href="path/to/file.md.old" with href="path/to/file.html"
    # 2. Replace href="path/to/file" with href="path/to/file.html" only if 'file' has no extension
    log_info "Adjusting links in '$html_file'..."

    # First, replace links ending with .md.old
    if ! sed -i -E 's|(href=")([^"#:/]+(/[^"#:/]+)*)\.md\.old(")|\1\2.html\4|g' "$temp_html_file"; then
        handle_error "Failed to adjust '.md.old' links in '$temp_html_file'." "$EXIT_CONVERSION"
    fi

    # Then, replace links without any extension
    if ! sed -i -E 's|(href=")([^"#:/.]+(/[^"#:/.]+)*)(")|\1\2.html\4|g' "$temp_html_file"; then
        handle_error "Failed to adjust extensionless links in '$temp_html_file'." "$EXIT_CONVERSION"
    fi

    # Adjust src attributes for images to prepend /tmp/vimwikihtml
    log_info "Adjusting image paths in '$temp_html_file'..."
    if ! sed -i -E 's|(<img[^>]*src=")(/[^"]*)(")|\1/tmp/vimwikihtml\2\3|g' "$temp_html_file"; then
        handle_error "Failed to adjust image paths in '$temp_html_file'." "$EXIT_CONVERSION"
    fi

    # Move the temporary HTML file to the final destination atomically
    mv "$temp_html_file" "$html_file"

    # Debug: Print a snippet of the HTML file after running sed
    log_info "Snippet after sed in '$html_file':"
    head -n 5 "$html_file" || true
    echo "..."

    # Log the successful conversion
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Converted '$md_old_file' to '$html_file'." >> "$LOG_FILE"

    log_success "Successfully converted '$md_old_file' to '$html_file'."
}

# Function to synchronize Markdown files and relevant assets to TEMP_DIR
synchronize_markdown() {
    log_info "Synchronizing Markdown files and assets to '$TEMP_DIR'..."

    # Use rsync to copy only .md, .pdf, and image files, excluding unwanted directories and files
    rsync -av --delete \
        --exclude='*.html' \
        --exclude='*.sh' \
        --exclude='.git/' \
        --exclude='.gitignore' \
        --exclude='*.bak' \
	--exclude='*.tex' \
	--exclude='*.toc' \
	--exclude='*.out' \
        --include='*/' \
        --include='*.md' \
        --include='*.pdf' \
        --include='*.png' \
        --include='*.jpg' \
        --include='*.jpeg' \
        --include='*.gif' \
        --exclude='*' \
        "$SOURCE_DIR/" "$TEMP_DIR/" | grep '\.md$' || true

    log_success "Synchronization completed."
}

# Function to rename .md files to .md.old in TEMP_DIR
rename_md_files() {
    log_info "Renaming new or modified .md files to .md.old in '$TEMP_DIR'..."

    # Find all .md files in TEMP_DIR
    find "$TEMP_DIR" -type f -name '*.md' | while IFS= read -r md_file; do
        # Determine the corresponding .md.old file
        md_old_file="${md_file}.old"

        # Determine the source .md file
        source_md="$SOURCE_DIR/${md_file#$TEMP_DIR/}"

        # Check if the .md.old file exists
        if [[ ! -f "$md_old_file" ]]; then
            # New file detected, copy to .md.old
            cp "$source_md" "$md_old_file"
            log_info "New file detected. Copied '$source_md' to '$md_old_file'."
            # Convert to HTML
            convert_md_to_html "$md_old_file" &
        else
            # Compare the source .md with the existing .md.old
            if ! diff -q "$source_md" "$md_old_file" &>/dev/null; then
                # Files differ, update .md.old and reconvert
                cp "$source_md" "$md_old_file"
                log_info "Modified file detected. Updated '$md_old_file' with changes from '$source_md'."
                # Convert to HTML
                convert_md_to_html "$md_old_file" &
            else
                log_info "No changes detected for '$source_md'. Skipping conversion."
            fi
        fi
    done

    # Wait for all background conversions to finish
    wait

    log_success "Renaming and conversion of new or modified .md files completed."
}

# Function to handle deletions: Remove .html files corresponding to deleted .md files
handle_deletions() {
    log_info "Handling deletions of Markdown files..."

    # Find all .md.old files in TEMP_DIR
    find "$TEMP_DIR" -type f -name '*.md.old' | while IFS= read -r md_old_file; do
        # Determine the corresponding .md file in SOURCE_DIR
        source_md="$SOURCE_DIR/${md_old_file#$TEMP_DIR/}"
        source_md="${source_md%.md.old}.md"

        # Check if the source .md file exists
        if [[ ! -f "$source_md" ]]; then
            # Corresponding .md file has been deleted, remove the .html file
            html_file="${md_old_file%.md.old}.html"
            if [[ -f "$html_file" ]]; then
                rm "$html_file"
                log_success "Deleted '$html_file' as the source Markdown file no longer exists."
                # Log the deletion
                echo "$(date +"%Y-%m-%d %H:%M:%S") - Deleted '$html_file' due to source removal." >> "$LOG_FILE"
            fi
            # Remove the .md.old file itself
            rm "$md_old_file"
            log_info "Removed obsolete '$md_old_file'."
        fi
    done

    log_success "Deletion handling completed."
}

# Function to generate index.html specifically
generate_index() {
    local index_md_old="$TEMP_DIR/index.md.old"
    local index_html="$TEMP_DIR/index.html"

    if [[ ! -f "$index_md_old" ]]; then
        handle_error "'index.md.old' not found in '$TEMP_DIR'." "$EXIT_FAILURE"
    fi

    log_info "Generating 'index.html' from 'index.md.old'..."

    # Convert the index.md.old file to HTML
    convert_md_to_html "$index_md_old"

    # Ensure index.html exists
    if [[ ! -f "$index_html" ]]; then
        handle_error "Failed to generate 'index.html'." "$EXIT_CONVERSION"
    fi

    log_success "'index.html' generation completed."
}

# Function to open index.html in qutebrowser
open_browser() {
    local index_file="$TEMP_DIR/index.html"
    if [[ -f "$index_file" ]]; then
        log_info "Opening '$index_file' in qutebrowser..."
        qutebrowser "$index_file" &
        log_success "Opened '$index_file' in qutebrowser."
    else
        handle_error "'$index_file' does not exist. Please ensure it is generated correctly." "$EXIT_FAILURE"
    fi
}

# Function to display usage information
usage() {
    echo -e "${BOLD}Usage:${RESET} $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --index-wiki, -iw       Synchronize and convert Vimwiki to HTML, then open index.html in qutebrowser."
    echo "  --help, -h              Display this help message."
    echo "  --version, -V           Display the script's version."
    echo ""
    echo "Examples:"
    echo "  $0 --index-wiki"
    echo "  $0 -iw"
    echo "  $0 --help"
    echo "  $0 -h"
    echo "  $0 --version"
    echo "  $0 -V"
}

# Function to display version information
version_info() {
    echo -e "${BOLD}Vimwiki HTML Converter${RESET} version ${GREEN}$VERSION${RESET}"
}

# Function to update synchronization and conversion based on differences
update_if_needed() {
    # Synchronize new and updated files
    synchronize_markdown
    # Rename and convert new or modified .md files
    rename_md_files
    # Handle deletions
    handle_deletions
    # Generate index.html
    generate_index
}

# ============================
# Signal Handling Functions
# ============================

# Function to handle script termination gracefully
cleanup() {
    log_warning "Script interrupted. Cleaning up..."
    # Terminate all background jobs
    jobs -rp | xargs -r kill -TERM 2>/dev/null || true
    exit "$EXIT_FAILURE"
}

# Trap SIGINT and SIGTERM signals
trap cleanup SIGINT SIGTERM

# ============================
# convert_single_file Function
# ============================
convert_single_file() {
    local md_file="$1"

    # Validate filename
    local filename
    filename=$(basename "$md_file")
    if ! is_valid_filename "$filename"; then
        log_warning "Skipping file with invalid filename: '$md_file'"
        return
    fi

    # Check if the file exists
    if [[ ! -f "$md_file" ]]; then
        handle_error "File '$md_file' does not exist." "$EXIT_FAILURE"
    fi

    # Copy the Markdown file to the temporary directory
    local dest_dir="/tmp/markdowndump/"
    mkdir -p "$dest_dir"
    local dest_md_file="$dest_dir$filename"
    cp "$md_file" "$dest_md_file"
    log_info "Copied '$md_file' to '$dest_md_file'."

    # Prepare the paths for HTML conversion
    local html_file="${dest_md_file%.md}.html"
    local temp_html_file="${html_file}.tmp"

    # Extract the title for the HTML document
    local title
    title=$(extract_title "$dest_md_file")

    # Convert Markdown to HTML using pandoc with CSS and metadata
    if [[ -f "$CSS_FILE" ]]; then
        if ! pandoc -f markdown -s --css="$CSS_FILE" --metadata title="$title" "$dest_md_file" -o "$temp_html_file"; then
            handle_error "Failed to convert '$dest_md_file' to HTML." "$EXIT_CONVERSION"
        fi
    else
        log_warning "CSS file '$CSS_FILE' not found. Skipping CSS for '$dest_md_file'."
        if ! pandoc -f markdown -s --metadata title="$title" "$dest_md_file" -o "$temp_html_file"; then
            handle_error "Failed to convert '$dest_md_file' to HTML." "$EXIT_CONVERSION"
        fi
    fi

    # Move the temporary HTML file to the final destination
    mv "$temp_html_file" "$html_file"
    log_info "Converted Markdown file '$dest_md_file' to HTML '$html_file'."

    # Open the HTML file in qutebrowser
    qutebrowser "$html_file" &
    log_success "Opened '$html_file' in qutebrowser."
}

# ============================
# Main Script Execution
# ============================

main() {
    # Parse command-line arguments
    if [[ $# -eq 0 ]]; then
        log_error "No arguments provided. Use --help for usage information."
        exit "$EXIT_FAILURE"
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --index-wiki|-iw)
                action="index_wiki"
                shift
                ;;
            --convert|-c)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${RED}[ERROR]${RESET} --convert flag requires a filename argument."
                    exit "$EXIT_FAILURE"
                fi
                convert_single_file "$2"
                exit "$EXIT_SUCCESS"
                ;;
            --help)
                usage
                exit "$EXIT_SUCCESS"
                ;;
            -h)
                usage
                exit "$EXIT_SUCCESS"
                ;;
            --version)
                version_info
                exit "$EXIT_SUCCESS"
                ;;
            -V)
                version_info
                exit "$EXIT_SUCCESS"
                ;;
            *)
                log_error "Unknown option: $1. Use --help for usage information."
                exit "$EXIT_FAILURE"
                ;;
        esac
    done

    # Execute based on the action
    case "$action" in
        index_wiki)
            check_bash
            check_dependencies
            validate_paths
            # Create TEMP_DIR if it doesn't exist
            if [[ ! -d "$TEMP_DIR" ]]; then
                log_info "Temporary directory '$TEMP_DIR' does not exist. Creating and performing full synchronization."
                mkdir -p "$TEMP_DIR"
                synchronize_markdown
                rename_md_files
                handle_deletions
                generate_index
            else
                log_info "Temporary directory '$TEMP_DIR' already exists. Checking for updates."
                update_if_needed
            fi
            open_browser
            log_success "All tasks completed successfully."
            exit "$EXIT_SUCCESS"
            ;;
        *)
            # This should not happen due to earlier checks
            log_error "Invalid action." "$EXIT_FAILURE"
            ;;
    esac
}

# Invoke the main function
main "$@"

