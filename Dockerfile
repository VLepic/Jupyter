FROM condaforge/miniforge3:26.7.2-0

ARG NB_UID=99
ARG NB_GID=100
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      tini git build-essential ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    (getent group "${NB_GID}" || groupadd --gid "${NB_GID}" notebook) && \
    useradd --uid "${NB_UID}" --gid "${NB_GID}" --create-home --shell /bin/bash jupyter && \
    mkdir -p /mnt/user/appdata/jupyter && \
    chown -R "${NB_UID}:${NB_GID}" /opt/conda /home/jupyter /mnt/user/appdata/jupyter

ENV HOME=/home/jupyter \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

USER jupyter
RUN conda create --yes --name PyTorch python=3.12 pip && conda clean --all --yes
ENV PATH=/opt/conda/envs/PyTorch/bin:/opt/conda/bin:$PATH \
    CONDA_DEFAULT_ENV=PyTorch \
    CONDA_PREFIX=/opt/conda/envs/PyTorch

# CUDA wheels include the runtime, but not the host driver.
RUN python -m pip install \
      torch==2.11.0 torchvision==0.26.0 torchaudio==2.11.0 \
      --index-url https://download.pytorch.org/whl/cu128
COPY requirements.txt /opt/notebook-requirements.txt
RUN python -m pip install -r /opt/notebook-requirements.txt && \
    python -m pip check && \
    python -m ipykernel install --name PyTorch --display-name "Python 3.12 / PyTorch (CUDA 12.8)" --sys-prefix && \
    python -c "import torch; assert torch.version.cuda == '12.8', torch.version.cuda" && \
    printf '\nsource /opt/conda/etc/profile.d/conda.sh\nconda activate PyTorch\n' >> /home/jupyter/.bashrc

COPY check_gpu.py /opt/check_gpu.py
COPY start-notebook.sh /usr/local/bin/start-notebook.sh

WORKDIR /mnt/user/appdata/jupyter
EXPOSE 8888
ENTRYPOINT ["/usr/bin/tini", "--", "/bin/bash", "/usr/local/bin/start-notebook.sh"]
CMD ["jupyter", "lab", "--ServerApp.root_dir=/mnt/user/appdata/jupyter", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
