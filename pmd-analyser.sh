#!/bin/bash
# shellcheck shell=bash

# Check whether to use latest version of PMD
if [ "$PMD_VERSION" == 'latest' ]; then
    DOWNLOAD_URL="$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pmd/pmd/releases/latest | jq --raw-output '.assets[] | select(.name | contains("bin")) | select(.name | contains("asc") | not) | .browser_download_url')"
    PMD_FILENAME="$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pmd/pmd/releases/latest | jq --raw-output '.assets[] | select(.name | contains("bin")) | select(.name | contains("asc") | not) | .name')"
    LATEST_TAG="$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pmd/pmd/releases/latest | jq --raw-output '.tag_name')"
    PMD_VERSION="${LATEST_TAG#"pmd_releases/"}"
else
    DOWNLOAD_URL="$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pmd/pmd/releases/tags/pmd_releases%2F"${PMD_VERSION}" | jq --raw-output '.assets[] | select(.name | contains("bin")) | select(.name | contains("asc") | not) | .browser_download_url')"
    PMD_FILENAME="$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pmd/pmd/releases/tags/pmd_releases%2F"${PMD_VERSION}" | jq --raw-output '.assets[] | select(.name | contains("bin")) | select(.name | contains("asc") | not) | .name')"
    LATEST_TAG="$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pmd/pmd/releases/tags/pmd_releases%2F"${PMD_VERSION}" | jq --raw-output '.tag_name')"
    PMD_VERSION="${LATEST_TAG#"pmd_releases/"}"
fi

# Download PMD
wget "${DOWNLOAD_URL}"
unzip "${PMD_FILENAME}"

# Now either run the full analysis or files changed based on the settings defined
if [ "$ANALYSE_ALL_CODE" == 'true' ]; then
    # Need to have a more future proof way once PMD 7 is stable, but for now we can just check if the version contains a 7
    if [[ "$PMD_VERSION" == *7* ]]; then
        PATH=$PATH:pmd-bin-"${PMD_VERSION}"/bin/
        pmd check -d "$FILE_PATH" -R "$RULES_PATH" --fail-on-violation false -f sarif > pmd-raw-output.sarif
    else
        pmd-bin-"${PMD_VERSION}"/bin/run.sh pmd -d "$FILE_PATH" -R "$RULES_PATH" --fail-on-violation false -f sarif > pmd-raw-output.sarif
    fi
else
    if [ "$ACTION_EVENT_NAME" == 'pull_request' ]; then
        # Now to determine whether to get the files changed from a git diff or using the files changed in a GitHub Pull Request
        # Both options will generate a CSV file first with the files changed
        if [ "$FILE_DIFF_TYPE" == 'git' ]; then
            git diff --name-only --diff-filter=d origin/"$CURRENT_CODE"..origin/"${CHANGED_CODE#"refs/heads/"}" | paste -s -d "," >> diff-file.csv
        else
            curl -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${AUTH_TOKEN}" https://api.github.com/repos/"$REPO_NAME"/pulls/"$PR_NUMBER"/files | jq --raw-output '.[] .filename' | paste -s -d "," >> diff-file.csv
        fi
    else
        # Irrespective of the file type diff selected on a push event, we will always do a git diff (as we can't get that from the GitHub API)
        git diff --name-only --diff-filter=d "$CURRENT_CODE".."$CHANGED_CODE" | paste -s -d "," >> diff-file.csv
    fi
    # Run the analysis
    # Need to have a more future proof way once PMD 7 is stable, but for now we can just check if the version contains a 7
    if [[ "$PMD_VERSION" == *7* ]]; then
        PATH=$PATH:pmd-bin-"${PMD_VERSION}"/bin/
        pmd check -filelist diff-file.csv -R "$RULES_PATH" -failOnViolation false -f sarif > pmd-raw-output.sarif
    else
        pmd-bin-"${PMD_VERSION}"/bin/run.sh pmd -filelist diff-file.csv -R "$RULES_PATH" -failOnViolation false -f sarif > pmd-raw-output.sarif
    fi
fi
# Loop through each rule and see if an error should be thrown
echo "error-found=false" >> "$GITHUB_OUTPUT"
while read -r rule; do
    RULE="$(echo "$rule" | jq --raw-output '.id')"
    if [[ "$RULE" && "$ERROR_RULES" == *"$RULE"* ]]; then
        echo "error-found=true" >> "$GITHUB_OUTPUT"
        break
    fi
done <<< "$(jq --compact-output '.runs[] .tool .driver .rules[]' < pmd-raw-output.sarif)"
# Set the correct file location for the report
jq --arg workspace "$WORKSPACE" '(.runs[] .results[] .locations[] .physicalLocation .artifactLocation .uri) |= ltrimstr($workspace)' < pmd-raw-output.sarif > pmd-file-locations-output.sarif
# Set the rule level configurations for whether they are notes or errors
jq --arg errors "$ERROR_RULES" '((.runs[] .tool .driver .rules[]) | select(.id==($errors | split(",")[]))) += {"defaultConfiguration": {"level": "error"}}' < pmd-file-locations-output.sarif > pmd-errors-output.sarif
jq --arg notes "$NOTE_RULES" '((.runs[] .tool .driver .rules[]) | select(.id==($notes | split(",")[]))) += {"defaultConfiguration": {"level": "note"}}' < pmd-errors-output.sarif > pmd-output.sarif
