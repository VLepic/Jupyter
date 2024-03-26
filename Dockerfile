
FROM pytorch/pytorch:2.2.1-cuda12.1-cudnn8-runtime

ENV PATH /opt/conda/bin:$PATH

RUN conda create -n anaconda11 python=3.11 -y
RUN echo "source activate anaconda11" > ~/.bashrc
ENV PATH /opt/conda/envs/anaconda11/bin:$PATH

RUN conda install -n anaconda11 -c conda-forge jupyterlab -y

WORKDIR /mnt/user/appdata/jupyter
VOLUME ["/mnt/user/appdata/jupyter"]

EXPOSE 8888

CMD ["conda", "run", "-n", "anaconda11", "jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password='dm'"]




