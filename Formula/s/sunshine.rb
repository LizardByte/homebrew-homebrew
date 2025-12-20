require "language/node"

class Sunshine < Formula
  GCC_VERSION = "14".freeze
  GCC_FORMULA = "gcc@#{GCC_VERSION}".freeze
  IS_UPSTREAM_REPO = ENV.fetch("GITHUB_REPOSITORY", "") == "LizardByte/Sunshine"

  desc "Self-hosted game stream host for Moonlight"
  homepage "https://app.lizardbyte.dev/Sunshine"
  url "https://github.com/LizardByte/Sunshine.git",
    tag: "v2025.924.154138"
  license all_of: ["GPL-3.0-only"]
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

  option "with-docs", "Enable docs"
  option "with-static-boost", "Enable static link of Boost libraries"
  option "without-static-boost", "Disable static link of Boost libraries" # default option

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "graphviz" => :build
  depends_on "node" => :build
  depends_on "pkgconf" => :build
  depends_on "curl"
  depends_on "icu4c@78"
  depends_on "miniupnpc"
  depends_on "openssl@3"
  depends_on "opus"

  on_linux do
    depends_on GCC_FORMULA => [:build, :test]
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
    depends_on "pulseaudio"
    depends_on "systemd"
    depends_on "wayland"
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

  def install
    ENV["BRANCH"] = ""
    ENV["BUILD_VERSION"] = "2025.924.154138"
    ENV["COMMIT"] = "86188d47a7463b0f73b35de18a628353adeaa20e"

    if OS.linux?
      gcc_path = Formula[GCC_FORMULA]
      ENV["CC"] = "#{gcc_path.opt_bin}/gcc-#{GCC_VERSION}"
      ENV["CXX"] = "#{gcc_path.opt_bin}/g++-#{GCC_VERSION}"

      # Add static linking flags for libgcc and libstdc++
      ENV.append "LDFLAGS", "-static-libgcc -static-libstdc++"
    end

    args = %W[
      -DBUILD_WERROR=ON
      -DCMAKE_CXX_STANDARD=23
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DHOMEBREW_ALLOW_FETCHCONTENT=ON
      -DOPENSSL_ROOT_DIR=#{Formula["openssl"].opt_prefix}
      -DSUNSHINE_ASSETS_DIR=sunshine/assets
      -DSUNSHINE_BUILD_HOMEBREW=ON
      -DSUNSHINE_PUBLISHER_NAME='LizardByte'
      -DSUNSHINE_PUBLISHER_WEBSITE='https://app.lizardbyte.dev'
      -DSUNSHINE_PUBLISHER_ISSUE_URL='https://app.lizardbyte.dev/support'
    ]

    if IS_UPSTREAM_REPO
      args << "-DBUILD_TESTS=ON"
      ohai "Building tests: enabled"
    else
      args << "-DBUILD_TESTS=OFF"
      ohai "Building tests: disabled"
    end

    if build.with? "docs"
      ohai "Building docs: enabled"
      args << "-DBUILD_DOCS=ON"
    else
      ohai "Building docs: disabled"
      args << "-DBUILD_DOCS=OFF"
    end

    if build.without? "static-boost"
      args << "-DBOOST_USE_STATIC=OFF"
      ohai "Disabled statically linking Boost libraries"
    else
      args << "-DBOOST_USE_STATIC=ON"
      ohai "Enabled statically linking Boost libraries"

      unless Formula["icu4c"].any_version_installed?
        odie <<~EOS
          icu4c must be installed to link against static Boost libraries,
          either install icu4c or use brew install sunshine --with-static-boost instead
        EOS
      end
      ENV.append "CXXFLAGS", "-I#{Formula["icu4c"].opt_include}"
      icu4c_lib_path = Formula["icu4c"].opt_lib.to_s
      ENV.append "LDFLAGS", "-L#{icu4c_lib_path}"
      ENV["LIBRARY_PATH"] = icu4c_lib_path
      ohai "Linking against ICU libraries at: #{icu4c_lib_path}"
    end

    if OS.linux?
      args << "-DCUDA_FAIL_ON_MISSING=OFF"
      # Pass static linking flags to CMake for libgcc and libstdc++
      args << "-DCMAKE_EXE_LINKER_FLAGS=-static-libgcc -static-libstdc++"
      args << "-DCMAKE_SHARED_LINKER_FLAGS=-static-libgcc -static-libstdc++"
    end

    system "cmake", "-S", ".", "-B", "build", "-G", "Unix Makefiles",
            *std_cmake_args,
            *args

    system "make", "-C", "build"
    system "make", "-C", "build", "install"

    bin.install "build/tests/test_sunshine" if IS_UPSTREAM_REPO

    # codesign the binary on intel macs
    system "codesign", "-s", "-", "--force", "--deep", bin/"sunshine" if OS.mac? && Hardware::CPU.intel?

    bin.install "src_assets/linux/misc/postinst" if OS.linux?
  end

  service do
    run [opt_bin/"sunshine", "~/.config/sunshine/sunshine.conf"]
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
        Sunshine can only access microphones on macOS due to system limitations.
        To stream system audio use "Soundflower" or "BlackHole".

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

    if IS_UPSTREAM_REPO
      # run the test suite
      system bin/"test_sunshine", "--gtest_color=yes", "--gtest_output=xml:test_results.xml"
      assert_path_exists testpath/"test_results.xml"
    end
  end
end

# this comment is forcing bottle builds in https://github.com/LizardByte/homebrew-homebrew/pull/42
