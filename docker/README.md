# ISPD26 Contest: Containers and Submission Information

## Container

The intention of this container is to provide a consistent interactive environment for development and evaluation. It is based on Ubuntu 24.04 and contains:
- OpenROAD - Binary installation with sources at `/OpenROAD` (Fork Commit `b84a4ac`)
    - This version is patched to support the [evaluator](../scripts/evaluation.tcl), see [this repository](https://github.com/sakundu/OpenROAD/tree/ispd26) if you wish to build your own version.
- OpenROAD-Flow-Scripts (commit `26b521c`)
- Conda 25.7.0 (Miniconda)
- Miscellaneous tools including Yosys.

See the [Dockerfile here](./dockerfile). A precompiled image can be retrieved from the Docker Hub [`udxs/ispd26:v4`](https://hub.docker.com/repository/docker/udxs/ispd26/tags/v4/sha256-d4e0f47c5c9628aece8ff02ebcd70cc4dfa8a5442046720891841fc77e8afacb). This image is also compatbile with Apptainer (formerly Singularity) - see below.

### Using Apptainer (Singularity)

For users with supercomputing environments, including contestants granted access to the Purdue Anvil system, it is possible to use Apptainer/Singularity instead of Docker. Unlike Docker, Apptainer (in `fakeroot` mode) will make your container directories read-only.

Thus, to support package installation, you need to create a writable "overlay" layer first, where Apptainer will store all changes. The process to do this and run the container is as follows:
```sh
# You only need to do this once but may create multiple overlays to represent multiple isolated instances.
# This example creates a 20 GB overlay but you may change this amount.
singularity overlay create --fakeroot -S -s 20480 my_overlay.img 

# For CPU only operation
singularity run -o my_overlay.img --fakeroot docker://udxs/ispd26:v4
# For CUDA-capable NVIDIA GPUs:
singularity run -o my_overlay.img --fakeroot --nv docker://udxs/ispd26:v4
```


## Submission Formatting 

 When you prepare your submission, you will be required to submit a ZIP file containing:
- A `setup.sh` that installs all necessary dependencies (incl. the ability to use `apt`, `pip`, and `conda`) and performs compilation
- A `run.sh` that will run your developed tool to produce the required DEF/Verilog output from a given input design.
- Any necessary data or code that is not already retrieved in your `setup.sh`.

The ZIP file should be named **TeamID_solution.zip** and submitted via the Dropbox [link](https://www.dropbox.com/request/EeQFhzvEIIHQEpM2jw2c). Contestants need to share the **cksum value** of the submission ZIP file via email (ispd26contest@gmail.com).

The contents of this ZIP file will be placed in `/opt/contest` in a fresh Apptainer container imaged as described above. `setup.sh` should install packages and 
set up any artifacts required for running your submission within the `/opt/contest` directory.

`run.sh <input_dir> <platform_dir> <output_dir> <top_module>` will be called as part of evaluation 
from the `/opt/contest` directory and will be called with the following arguments:
- `input_dir` contains the input design: `contest.def`, `contest.sdc`, and `contest.v`.
- `platform_dir` contains the ASAP7 enablement, in the same layout as [Platform/ASAP7](../Platform/ASAP7).
- `output_dir` is the empty directory in which you will place your `result.def` and `result.v`.
- `top_module` is the top module of the design.

See *Section 6. Submission Guidelines* and *Section 3.2.2. Platforms* in the [contest description](../ISPD26_contest_description.pdf) for more details. Please test your submission scripts in the container before submitting.