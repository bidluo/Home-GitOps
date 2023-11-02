# K3s GitOps

Hey there! 👋 Thanks for stopping by. This repo is a little window into my world of managing Kubernetes with K3s on Flux. It's a practical setup, a bit of experimentation, and a whole lot of learning on the go. Dive in and take a look around!
It's kept up to date as it is a 'production' cluster

## Table of Contents

- [Repository Structure](#repository-structure)
- [CI/CD and Automation](#cicd-and-automation)
- [Security and Compliance](#security-and-compliance)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Repository Structure

The repository is structured as follows:

```
├── .github/            # GitHub Actions and workflows
├── apps/               # Application values and definitions
├── base/               # Base configuration and flux generated files
├── charts/             # Chart repository definitions
├── configs/            # Cluster wide configurations
└── README.md
```

## CI/CD and Automation

This repository leverages GitHub Actions for continuous integration and deployment. The workflows are defined in the `.github/workflows/` directory. They ensure that every change pushed to the repository is automatically synced to the K3s cluster using Flux.

## Security and Compliance

I use SOPS (Secrets OPerationS) for managing secrets securely. SOPS lets me encrypt my secrets so that I can safely store them in my Git repository.

### Why?
- Transparent Encryption/Decryption: SOPS decrypts files on-the-fly, making it feel like you're working with plain text.
- Fine-Grained Control: It allows encrypting only the values, not the keys, in my secret files. This balances security and usability well.
- Versatile Key Management: It supports various key management services, fitting well in different cloud environments.
- Smooth Integration with Flux: I’ve set things up so Flux and SOPS work seamlessly together, decrypting secrets during deployment without exposing sensitive information.

## License

This project is open-sourced under the [MIT License](LICENSE).

## Acknowledgements

A big thank you to all the contributors and maintainers of the tools and technologies used in this project, including K3s, KairosOS, Flux, and the wider Kubernetes community.
