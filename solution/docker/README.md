# Docker Workflow

Use the prebuilt contest image to get a consistent OpenROAD environment.

## Quick start
```bash
# from repo root
wsl solution/docker/get_into_docker.sh
```
This script runs:
```
docker run -it --rm -v ${PWD}:/ISPD26-Contest udxs/ispd26:v4
```
- `-it`: interactive shell.
- `--rm`: container is removed on exit.
- `-v ${PWD}:/ISPD26-Contest`: mounts your repo into the container.
- `udxs/ispd26:v4`: contest image with required tooling.

## Manual run (if script not executable)
```bash
docker run -it --rm -v "$(pwd)":/ISPD26-Contest udxs/ispd26:v4
```

## Notes
- Work inside `/ISPD26-Contest` in the container; changes persist to your host.
- Exit the shell to stop and remove the container.
