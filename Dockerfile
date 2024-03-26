# Use the specified PyTorch image with CUDA 12.1 and cuDNN 8 development environment
FROM pytorch/pytorch:2.2.1-cuda12.1-cudnn8-runtime

# Install wget and bzip2 (needed to install Anaconda)
RUN apt-get update && apt-get install -y wget bzip2
# Install the latest version of Anaconda by downloading the latest installer
RUN wget https://repo.anaconda.com/archive/Anaconda3-2024.02-1-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

# Set PATH to include the Anaconda bin directory
ENV PATH /opt/conda/bin:$PATH

# Create a new Anaconda environment with Python 3.11
RUN conda create -n anaconda11 python=3.11 -y
RUN echo "source activate anaconda11" > ~/.bashrc
ENV PATH /opt/conda/envs/anaconda11/bin:$PATH

# Install JupyterLab in the new environment
RUN conda install -n anaconda11 -c conda-forge jupyterlab -y

# Since PyTorch is already installed, verify compatibility with Python 3.11 and CUDA 12.1
# If needed, update PyTorch within the environment to ensure compatibility
# RUN conda install -n myenv -c pytorch pytorch torchvision torchaudio cudatoolkit=12.1 -y

# Set up the working directory
WORKDIR /mnt/user/appdata/jupyter
VOLUME ["/mnt/user/appdata/jupyter"]

# Expose the default Jupyter port
EXPOSE 8888

# Start Jupyter Lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password='dm'"]



