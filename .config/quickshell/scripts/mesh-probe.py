#!/usr/bin/env python3
"""Streams the agent mesh as one JSON line per second.

Reads the mesh store read-only and the per-pane agent-notify state. Message
bodies are never read: only sender, recipient and timing leave the database.
"""
import glob
import json
import os
import sqlite3
import time
from datetime import datetime, timezone

DB = os.path.expanduser("~/.copilot/extensions/agent-mesh/agent-mesh.db")
NOTIFY = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "agent-notify")
FRESH_SECS = 1800
LOCAL = os.uname().nodename


def parse(ts):
    return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(timezone.utc).timestamp()


def pane_states():
    by_cwd = {}
    for path in glob.glob(os.path.join(NOTIFY, "*.json")):
        try:
            with open(path) as f:
                d = json.load(f)
        except (OSError, ValueError):
            continue
        cwd = d.get("cwd")
        if cwd and d.get("ts", 0) >= by_cwd.get(cwd, {}).get("ts", 0):
            by_cwd[cwd] = d
    return by_cwd


def snapshot(db, last_id):
    now = time.time()
    states = pane_states()
    nodes = []
    for sid, cwd, repo, status, hb, machine in db.execute(
        "SELECT s.session_id, s.cwd, s.repo, s.status, s.last_heartbeat, r.machine "
        "FROM agent_sessions s LEFT JOIN mesh_remote_sessions r ON r.session_id = s.session_id "
        "WHERE s.kind = 'agent'"
    ):
        if status != "active" or now - parse(hb) > FRESH_SECS:
            continue
        pane = states.get(cwd) if machine is None else None
        nodes.append({
            "id": sid,
            "repo": repo,
            "machine": machine or LOCAL,
            "state": pane["state"] if pane else "active",
        })
    ids = {n["id"] for n in nodes}

    edges = {}
    for a, b, n in db.execute(
        "SELECT sender_session_id, recipient_session_id, COUNT(*) FROM agent_messages "
        "WHERE created_at > ? GROUP BY 1, 2",
        (datetime.fromtimestamp(now - 86400, timezone.utc).isoformat(),),
    ):
        if a in ids and b in ids:
            edges[(a, b)] = n

    newest = db.execute("SELECT COALESCE(MAX(message_id), 0) FROM agent_messages").fetchone()[0]
    msgs = []
    if last_id is not None:
        for mid, a, b in db.execute(
            "SELECT message_id, sender_session_id, recipient_session_id FROM agent_messages "
            "WHERE message_id > ? ORDER BY message_id", (last_id,)
        ):
            msgs.append({"id": mid, "from": a, "to": b})
    return newest, {
        "nodes": nodes,
        "edges": [{"from": a, "to": b, "n": n} for (a, b), n in edges.items()],
        "msgs": msgs,
    }


def main():
    last = None
    while True:
        db = sqlite3.connect(f"file:{DB}?mode=ro", uri=True, timeout=2)
        try:
            last_new, snap = snapshot(db, last)
            last = last_new
            print(json.dumps(snap, separators=(",", ":")), flush=True)
        except sqlite3.Error:
            pass
        finally:
            db.close()
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
