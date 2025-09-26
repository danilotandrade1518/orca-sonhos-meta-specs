#!/bin/bash

# validate-metadata.sh
# Script to validate YAML metadata in OrçaSonhos documentation
# Part of the hybrid documentation maintenance approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
errors=0
warnings=0
total_files=0

echo -e "${BLUE}🔍 OrçaSonhos Documentation Metadata Validation${NC}"
echo "=================================================="

# Function to validate YAML syntax
validate_yaml_syntax() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML block and validate
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    # Check if YAML is valid using python
    if python3 -c "import yaml; yaml.safe_load(open('$temp_yaml'))" 2>/dev/null; then
        rm -f "$temp_yaml"
        return 0
    else
        rm -f "$temp_yaml"
        return 1
    fi
}

# Function to check required fields
check_required_fields() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"
    local missing_fields=()

    # Extract YAML block
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    # Required fields for all documents
    required_fields=("document_type" "domain" "audience" "complexity" "tags" "last_updated")

    for field in "${required_fields[@]}"; do
        if ! grep -q "^${field}:" "$temp_yaml"; then
            missing_fields+=("$field")
        fi
    done

    rm -f "$temp_yaml"

    if [ ${#missing_fields[@]} -eq 0 ]; then
        return 0
    else
        echo -e "${YELLOW}    Missing fields: ${missing_fields[*]}${NC}"
        return 1
    fi
}

# Function to validate date format
validate_date_format() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML block
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    # Check last_updated format (YYYY-MM-DD)
    if grep -q "^last_updated:" "$temp_yaml"; then
        local date_value=$(grep "^last_updated:" "$temp_yaml" | sed 's/.*: *"\?\([^"]*\)"\?.*/\1/')
        if [[ ! $date_value =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            rm -f "$temp_yaml"
            echo -e "${YELLOW}    Invalid date format: $date_value (expected YYYY-MM-DD)${NC}"
            return 1
        fi
    fi

    rm -f "$temp_yaml"
    return 0
}

# Function to validate tags format
validate_tags_format() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML block
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    # Check if tags is an array
    if grep -q "^tags:" "$temp_yaml"; then
        # Simple check - tags should be in array format [tag1, tag2] or yaml list format
        if ! grep -A 5 "^tags:" "$temp_yaml" | grep -q -E "(\[.*\]|- .*)" ; then
            rm -f "$temp_yaml"
            echo -e "${YELLOW}    Tags should be in array format${NC}"
            return 1
        fi
    fi

    rm -f "$temp_yaml"
    return 0
}

# Function to validate audience format
validate_audience_format() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML block
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    # Check if audience is an array
    if grep -q "^audience:" "$temp_yaml"; then
        if ! grep -A 3 "^audience:" "$temp_yaml" | grep -q -E "(\[.*\]|- .*)" ; then
            rm -f "$temp_yaml"
            echo -e "${YELLOW}    Audience should be in array format${NC}"
            return 1
        fi
    fi

    rm -f "$temp_yaml"
    return 0
}

# Function to validate complexity values
validate_complexity_values() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML block
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    # Check complexity value
    if grep -q "^complexity:" "$temp_yaml"; then
        local complexity_value=$(grep "^complexity:" "$temp_yaml" | sed 's/.*: *"\?\([^"]*\)"\?.*/\1/')
        if [[ ! $complexity_value =~ ^(beginner|intermediate|advanced|reference)$ ]]; then
            rm -f "$temp_yaml"
            echo -e "${YELLOW}    Invalid complexity value: $complexity_value (should be: beginner|intermediate|advanced|reference)${NC}"
            return 1
        fi
    fi

    rm -f "$temp_yaml"
    return 0
}

# Function to check if file is stale (not updated in 90 days)
check_staleness() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML block
    sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml"

    if grep -q "^last_updated:" "$temp_yaml"; then
        local date_value=$(grep "^last_updated:" "$temp_yaml" | sed 's/.*: *"\?\([^"]*\)"\?.*/\1/')

        # Convert to seconds since epoch for comparison
        if command -v date >/dev/null 2>&1; then
            local doc_date_seconds
            local current_date_seconds
            local days_diff

            # Try different date command formats (Linux vs macOS)
            if date -d "$date_value" >/dev/null 2>&1; then
                # Linux date command
                doc_date_seconds=$(date -d "$date_value" +%s)
                current_date_seconds=$(date +%s)
            elif date -j -f "%Y-%m-%d" "$date_value" >/dev/null 2>&1; then
                # macOS date command
                doc_date_seconds=$(date -j -f "%Y-%m-%d" "$date_value" +%s)
                current_date_seconds=$(date +%s)
            else
                rm -f "$temp_yaml"
                return 0  # Skip if can't parse date
            fi

            days_diff=$(( (current_date_seconds - doc_date_seconds) / 86400 ))

            if [ $days_diff -gt 90 ]; then
                echo -e "${YELLOW}    Document potentially stale (last updated $days_diff days ago)${NC}"
                warnings=$((warnings + 1))
            fi
        fi
    fi

    rm -f "$temp_yaml"
    return 0
}

# Main validation loop
echo "Scanning for markdown files..."

# Find all markdown files, excluding certain directories
while IFS= read -r -d '' file; do
    total_files=$((total_files + 1))
    file_errors=0
    file_warnings=0

    echo -n "Checking $(basename "$file")... "

    # Check if file has YAML metadata
    if ! grep -q "^```yaml" "$file"; then
        echo -e "${YELLOW}NO METADATA${NC}"
        warnings=$((warnings + 1))
        continue
    fi

    # Validate YAML syntax
    if ! validate_yaml_syntax "$file"; then
        echo -e "${RED}INVALID YAML${NC}"
        errors=$((errors + 1))
        continue
    fi

    # Check required fields
    if ! check_required_fields "$file"; then
        file_errors=$((file_errors + 1))
    fi

    # Validate date format
    if ! validate_date_format "$file"; then
        file_warnings=$((file_warnings + 1))
    fi

    # Validate tags format
    if ! validate_tags_format "$file"; then
        file_warnings=$((file_warnings + 1))
    fi

    # Validate audience format
    if ! validate_audience_format "$file"; then
        file_warnings=$((file_warnings + 1))
    fi

    # Validate complexity values
    if ! validate_complexity_values "$file"; then
        file_warnings=$((file_warnings + 1))
    fi

    # Check for staleness
    check_staleness "$file"

    # Print result for this file
    if [ $file_errors -gt 0 ]; then
        echo -e "${RED}ERRORS${NC}"
        errors=$((errors + file_errors))
    elif [ $file_warnings -gt 0 ]; then
        echo -e "${YELLOW}WARNINGS${NC}"
        warnings=$((warnings + file_warnings))
    else
        echo -e "${GREEN}OK${NC}"
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
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "=================================================="
echo "Files processed: $total_files"
echo -e "Errors: ${RED}$errors${NC}"
echo -e "Warnings: ${YELLOW}$warnings${NC}"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✅ All metadata is valid!${NC}"
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validation completed with warnings${NC}"
    exit 0
else
    echo -e "${RED}❌ Validation failed with errors${NC}"
    echo ""
    echo "Common fixes:"
    echo "• Add missing required metadata fields"
    echo "• Fix YAML syntax errors"
    echo "• Use proper date format (YYYY-MM-DD)"
    echo "• Ensure tags and audience are arrays"
    echo "• Use valid complexity values: beginner|intermediate|advanced|reference"
    exit 1
fi