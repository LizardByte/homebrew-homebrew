require_relative "../../lib/cuda_formula"

class CudaAT131 < Formula
  include CudaFormula

  desc "NVIDIA CUDA Toolkit - GPU-accelerated library and nvcc compiler"
  homepage "https://developer.nvidia.com/cuda-toolkit"

  CUDA_VERSION = "13.1.1".freeze
  DRIVER_VERSION = "590.48.01".freeze
  INTEL_SHA256 = "24ff323723722781436804b392a48f691cb40de9808095d3e2192d0db6dfb8e4".freeze
  ARM_SHA256 = "8adcd5d4b3e1e70f7420959b97514c0c97ec729da248d54902174c4d229bfd2c".freeze

  revision 1

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
    sha256 cellar: :any, arm64_linux:  "e4810b4ed3b724056898248f3a276d4fd90ab08d45d7232019d85fefc72b867f"
    sha256 cellar: :any, x86_64_linux: "3d9f716aaf64a96a8b68ca53bd6bf860aad7f05b9571e678406e4a88ec29a378"
  end
end
