1) Change into the repo: `cd /path/to/ISPD26-Contest`
2) Start the Docker environment:
   ```bash
   docker run -it --rm -v ${PWD}:/work udxs/ispd26:v3
   ```
   - `-it`: run interactively with a TTY.
   - `--rm`: remove the container when you exit.
   - `-v ${PWD}:/work`: mount the current directory into `/work` inside the container.
      - `${PWD}` expands to your current directory; different shells/OSes vary:
        - macOS/Linux bash/zsh: `-v ${PWD}:/work`
        - POSIX sh/ksh: `-v $PWD:/work`
        - Windows PowerShell: `-v ${PWD}:/work`
        - Windows CMD: `-v %CD%:/work`
        - Portable fallback: `-v "$(pwd)":/work`
