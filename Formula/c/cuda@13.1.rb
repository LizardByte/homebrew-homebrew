class CudaAT131 < Formula
  CUDA_VERSION = "13.1.1".freeze
  DRIVER_VERSION = "590.48.01".freeze
  INTEL_SHA256 = "24ff323723722781436804b392a48f691cb40de9808095d3e2192d0db6dfb8e4".freeze
  ARM_SHA256 = "8adcd5d4b3e1e70f7420959b97514c0c97ec729da248d54902174c4d229bfd2c".freeze

  desc "NVIDIA CUDA Toolkit - GPU-accelerated library and nvcc compiler"
  homepage "https://developer.nvidia.com/cuda-toolkit"

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

  depends_on "cmake" => :test
  depends_on :linux

  def install
    ohai "Installing CUDA Toolkit #{version}"

    # Determine the installer filename based on architecture
    installer = if Hardware::CPU.intel?
      "cuda_#{version}_#{DRIVER_VERSION}_linux.run"
    else
      "cuda_#{version}_#{DRIVER_VERSION}_linux_sbsa.run"
    end

    # set tmp directory variable and create it
    tmpdir = buildpath/"tmp"
    tmpdir.mkpath

    # Run the CUDA installer in silent mode
    system "sh", installer,
           "--defaultroot=#{lib}",
           "--no-drm",
           "--no-man-page",
           "--no-opengl-libs",
           "--silent",
           "--tmpdir=#{tmpdir}",
           "--toolkit",
           "--toolkitpath=#{libexec}"

    # NOTE: We do not symlink lib64 or include to avoid conflicts and hacks
    # Dependent formulae should use CMAKE_CUDA_TOOLKIT_ROOT_DIR=#{libexec}
    # or set CUDA_HOME=#{libexec} to find libraries and headers

    # Create wrapper scripts for CUDA binaries
    # This ensures they can find cuda_runtime.h, nvcc.profile, and other dependencies
    Dir[libexec/"bin/*"].select { |f| File.file?(f) && File.executable?(f) }.each do |exe|
      binary_name = File.basename(exe)
      (bin/binary_name).write <<~EOS
        #!/bin/bash
        export CUDA_HOME="#{libexec}"
        export PATH="#{libexec}/bin:$PATH"
        export LD_LIBRARY_PATH="#{libexec}/lib64:$LD_LIBRARY_PATH"
        exec "#{libexec}/bin/#{binary_name}" "$@"
      EOS
      chmod 0755, bin/binary_name
    end
  end

  def caveats
    <<~EOS
      CUDA Toolkit #{version} has been installed to:
        #{opt_libexec}

      Wrapper scripts for CUDA binaries are available at:
        #{opt_bin}/nvcc

      These wrappers automatically set CUDA_HOME for you.

      For CMake projects (sunshine-beta example):
        cuda_path = Formula["lizardbyte/homebrew/cuda@13.1"]
        args << "-DCMAKE_CUDA_COMPILER=\#{cuda_path.opt_bin}/nvcc"
        args << "-DCMAKE_CUDA_TOOLKIT_ROOT_DIR=\#{cuda_path.opt_libexec}"

      For shell/manual configuration:
        export CUDA_HOME=#{opt_libexec}
        export PATH=#{opt_bin}:$PATH
        export LD_LIBRARY_PATH=#{opt_libexec}/lib64:$LD_LIBRARY_PATH

      This formula only installs the CUDA Toolkit (compiler and libraries).
      You still need to install the NVIDIA driver separately for your system.

      Verify your installation with:
        nvcc --version
    EOS
  end

  test do
    # Test that nvcc is available and can report its version
    assert_match version.to_s, shell_output("#{bin}/nvcc --version")

    # Test compiling a simple CUDA program
    (testpath/"test.cu").write <<~EOS
      #include <stdio.h>

      __global__ void hello() {
        printf("Hello from CUDA!\\n");
      }

      int main() {
        printf("CUDA Toolkit Test\\n");
        return 0;
      }
    EOS

    # Compile the test program
    system bin/"nvcc", "test.cu", "-o", "test"
    assert_path_exists testpath/"test"

    # Test that CMake can find the CUDA toolkit
    # This verifies that cmake_cuda_find_toolkit works correctly
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.18)
      project(CUDATest LANGUAGES CXX CUDA)

      message(STATUS "CUDA Toolkit Root: ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")
      message(STATUS "CUDA Compiler: ${CMAKE_CUDA_COMPILER}")

      add_executable(cuda_test test.cu)
    EOS

    # Try to configure the CMake project
    # This will fail if CMake cannot find the CUDA library root
    system "cmake", "-S", testpath, "-B", testpath/"build",
           "-DCMAKE_CUDA_COMPILER=#{bin}/nvcc",
           "-DCMAKE_CUDA_TOOLKIT_ROOT_DIR=#{libexec}"

    # Verify CMake found the CUDA toolkit
    assert_path_exists testpath/"build/CMakeCache.txt"
  end
end
