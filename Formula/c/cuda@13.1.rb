require_relative "../../lib/cuda_formula"

class CudaAT131 < Formula
  include CudaFormula

  desc "NVIDIA CUDA Toolkit - GPU-accelerated library and nvcc compiler"
  homepage "https://developer.nvidia.com/cuda-toolkit"

  CUDA_VERSION = "13.1.1".freeze
  DRIVER_VERSION = "590.48.01".freeze
  INTEL_SHA256 = "24ff323723722781436804b392a48f691cb40de9808095d3e2192d0db6dfb8e4".freeze
  ARM_SHA256 = "8adcd5d4b3e1e70f7420959b97514c0c97ec729da248d54902174c4d229bfd2c".freeze

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
    sha256 cellar: :any_skip_relocation, x86_64_linux: "0b78c36d6ccb5cb9f52d0d3aeb553ed7eed444595756a5d71d24bfd6a7ce1b48"
  end
end
# rebuild: 1769021478
