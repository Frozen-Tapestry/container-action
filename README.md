# Podman (Login,Build,Push) GitHub Action

This repository provides a GitHub Action to build and push container images using [Podman](https://podman.io/). It supports Podman login, building images from Dockerfiles, and pushing images to container registries.

## Features

- Build container images with Podman.
- Push images to a container registry (e.g., `ghcr.io`, `quay.io`).
- Flexible support for build arguments, labels, tags, and security options.
- Designed to run in GitHub workflows for CI/CD automation.
- Supports Gitea Actions with a shared storage between runs.

## Directory Structure

```plaintext
podman-action
├── LICENSE                 # License information (MIT)
├── README.md               # This documentation
├── .github
│    └── workflows
│        └── verify.yml     # Example GitHub workflow for verification
├── scripts
│   └── run.sh              # Core script to handle Podman operations
└── action.yml              # GitHub Action definition
```

## Usage

### Example Workflow

Add the following workflow file to `.github/workflows/build.yml`:

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
        uses: frozen-tapestry/podman-build-push-action@v1
        with:
          login_registry: ghcr.io
          login_username: ${{ secrets.REGISTRY_USERNAME }}
          login_password: ${{ secrets.REGISTRY_PASSWORD }}
          tags: ghcr.io/your-namespace/your-image:latest
          dockerfile: path/to/Dockerfile
          push: true
```

### Inputs

| Input            | Description                                                                                      | Required | Default          |
|------------------|--------------------------------------------------------------------------------------------------|----------|------------------|
| `login_registry` | The container registry to push to (e.g., `ghcr.io`).                                             | No       |                  |
| `login_username` | Registry username.                                                                               | No       |                  |
| `login_password` | Registry password (use GitHub secrets).                                                          | No       |                  |
| `tags`           | Tags for the image (space-separated or newline-separated).                                       | No       |                  |
| `labels`         | Additional metadata for the image (space-separated or newline-separated).                        | No       |                  |
| `build_args`     | Build arguments (space-separated or newline-separated).                                          | No       |                  |
| `extra_args`     | Extra arguments for the `podman build` command (newline-separated).                              | No       |                  |
| `dockerfile`     | Path to the Dockerfile. If set, the build step is performed.                                     | No       |                  |
| `push`           | Whether to push the image after building.                                                        | No       | `false`          |
| `shared_path`    | Path to a shared folder for cache files on the host filesystem (useful for self-hosted runners). | No       | `/tmp/shared`    |
| `security`       | Security options for the intermediate container (space-separated).                               | No       | `--network=host` |

## Development

### Verify Workflow

The `verify.yml` workflow tests the action by:
1. Creating a temporary `Dockerfile`.
2. Building and pushing the container image.
3. Running the container to validate its output.

You can use this workflow as a template for testing your own usage.

### Core Script

The main logic for building and pushing images resides in the `scripts/run.sh` file. It:
- Logs into the container registry if credentials are provided.
- Builds the container image with specified tags, labels, and build arguments.
- Pushes the image if the `push` input is set to `true`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributions

Contributions, issues, and feature requests are welcome! Feel free to open a pull request or issue in this repository.