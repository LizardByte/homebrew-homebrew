require "language/node"

class Sunshine < Formula
  include Language::Python::Virtualenv

  CUDA_VERSION = "13.1".freeze
  CUDA_FORMULA = "cuda@#{CUDA_VERSION}".freeze
  GCC_VERSION = "14".freeze
  GCC_FORMULA = "gcc@#{GCC_VERSION}".freeze
  IS_UPSTREAM_REPO = ENV.fetch("GITHUB_REPOSITORY", "") == "LizardByte/Sunshine"

  desc "Self-hosted game stream host for Moonlight"
  homepage "https://app.lizardbyte.dev/Sunshine"
  url "https://github.com/LizardByte/Sunshine.git",
    tag: "v2026.516.143833"
  license all_of: ["GPL-3.0-only"]
  revision 1
  head "https://github.com/LizardByte/Sunshine.git", branch: "master"

  # https://docs.brew.sh/Brew-Livecheck#githublatest-strategy-block
  livecheck do
    url :stable
    regex(/^v?(\d+\.\d+\.\d+)$/i)
    strategy :github_latest do |json, regex|
      match = json["tag_name"]&.match(regex)
      next if match.blank?

      match[1]
    end
  end

  bottle do
    root_url "https://ghcr.io/v2/lizardbyte/homebrew"
    sha256 arm64_tahoe:   "ca316bf66d3119037beab511c0043b9dae74c6e397066436e5e91ff16bbbbc88"
    sha256 arm64_sequoia: "2d820a687bc2c582466d664775c63b3f6572780e253e90c196e97ef02de23bc7"
    sha256 arm64_sonoma:  "afda612549511738422a19f509d8682d822ea7d330c2771709278ad55e095d7f"
    sha256 arm64_linux:   "cd9a326604c8f313701160ea132a77b1ac569dbbc7c1c279b26204674c2e02c1"
    sha256 x86_64_linux:  "f2e0393c42e4114e93dcf2664888aa4cd46f96bef56f306d635fa17e25973e96"
  end

  option "with-cuda", "Enable CUDA support (Linux only)"
  option "with-docs", "Enable docs build"
  option "with-static-boost", "Enable static link of Boost libraries"
  option "without-static-boost", "Disable static link of Boost libraries" # default option

  depends_on "cmake" => :build
  depends_on "doxygen" => :build if build.with? "docs"
  depends_on "graphviz" => :build if build.with? "docs"
  depends_on "node" => :build
  depends_on "pkgconf" => :build
  depends_on "gcovr" => :test
  depends_on "boost"
  depends_on "curl"
  depends_on "icu4c@78"
  depends_on "miniupnpc"
  depends_on "openssl@3"
  depends_on "opus"

  on_macos do
    depends_on "llvm" => [:build, :test]
  end

  on_linux do
    depends_on GCC_FORMULA => [:build, :test]
    depends_on "lizardbyte/homebrew/#{CUDA_FORMULA}" => :build if build.with? "cuda"
    depends_on "python3" => :build
    depends_on "at-spi2-core"
    depends_on "avahi"
    depends_on "ayatana-ido"
    depends_on "cairo"
    depends_on "gdk-pixbuf"
    depends_on "glib"
    depends_on "gnu-which"
    depends_on "gtk+3"
    depends_on "harfbuzz"
    depends_on "libayatana-appindicator"
    depends_on "libayatana-indicator"
    depends_on "libcap"
    depends_on "libdbusmenu"
    depends_on "libdrm"
    depends_on "libice"
    depends_on "libnotify"
    depends_on "libsm"
    depends_on "libva"
    depends_on "libx11"
    depends_on "libxcb"
    depends_on "libxcursor"
    depends_on "libxext"
    depends_on "libxfixes"
    depends_on "libxi"
    depends_on "libxinerama"
    depends_on "libxrandr"
    depends_on "libxtst"
    depends_on "mesa"
    depends_on "numactl"
    depends_on "pango"
    depends_on "pipewire"
    depends_on "pulseaudio"
    depends_on "shaderc"
    depends_on "systemd"
    depends_on "vulkan-loader"
    depends_on "wayland"

    # Jinja2 is required at build time by the glad OpenGL/EGL loader generator (Linux only).
    # Declared as resources per https://docs.brew.sh/Formula-Cookbook#python-dependencies
    resource "markupsafe" do
      url "https://files.pythonhosted.org/packages/7e/99/7690b6d4034fffd95959cbe0c02de8deb3098cc577c67bb6a24fe5d7caa7/markupsafe-3.0.3.tar.gz"
      sha256 "722695808f4b6457b320fdc131280796bdceb04ab50fe1795cd540799ebe1698"
    end

    resource "jinja2" do
      url "https://files.pythonhosted.org/packages/df/bf/f7da0350254c0ed7c72f3e33cef02e048281fec7ecec5f032d4aac52226b/jinja2-3.1.6.tar.gz"
      sha256 "0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d"
    end

    # setuptools provides pkg_resources which glad's plugin.py imports at build time.
    # setuptools >= 81 removed pkg_resources; this is the last release that still ships it.
    resource "setuptools" do
      url "https://files.pythonhosted.org/packages/76/95/faf61eb8363f26aa7e1d762267a8d602a1b26d4f3a1e758e92cb3cb8b054/setuptools-80.10.2.tar.gz"
      sha256 "8b0e9d10c784bf7d262c4e5ec5d4ec94127ce206e8738f29a437945fbc219b70"
    end
  end

  conflicts_with "sunshine-beta", because: "sunshine and sunshine-beta cannot be installed at the same time"

  fails_with :clang do
    build 1400
    cause "Requires C++23 support"
  end

  fails_with :gcc do
    version "12" # fails with GCC 12.x and earlier
    cause "Requires C++23 support"
  end

  fails_with :gcc do
    version "13"
    cause "Array out of bounds error when compiling glad sources"
  end

  # Backport https://github.com/LizardByte/Sunshine/pull/5223 so Linux Homebrew
  # installs service/udev files inside the prefix instead of system paths.
  patch :DATA

  def setup_build_environment
    ENV["BRANCH"] = ""
    ENV["BUILD_VERSION"] = "2026.516.143833"
    ENV["COMMIT"] = "14ffa6fdaa53f7b51512be2b3d24f3939695403c"

    setup_linux_gcc_environment if OS.linux?

    return unless OS.linux?

    # Install jinja2 (required by the glad OpenGL/EGL loader generator) into a
    # temporary virtualenv. We pass its Python path to cmake via Python_EXECUTABLE
    # so glad uses the venv Python that has jinja2, and set GLAD_SKIP_PIP_INSTALL=ON
    # to prevent cmake from trying to pip-install again.
    # Follows https://docs.brew.sh/Formula-Cookbook#python-dependencies
    venv = virtualenv_create(buildpath/"venv", "python3")
    venv.pip_install resources
    @glad_python = (buildpath/"venv/bin/python3").to_s
  end

  def setup_linux_gcc_environment
    # Use GCC because gcov from llvm cannot handle our paths
    gcc_path = Formula[GCC_FORMULA]
    ENV["CC"] = "#{gcc_path.opt_bin}/gcc-#{GCC_VERSION}"
    ENV["CXX"] = "#{gcc_path.opt_bin}/g++-#{GCC_VERSION}"
  end

  def base_cmake_args
    args = %W[
      -DBUILD_WERROR=ON
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DGLAD_SKIP_PIP_INSTALL=ON
      -DHOMEBREW_ALLOW_FETCHCONTENT=ON
      -DOPENSSL_ROOT_DIR=#{formula_opt_prefix("openssl")}
      -DSUNSHINE_ASSETS_DIR=sunshine/assets
      -DSUNSHINE_BUILD_HOMEBREW=ON
      -DSUNSHINE_PUBLISHER_NAME='LizardByte'
      -DSUNSHINE_PUBLISHER_WEBSITE='https://app.lizardbyte.dev'
      -DSUNSHINE_PUBLISHER_ISSUE_URL='https://app.lizardbyte.dev/support'
    ]
    args << "-DSUNSHINE_EXECUTABLE_PATH=#{opt_bin}/sunshine" if OS.linux?
    # Point cmake at the venv Python that has jinja2 installed (set up in setup_build_environment)
    args << "-DPython_EXECUTABLE=#{@glad_python}" if @glad_python
    args
  end

  def add_test_args(args)
    if IS_UPSTREAM_REPO
      args << "-DBUILD_TESTS=ON"
      ohai "Building tests: enabled"
    else
      args << "-DBUILD_TESTS=OFF"
      ohai "Building tests: disabled"
    end
  end

  def add_docs_args(args)
    if build.with? "docs"
      ohai "Building docs: enabled"
      args << "-DBUILD_DOCS=ON"
    else
      ohai "Building docs: disabled"
      args << "-DBUILD_DOCS=OFF"
    end
  end

  def add_boost_args(args)
    if build.without? "static-boost"
      args << "-DBOOST_USE_STATIC=OFF"
      ohai "Disabled statically linking Boost libraries"
    else
      configure_static_boost(args)
    end
  end

  def configure_static_boost(args)
    args << "-DBOOST_USE_STATIC=ON"
    ohai "Enabled statically linking Boost libraries"

    unless formula_any_version_installed?("icu4c")
      odie <<~EOS
        icu4c must be installed to link against static Boost libraries,
        either install icu4c or use brew install sunshine --with-static-boost instead
      EOS
    end
    ENV.append "CXXFLAGS", "-I#{formula_opt_include("icu4c")}"
    icu4c_lib_path = formula_opt_lib("icu4c").to_s
    ENV.append "LDFLAGS", "-L#{icu4c_lib_path}"
    ENV["LIBRARY_PATH"] = icu4c_lib_path
    ohai "Linking against ICU libraries at: #{icu4c_lib_path}"
  end

  def add_cuda_args(args)
    return unless OS.linux?

    if build.with?("cuda")
      configure_cuda(args)
    else
      args << "-DSUNSHINE_ENABLE_CUDA=OFF"
      ohai "CUDA disabled"
    end
  end

  def configure_cuda(args)
    cuda_path = Formula["lizardbyte/homebrew/#{CUDA_FORMULA}"]
    nvcc_path = "#{cuda_path.opt_libexec}/homebrew/bin/nvcc"
    gcc_path = Formula[GCC_FORMULA]

    args << "-DSUNSHINE_ENABLE_CUDA=ON"
    args << "-DCMAKE_CUDA_COMPILER:PATH=#{nvcc_path}"
    args << "-DCMAKE_CUDA_TOOLKIT_ROOT_DIR:PATH=#{cuda_path.opt_libexec}"
    args << "-DCMAKE_CUDA_HOST_COMPILER=#{gcc_path.opt_bin}/gcc-#{GCC_VERSION}"
    ohai "CUDA enabled with nvcc at: #{nvcc_path}"
  end

  def build_cmake_args
    args = base_cmake_args
    add_test_args(args)
    add_docs_args(args)
    add_boost_args(args)
    add_cuda_args(args)
    args
  end

  def build_and_install_project
    system "cmake", "-S", ".", "-B", "build", "-G", "Unix Makefiles",
            *std_cmake_args,
            *build_cmake_args

    system "make", "-C", "build"
    system "make", "-C", "build", "install"
  end

  def install_platform_specific_files
    bin.install "build/tests/test_sunshine" if IS_UPSTREAM_REPO

    # codesign the binary on intel macs
    system "codesign", "-s", "-", "--force", "--deep", bin/"sunshine" if OS.mac? && Hardware::CPU.intel?

    bin.install "src_assets/linux/misc/postinst" if OS.linux?
  end

  def install
    setup_build_environment
    build_and_install_project
    install_platform_specific_files
  end

  service do
    run [opt_bin/"sunshine", "~/.config/sunshine/sunshine.conf"] if OS.mac?
    name linux: "app-dev.lizardbyte.app.Sunshine" if OS.linux?
  end

  def post_install
    if OS.linux?
      opoo <<~EOS
        ATTENTION: To complete installation, you must run the following command:
        `sudo #{bin}/postinst`
      EOS
    end

    if OS.mac?
      opoo <<~EOS
        Gamepads are not currently supported on macOS.
      EOS
    end
  end

  def caveats
    <<~EOS
      Thanks for installing Sunshine!

      To get started, review the documentation at:
        https://docs.lizardbyte.dev/projects/sunshine
    EOS
  end

  test do
    # test that the binary runs at all
    system bin/"sunshine", "--version"

    if IS_UPSTREAM_REPO && ENV.fetch("HOMEBREW_BOTTLE_BUILD", "false") != "true"
      # run the test suite
      system bin/"test_sunshine", "--gtest_color=yes", "--gtest_output=xml:tests/test_results.xml"
      assert_path_exists File.join(testpath, "tests", "test_results.xml")

      # create gcovr report
      buildpath = ENV.fetch("HOMEBREW_BUILDPATH", "")
      unless buildpath.empty?
        # Change to the source directory for gcovr to work properly
        cd "#{buildpath}/build" do
          # Use GCC version to match what was used during compilation
          if OS.linux?
            gcc_path = Formula[GCC_FORMULA]
            gcov_executable = "#{gcc_path.opt_bin}/gcov-#{GCC_VERSION}"

            system "gcovr", ".",
              "-r", "../src",
              "--gcov-executable", gcov_executable,
              "--exclude-noncode-lines",
              "--exclude-throw-branches",
              "--exclude-unreachable-branches",
              "--xml-pretty",
              "-o=#{testpath}/coverage.xml"

            assert_path_exists File.join(testpath, "coverage.xml")
          end
        end
      end
    end
  end
end
# rebuild: 1779602876
__END__
diff --git a/cmake/packaging/linux.cmake b/cmake/packaging/linux.cmake
index 3bff6328..8f493b07 100644
--- a/cmake/packaging/linux.cmake
+++ b/cmake/packaging/linux.cmake
@@ -18,6 +18,13 @@ if(${SUNSHINE_BUILD_APPIMAGE} OR ${SUNSHINE_BUILD_FLATPAK})
             DESTINATION "${SUNSHINE_ASSETS_DIR}/modules-load.d")
     install(FILES "${CMAKE_CURRENT_BINARY_DIR}/app-${PROJECT_FQDN}.service"
             DESTINATION "${SUNSHINE_ASSETS_DIR}/systemd/user")
+elseif(${SUNSHINE_BUILD_HOMEBREW})
+    install(FILES "${SUNSHINE_SOURCE_ASSETS_DIR}/linux/misc/60-sunshine.rules"
+            DESTINATION "${CMAKE_INSTALL_LIBDIR}/udev/rules.d")
+    install(FILES "${SUNSHINE_SOURCE_ASSETS_DIR}/linux/misc/60-sunshine.conf"
+            DESTINATION "${CMAKE_INSTALL_LIBDIR}/modules-load.d")
+    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/app-${PROJECT_FQDN}.service"
+            DESTINATION ".")
 else()
     find_package(Systemd)
     find_package(Udev)
