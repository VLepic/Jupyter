"""Run inside the container: python /opt/check_gpu.py."""

import torch
import torch.nn.functional as F


def main():
    print(f"PyTorch: {torch.__version__}; CUDA: {torch.version.cuda}")
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is unavailable. Check the host driver and Docker GPU passthrough.")

    print(f"Compiled architectures: {torch.cuda.get_arch_list()}")
    for index in range(torch.cuda.device_count()):
        device = torch.device("cuda", index)
        capability = torch.cuda.get_device_capability(index)
        print(f"GPU {index}: {torch.cuda.get_device_name(index)}; capability: {capability}")
        # Exercise CUDA kernels, cuBLAS, cuDNN and autograd, not just device detection.
        x = torch.ones((256, 256), device=device)
        torch.testing.assert_close(x @ x, torch.full_like(x, 256))
        inputs = torch.randn(2, 3, 32, 32, device=device, requires_grad=True)
        weights = torch.randn(8, 3, 3, 3, device=device, requires_grad=True)
        loss = F.conv2d(inputs, weights).square().mean()
        loss.backward()
        torch.cuda.synchronize(index)
        assert torch.isfinite(loss).item(), "Non-finite convolution result"
        assert torch.isfinite(inputs.grad).all().item(), "Non-finite gradients"
        print(f"GPU {index}: matrix multiplication and convolution backward passed.")


if __name__ == "__main__":
    main()
