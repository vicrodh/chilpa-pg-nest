"""Check the packaged interface's imports and relative assets, not source files."""
import json
from pathlib import Path
import posixpath
import re
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class PackagedInterfaceTests(unittest.TestCase):
    def test_relative_imports_fonts_and_artwork_resolve_inside_the_zip(self):
        version = json.loads((ROOT / "manifest.json").read_text())["version"]
        packages = list((ROOT / "dist").glob(f"chilpa-nest-{version}-*.zip"))
        self.assertTrue(packages, "Build the current package before running this check")
        for package in packages:
            with zipfile.ZipFile(package) as archive:
                members = set(archive.namelist())
                for name in sorted(members):
                    if not name.endswith(".qml"):
                        continue
                    text = archive.read(name).decode()
                    references = re.findall(r'^import\s+"([^"]+)"', text, re.MULTILINE)
                    references += re.findall(r'\bsource\s*:\s*"([^"\n]+\.(?:svg|png|ttf))"', text)
                    for reference in references:
                        if ":" in reference:
                            continue
                        resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), reference))
                        with self.subTest(package=package.name, component=name, reference=reference):
                            self.assertFalse(resolved.startswith("../"))
                            self.assertTrue(resolved in members or any(member.startswith(resolved + "/") for member in members),
                                            f"Missing packaged dependency: {resolved}")


if __name__ == "__main__":
    unittest.main()
