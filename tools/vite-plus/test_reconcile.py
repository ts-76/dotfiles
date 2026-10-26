import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[2] / "dot_local/bin/executable_vp-tools"
FAKE_VP = """#!/usr/bin/env python3
import json, os, pathlib, sys
root = pathlib.Path(os.environ["VP_HOME"])
state = root / "installed.json"
packages = json.loads(state.read_text())
args = sys.argv[1:]
with (root / "calls.jsonl").open("a") as out:
    out.write(json.dumps(args) + "\\n")
if args == ["list", "-g", "--json"]:
    print(json.dumps(packages))
elif args[:2] == ["env", "install"] or args[:2] == ["env", "setup"]:
    pass
elif args[:2] == ["install", "-g"]:
    if os.environ.get("FAIL_INSTALL"):
        sys.exit(7)
    name, version = args[-1].rsplit("@", 1)
    packages = [pkg for pkg in packages if pkg["name"] != name]
    packages.append({"name": name, "version": version, "platform": {"node": args[3]}, "bins": ["test-cli"]})
    state.write_text(json.dumps(packages))
    package_dir = root / "packages" / name / "lib/node_modules" / name
    package_dir.mkdir(parents=True, exist_ok=True)
    (package_dir / "package.json").write_text(json.dumps({"version": version}))
    binary = root / "bin/test-cli"
    binary.write_text("#!/bin/sh\\nexit 0\\n")
    binary.chmod(0o755)
else:
    raise SystemExit("Unexpected command: " + repr(args))
"""


class ReconcileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "bin").mkdir()
        stub = self.root / "bin/vp"
        stub.write_text(FAKE_VP)
        stub.chmod(0o755)
        self.config = {
            "defaultNodeVersion": "24.22.1",
            "defaultPackageManagerVersions": {"pnpm": "12.15.0"},
            "packageManagerShimModes": {
                name: "managed" for name in ["npm", "pnpm", "bun", "yarn"]
            },
        }
        self.desired = {
            "packages": [{"name": "@test/cli", "version": "1.2.3", "node": "24.22.1"}]
        }
        self.installed = self.root / "installed.json"
        self.installed.write_text("[]")
        self.manifest = self.root / "tools.json"
        self.env = dict(
            os.environ,
            VP_HOME=str(self.root),
            XDG_DATA_HOME=str(self.root / "data"),
            PATH=str(self.root / "bin") + os.pathsep + os.environ["PATH"],
        )

    def run_script(self, *args):
        (self.root / "config.json").write_text(json.dumps(self.config))
        self.manifest.write_text(json.dumps(self.desired))
        return subprocess.run(
            ["bash", str(SCRIPT), *args, str(self.manifest)],
            env=self.env, text=True, capture_output=True,
        )

    def calls(self):
        path = self.root / "calls.jsonl"
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def test_check_does_not_install(self):
        result = self.run_script("--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("MISSING @test/cli@1.2.3", result.stdout)
        self.assertEqual(self.calls(), [["list", "-g", "--json"]])

    def test_relative_inventory_path(self):
        self.run_script("--check")
        nested = self.root / "nested"
        nested.mkdir()
        (nested / "tools.json").write_text(json.dumps(self.desired))
        result = subprocess.run(
            ["bash", str(SCRIPT), "nested/tools.json"],
            cwd=self.root, env=self.env, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.installed.read_text())[0]["name"], "@test/cli")

    def test_apply_twice_installs_package_once(self):
        first = self.run_script()
        second = self.run_script()
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        installs = [args for args in self.calls() if args[:2] == ["install", "-g"]]
        self.assertEqual(installs, [["install", "-g", "--node", "24.22.1", "@test/cli@1.2.3"]])
        self.assertIn("OK @test/cli@1.2.3", second.stdout)

    def test_version_change_reinstalls(self):
        self.assertEqual(self.run_script().returncode, 0)
        self.desired["packages"][0]["version"] = "1.2.4"
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual(json.loads(self.installed.read_text())[0]["version"], "1.2.4")

    def test_missing_package_payload_is_repaired(self):
        self.assertEqual(self.run_script().returncode, 0)
        package_json = self.root / "packages/@test/cli/lib/node_modules/@test/cli/package.json"
        package_json.unlink()
        self.assertEqual(self.run_script("--check").returncode, 1)
        self.assertEqual(self.run_script().returncode, 0)
        self.assertTrue(package_json.is_file())

    def test_missing_binary_is_repaired(self):
        self.assertEqual(self.run_script().returncode, 0)
        (self.root / "bin/test-cli").unlink()
        self.assertEqual(self.run_script("--check").returncode, 1)
        self.assertEqual(self.run_script().returncode, 0)
        self.assertTrue((self.root / "bin/test-cli").is_file())

    def test_node_change_reinstalls(self):
        self.assertEqual(self.run_script().returncode, 0)
        self.desired["packages"][0]["node"] = "22.20.0"
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual(json.loads(self.installed.read_text())[0]["platform"]["node"], "22.20.0")

    def test_unmanaged_package_is_reported_and_kept(self):
        self.installed.write_text(json.dumps([{
            "name": "extra", "version": "9.0.0", "platform": {"node": "24.22.1"}
        }]))
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("UNMANAGED extra@9.0.0", result.stdout)
        self.assertEqual(len(json.loads(self.installed.read_text())), 2)

    def test_invalid_inventory_writes_nothing(self):
        for value in ["latest", "^1.2.3", "1.2.3\nmalicious"]:
            with self.subTest(value=value):
                self.desired["packages"][0]["version"] = value
                self.assertEqual(self.run_script().returncode, 2)
                self.assertEqual(self.calls(), [])

    def test_duplicate_names_write_nothing(self):
        self.desired["packages"] *= 2
        self.assertEqual(self.run_script().returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_system_first_config_writes_nothing(self):
        self.config["nodeShimMode"] = "system_first"
        self.assertEqual(self.run_script().returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_install_failure_is_not_success(self):
        self.env["FAIL_INSTALL"] = "1"
        self.assertEqual(self.run_script().returncode, 7)
        self.assertEqual(json.loads(self.installed.read_text()), [])


if __name__ == "__main__":
    unittest.main()
