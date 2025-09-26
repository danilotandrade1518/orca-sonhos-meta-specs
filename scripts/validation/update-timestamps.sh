#!/bin/bash

# update-timestamps.sh
# Script to update last_updated timestamps in OrçaSonhos documentation
# Part of the hybrid documentation maintenance approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
FORCE_UPDATE=false
MAX_AGE_DAYS=1

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --max-age)
            MAX_AGE_DAYS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run        Show what would be updated without making changes"
            echo "  --force          Update all files regardless of modification time"
            echo "  --max-age DAYS   Update files modified in the last N days (default: 1)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Counters
updated_files=0
skipped_files=0
total_files=0

echo -e "${BLUE}📅 OrçaSonhos Documentation Timestamp Update${NC}"
echo "=================================================="

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
fi

if [[ "$FORCE_UPDATE" == true ]]; then
    echo -e "${YELLOW}⚡ FORCE MODE - Updating all files with metadata${NC}"
fi

echo "Max age for auto-update: $MAX_AGE_DAYS day(s)"
echo ""

# Function to check if file was recently modified
is_recently_modified() {
    local file="$1"
    local max_age="$2"

    # Get file modification time in seconds since epoch
    if command -v stat >/dev/null 2>&1; then
        local file_mtime
        local current_time
        local age_seconds

        # Try different stat command formats (Linux vs macOS)
        if stat -c %Y "$file" >/dev/null 2>&1; then
            # Linux stat command
            file_mtime=$(stat -c %Y "$file")
        elif stat -f %m "$file" >/dev/null 2>&1; then
            # macOS stat command
            file_mtime=$(stat -f %m "$file")
        else
            # Fallback - assume it's recent
            return 0
        fi

        current_time=$(date +%s)
        age_seconds=$((current_time - file_mtime))
        local age_days=$((age_seconds / 86400))

        if [[ $age_days -le $max_age ]]; then
            return 0  # File is recent
        else
            return 1  # File is old
        fi
    else
        # If stat is not available, assume file is recent
        return 0
    fi
}

# Function to extract current last_updated date
get_current_timestamp() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML metadata
    if sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml" 2>/dev/null; then
        if grep -q "^last_updated:" "$temp_yaml"; then
            local current_date
            current_date=$(grep "^last_updated:" "$temp_yaml" | sed 's/.*: *"\?\([^"]*\)"\?.*/\1/')
            rm -f "$temp_yaml"
            echo "$current_date"
            return 0
        fi
    fi

    rm -f "$temp_yaml"
    return 1
}

# Function to update timestamp in file
update_timestamp() {
    local file="$1"
    local new_date="$2"

    # Create backup if not in dry run mode
    if [[ "$DRY_RUN" != true ]]; then
        cp "$file" "${file}.backup"
    fi

    # Update the timestamp
    if [[ "$DRY_RUN" != true ]]; then
        # Use different sed syntax for macOS vs Linux
        if sed --version >/dev/null 2>&1; then
            # GNU sed (Linux)
            sed -i "s/^last_updated: .*/last_updated: \"$new_date\"/" "$file"
        else
            # BSD sed (macOS)
            sed -i '' "s/^last_updated: .*/last_updated: \"$new_date\"/" "$file"
        fi

        # Remove backup if update was successful
        rm -f "${file}.backup"
    fi

    return 0
}

# Function to validate timestamp update
validate_timestamp_update() {
    local file="$1"
    local expected_date="$2"

    local actual_date
    if actual_date=$(get_current_timestamp "$file"); then
        if [[ "$actual_date" == "$expected_date" ]]; then
            return 0
        else
            echo -e "    ${RED}❌ Validation failed: expected '$expected_date', got '$actual_date'${NC}"
            return 1
        fi
    else
        echo -e "    ${RED}❌ Could not read updated timestamp${NC}"
        return 1
    fi
}

# Function to should_update_file
should_update_file() {
    local file="$1"

    # Force mode updates all files
    if [[ "$FORCE_UPDATE" == true ]]; then
        return 0
    fi

    # Check if file was recently modified
    if is_recently_modified "$file" "$MAX_AGE_DAYS"; then
        return 0
    else
        return 1
    fi
}

# Get current date in YYYY-MM-DD format
current_date=$(date +%Y-%m-%d)

echo "Current date: $current_date"
echo ""

# Main processing loop
while IFS= read -r -d '' file; do
    total_files=$((total_files + 1))

    echo -n "Processing $(basename "$file")... "

    # Check if file has YAML metadata
    if ! grep -q "^```yaml" "$file"; then
        echo -e "${YELLOW}NO METADATA${NC}"
        skipped_files=$((skipped_files + 1))
        continue
    fi

    # Check if file has last_updated field
    if ! grep -A 20 "^```yaml" "$file" | grep -q "^last_updated:"; then
        echo -e "${YELLOW}NO TIMESTAMP FIELD${NC}"
        skipped_files=$((skipped_files + 1))
        continue
    fi

    # Get current timestamp from file
    current_timestamp=""
    if current_timestamp=$(get_current_timestamp "$file"); then
        # Check if timestamp is already current
        if [[ "$current_timestamp" == "$current_date" ]]; then
            echo -e "${GREEN}ALREADY CURRENT${NC}"
            skipped_files=$((skipped_files + 1))
            continue
        fi
    fi

    # Check if file should be updated
    if ! should_update_file "$file"; then
        echo -e "${YELLOW}NOT RECENTLY MODIFIED${NC} (last updated: $current_timestamp)"
        skipped_files=$((skipped_files + 1))
        continue
    fi

    # Update the timestamp
    if update_timestamp "$file" "$current_date"; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${BLUE}WOULD UPDATE${NC} ($current_timestamp → $current_date)"
        else
            # Validate the update
            if validate_timestamp_update "$file" "$current_date"; then
                echo -e "${GREEN}UPDATED${NC} ($current_timestamp → $current_date)"
            else
                echo -e "${RED}UPDATE FAILED${NC}"
                # Restore backup if validation failed
                if [[ -f "${file}.backup" ]]; then
                    mv "${file}.backup" "$file"
                fi
                continue
            fi
        fi
        updated_files=$((updated_files + 1))
    else
        echo -e "${RED}FAILED${NC}"
    fi

done < <(find . -name "*.md" \
    -not -path "./node_modules/*" \
    -not -path "./.git/*" \
    -not -path "./temp/*" \
    -not -path "./.cache/*" \
    -print0)

# Summary
echo ""
echo "=================================================="
echo -e "${BLUE}📊 Timestamp Update Summary${NC}"
echo "=================================================="
echo "Files processed: $total_files"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "Would update: ${BLUE}$updated_files${NC}"
else
    echo -e "Updated: ${GREEN}$updated_files${NC}"
fi

echo -e "Skipped: ${YELLOW}$skipped_files${NC}"

# Detailed breakdown of skipped files
if [[ $skipped_files -gt 0 ]]; then
    echo ""
    echo "Skipped reasons:"
    echo "• No metadata block"
    echo "• No last_updated field"
    echo "• Already up to date"
    if [[ "$FORCE_UPDATE" != true ]]; then
        echo "• Not recently modified (use --force to override)"
    fi
fi

if [[ $updated_files -eq 0 ]]; then
    echo -e "${GREEN}✅ All timestamps are current!${NC}"
else
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}ℹ️  Run without --dry-run to apply changes${NC}"
    else
        echo -e "${GREEN}✅ Timestamp update completed!${NC}"
    fi
fi

echo ""
echo "Tips:"
echo "• Use --dry-run to preview changes"
echo "• Use --force to update all files"
echo "• Use --max-age N to set different recency threshold"

if [[ "$DRY_RUN" == true ]]; then
    exit 0
else
    exit 0
fi