#!/usr/bin/env python3
"""Team 67 backend. The same file runs as Backend A (Thejas) or Backend B (Garv).

Start:  BACKEND=A PORT=3001 python3 backend/server.py
        BACKEND=B PORT=3002 python3 backend/server.py
"""
import hashlib
import json
import os
import socket
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BACKEND = os.environ.get("BACKEND", "A")
PORT = int(os.environ.get("PORT", "3001"))
BIND = os.environ.get("BIND", "0.0.0.0")  # all interfaces, so the edge can reach it (not 127.0.0.1 only)

# Same body on A and B, so the same ETag: a 304 works whichever backend nginx picks
CACHED_BODY = json.dumps({"data": "this response is cacheable", "version": 1}).encode()
CACHED_ETAG = '"' + hashlib.sha256(CACHED_BODY).hexdigest()[:16] + '"'


def now():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


class Handler(BaseHTTPRequestHandler):
    server_version = "team67-backend"

    def reply(self, code, body=b"", headers=None):
        self.send_response(code)
        self.send_header("X-Backend", BACKEND)  # who served this response
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        if code != 304:
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD" and code != 304:
            self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/":
            body = {"service": "team67 backend", "backend": BACKEND, "host": socket.gethostname(), "message": "running"}
            self.reply(200, json.dumps(body).encode())
        elif path == "/api/status":
            # Never cached, so every request reaches a backend and load balancing stays visible
            body = {"backend": BACKEND, "status": "ok", "time": now()}
            self.reply(200, json.dumps(body).encode(), {"Cache-Control": "no-store"})
        elif path == "/api/cached":
            headers = {"Cache-Control": "public, max-age=60", "ETag": CACHED_ETAG}
            inm = [t.strip() for t in self.headers.get("If-None-Match", "").split(",")]
            if CACHED_ETAG in inm or "*" in inm:
                self.reply(304, headers=headers)  # client's copy is still valid: no body
            else:
                self.reply(200, CACHED_BODY, headers)
        else:
            self.reply(404, json.dumps({"backend": BACKEND, "error": "not found"}).encode())

    do_HEAD = do_GET  # `curl -I` sends HEAD; reply() skips the body

    def log_message(self, fmt, *args):
        # from= is the TCP peer: behind nginx this is always the edge, never the client
        print(f"{now()}  from={self.client_address[0]}  {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"Backend {BACKEND} listening on {BIND}:{PORT}", flush=True)
    ThreadingHTTPServer((BIND, PORT), Handler).serve_forever()
