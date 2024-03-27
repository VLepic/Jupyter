FROM pytorch/pytorch:2.2.1-cuda12.1-cudnn8-runtime

ENV PATH /opt/conda/bin:$PATH

RUN conda create -n anaconda11 python=3.11 -y
ENV PATH /opt/conda/envs/anaconda11/bin:$PATH

RUN conda install -n anaconda11 pytorch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 pytorch-cuda=12.1 -c pytorch -c nvidia -y
#RUN conda install -n anaconda11 pytorch torchvision torchaudio -c pytorch -y
RUN conda install -n anaconda11 nvidia/label/cuda-12.1.1::cuda-toolkit -c pytorch -y

RUN conda install -n anaconda11 -c conda-forge jupyterlab -y

RUN conda run -n anaconda11 python -m ipykernel install --user --name=anaconda11 --display-name="Python 3.11 (Anaconda)"

WORKDIR /mnt/user/appdata/jupyter
VOLUME ["/mnt/user/appdata/jupyter"]

EXPOSE 8888

CMD ["conda", "run", "-n", "anaconda11", "jupyter", "lab", "--notebook-dir=/mnt/user/appdata/jupyter", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]




