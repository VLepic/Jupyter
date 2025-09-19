# PyTorch 2.7.1 (CUDA 12.6, cuDNN 9)
FROM pytorch/pytorch:2.7.1-cuda12.6-cudnn9-runtime

ENV PATH=/opt/conda/bin:$PATH

RUN conda create -n PyTorch python=3.12 -y && conda clean -afy

ENV PATH=/opt/conda/envs/PyTorch/bin:$PATH
ENV CONDA_DEFAULT_ENV=PyTorch

RUN python -m pip install --upgrade pip && \
    pip install jupyterlab ipykernel && \
    python -m ipykernel install --name PyTorch --display-name "PyTorch (Python 3.12)" --sys-prefix

RUN pip install --index-url https://download.pytorch.org/whl/cu126 \
      torch torchvision torchaudio

WORKDIR /mnt/user/appdata/jupyter
VOLUME ["/mnt/user/appdata/jupyter"]

EXPOSE 8888


CMD ["conda","run","-n","PyTorch","jupyter","lab",\
     "--notebook-dir=/mnt/user/appdata/jupyter",\
     "--ip=0.0.0.0","--port=8888","--no-browser","--allow-root",\
     "--ServerApp.token=","--ServerApp.password="]






