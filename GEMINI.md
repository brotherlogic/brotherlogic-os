# Gemini Agent Instructions

Welcome, Agent. To maintain the integrity and workflow of the `brotherlogic-os` repository, please adhere to the following guidelines when making modifications.

## 🛠 Making Changes

1.  **Research & Plan**: Always research the existing configuration (located in `recipes/` and `files/`) before making changes.
2.  **Implementation**: After obtaining approval, implement your changes using the appropriate tools.
3.  **Verification**: Verify your changes where possible by checking syntax or confirming file paths.

## 🚀 Completing the Task

Once your modifications are complete, you **MUST** follow the `/finish` workflow to commit and push your changes.

### The `/finish` Workflow
This workflow is defined in [.agents/workflows/finish.md](file:///.agents/workflows/finish.md) and should be executed using terminal commands:

1.  **Verify**: Check changes with `git status` and `git diff`.
2.  **Branch**: Create a new branch if on `main`: `git checkout -b <descriptive-name>`.
3.  **Stage**: Add your changes: `git add <files>`.
4.  **Commit**: Use a clear commit message: `git commit -m "<Description>"`.
5.  **Push**: Push to origin: `git push -u origin <branch-name>`.
6.  **Report**: provide the GitHub Pull Request creation link to the user.

> [!IMPORTANT]
> Always use a new branch for changes unless we're already on a non-main branch
