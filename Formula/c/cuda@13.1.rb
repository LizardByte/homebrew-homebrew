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
    sha256 cellar: :any_skip_relocation, x86_64_linux: "da6fe4ebf2bb09d5cc816e612b896306e8ac47c3479c820c1b62de44a31c88d3"
  end

  # Force building from source
  pour_bottle? do
    reason "CUDA requires building from source to ensure all runtime files are present"
    satisfy { false }
  end

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
           "--toolkitpath=#{prefix}",
           "--no-opengl-libs",
           "--no-drm",
           "--no-man-page"

    # Only cleanup in our custom tap to satisfy the audit
    if build.bottle?
      ohai "CUDA Cleanup: Removing files for bottle audit compliance"
      # Remove non-executable files from bin directory
      rm prefix/"bin/nvcc.profile" if (prefix/"bin/nvcc.profile").exist?
      rm_r prefix/"bin/crt" if (prefix/"bin/crt").exist?

      # Remove binaries built for non-native architectures
      # Remove 32-bit x86 binaries (not needed on modern 64-bit systems)
      rm_r prefix/"compute-sanitizer/x86" if (prefix/"compute-sanitizer/x86").exist?

      # Remove 32-bit x86 binaries from nsight-compute as well
      Pathname.glob(prefix/"nsight-compute-*/target/linux-desktop-glibc_2_11_3-x86").each do |path|
        rm_r path if path.exist?
      end

      if Hardware::CPU.intel?
        # On x86_64, remove ARM binaries
        Pathname.glob(prefix/"nsight-compute-*/target/linux-desktop-t210-a64").each do |path|
          rm_r path if path.exist?
        end
      elsif Hardware::CPU.arm?
        # On ARM, remove x86_64 binaries
        Pathname.glob(prefix/"nsight-compute-*/target/linux-desktop-glibc_2_17_3-x64").each do |path|
          rm_r path if path.exist?
        end
      end
    end
  end

  def caveats
    <<~EOS
      CUDA Toolkit #{version} has been installed to:
        #{prefix}

      The nvcc compiler is available at:
        #{bin}/nvcc

      To use CUDA in your projects, you may need to set the following environment variables:
        export CUDA_HOME=#{prefix}
        export PATH=#{bin}:$PATH
        export LD_LIBRARY_PATH=#{lib}:$LD_LIBRARY_PATH

      Note: This formula only installs the CUDA Toolkit (compiler and libraries).
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
  end
end
