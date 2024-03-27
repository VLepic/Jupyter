# Use the specified base image
FROM pytorch/pytorch:2.2.1-cuda11.8-cudnn8-runtime

# Ensure the conda binary is available in PATH
ENV PATH /opt/conda/bin:$PATH

# Create a conda environment for PyTorch
RUN conda create -n anaconda11 python=3.11 -y && \
    conda install -n anaconda11 pytorch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 -c pytorch -c nvidia -y && \
    conda install -n anaconda11 -c conda-forge jupyterlab -y && \
    conda run -n anaconda11 python -m ipykernel install --user --name=anaconda11 --display-name="Pytorch (python 3.11)"

# Create a conda environment for TensorFlow
RUN conda create -n tf python=3.11 -y && \
    conda install -n tf conda-forge::tensorflow -y && \
    conda run -n tf python -m ipykernel install --user --name=tf --display-name="Tensorflow (python 3.11)"

# Set the working directory
WORKDIR /mnt/user/appdata/jupyter

# Mount a volume
VOLUME ["/mnt/user/appdata/jupyter"]

# Expose the port JupyterLab will run on
EXPOSE 8888

# Command to run JupyterLab
CMD ["conda", "run", "-n", "anaconda11", "jupyter", "lab", "--notebook-dir=/mnt/user/appdata/jupyter", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]




