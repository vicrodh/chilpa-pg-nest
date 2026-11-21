"""Exercise the packaged worker's actual protocol and input limits."""
import json
from pathlib import Path
import platform
import subprocess
import unittest

PROGRAM = Path(__file__).resolve().parents[1] / "dist" / ("linux-" + platform.machine()) / "plugin"


class WorkerTests(unittest.TestCase):
    def exchange(self, requests):
        result = subprocess.run([str(PROGRAM)], input="\n".join(requests) + "\n", text=True, capture_output=True, timeout=3)
        self.assertEqual(result.returncode, 0, result.stderr)
        return [json.loads(line) for line in result.stdout.splitlines()]

    def test_initialize_echoes_id_without_inventing_catalog_or_player_capabilities(self):
        reply, = self.exchange([json.dumps({"jsonrpc":"2.0", "id":14, "method":"initialize", "params":{}})])
        self.assertEqual(reply, {"jsonrpc":"2.0", "id":14, "result":{"protocol":1, "capabilities":{}}})

    def test_notifications_get_no_reply_and_unknown_methods_fail(self):
        notification = json.dumps({"jsonrpc":"2.0", "method":"network.changed", "params":{"enabled":False}})
        reply, = self.exchange([notification, json.dumps({"jsonrpc":"2.0", "id":4, "method":"player.play"})])
        self.assertEqual(reply["id"], 4)
        self.assertEqual(reply["error"]["code"], -32601)

    def test_malformed_input_does_not_break_the_next_request(self):
        replies = self.exchange(["broken", "[]", json.dumps({"jsonrpc":"2.0", "id":7, "method":"initialize"})])
        self.assertEqual([reply.get("error", {}).get("code") for reply in replies[:2]], [-32700, -32700])
        self.assertEqual(replies[2]["id"], 7)

    def test_multiple_requests_and_restart_keep_their_own_ids(self):
        requests = [json.dumps({"jsonrpc":"2.0", "id":index, "method":"initialize"}) for index in range(20)]
        for _ in range(2):
            self.assertEqual([reply["id"] for reply in self.exchange(requests)], list(range(20)))

    def test_oversized_input_exits_without_echoing_the_payload(self):
        result = subprocess.run([str(PROGRAM)], input="x" * 20000 + "\n", text=True, capture_output=True, timeout=3)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
