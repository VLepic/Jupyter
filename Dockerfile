FROM pytorch/pytorch:2.2.1-cuda11.8-cudnn8-runtime

ENV PATH /opt/conda/bin:$PATH

RUN conda create -n anaconda11 python=3.11 -y
ENV PATH /opt/conda/envs/anaconda11/bin:$PATH

RUN conda install -n anaconda11 pytorch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 pytorch-cuda=11.8 -c pytorch -c nvidia

RUN conda install -n anaconda11 -c conda-forge jupyterlab -y
RUN conda run -n anaconda11 python -m ipykernel install --user --name=anaconda11 --display-name="Pytorch (python 3.11)"




WORKDIR /mnt/user/appdata/jupyter
VOLUME ["/mnt/user/appdata/jupyter"]

EXPOSE 8888

CMD ["conda", "run", "-n", "anaconda11", "jupyter", "lab", "--notebook-dir=/mnt/user/appdata/jupyter", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]




