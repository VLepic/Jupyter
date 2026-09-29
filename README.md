# General-purpose GPU Python notebook

Miniforge provides Conda and Mamba. The default `PyTorch` environment contains
Python 3.12, PyTorch 2.11.0, torchvision 0.26.0, torchaudio 2.11.0 and CUDA 12.8.
It supports RTX 5070 Ti (Blackwell, sm_120) and other GPUs supported by these
PyTorch wheels. NVIDIA GPUs are optional for ordinary Python work; the supplied
Compose file requests a GPU. CUDA compilation tools (`nvcc`) are not included.

JupyterLab includes widgets and Git integration. NumPy, pandas, SciPy,
scikit-learn, Matplotlib, Seaborn, Plotly, SymPy, Pillow, OpenPyXL, PyArrow,
tqdm and requests are preinstalled. Git, a C/C++ compiler and FFmpeg are included.
GPU-aware libraries such as PyTorch can use CUDA; pandas and scikit-learn do not
automatically become GPU-accelerated.

## Unraid deployment

Install an NVIDIA driver supporting your GPU through the Unraid NVIDIA Driver
plugin and configure Docker NVIDIA GPU passthrough. CUDA 12.8 Update 1 lists
Linux driver 570.124.06 or newer; prefer a current supported driver.
Confirm the GPU appears in `nvidia-smi` on the server.

Jupyter runs as `jupyter`, default UID 99 / GID 100 (Unraid's usual
`nobody:users` mapping). The entrypoint starts as root, repairs ownership and
owner write permissions under `/mnt/user/appdata/jupyter` and `/home/jupyter`,
then drops privileges before starting Jupyter. This includes old root-owned
notebooks and `.ipynb_checkpoints`. It does not follow symlinks. On large folders
the initial permission scan can take time. The mounts must be read-write.

For different IDs, set `NB_UID` and `NB_GID` in a project `.env` file before
building. Both IDs are build arguments, not runtime user remapping.
Set `FIX_PERMISSIONS=0` to disable automatic ownership changes on storage whose
permissions you manage separately. An explicit non-root Docker `--user` also
skips repair, so the mounted directories must already be writable.

```sh
docker compose build --pull
docker compose up -d
docker compose exec --user jupyter jupyter python /opt/check_gpu.py
```

Open `http://<unraid-address>:8888`. Existing notebooks retain the `PyTorch`
kernel name. Notebook files persist in `/mnt/user/appdata/jupyter`; the named
volume `jupyter-home` retains settings, caches, user kernels and custom Conda
environments. Do not use `docker compose down -v` to perform an upgrade.

For Unraid GUI deployment, build the image with the correct UID/GID, enable
NVIDIA GPU passthrough, mount the notebook folder and a separate persistent
directory at `/home/jupyter`, and add `--shm-size=2g` to Extra Parameters.
Leave the image's default user and entrypoint in place so startup can repair
permissions. Jupyter and its terminals still run without root privileges.

Authentication remains off by default, matching the previous deployment.
Set `JUPYTER_TOKEN` in `.env` (or the Unraid container environment) to enable it.

## Python packages and environments

The terminal starts in the `PyTorch` environment. Use `%pip install package`
in a notebook or `python -m pip install package` in the terminal. Changes to
the built-in environment survive restart but not container recreation; add
permanent dependencies to `requirements.txt` and rebuild.
For a shell through Docker, use `docker compose exec --user jupyter jupyter bash`;
plain `docker exec` inherits the image's root startup user.

For a separate persistent environment, run in the Jupyter terminal:

```sh
conda create -y -p "$HOME/.conda/envs/analysis" python=3.12 pip ipykernel pandas
conda activate "$HOME/.conda/envs/analysis"
python -m ipykernel install --user --name analysis --display-name "Python (analysis)"
```

Select that kernel in Jupyter. Additional environments need their own PyTorch
installation if they use the GPU; use matching CUDA wheels from pytorch.org.

## Stability and diagnostics

The image uses Tini to forward shutdown signals and reap orphaned processes.
Compose allows 30 seconds for shutdown, rotates logs, and allocates 2 GB shared
memory for DataLoader workers. This is a limit, not 2 GB reserved on startup.

A root warning alone does not explain a crash. Inspect evidence first:

```sh
docker compose logs --tail=200 jupyter
docker inspect pytorch-jupyter --format '{{.State.OOMKilled}} {{.State.ExitCode}} {{.State.Error}}'
docker stats --no-stream pytorch-jupyter
docker compose exec --user jupyter jupyter df -h /dev/shm
docker compose exec --user jupyter jupyter python /opt/check_gpu.py
```

- `OOMKilled=true` indicates the container was killed due to host/container
  memory pressure; a killed notebook kernel alone may not set this flag.
- CUDA out-of-memory errors concern VRAM; reduce batch/model size.
- DataLoader bus errors can indicate exhausted shared memory; reduce workers
  or increase `shm_size` after checking host RAM.
- CUDA initialization errors require checking the host driver and GPU passthrough.
- Permission errors require matching directory ownership to the container user.

## Sources

- https://github.com/conda-forge/miniforge
- https://pytorch.org/get-started/previous-versions/
- https://developer.nvidia.com/cuda/gpus
- https://docs.nvidia.com/cuda/archive/12.8.1/cuda-toolkit-release-notes/
- https://docs.pytorch.org/tutorials/intermediate/intermediate_data_loading_tutorial.html
