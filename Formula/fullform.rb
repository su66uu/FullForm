class Fullform < Formula
  desc "macOS selected-text full-form lookup utility"
  homepage "https://github.com/su66uu/FullForm"
  url "https://github.com/su66uu/FullForm.git", branch: "main"
  version "0.1.0"

  depends_on xcode: :build

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    bin.install ".build/release/fullform"
    pkgshare.install "Resources/fullform.json"
    pkgshare.install "Workflows/Look Up FullForm.workflow"
  end

  def caveats
    <<~EOS
      To install the macOS Quick Action and sample glossary, run:
        fullform install-service
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/fullform 2>&1", 1)
  end
end
