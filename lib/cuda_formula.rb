# frozen_string_literal: true

# Common module for CUDA formula implementations
# This module contains all shared logic for CUDA Toolkit installations
module CudaFormula
  def self.included(base)
    base.class_eval do
      depends_on "cmake" => :test
      depends_on :linux

      # Default livecheck - will be overridden by setup_livecheck if CUDA_VERSION is defined
      livecheck do
        url "https://developer.nvidia.com/cuda-toolkit-archive"
        regex(%r{href="/cuda-(?:downloads|[\d-]+-download-archive)">CUDA\s+Toolkit\s+v?(\d+\.\d+\.[\d.]+)}i)
      end
    end
  end

  # Call this method after defining CUDA_VERSION to set up version-specific livecheck
  def self.setup_livecheck(formula_class)
    cuda_version = formula_class::CUDA_VERSION
    major_minor = cuda_version[/^(\d+\.\d+)/, 1]

    formula_class.class_eval do
      livecheck do
        url "https://developer.nvidia.com/cuda-toolkit-archive"
        regex(%r{href="/cuda-(?:downloads|[\d-]+-download-archive)">CUDA\s+Toolkit\s+v?
                 (#{Regexp.escape(major_minor)}\.[\d.]+)}ix)
      end
    end
  end

  def install
    ohai "Installing CUDA Toolkit #{version}"

    # Determine the installer filename based on architecture
    installer = if Hardware::CPU.intel?
      "cuda_#{version}_#{self.class::DRIVER_VERSION}_linux.run"
    else
      "cuda_#{version}_#{self.class::DRIVER_VERSION}_linux_sbsa.run"
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

    # Symlink all .so files from Nsight tools
    # This allows Homebrew's linkage checker to find bundled libraries
    # The tools will still use their bundled copies via RPATH
    # So this hack is not truly necessary, other than to get CI to pass

    # Use install_symlink with glob to create proper relative symlinks for bottles
    lib.install_symlink libexec.glob("nsight-*/**/*.so*")

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

      Note: Nsight tools (Nsight Systems, Nsight Compute) have their libraries
      symlinked to #{opt_lib} for Homebrew compatibility, but the tools
      use their bundled versions via RPATH.

      Verify your installation with:
        nvcc --version
    EOS
  end

  def test
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
    # This will fail if CMake cannot find a working CUDA compiler
    system "cmake", "-S", testpath, "-B", testpath/"build",
           "-DCMAKE_CUDA_COMPILER=#{bin}/nvcc"

    # Verify CMake found the CUDA toolkit
    assert_path_exists testpath/"build/CMakeCache.txt"
  end
end
