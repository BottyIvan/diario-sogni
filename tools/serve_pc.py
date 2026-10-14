"""Serve only the compiled browser app on this PC, without exposing it to LAN."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json

APP = Path(__file__).resolve().parents[1]

class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/_diario_health':
            data = json.dumps({'app': 'diario-sogni', 'version': '0.4.1'}).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()

if __name__ == '__main__':
    ThreadingHTTPServer(('127.0.0.1', 8787), partial(Handler, directory=str(APP / 'build' / 'web'))).serve_forever()
