FROM pytorch/pytorch:2.2.1-cuda12.1-cudnn8-runtime

ENV PATH /opt/conda/bin:$PATH


RUN conda create -n torch11 python=3.11 -y
ENV PATH /opt/conda/envs/torch11/bin:$PATH
RUN conda install -n torch11 pytorch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 pytorch-cuda=12.1 -c pytorch -c nvidia -y
RUN conda install -n torch11 -c conda-forge jupyterlab -y
RUN conda run -n torch11 python -m ipykernel install --user --name=torch11 --display-name="PyTorch (Python 3.11)"


RUN conda create -n tf-gpu python=3.11 tensorflow-gpu -c conda-forge -y
RUN conda install -n tf-gpu -c conda-forge jupyterlab -y
RUN conda run -n tf-gpu python -m ipykernel install --user --name=tf-gpu --display-name="TensorFlow GPU (Python 3.11)"

WORKDIR /mnt/user/appdata/jupyter
VOLUME ["/mnt/user/appdata/jupyter"]

EXPOSE 8888

CMD ["conda", "run", "-n", "torch11", "jupyter", "lab", "--notebook-dir=/mnt/user/appdata/jupyter", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]




