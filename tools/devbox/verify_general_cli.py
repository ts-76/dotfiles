#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--bin-dir", type=Path, default=Path.home() / ".local/share/devbox/global/default/.devbox/nix/profile/default/bin")
parser.add_argument("--receipt", type=Path)
args = parser.parse_args()
versions = {"rtk": "0.43.0", "chezmoi": "2.69.3", "mo": "1.6.7", "stripe": "1.40.9", "apm": "0.16.1", "gcloud": "559.0.0"}
receipt = {"bin_dir": str(args.bin_dir), "commands": []}

with tempfile.TemporaryDirectory(prefix="general-cli-smoke-") as temporary:
    temporary = Path(temporary)
    stripe_config = temporary / "stripe.toml"
    stripe_config.touch(mode=0o600)
    env = dict(os.environ)
    env.update({
        "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
        "XDG_CONFIG_HOME": str(temporary / "config"),
        "XDG_CACHE_HOME": str(temporary / "cache"),
        "CLOUDSDK_CONFIG": str(temporary / "gcloud"),
        "CLOUDSDK_CORE_DISABLE_USAGE_REPORTING": "true",
        "CLOUDSDK_CORE_DISABLE_FILE_LOGGING": "true",
        "CLOUDSDK_PAGER": "cat",
    })
    commands = [
        (name, [str(args.bin_dir / name), "--version"], version)
        for name, version in versions.items() if name not in ["stripe", "gcloud"]
    ]
    commands += [
        ("stripe", [str(args.bin_dir / "stripe"), "--config", str(stripe_config), "--version"], versions["stripe"]),
        ("gcloud", [str(args.bin_dir / "gcloud"), "version", "--format=json"], versions["gcloud"]),
        ("bq", [str(args.bin_dir / "bq"), "version"], None),
        ("gsutil", [str(args.bin_dir / "gsutil"), "version", "-l"], None),
        ("gcloud-alpha", [str(args.bin_dir / "gcloud"), "alpha", "--help"], None),
        ("gcloud-components", [str(args.bin_dir / "gcloud"), "components", "list", "--only-local-state", "--format=json"], None),
    ]
    for name, command, expected in commands:
        result = subprocess.run(command, env=env, text=True, capture_output=True, timeout=60)
        item = {"name": name, "argv": command, "exit": result.returncode, "stdout": result.stdout, "stderr": result.stderr}
        receipt["commands"].append(item)
        if args.receipt:
            args.receipt.write_text(json.dumps(receipt, indent=2) + "\n")
        if result.returncode:
            raise SystemExit(f"FAIL {name}: {result.stderr or result.stdout}")
        if "Traceback (most recent call last)" in result.stderr + result.stdout:
            raise SystemExit(f"FAIL {name}: Python traceback in command output")
        if expected and not re.search(r"(?<![0-9.])" + re.escape(expected) + r"(?![0-9.])", result.stdout):
            raise SystemExit(f"FAIL {name}: expected version {expected}, got {result.stdout!r}")
        if name == "gcloud-components":
            components = {component["id"] for component in json.loads(result.stdout)}
            if components != {"core", "bq", "alpha", "gsutil", "gcloud-crc32c"}:
                raise SystemExit(f"FAIL gcloud components: {components!r}")
        if name == "gsutil" and "compiled crcmod: True" not in result.stdout:
            raise SystemExit("FAIL gsutil: compiled crcmod is unavailable")
        print(f"PASS {name}" + (f" {expected}" if expected else ""))

if args.receipt:
    args.receipt.write_text(json.dumps(receipt, indent=2) + "\n")
