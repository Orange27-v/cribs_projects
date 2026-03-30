#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TARBALL_NAME="cribs_arena_snapshot_${TIMESTAMP}.tar.gz"
TEMP_DIR="/Users/macbookpro/.gemini/tmp/4f7c85aa7468510426760b0f9ebfd7120cd089496ec6f4ee412c56c50fe4e148"
PROJECT_DIR="/Applications/XAMPP/xamppfiles/htdocs/project/cribs_arena"

tar -czf "${TEMP_DIR}/${TARBALL_NAME}" -C "$(dirname "${PROJECT_DIR}")" "$(basename "${PROJECT_DIR}")"

echo "Created snapshot: ${TEMP_DIR}/${TARBALL_NAME}"