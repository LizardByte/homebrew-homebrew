class CudaAT131 < Formula
  CUDA_VERSION = "13.1.0".freeze
  DRIVER_VERSION = "590.44.01".freeze
  INTEL_SHA256 = "6b4fdf2694b3d7afbc526f26412b4cf4f050b202324455053307310f53b323a7".freeze
  ARM_SHA256 = "06cda49a7031b1c99f784237be5c852619379cbba9555036045044b9ddc99240".freeze

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
    rebuild 3
    sha256 cellar: :any_skip_relocation, x86_64_linux: "dbc2fe792ce4a748642a2386176e2944975201fbbcaab487ff716281f8a74675"
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

    # Run the CUDA installer in silent mode
    system "sh", installer,
           "--silent",
           "--toolkit",
           "--toolkitpath=#{libexec}",
           "--no-opengl-libs",
           "--no-drm",
           "--no-man-page"

    # Symlink directories for CMake CUDA toolkit detection
    # CMake needs to find the CUDA root with bin/, lib/, include/, etc.
    # Only symlink actual executables to bin/ (exclude config files like nvcc.profile)
    bin.install_symlink Dir[libexec/"bin/*"].select { |f| File.file?(f) && File.executable?(f) }
    lib.install_symlink Dir[libexec/"lib64/*"]
    include.install_symlink Dir[libexec/"include/*"]

    # Symlink other important CUDA directories that tools might need
    (prefix/"nvvm").install_symlink Dir[libexec/"nvvm/*"] if (libexec/"nvvm").exist?
    (prefix/"extras").install_symlink Dir[libexec/"extras/*"] if (libexec/"extras").exist?
  end

  def caveats
    <<~EOS
      CUDA Toolkit #{version} has been installed to:
        #{libexec}

      The nvcc compiler is available at:
        #{bin}/nvcc

      To use CUDA in your projects, you may need to set the following environment variables:
        export CUDA_HOME=#{libexec}
        export PATH=#{bin}:$PATH
        export LD_LIBRARY_PATH=#{lib}:$LD_LIBRARY_PATH

      NOTE: CUDA_HOME points to libexec where nvcc.profile and other config files are located.

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
