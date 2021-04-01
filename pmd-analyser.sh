# shellcheck shell=sh

ERROR_COUNT=0

# Download PMD
wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F"${PMD_VERSION}"/pmd-bin-"${PMD_VERSION}".zip
unzip pmd-bin-"${PMD_VERSION}".zip
# Now either run the full analysis or files changed based on the settings defined
if [ "$ANALYSE_ALL_CODE" == 'true' ]; then
    pmd-bin-"${PMD_VERSION}"/bin/run.sh pmd -d "$FILE_PATH" -R "$RULES_PATH" -failOnViolation false -f json > pmd-output.json
else
    # Generate a CSV file first with the files changed
    git diff --name-only --diff-filter=d origin/"$TARGET_BRANCH"..origin/"${SOURCE_BRANCH#"refs/heads/"}" | paste -s -d "," >> diff-file.csv
    # Run the analysis
    pmd-bin-"${PMD_VERSION}"/bin/run.sh pmd -filelist diff-file.csv -R "$RULES_PATH" -failOnViolation false -f json > pmd-output.json
fi
# Loop through each file and then loop through each violation identified
 while read -r file; do
    FILENAME="$(echo "$file" | jq --raw-output '.filename | ltrimstr("${{ github.workspace }}/")')"
    while read -r violation; do
        MESSAGE="$(echo "$violation" | jq --raw-output '" \(.ruleset) - \(.rule): \(.description). This applies from line \(.beginline) to \(.endline) and from column \(.begincolumn) to \(.endcolumn). For more information on this rule visit \(.externalInfoUrl)"')"
        LINE="$(echo "$violation" | jq --raw-output '.beginline')"
        COLUMN="$(echo "$violation" | jq --raw-output '.begincolumn')"
        RULE="$(echo "$violation" | jq --raw-output '.rule')"
        if [ -n "$RULE" ]; then
            if [[ "$ERROR_RULES" == *"$RULE"* ]]; then
                echo ::error file="$FILENAME",line="$LINE",col="$COLUMN"::"$MESSAGE"
                ERROR_COUNT=$((ERROR_COUNT + 1))
            else
                echo ::warning file="$FILENAME",line="$LINE",col="$COLUMN"::"$MESSAGE"
            fi
        fi
    done <<< "$(echo "$file" | jq --compact-output '.violations[]')"
done <<< "$(cat pmd-output.json | jq --compact-output '.files[]')"
# If there are any errors logged we want this to fail (warnings don't count)
if [ "$ERROR_COUNT" -gt 0 ]; then
    exit 3
fi