require_relative "../../lib/cuda_formula"

class CudaAT132 < Formula
  include CudaFormula

  desc "NVIDIA CUDA Toolkit - GPU-accelerated library and nvcc compiler"
  homepage "https://developer.nvidia.com/cuda-toolkit"

  CUDA_VERSION = "13.2.1".freeze
  DRIVER_VERSION = "595.58.03".freeze
  INTEL_SHA256 = "5514a3fe7bcea92b25073c7c100c3e64e7961a7e1dbad6955adb8b59806053f0".freeze
  ARM_SHA256 = "38560e0c48eba793c883ea1ada6ad4c37b744cb5284034d16fd7ee57f95dda04".freeze

  # Set up version-specific livecheck
  CudaFormula.setup_livecheck(self)

  if Hardware::CPU.arm?
      url "https://developer.download.nvidia.com/compute/cuda/#{CUDA_VERSION}/local_installers/cuda_#{CUDA_VERSION}_#{DRIVER_VERSION}_linux_sbsa.run"
      sha256 ARM_SHA256
  else
      url "https://developer.download.nvidia.com/compute/cuda/#{CUDA_VERSION}/local_installers/cuda_#{CUDA_VERSION}_#{DRIVER_VERSION}_linux.run"
      sha256 INTEL_SHA256
  end

  bottle do
      root_url "https://ghcr.io/v2/lizardbyte/homebrew"
      sha256 cellar: :any_skip_relocation, x86_64_linux: "0000000000000000000000000000000000000000000000000000000000000000"
  end
end
