
FROM pytorch/pytorch:2.2.1-cuda11.8-cudnn8-runtime

ENV PATH /opt/conda/bin:$PATH

# Install Mamba in the base environment to speed up package management tasks
RUN conda install mamba -n base -c conda-forge -y

# Create a PyTorch environment with Python 3.11 using Mamba
RUN mamba create -n anaconda11 python=3.11 -y
RUN mamba install -n anaconda11 pytorch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 -c pytorch -c nvidia -y
RUN mamba install -n anaconda11 -c conda-forge jupyterlab -y
RUN mamba run -n anaconda11 python -m ipykernel install --user --name=anaconda11 --display-name="Pytorch (python 3.11)"

# Create a TensorFlow environment with Python 3.11 using Mamba
RUN mamba create -n tf python=3.11 -y
RUN mamba install -n tf conda-forge::tensorflow -y
RUN mamba run -n tf python -m ipykernel install --user --name=tf --display-name="Tensorflow (python 3.11)"

WORKDIR /mnt/user/appdata/jupyter

VOLUME ["/mnt/user/appdata/jupyter"]

EXPOSE 8888

CMD ["conda", "run", "-n", "anaconda11", "jupyter", "lab", "--notebook-dir=/mnt/user/appdata/jupyter", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]




