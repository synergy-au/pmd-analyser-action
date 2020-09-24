# PMD Analyser - GitHub Action

GitHub Action to run [PMD Analyser](https://pmd.github.io/) based on the ruleset defined. This is using [ShellCheck](https://github.com/koalaman/shellcheck) to lint this script.

By default this will generate warning notifications for any rule violations specified in the ruleset on a pull request or a push, but the check won't fail. If you wish for some rule violations to cause error notifications and for the check to fail, you can specify the rule names in a comma separated input in the workflow file.

## Example GitHub Action Workflow File
```
name: PMD Static Code Analysis
on:
  pull_request:
  push:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2
        with:
          # If you are looking to do incremental diffs on push, set the fetch depth to 0
          # For all other situations for performance purposes, set the fetch depth to 1
          fetch-depth: '1'
      - name: Run PMD Analyser
        uses: synergy-au/pmd-analyser-action@v1
        with:
          pmd-version: '6.27.0'
          file-path: './src'
          rules-path: './pmd-ruleset.xml'
          error-rules: 'AvoidDirectAccessTriggerMap,AvoidDmlStatementsInLoops,AvoidHardcodingId'
```

## Inputs

### analyse-all-code

Used to determine whether you just want to analyse the files changed or the whole repository. Note that if you wish to analyse the files changed on pushes only, you will need to set the fetch-depth in the checkout action in the workflow to '0'.

-   required: false
-   default: 'false'

### error-rules

If you wish to define rules that log as an error, enter each rule name separated with a comma and no spaces. Note that if an error is identified the run will fail. e.g. ClassNamingConventions,GuardLogStatement

-   required: false

### file-path

Path to the sources to analyse. This can be a file name, a directory, or a jar or zip file containing the sources.

-   required: true

### pmd-version

The version of PMD you would like to run.

-   required: true
-   default: '6.27.0'

### rules-path

The ruleset file you want to use. PMD uses xml configuration files, called rulesets, which specify which rules to execute on your sources. You can also run a single rule by referencing it using its category and name (more details here). For example, you can check for unnecessary modifiers on Java sources with -R category/java/codestyle.xml/UnnecessaryModifier.

-   required: true
