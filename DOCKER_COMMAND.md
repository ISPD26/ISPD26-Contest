# ISPD26 Contest – Docker Environment Setup

This repository is designed to be run inside a Docker container to ensure a consistent and reproducible environment for the ISPD 2026 Contest.

---

## Prerequisites

- Docker (Docker Desktop or Docker Engine)
- A cloned copy of this repository on your local machine

Verify Docker is available:

```bash
docker --version
```

---

## Quick Start

### 1. Enter the repository

```bash
cd /path/to/ISPD26-Contest
```

---

### 2. Start the Docker container

```bash
docker pull udxs/ispd26:v3
docker run -it --rm -v ${PWD}:/ISPD26-Contest udxs/ispd26:v3
```

This command launches an interactive container and mounts the current repository into the container.

---

## Docker Command Explained

| Option | Description |
|------|-------------|
| `-it` | Run interactively with a TTY |
| `--rm` | Automatically remove the container when it exits |
| `-v ${PWD}:/ISPD26-Contest` | Mount the current directory into `/ISPD26-Contest` inside the container |
| `udxs/ispd26:v3` | Pre-built Docker image for the ISPD26 contest |

---

## Volume Mount Notes (Shell Differences)

The `${PWD}` syntax depends on your shell and operating system:

- **macOS / Linux (bash, zsh)**  
  ```bash
  -v ${PWD}:/ISPD26-Contest
  ```

- **POSIX sh / ksh**  
  ```bash
  -v $PWD:/ISPD26-Contest
  ```

- **Windows PowerShell**  
  ```powershell
  -v ${PWD}:/ISPD26-Contest
  ```

- **Windows CMD**  
  ```cmd
  -v %CD%:/ISPD26-Contest
  ```

- **Portable fallback (recommended if unsure)**  
  ```bash
  -v "$(pwd)":/ISPD26-Contest
  ```

---

## Inside the Container

Once inside the container:

- Your repository is available at:
  ```bash
  /ISPD26-Contest
  ```
- All modifications are reflected back to your local filesystem.
- Exiting the shell will automatically stop and remove the container.

---

## Notes

- Do **not** modify the Docker image itself; all work should be done inside the mounted `/ISPD26-Contest` directory.
- This setup ensures environment consistency across different machines and operating systems.

---

## Exit

To exit the container:

```bash
exit
```

The container will be removed automatically due to `--rm`.
