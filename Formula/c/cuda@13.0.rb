require_relative "../../lib/cuda_formula"

class CudaAT130 < Formula
  include CudaFormula

  desc "NVIDIA CUDA Toolkit - GPU-accelerated library and nvcc compiler"
  homepage "https://developer.nvidia.com/cuda-toolkit"

  CUDA_VERSION = "13.0.2".freeze
  DRIVER_VERSION = "580.95.05".freeze
  INTEL_SHA256 = "81a5d0d0870ba2022efb0a531dcc60adbdc2bbff7b3ef19d6fd6d8105406c775".freeze
  ARM_SHA256 = "93ab4c77ae2bc0f1f600ef48ccd3ff25a3203a6a6161a84511a33cbf5b5621fc".freeze

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
    sha256 cellar: :any, arm64_linux:  "99ed824a06e23a53939d36ea1cb2dc8ce6e84c832d7f351d4703ce49cee38317"
    sha256 cellar: :any, x86_64_linux: "c18b139fcc9127bd657c5addf5dc876fc6dc1957e105426aa32c5c13fc96abcc"
  end
end
