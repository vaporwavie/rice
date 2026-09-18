import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


@unittest.skipUnless(shutil.which("qs"), "Quickshell is required")
class KeevyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "Keevy.qml").symlink_to(Path(__file__).resolve().parents[1] / "Keevy.qml")
        self.fixture = self.root / "picker.json"
        self.calls = self.root / "calls"
        self.configure()
        (self.root / "picker.py").write_text('''
import json, sys, time
from pathlib import Path
root = Path(__file__).parent
data = json.loads((root / "picker.json").read_text())
if sys.argv[1] == "--list":
    if data.get("list_error"):
        sys.exit(data["list_error"])
    print(data.get("raw", json.dumps(data["machines"])))
else:
    with (root / "calls").open("a") as calls:
        calls.write(sys.argv[1] + "\\n")
    time.sleep(0.3)
    if data.get("switch_error"):
        sys.exit(data["switch_error"])
''')
        (self.root / "shell.qml").write_text('''
import QtQuick
import Quickshell
import Quickshell.Io
import qs
ShellRoot {
    id: root
    property int successes: 0
    Connections {
        target: Keevy
        function onSwitched() { root.successes++ }
    }
    IpcHandler {
        target: "test"
        function refresh(): void { Keevy.refresh() }
        function select(name: string): void { Keevy.select(name) }
        function state(): string {
            return JSON.stringify({machines: Keevy.machines, error: Keevy.error,
                busy: Keevy.busy, loading: Keevy.loading, successes: root.successes,
                switchingTo: Keevy.switchingTo})
        }
    }
}
''')
        self.env = {**os.environ, "QT_QPA_PLATFORM": "offscreen",
                    "KEEVY_PICKER": str(self.root / "picker.py")}
        self.log = (self.root / "qs.log").open("w+")
        self.addCleanup(self.log.close)
        self.process = subprocess.Popen(
            ["qs", "-p", str(self.root)], env=self.env,
            stdout=self.log, stderr=subprocess.STDOUT,
        )
        self.addCleanup(self.stop)
        self.wait_for(lambda state: state is not None)

    def stop(self):
        self.process.terminate()
        self.process.wait(timeout=5)

    def configure(self, **overrides):
        self.fixture.write_text(json.dumps({"machines": [
            {"name": "mine", "key": 1}, {"name": "office mac", "key": 3},
        ], **overrides}))

    def ipc(self, method, *args):
        return subprocess.run(
            ["qs", "-p", str(self.root), "ipc", "--any-display", "call", "test", method, *args],
            env=self.env, capture_output=True, text=True, timeout=5,
        )

    def wait_for(self, predicate):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            response = self.ipc("state")
            state = json.loads(response.stdout) if response.returncode == 0 else None
            if state is not None and predicate(state):
                return state
            time.sleep(0.02)
        self.log.seek(0)
        self.fail(f"State did not settle: {state}\n{self.log.read()}")

    def refresh(self):
        self.assertEqual(self.ipc("refresh").returncode, 0)
        return self.wait_for(lambda state: not state["loading"])

    def test_refresh_tracks_changed_and_empty_profiles(self):
        self.assertEqual(len(self.refresh()["machines"]), 2)
        self.configure(machines=[])
        self.assertEqual(self.refresh()["machines"], [])
        self.assertFalse(self.calls.exists())

    def test_discovery_errors_clear_stale_rows_and_recover(self):
        self.refresh()
        self.configure(list_error="profiles unavailable")
        state = self.refresh()
        self.assertEqual(state["machines"], [])
        self.assertEqual(state["error"], "profiles unavailable")
        self.configure(raw="not json")
        self.assertIn("Could not read", self.refresh()["error"])
        self.configure()
        self.assertEqual(self.refresh()["error"], "")

    def test_switch_preserves_name_and_ignores_repeat_or_unknown_selection(self):
        self.refresh()
        self.ipc("select", "unknown")
        self.assertFalse(self.calls.exists())
        self.ipc("select", "office mac")
        self.wait_for(lambda state: state["busy"])
        self.ipc("select", "mine")
        state = self.wait_for(lambda state: state["successes"] == 1)
        self.assertEqual(state["error"], "")
        self.assertEqual(self.calls.read_text(), "office mac\n")

    def test_switch_failure_is_visible_and_retry_succeeds(self):
        self.configure(switch_error="HID permission denied")
        self.refresh()
        self.ipc("select", "mine")
        state = self.wait_for(lambda state: bool(state["error"]))
        self.assertEqual(state["error"], "mine failed: HID permission denied")
        self.assertFalse(state["busy"])
        self.assertEqual(state["successes"], 0)
        self.configure()
        self.ipc("select", "mine")
        self.wait_for(lambda state: state["successes"] == 1)


if __name__ == "__main__":
    unittest.main()
