#!/bin/bash

# verify-structure.sh
# Script to verify OrçaSonhos documentation structure and conventions
# Part of the hybrid documentation maintenance approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
structure_errors=0
naming_violations=0
missing_indices=0
total_directories=0

echo -e "${BLUE}🏗️  OrçaSonhos Documentation Structure Verification${NC}"
echo "=================================================="

# Expected directory structure
declare -A expected_directories=(
    ["business"]="Business documentation and concepts"
    ["business/product-vision"]="Product vision and core concepts"
    ["business/customer-profile"]="Customer personas and profiles"
    ["technical"]="Technical documentation"
    ["technical/frontend-architecture"]="Frontend architecture documentation"
    ["technical/backend-architecture"]="Backend architecture documentation"
    ["technical/code-standards"]="Code standards and conventions"
    ["adr"]="Architecture Decision Records"
    ["schemas"]="Entity schemas and structured data"
    ["templates"]="Documentation templates"
    ["scripts/validation"]="Validation scripts"
    ["maintenance"]="Maintenance documentation"
)

# Required files in root
declare -a required_root_files=(
    "index.md"
    "domain-ontology.md"
    "domain-glossary.md"
    "documentation-maintenance-guide.md"
)

# Directories that should have index.md files
declare -a directories_needing_index=(
    "business"
    "business/product-vision"
    "business/customer-profile"
    "technical"
    "technical/frontend-architecture"
    "technical/backend-architecture"
    "technical/code-standards"
    "adr"
)

# Function to check directory structure
check_directory_structure() {
    echo -e "${BLUE}🔍 Checking directory structure...${NC}"

    for dir in "${!expected_directories[@]}"; do
        total_directories=$((total_directories + 1))
        if [[ -d "$dir" ]]; then
            echo -e "  ${GREEN}✅${NC} $dir/ - ${expected_directories[$dir]}"
        else
            echo -e "  ${RED}❌${NC} Missing: $dir/ - ${expected_directories[$dir]}"
            structure_errors=$((structure_errors + 1))
        fi
    done
}

# Function to check required root files
check_required_files() {
    echo -e "\n${BLUE}📄 Checking required root files...${NC}"

    for file in "${required_root_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "  ${GREEN}✅${NC} $file"
        else
            echo -e "  ${RED}❌${NC} Missing: $file"
            structure_errors=$((structure_errors + 1))
        fi
    done
}

# Function to check for index files
check_index_files() {
    echo -e "\n${BLUE}📑 Checking index files...${NC}"

    for dir in "${directories_needing_index[@]}"; do
        local index_file="$dir/index.md"
        if [[ -f "$index_file" ]]; then
            echo -e "  ${GREEN}✅${NC} $index_file"

            # Check if index file has proper structure
            if grep -q "^# .*Índice" "$index_file" || grep -q "^# .*Index" "$index_file"; then
                echo -e "      ${GREEN}→${NC} Has proper index title"
            else
                echo -e "      ${YELLOW}⚠️${NC} Index title could be improved"
            fi

            # Check if index file lists subdirectories/files
            if grep -qE "\[.*\]\(\./" "$index_file"; then
                echo -e "      ${GREEN}→${NC} Contains navigation links"
            else
                echo -e "      ${YELLOW}⚠️${NC} Could benefit from navigation links"
            fi

        else
            echo -e "  ${RED}❌${NC} Missing: $index_file"
            missing_indices=$((missing_indices + 1))
        fi
    done
}

# Function to check naming conventions
check_naming_conventions() {
    echo -e "\n${BLUE}📝 Checking naming conventions...${NC}"

    local violations=0

    # Check markdown files
    while IFS= read -r -d '' file; do
        local basename_file
        basename_file=$(basename "$file")

        # Check for spaces in filenames (should use kebab-case)
        if [[ "$basename_file" =~ \  ]]; then
            echo -e "  ${YELLOW}⚠️${NC} Space in filename: $file (consider kebab-case)"
            violations=$((violations + 1))
        fi

        # Check for uppercase in filenames (should be lowercase)
        if [[ "$basename_file" =~ [A-Z] ]]; then
            # Exception for README files
            if [[ "$basename_file" != "README.md" ]]; then
                echo -e "  ${YELLOW}⚠️${NC} Uppercase in filename: $file (consider lowercase)"
                violations=$((violations + 1))
            fi
        fi

        # Check for underscores (prefer kebab-case)
        if [[ "$basename_file" =~ _ ]] && [[ "$basename_file" != *template* ]]; then
            echo -e "  ${YELLOW}⚠️${NC} Underscore in filename: $file (prefer kebab-case)"
            violations=$((violations + 1))
        fi

    done < <(find . -name "*.md" \
        -not -path "./node_modules/*" \
        -not -path "./.git/*" \
        -not -path "./temp/*" \
        -not -path "./.cache/*" \
        -print0)

    # Check directories
    while IFS= read -r -d '' dir; do
        local basename_dir
        basename_dir=$(basename "$dir")

        # Skip root and special directories
        if [[ "$dir" == "." ]] || [[ "$basename_dir" == ".git" ]] || [[ "$basename_dir" == "node_modules" ]]; then
            continue
        fi

        # Check for spaces in directory names
        if [[ "$basename_dir" =~ \  ]]; then
            echo -e "  ${YELLOW}⚠️${NC} Space in directory name: $dir (consider kebab-case)"
            violations=$((violations + 1))
        fi

        # Check for uppercase in directory names
        if [[ "$basename_dir" =~ [A-Z] ]]; then
            echo -e "  ${YELLOW}⚠️${NC} Uppercase in directory name: $dir (consider lowercase)"
            violations=$((violations + 1))
        fi

    done < <(find . -type d -print0)

    naming_violations=$violations

    if [[ $violations -eq 0 ]]; then
        echo -e "  ${GREEN}✅${NC} All names follow conventions"
    else
        echo -e "  ${YELLOW}⚠️${NC} Found $violations naming convention violations"
    fi
}

# Function to check file organization
check_file_organization() {
    echo -e "\n${BLUE}📁 Checking file organization...${NC}"

    local misplaced_files=0

    # Check for business docs in technical folders
    while IFS= read -r -d '' file; do
        if grep -qiE "(persona|customer|business|product.*vision|use.*case)" "$file"; then
            echo -e "  ${YELLOW}⚠️${NC} Possible business doc in technical folder: $file"
            misplaced_files=$((misplaced_files + 1))
        fi
    done < <(find ./technical -name "*.md" -print0 2>/dev/null || true)

    # Check for technical docs in business folders
    while IFS= read -r -d '' file; do
        if grep -qiE "(architecture|code.*standard|implementation|technical)" "$file"; then
            # Skip if it's just referencing technical docs
            if ! grep -qiE "(reference|see.*also|related)" "$file"; then
                echo -e "  ${YELLOW}⚠️${NC} Possible technical doc in business folder: $file"
                misplaced_files=$((misplaced_files + 1))
            fi
        fi
    done < <(find ./business -name "*.md" -print0 2>/dev/null || true)

    # Check for ADRs outside adr folder
    while IFS= read -r -d '' file; do
        if [[ "$(basename "$file")" =~ ^[0-9]+-.*\.md$ ]] && [[ "$file" != ./adr/* ]]; then
            echo -e "  ${YELLOW}⚠️${NC} Possible ADR outside adr/ folder: $file"
            misplaced_files=$((misplaced_files + 1))
        fi
    done < <(find . -name "*.md" -not -path "./adr/*" -print0)

    if [[ $misplaced_files -eq 0 ]]; then
        echo -e "  ${GREEN}✅${NC} File organization looks good"
    else
        echo -e "  ${YELLOW}⚠️${NC} Found $misplaced_files potentially misplaced files"
    fi
}

# Function to check for semantic consistency
check_semantic_consistency() {
    echo -e "\n${BLUE}🧠 Checking semantic consistency...${NC}"

    local consistency_issues=0

    # Check if domain ontology exists and is referenced
    if [[ -f "domain-ontology.md" ]]; then
        echo -e "  ${GREEN}✅${NC} Domain ontology exists"

        # Check if ontology is referenced in other docs
        local ontology_refs=0
        while IFS= read -r -d '' file; do
            if [[ "$file" != "./domain-ontology.md" ]] && grep -q "domain-ontology" "$file"; then
                ontology_refs=$((ontology_refs + 1))
            fi
        done < <(find . -name "*.md" -print0)

        if [[ $ontology_refs -gt 0 ]]; then
            echo -e "      ${GREEN}→${NC} Referenced in $ontology_refs other documents"
        else
            echo -e "      ${YELLOW}⚠️${NC} Not referenced in other documents"
            consistency_issues=$((consistency_issues + 1))
        fi
    else
        echo -e "  ${RED}❌${NC} Domain ontology missing"
        consistency_issues=$((consistency_issues + 1))
    fi

    # Check if domain glossary exists and is comprehensive
    if [[ -f "domain-glossary.md" ]]; then
        echo -e "  ${GREEN}✅${NC} Domain glossary exists"

        # Count defined terms
        local term_count
        term_count=$(grep -c "^### \*\*.*\*\*" "domain-glossary.md" || echo "0")
        echo -e "      ${GREEN}→${NC} Defines approximately $term_count terms"

        if [[ $term_count -lt 10 ]]; then
            echo -e "      ${YELLOW}⚠️${NC} Glossary might need more terms"
            consistency_issues=$((consistency_issues + 1))
        fi
    else
        echo -e "  ${RED}❌${NC} Domain glossary missing"
        consistency_issues=$((consistency_issues + 1))
    fi

    # Check schema consistency
    if [[ -d "schemas" ]]; then
        echo -e "  ${GREEN}✅${NC} Schemas directory exists"

        local schema_files
        schema_files=$(find schemas -name "*.yaml" -o -name "*.yml" | wc -l)
        echo -e "      ${GREEN}→${NC} Contains $schema_files schema files"

        if [[ $schema_files -eq 0 ]]; then
            echo -e "      ${YELLOW}⚠️${NC} No schema files found"
            consistency_issues=$((consistency_issues + 1))
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC} Schemas directory missing"
        consistency_issues=$((consistency_issues + 1))
    fi

    if [[ $consistency_issues -eq 0 ]]; then
        echo -e "  ${GREEN}✅${NC} Semantic structure is consistent"
    else
        echo -e "  ${YELLOW}⚠️${NC} Found $consistency_issues semantic consistency issues"
    fi
}

# Function to check script permissions
check_script_permissions() {
    echo -e "\n${BLUE}🔧 Checking script permissions...${NC}"

    local permission_issues=0

    if [[ -d "scripts" ]]; then
        while IFS= read -r -d '' script; do
            if [[ -f "$script" ]]; then
                if [[ -x "$script" ]]; then
                    echo -e "  ${GREEN}✅${NC} $script (executable)"
                else
                    echo -e "  ${YELLOW}⚠️${NC} $script (not executable)"
                    permission_issues=$((permission_issues + 1))
                fi
            fi
        done < <(find scripts -name "*.sh" -print0 2>/dev/null || true)

        if [[ $permission_issues -gt 0 ]]; then
            echo -e "      ${BLUE}💡${NC} Run: chmod +x scripts/**/*.sh to fix"
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC} Scripts directory not found"
    fi
}

# Function to generate structure health report
generate_health_report() {
    echo -e "\n${BLUE}📊 Structure Health Report${NC}"
    echo "=================================================="

    local total_issues=$((structure_errors + naming_violations + missing_indices))

    echo "Directories checked: $total_directories"
    echo -e "Structure errors: ${RED}$structure_errors${NC}"
    echo -e "Naming violations: ${YELLOW}$naming_violations${NC}"
    echo -e "Missing indices: ${RED}$missing_indices${NC}"
    echo -e "Total issues: $total_issues"

    # Calculate health score
    local total_checks=$((total_directories + ${#required_root_files[@]} + ${#directories_needing_index[@]}))
    local health_score=$(( (total_checks - total_issues) * 100 / total_checks ))

    echo ""
    echo "Structure Health Score: $health_score%"

    if [[ $health_score -ge 90 ]]; then
        echo -e "${GREEN}🏆 Excellent structure health!${NC}"
    elif [[ $health_score -ge 70 ]]; then
        echo -e "${YELLOW}👍 Good structure health${NC}"
    elif [[ $health_score -ge 50 ]]; then
        echo -e "${YELLOW}⚠️  Structure needs attention${NC}"
    else
        echo -e "${RED}🚨 Structure needs significant improvement${NC}"
    fi
}

# Main execution
check_directory_structure
check_required_files
check_index_files
check_naming_conventions
check_file_organization
check_semantic_consistency
check_script_permissions
generate_health_report

# Summary and exit
echo ""
echo "=================================================="
echo -e "${BLUE}✅ Structure verification completed${NC}"

if [[ $structure_errors -eq 0 ]] && [[ $missing_indices -eq 0 ]]; then
    if [[ $naming_violations -eq 0 ]]; then
        echo -e "${GREEN}🎉 All structural requirements met!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Minor naming convention issues found${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ Critical structural issues found${NC}"
    echo ""
    echo "Recommended actions:"
    if [[ $structure_errors -gt 0 ]]; then
        echo "• Create missing directories and files"
    fi
    if [[ $missing_indices -gt 0 ]]; then
        echo "• Add index.md files to organize navigation"
    fi
    if [[ $naming_violations -gt 0 ]]; then
        echo "• Rename files to follow kebab-case convention"
    fi
    exit 1
fi