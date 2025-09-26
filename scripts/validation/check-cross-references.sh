#!/bin/bash

# check-cross-references.sh
# Script to verify internal cross-references in OrçaSonhos documentation
# Part of the hybrid documentation maintenance approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
broken_links=0
orphaned_files=0
total_links=0
total_files=0

echo -e "${BLUE}🔗 OrçaSonhos Documentation Cross-Reference Check${NC}"
echo "=================================================="

# Function to resolve relative path
resolve_path() {
    local base_dir="$1"
    local relative_path="$2"

    # Remove anchor/fragment from path
    local clean_path="${relative_path%%#*}"

    # If path starts with /, it's relative to repo root
    if [[ "$clean_path" == /* ]]; then
        echo ".${clean_path}"
    else
        # Otherwise, it's relative to the current file's directory
        echo "${base_dir}/${clean_path}"
    fi
}

# Function to normalize path (resolve .. and . components)
normalize_path() {
    local path="$1"
    # Use realpath if available, otherwise use a simpler approach
    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$path" 2>/dev/null || echo "$path"
    else
        # Simple normalization - remove ./ and handle ../
        echo "$path" | sed 's|/\./|/|g' | sed 's|/[^/]*/\.\./|/|g' | sed 's|^\./||'
    fi
}

# Function to check if link target exists
check_link() {
    local source_file="$1"
    local link="$2"
    local source_dir

    source_dir=$(dirname "$source_file")

    # Extract the file path from markdown link
    local link_path
    link_path=$(echo "$link" | sed 's/.*](\([^)]*\)).*/\1/')

    # Skip external links (http/https)
    if [[ "$link_path" =~ ^https?:// ]]; then
        return 0
    fi

    # Skip mailto links
    if [[ "$link_path" =~ ^mailto: ]]; then
        return 0
    fi

    # Skip anchor-only links (starting with #)
    if [[ "$link_path" =~ ^# ]]; then
        return 0
    fi

    # Resolve the full path
    local resolved_path
    resolved_path=$(resolve_path "$source_dir" "$link_path")
    resolved_path=$(normalize_path "$resolved_path")

    # Check if target file exists
    if [[ ! -f "$resolved_path" ]]; then
        echo -e "  ${RED}❌ Broken link:${NC} $link_path"
        echo -e "     ${YELLOW}From:${NC} $source_file"
        echo -e "     ${YELLOW}Resolved to:${NC} $resolved_path"
        return 1
    fi

    return 0
}

# Function to extract and validate anchors
check_anchors() {
    local source_file="$1"
    local link="$2"

    # Extract anchor from link
    local anchor
    if [[ "$link" =~ \#([^)]*) ]]; then
        anchor="${BASH_REMATCH[1]}"

        # Extract file path
        local link_path
        link_path=$(echo "$link" | sed 's/.*](\([^#)]*\)).*/\1/')

        # If no file path, it's an anchor in the same file
        if [[ -z "$link_path" ]]; then
            link_path="$source_file"
        else
            # Resolve target file path
            local source_dir
            source_dir=$(dirname "$source_file")
            link_path=$(resolve_path "$source_dir" "$link_path")
            link_path=$(normalize_path "$link_path")
        fi

        # Check if target file exists
        if [[ ! -f "$link_path" ]]; then
            return 0  # File doesn't exist, already reported by check_link
        fi

        # Check if anchor exists in target file
        # Look for headers that would generate this anchor
        local anchor_pattern
        # Convert anchor to possible header formats
        # GitHub-style: spaces become dashes, lowercase, special chars removed
        anchor_pattern=$(echo "$anchor" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

        # Check for various header formats that could generate this anchor
        if ! grep -qiE "(^#{1,6}.*$anchor|^#{1,6}.*$(echo "$anchor" | sed 's/-/ /g')|id.*=.*[\"']$anchor[\"'])" "$link_path"; then
            echo -e "  ${YELLOW}⚠️  Potential missing anchor:${NC} #$anchor"
            echo -e "     ${YELLOW}In file:${NC} $link_path"
            echo -e "     ${YELLOW}Referenced from:${NC} $source_file"
            return 1
        fi
    fi

    return 0
}

# Function to find orphaned files
find_orphaned_files() {
    local all_files=()
    local referenced_files=()

    echo -e "\n${BLUE}🔍 Checking for orphaned files...${NC}"

    # Get all markdown files
    while IFS= read -r -d '' file; do
        all_files+=("$file")
    done < <(find . -name "*.md" \
        -not -path "./node_modules/*" \
        -not -path "./.git/*" \
        -not -path "./temp/*" \
        -not -path "./.cache/*" \
        -print0)

    # Find all referenced files
    for file in "${all_files[@]}"; do
        while IFS= read -r link; do
            # Extract file path from link
            local link_path
            link_path=$(echo "$link" | sed 's/.*](\([^#)]*\)).*/\1/')

            # Skip external links and anchors
            if [[ "$link_path" =~ ^https?:// ]] || [[ "$link_path" =~ ^mailto: ]] || [[ "$link_path" =~ ^# ]]; then
                continue
            fi

            # Skip empty paths
            if [[ -z "$link_path" ]]; then
                continue
            fi

            # Resolve path
            local source_dir
            source_dir=$(dirname "$file")
            local resolved_path
            resolved_path=$(resolve_path "$source_dir" "$link_path")
            resolved_path=$(normalize_path "$resolved_path")

            # Add to referenced files if it exists
            if [[ -f "$resolved_path" ]]; then
                referenced_files+=("$resolved_path")
            fi
        done < <(grep -oE '\[.*\]\([^)]+\)' "$file" 2>/dev/null || true)
    done

    # Always consider index.md files as referenced
    referenced_files+=("./index.md")
    for file in "${all_files[@]}"; do
        if [[ "$(basename "$file")" == "index.md" ]]; then
            referenced_files+=("$file")
        fi
    done

    # Remove duplicates and sort
    IFS=$'\n' referenced_files=($(sort -u <<<"${referenced_files[*]}"))

    # Check for orphaned files
    for file in "${all_files[@]}"; do
        local is_referenced=false
        for ref_file in "${referenced_files[@]}"; do
            if [[ "$file" == "$ref_file" ]]; then
                is_referenced=true
                break
            fi
        done

        if [[ "$is_referenced" == false ]]; then
            echo -e "  ${YELLOW}⚠️  Potentially orphaned file:${NC} $file"
            orphaned_files=$((orphaned_files + 1))
        fi
    done
}

# Function to validate related_docs in metadata
check_metadata_references() {
    local file="$1"
    local temp_yaml="temp_yaml_$$.yml"

    # Extract YAML metadata
    if ! sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > "$temp_yaml" 2>/dev/null; then
        return 0
    fi

    # Check if file has related_docs field
    if ! grep -q "related_docs:" "$temp_yaml"; then
        rm -f "$temp_yaml"
        return 0
    fi

    # Extract related_docs array items
    local source_dir
    source_dir=$(dirname "$file")

    # Simple extraction of related_docs items (basic YAML parsing)
    while IFS= read -r doc_ref; do
        # Clean up the reference (remove quotes, brackets, etc.)
        doc_ref=$(echo "$doc_ref" | sed 's/.*["\[]//;s/["\],.*//;s/["\]].*//;s/^[[:space:]]*-[[:space:]]*//')

        # Skip empty references
        if [[ -z "$doc_ref" ]]; then
            continue
        fi

        # Resolve path
        local resolved_path
        resolved_path=$(resolve_path "$source_dir" "$doc_ref")
        resolved_path=$(normalize_path "$resolved_path")

        # Check if referenced file exists
        if [[ ! -f "$resolved_path" ]]; then
            echo -e "  ${RED}❌ Broken metadata reference:${NC} $doc_ref"
            echo -e "     ${YELLOW}In metadata of:${NC} $file"
            echo -e "     ${YELLOW}Resolved to:${NC} $resolved_path"
            broken_links=$((broken_links + 1))
        fi
    done < <(grep -A 10 "related_docs:" "$temp_yaml" | grep -E "^[[:space:]]*-|^\[.*\]" || true)

    rm -f "$temp_yaml"
    return 0
}

# Main validation loop
echo "Scanning for markdown files and checking links..."

while IFS= read -r -d '' file; do
    total_files=$((total_files + 1))
    local_broken=0

    echo "Checking links in $(basename "$file")..."

    # Check markdown links
    while IFS= read -r link; do
        total_links=$((total_links + 1))

        if ! check_link "$file" "$link"; then
            local_broken=$((local_broken + 1))
        fi

        # Check anchors in links
        check_anchors "$file" "$link" || true  # Don't fail on anchor warnings

    done < <(grep -oE '\[.*\]\([^)]+\)' "$file" 2>/dev/null || true)

    # Check metadata references
    check_metadata_references "$file"

    broken_links=$((broken_links + local_broken))

    if [[ $local_broken -eq 0 ]]; then
        echo -e "  ${GREEN}✅ All links valid${NC}"
    else
        echo -e "  ${RED}❌ Found $local_broken broken link(s)${NC}"
    fi

done < <(find . -name "*.md" \
    -not -path "./node_modules/*" \
    -not -path "./.git/*" \
    -not -path "./temp/*" \
    -not -path "./.cache/*" \
    -print0)

# Check for orphaned files
find_orphaned_files

# Summary
echo ""
echo "=================================================="
echo -e "${BLUE}📊 Cross-Reference Check Summary${NC}"
echo "=================================================="
echo "Files processed: $total_files"
echo "Links checked: $total_links"
echo -e "Broken links: ${RED}$broken_links${NC}"
echo -e "Orphaned files: ${YELLOW}$orphaned_files${NC}"

if [[ $broken_links -eq 0 ]] && [[ $orphaned_files -eq 0 ]]; then
    echo -e "${GREEN}✅ All cross-references are valid!${NC}"
    exit 0
elif [[ $broken_links -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No broken links, but found orphaned files${NC}"
    echo ""
    echo "Consider:"
    echo "• Adding references to orphaned files"
    echo "• Removing unused files"
    echo "• Adding files to appropriate index pages"
    exit 0
else
    echo -e "${RED}❌ Cross-reference check failed${NC}"
    echo ""
    echo "To fix broken links:"
    echo "• Update file paths to correct locations"
    echo "• Remove references to deleted files"
    echo "• Fix typos in file names"
    echo "• Ensure referenced files exist"
    exit 1
fi