#!/bin/bash
# ktests.sh - Common test framework runner
# Usage: ktests.sh SCRIPT_DIR [SUITE_NAME] [TEST_FILTER] [OPTIONS]
# Parameters:
#   SCRIPT_DIR    - Directory containing test files (usually $SCRIPT_DIR from caller)
#   SUITE_NAME    - Name of the test suite (for display)
#   TEST_FILTER   - Optional grep pattern to filter test files (default: '/[0-9][0-9][0-9]_')
#   OPTIONS       - Additional options passed to kt_runner_parse_args

set -o pipefail

# Check required parameter
if [[ -z "$1" ]]; then
    echo "Error: SCRIPT_DIR parameter required"
    echo "Usage: ktests.sh SCRIPT_DIR [SUITE_NAME] [TEST_FILTER] [remaining_options...]"
    exit 1
fi

SCRIPT_DIR="$1"
SUITE_NAME="${2:-Test Suite}"
TEST_FILTER="${3:-/[0-9][0-9][0-9]_}"

# Shift to remove consumed arguments
if [[ $# -ge 3 ]]; then
    shift 3
elif [[ $# -ge 2 ]]; then
    shift 2
else
    shift 1
fi

# Determine ktests library directory based on current script location
KTESTS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KTESTS_LIB_DIR
source "$KTESTS_LIB_DIR/ktest.sh"

# Parse remaining command line arguments
kt_runner_parse_args "$@"

# Show test execution info
kt_test_section "Starting $SUITE_NAME"

# Find test files
test_files=()
while IFS= read -r file; do
    test_files+=("$file")
done < <(kt_runner_find_tests "$SCRIPT_DIR" | grep "$TEST_FILTER")

if [[ ${#test_files[@]} -eq 0 ]]; then
    kt_test_error "No test files found in $SCRIPT_DIR matching pattern: $TEST_FILTER"
    exit 1
fi

# Show test files to be executed in info mode
if [[ "$VERBOSITY" == "info" ]]; then
    echo "Found ${#test_files[@]} test file(s):"
    for f in "${test_files[@]}"; do
        echo "  - $(basename "$f")"
    done
    echo ""
fi

# Execute all tests
kt_runner_execute_tests "$SCRIPT_DIR"

# Display final results
echo ""
kt_test_show_results "${FAILED_TEST_FILES[@]}"

# Exit with appropriate code
exit $?
