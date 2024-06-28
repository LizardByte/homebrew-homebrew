require "language/node"

class Sunshine < Formula
  desc "Self-hosted game stream host for Moonlight"
  homepage "https://app.lizardbyte.dev/Sunshine"
  url "https://github.com/LizardByte/Sunshine.git",
    tag: "v0.23.1"
  license all_of: ["GPL-3.0-only"]
  head "https://github.com/LizardByte/Sunshine.git", branch: "master"

  depends_on "boost" => :build
  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "graphviz" => :build # for `dot`
  depends_on "node" => :build
  depends_on "pkg-config" => :build
  depends_on "curl"
  depends_on "miniupnpc"
  depends_on "openssl"
  depends_on "opus"

  def install
    ENV["BRANCH"] = "master"
    ENV["BUILD_VERSION"] = "v#{version}"
    if build.head?
      # For a HEAD build, the `version` field will be something like "HEAD-59ff5dc". This works
      # fine itself as a value for BUILD_VERSION. Sticking a "v" prefix in front of this value
      # would look ugly, so we'll remove the prefix.
      ENV["BUILD_VERSION"] = ENV["BUILD_VERSION"][1..]
    end
    ENV["COMMIT"] = `git rev-parse HEAD`.strip

    args = %W[
      -DBUILD_WERROR=ON
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DOPENSSL_ROOT_DIR=#{Formula["openssl"].opt_prefix}
      -DSUNSHINE_ASSETS_DIR=sunshine/assets
      -DSUNSHINE_BUILD_HOMEBREW=ON
      -DTESTS_ENABLE_PYTHON_TESTS=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args

    cd "build" do
      system "make", "-j"
      system "make", "install"
      bin.install "tests/test_sunshine"
    end
  end

  service do
    run [opt_bin/"sunshine", "~/.config/sunshine/sunshine.conf"]
  end

  def caveats
    <<~EOS
      Thanks for installing Sunshine!

      To get started, review the documentation at:
        https://docs.lizardbyte.dev/projects/sunshine/en/latest/

      Sunshine can only access microphones on macOS due to system limitations.
      To stream system audio use "Soundflower" or "BlackHole".

      Gamepads are not currently supported on macOS.
    EOS
  end

  test do
    # test that the binary runs at all
    system "#{bin}/sunshine", "--version"

    # run the test suite
    # cannot build tests with python tests because homebrew destroys the source directory
    system "#{bin}/test_sunshine", "--gtest_color=yes"
  end
end
