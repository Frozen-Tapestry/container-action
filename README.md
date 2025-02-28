# Podman (Login, Build, Push) GitHub Action

This repository provides a GitHub Action to build and push container images using [Podman](https://podman.io/). The action supports Podman login, building images from Dockerfiles, and pushing images to container registries. It is designed to work seamlessly within GitHub workflows to automate CI/CD pipelines.

## Features

- **Build and Push:** Build container images and optionally push them to a container registry.
- **Flexible Configuration:** Support for build arguments, labels, tags, and security options.
- **CI/CD Ready:** Designed for GitHub Actions workflows.
- **Shared Storage Support:** Compatible with shared storage on self-hosted runners for caching.

## Directory Structure

```plaintext
container-action
├── LICENSE                 # License information (MIT)
├── README.md               # This documentation
├── .github
│    └── workflows
│        └── verify.yml     # Example workflow for testing
├── scripts
│   └── run.sh              # Core script to handle Podman operations
└── action.yml              # GitHub Action definition
```

## Usage

### Example Workflow

To use this action in a workflow, create a file `.github/workflows/build.yml` with the following content:

```yaml
name: Build and Push Container Image

on:
  push:
    branches:
      - main

jobs:
  build-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Use Podman Build and Push Action
        uses: Frozen-Tapestry/container-action@v1
        with:
          login_registry: ghcr.io
          login_username: ${{ secrets.REGISTRY_USERNAME }}
          login_password: ${{ secrets.REGISTRY_PASSWORD }}
          tags: ghcr.io/your-namespace/your-image:latest
          dockerfile: path/to/Dockerfile
          # Use those security flags if using GitHub Action. Keep the defaults, if using Gitea.
          security: |
            --security-opt=seccomp=unconfined
            --security-opt=apparmor=unconfined
          push: true
```

### Inputs

| Input            | Description                                                                                             | Required | Default          |
|------------------|---------------------------------------------------------------------------------------------------------|----------|------------------|
| `login_registry` | Container registry to push to (e.g., `quay.io`). If not set, the image is only built locally.           | No       |                  |
| `login_username` | Registry username.                                                                                      | No       |                  |
| `login_password` | Registry password (GitHub secret recommended).                                                          | No       |                  |
| `tags`           | Tags for the image. Space-separated. e.g. `quay.io/podman/stable:latest quay.io/podman/stable:nightly`. | No       |                  |
| `labels`         | List of additional metadata for an image. Space-separated.                                              | No       |                  |
| `build_args`     | Optional build arguments. Space-separated. e.g. `MY_ENV_VAR=Test MY_ENV_VAR2=Test2`.                    | No       |                  |
| `extra_args`     | Extra arguments to be passed to Podman. Space-separated. e.g. `-e=MY_ENV=Test -e=MY_ENV=Test2`.         | No       |                  |
| `dockerfile`     | Path to the Dockerfile. If set, the build step is performed.                                            | No       |                  |
| `push`           | Whether to push the image after building.                                                               | No       | `false`          |
| `security`       | Security flags used for an intermediate container. Newline-separated.                                   | No       | `--network=host` |

## Development

### Verify Workflow

The `verify.yml` workflow tests the action by:
1. Creating a temporary `Dockerfile`.
2. Building and pushing the container image.
3. Running the container to validate its output.

You can use this workflow as a template for testing your own usage. It is located at `.github/workflows/verify.yml`.

### Core Script

The main logic for building and pushing images resides in the `scripts/run.sh` file. It:
- Logs into the container registry if credentials are provided.
- Builds the container image with specified tags, labels, and build arguments.
- Pushes the image if the `push` input is set to `true`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributions

Contributions, issues, and feature requests are welcome! Feel free to open a pull request or issue in this repository.
