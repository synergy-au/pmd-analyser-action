# Contributing Guidelines
Below provides an overview of guidelines for contributing to this project. We are continuing to improve our standards and guidelines as the project matures so feedback is always welcome.

## Code of Conduct
We have [established Code of Conduct guidelines](./CODE_OF_CONDUCT.md) for creating an inclusive environment to contribute to this project.

## Coding Standards
We are using [ShellCheck](https://github.com/koalaman/shellcheck) to lint this script. Our ShellCheck rule configuration could do with some improvement so feedback is definitely welcome. We have the extension setup for making use of GitHub Codespaces, but aren't running the linter as part of a GitHub Action (would be open to have this setting up as well once rules are in place).

## Commit Messaging Standards
We treat commit messaging as part of our documentation to describe the evolution and rationale of how this project is in its current state. Therefore we follow these [Commit Messaging Guidelines](https://chris.beams.io/posts/git-commit/) which can be summarised as:

1. Separate subject from body with a blank line
2. Limit the subject line to 50 characters
3. Capitalize the subject line
4. Do not end the subject line with a period
5. Use the imperative mood in the subject line
6. Wrap the body at 72 characters
7. Use the body to explain what and why vs. how

We will ask for commit messages to be refactored in pull requests if it doesn't meet these guidelines.