"""Run inside a disposable container with Jupyter already running."""

import importlib
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import urllib.request

import nbformat
from nbclient import NotebookClient


assert os.getuid() != 0, "Notebook must not run as root"
assert os.environ["CONDA_DEFAULT_ENV"] == "PyTorch"
subprocess.run(["conda", "--version"], check=True)
subprocess.run(["mamba", "--version"], check=True)
subprocess.run(["python", "-m", "pip", "check"], check=True)
subprocess.run(
    ["bash", "-ic", "conda activate PyTorch && test \"$CONDA_PREFIX\" = /opt/conda/envs/PyTorch"],
    check=True,
)

for module in (
    "torch", "torchvision", "torchaudio", "numpy", "pandas", "scipy", "sklearn",
    "matplotlib", "seaborn", "plotly", "sympy", "PIL", "openpyxl", "pyarrow",
    "tqdm", "requests", "ipywidgets", "jupyterlab_git",
):
    importlib.import_module(module)

request = urllib.request.Request("http://127.0.0.1:8888/api/kernelspecs")
token = os.environ.get("JUPYTER_TOKEN")
if token:
    request.add_header("Authorization", f"token {token}")
with urllib.request.urlopen(request, timeout=15) as response:
    specs = json.load(response)["kernelspecs"]
assert "pytorch" in specs, specs

cell = '''
import io, os, sys
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import torch
from sklearn.linear_model import LinearRegression
assert os.getuid() != 0
assert sys.prefix == "/opt/conda/envs/PyTorch", sys.prefix
assert torch.version.cuda == "12.8"
assert "sm_120" in torch._C._cuda_getArchFlags()
assert (torch.ones(4, 4) @ torch.ones(4, 4)).sum().item() == 64
frame = pd.DataFrame({"x": [1, 2, 3], "y": [2, 4, 6]})
buffer = io.BytesIO()
frame.to_parquet(buffer)
buffer.seek(0)
pd.testing.assert_frame_equal(frame, pd.read_parquet(buffer))
model = LinearRegression().fit(frame[["x"]], frame["y"])
assert abs(model.coef_[0] - 2) < 1e-6
plt.plot(frame.x, frame.y)
plot = io.BytesIO()
plt.savefig(plot, format="png")
assert plot.getbuffer().nbytes > 1000
plt.close("all")
print("Kernel, CPU PyTorch, Parquet, scikit-learn and plotting passed.")
'''

with tempfile.TemporaryDirectory(dir=Path.cwd()) as directory:
    notebook = nbformat.v4.new_notebook(cells=[nbformat.v4.new_code_cell(cell)])
    NotebookClient(notebook, kernel_name="pytorch", timeout=90).execute(cwd=directory)
    path = Path(directory) / "smoke.ipynb"
    nbformat.write(notebook, path)
    nbformat.validate(nbformat.read(path, as_version=4))

with tempfile.TemporaryDirectory(dir=Path.home()) as directory:
    (Path(directory) / "writable").write_text("ok")

print(f"PASS: Jupyter HTTP, kernel execution, notebook save, packages and permissions ({os.getuid()}:{os.getgid()}).")
