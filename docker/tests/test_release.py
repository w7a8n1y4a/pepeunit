"""Lifecycle/API integration checks; no Docker daemon or GitLab account required."""
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
FILES = {
    "linux": [f"pepeunit-client-linux-{arch}.tar.gz" for arch in ("amd64", "arm64")],
    "android": [f"pepeunit-client-android-{abi}.apk" for abi in ("armeabi-v7a", "arm64-v8a", "x86_64")],
}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def respond(self, code, body):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        state = self.server.state
        if state["deny"]:
            self.respond(403, {"message": "forbidden"})
        elif "/packages/generic/" in self.path:
            name = self.path.rsplit("/", 1)[1]
            self.respond(200, state["files"][name]) if name in state["files"] else self.respond(404, {})
        elif "/assets/links" in self.path:
            self.respond(200, state["links"])
        else:
            self.respond(200, {}) if state["exists"] else self.respond(404, {})

    def do_PUT(self):
        state = self.server.state
        content = self.rfile.read(int(self.headers["Content-Length"]))
        if "/packages/generic/" in self.path:
            name = self.path.rsplit("/", 1)[1]
            state["uploads"].append(name)
            state["files"][name] = content
            self.respond(201, {})
        elif "/assets/links/" in self.path:
            link_id = int(self.path.rsplit("/", 1)[1])
            link = next(link for link in state["links"] if link["id"] == link_id)
            link.update(json.loads(content))
            self.respond(200, link)
        else:
            self.respond(200, {})

    def do_POST(self):
        state = self.server.state
        content = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        if "/assets/links" in self.path:
            content["id"] = max((link["id"] for link in state["links"]), default=0) + 1
            state["links"].append(content)
            self.respond(201, content)
        elif state["exists"]:
            self.respond(409, {"message": "Release already exists"})
        else:
            state["creates"] += 1
            state["exists"] = True
            state["links"] = [dict(link, id=i + 1) for i, link in enumerate(content["assets"]["links"])]
            self.respond(201, content)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.state = {"files": {}, "uploads": [], "links": [], "creates": 0, "exists": False, "deny": False}
        self.server.state = self.state
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.environment = patch.dict(os.environ, {
            "CI_API_V4_URL": f"http://127.0.0.1:{self.server.server_port}/api/v4",
            "CI_PROJECT_ID": "212", "CI_COMMIT_TAG": "1.5.0", "CI_ACCESS_TOKEN": "test-token",
            "HUB_IMAGE": "example/client", "CI_JOB_ID": "987654321",
            "CI_PROJECT_DIR": str(ROOT), "CI_PIPELINE_IID": "42",
        })
        self.environment.start()

    def tearDown(self):
        self.environment.stop()
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def publish(self, *args, success=True):
        result = subprocess.run(["bash", str(ROOT / "docker/publish-release.sh"), *args],
                                capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def seed(self):
        for group in FILES.values():
            for name in group:
                self.state["files"][name] = name.encode()

    def test_release_retry_keeps_packages_and_links(self):
        self.seed()
        self.publish()
        self.publish()
        self.assertEqual(self.state["creates"], 1)
        self.assertEqual(self.state["uploads"], ["SHA256SUMS"])
        self.assertEqual(len(self.state["links"]), 6)
        for link in self.state["links"]:
            self.assertIn("/packages/generic/pepeunit-client/1.5.0/", link["url"])
            self.assertEqual(link["link_type"], "package")
        for line in self.state["files"]["SHA256SUMS"].decode().splitlines():
            digest, name = line.split("  ")
            self.assertEqual(digest, hashlib.sha256(self.state["files"][name]).hexdigest())

    def test_partial_release_repairs_links(self):
        self.seed()
        self.state["exists"] = True
        self.state["links"] = [{"id": 12, "name": FILES["linux"][0], "url": "https://old.example/file"}]
        self.publish()
        self.assertEqual(len(self.state["links"]), 6)
        self.assertEqual(self.state["links"][0]["id"], 12)
        self.assertTrue(all(link["url"].startswith(f"{os.environ['CI_API_V4_URL']}/projects/212/packages/generic/pepeunit-client/1.5.0") for link in self.state["links"]))

    def test_missing_platform_prevents_release(self):
        self.seed()
        del self.state["files"][FILES["android"][0]]
        result = self.publish(success=False)
        self.assertIn("Package unavailable", result.stderr)
        self.assertEqual(self.state["creates"], 0)
        self.assertEqual(self.state["uploads"], [])

    def test_checksum_conflict_prevents_release(self):
        self.seed()
        self.state["files"]["SHA256SUMS"] = b"old checksums"
        result = self.publish(success=False)
        self.assertIn("conflicts", result.stderr)
        self.assertEqual(self.state["creates"], 0)

    def test_partial_upload_preserves_existing_bytes(self):
        names = FILES["linux"]
        self.state["files"][names[0]] = b"first build"
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / names[0]).write_bytes(b"non-reproducible rebuild")
            (directory / names[1]).write_bytes(b"new arm64 build")
            self.publish("--upload", "linux", "--directory", str(directory))
            self.publish("--upload", "linux", "--directory", str(directory))
        self.assertEqual(self.state["files"][names[0]], b"first build")
        self.assertEqual(self.state["uploads"], [names[1]])

    def test_auth_error_is_not_treated_as_missing(self):
        self.state["deny"] = True
        result = self.publish("--check", "linux", success=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("HTTP 403", result.stderr)
        self.assertEqual(self.state["uploads"], [])

    def run_lifecycle(self, target, fail=False):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            fake = directory / "docker"
            fake.write_text('''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
args = sys.argv[1:]
with open(os.environ['DOCKER_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
if args[:2] == ['buildx', 'build']:
    if os.environ.get('FAIL_BUILD') == '1': sys.exit(7)
    out = pathlib.Path(os.environ['RELEASE_DIR'])
    for arch in ('amd64', 'arm64'):
        (out / f'pepeunit-client-linux-{arch}.tar.gz').write_bytes(arch.encode())
''')
            fake.chmod(0o755)
            log = directory / "docker.log"
            environment = dict(os.environ, DOCKER=str(fake), DOCKER_LOG=str(log),
                               FAIL_BUILD="1" if fail else "0", PATH=f"{directory}:{os.environ['PATH']}")
            result = subprocess.run(["bash", str(ROOT / "docker/release-ci.sh"), target],
                                    env=environment, capture_output=True, text=True)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
        self.assertFalse((ROOT / "build/release-ci-987654321").exists(), result.stderr)
        return result, calls

    def test_linux_success_uploads_then_cleans_builder(self):
        result, calls = self.run_lifecycle("linux")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1][:3], ["buildx", "rm", "-f"])
        self.assertEqual(len(self.state["uploads"]), 2)

    def test_linux_failure_cleans_builder_without_upload(self):
        result, calls = self.run_lifecycle("linux", fail=True)
        self.assertEqual(result.returncode, 7, result.stderr)
        self.assertEqual(calls[-1][:3], ["buildx", "rm", "-f"])
        self.assertEqual(self.state["uploads"], [])



if __name__ == "__main__":
    unittest.main()
