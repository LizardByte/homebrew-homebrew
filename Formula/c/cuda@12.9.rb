require_relative "../../lib/cuda_formula"

class CudaAT129 < Formula
  include CudaFormula

  desc "NVIDIA CUDA Toolkit - GPU-accelerated library and nvcc compiler"
  homepage "https://developer.nvidia.com/cuda-toolkit"

  CUDA_VERSION = "12.9.1".freeze
  DRIVER_VERSION = "575.57.08".freeze
  INTEL_SHA256 = "0f6d806ddd87230d2adbe8a6006a9d20144fdbda9de2d6acc677daa5d036417a".freeze
  ARM_SHA256 = "64f47ab791a76b6889702425e0755385f5fa216c5a9f061875c7deed5f08cdb6".freeze

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
    sha256 cellar: :any, arm64_linux:  "9f427fcb4bcd3e5eb2736b502287474ebbfe2988bf0b9c92bfba615febad8db5"
    sha256 cellar: :any, x86_64_linux: "10763e20564695a9dbb6573d45a4e9671e68c6cffeaa9fb0cfca0e67575fbf6d"
  end
end
