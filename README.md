# PMD Analyser - GitHub Action

GitHub Action to run [PMD Analyser](https://pmd.github.io/) based on the ruleset defined. This action generates a SARIF report which can be uploaded to GitHub.

Features of this action include:

- Set the severity level you want rules reported at. Levels include error, warning and note (default level is warning).
- Run PMD Analyser on the files changed. File comparison can be done either based on a git diff or based on the files changed specified on the GitHub pull request.

## Example GitHub Action Workflow File
```
name: PMD Static Code Analysis
on:
  pull_request:
  push:

jobs:
  pmd-analyser-check:
    name: PMD Static Code Analysis
    permissions:
      security-events: write
      actions: read
      contents: read
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2
        with:
          # Incremental diffs require fetch depth to be at 0 to grab the target branch
          fetch-depth: '0'
      - name: Run PMD Analyser
        id: pmd-analysis
        uses: synergy-au/pmd-analyser-action@v2
        with:
          pmd-version: '6.34.0'
          file-path: './src'
          rules-path: './pmd-ruleset.xml'
          error-rules: 'AvoidDirectAccessTriggerMap,AvoidDmlStatementsInLoops,AvoidHardcodingId'
          note-rules: 'ApexDoc'
      - name: Upload results to GitHub
        uses: github/codeql-action/upload-sarif@v1
        with:
          sarif_file: pmd-output.sarif
      - name: No PMD Errors?
        run: |
          if ${{ steps.pmd-analysis.outputs.error-found }}
          then
            exit 3
          fi
```

## Inputs

### analyse-all-code

Used to determine whether you just want to analyse the files changed or the whole repository. Note that if you wish to analyse the files changed, you will need to set the fetch-depth in the checkout action in the workflow to '0'.

-   required: false
-   default: 'false'

### auth-token:
If you are looking to compare the file difference based on the GitHub pull request, you will need to specify the [GitHub secrets token](https://docs.github.com/en/actions/reference/authentication-in-a-workflow)'
    
-   required: false

### error-rules

If you wish to define rules that log as an error, enter each rule name separated with a comma and no spaces. Note that if an error is identified the run will fail. e.g. ClassNamingConventions,GuardLogStatement

-   required: false

### file-diff-type

Choose whether you want the file comparison to be based on a git diff or based on the files changed specified on the GitHub pull request. Note that if you use the GitHub pull request option, this action will only work on a pull request event. Options to set this are either `git` or `github`.
   
-   required: false
-   default: 'git'

### file-path

Path to the sources to analyse. This can be a file name, a directory, or a jar or zip file containing the sources.

-   required: true

### note-rules

If you wish to define rules that log as a note, enter each rule name separated with a comma and no spaces. Note that if a note is identified the run will not fail. e.g. ClassNamingConventions,GuardLogStatement

-   required: false

### pmd-version

The version of PMD you would like to run.

-   required: true
-   default: '6.33.0'

### rules-path

The ruleset file you want to use. PMD uses xml configuration files, called rulesets, which specify which rules to execute on your sources. You can also run a single rule by referencing it using its category and name (more details here). For example, you can check for unnecessary modifiers on Java sources with -R category/java/codestyle.xml/UnnecessaryModifier.

-   required: true

## Outputs

### error-found

Identifies whether an error has been found based on the error ruleset. If an error is found 'true' is returned.
