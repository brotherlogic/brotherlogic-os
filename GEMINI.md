# Brotherlogic OS

This project is a custom Fedora-based atomic OS image built using [BlueBuild](https://blue-build.org). It is based on [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) and customized for personal use.

## Project Structure

- **`recipes/recipe.yml`**: The main configuration file for the OS image. Defines the base image, packages, modules, and custom script snippets.
- **`files/system/`**: Contains configuration files and assets that are copied into the root filesystem of the image.
- **`modules/`**: Placeholder for custom BlueBuild modules.
- **`.agents/workflows/`**: Contains workflows for AI assistants (like this one).

## Modern BlueBuild Standards

- **Declarative Configuration**: Prefer using built-in BlueBuild modules (`dnf`, `rpm-ostree`, `flatpaks`) over raw script snippets whenever possible.
- **System-Wide Defaults**: When adding tools or configurations, ensure they are placed in system directories (`/usr/bin`, `/etc/skel`, `/usr/share`) to be available across the image.
- **Immutable Root**: Remember that the root filesystem is read-only. Persistent user data belongs in `/var/home`.

## AI Assistant Guidelines

### The Finish Command
> [!IMPORTANT]
> Whenever you make modifications to files in this repository, you **MUST** follow the [.agents/workflows/finish.md](file:///.agents/workflows/finish.md) workflow.
> This involves:
> 1. Verifying changes with `git status` and `git diff`.
> 2. Creating a new descriptive branch.
> 3. Committing and pushing the changes.
> 4. Providing the PR link to the user.

Always call the `/finish` command (or follow its steps) after completing any task that modifies the codebase.
