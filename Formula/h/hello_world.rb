class HelloWorld < Formula
  HELLO_WORLD_EXECUTABLE = "hello-world".freeze

  desc "Simple program that outputs 'Hello, World!'"
  homepage "https://app.lizardbyte.dev"
  url "https://github.com/LizardByte/actions.git"
  version "0.0.1"

  bottle do
    root_url "https://ghcr.io/v2/lizardbyte/homebrew"
    rebuild 1
    sha256 arm64_tahoe:   "0000000000000000000000000000000000000000000000000000000000000000"
    sha256 arm64_sequoia: "0000000000000000000000000000000000000000000000000000000000000000"
    sha256 arm64_sonoma:  "0000000000000000000000000000000000000000000000000000000000000000"
    sha256 x86_64_linux:  "0000000000000000000000000000000000000000000000000000000000000000"
  end

  def install
    # create hello world sh file with echo command
    (buildpath/HELLO_WORLD_EXECUTABLE).write <<~EOS
      #!/bin/sh
      echo "Hello, World!"
    EOS
    chmod "+x", buildpath/HELLO_WORLD_EXECUTABLE

    # install the hello-world file to the bin directory
    bin.install HELLO_WORLD_EXECUTABLE

    puts "buildpath: #{buildpath}"
  end

  test do
    assert_equal "Hello, World!", shell_output("#{bin}/#{HELLO_WORLD_EXECUTABLE}").strip

    puts "testpath: #{testpath}"

    # test the env
    if ENV["HOMEBREW_BUILDPATH"]
      dummy_filename = "dummy.txt"
      cd File.join(ENV["HOMEBREW_BUILDPATH"]) do
        # create a dummy file
        File.write(dummy_filename, "Hello, World!")
        assert_path_exists dummy_filename
      end
      assert_path_exists File.join(ENV["HOMEBREW_BUILDPATH"], dummy_filename)
    end
  end
end
# Created from LizardByte/actions@2daa289a1af3ca8fed3c8cbb5dfc1e998c5ee7fa
