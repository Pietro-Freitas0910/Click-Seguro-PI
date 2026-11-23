#!/usr/bin/env python3
"""Serve a exportação Web (build/web) por HTTPS para testar no celular.

O Godot só roda no navegador em "contexto seguro" (localhost ou HTTPS).
Pelo IP da rede local é preciso HTTPS, então este script cria um
certificado próprio (na primeira vez) e sobe o servidor.

Uso:  python3 servir_web.py
No celular (mesmo Wi-Fi), abra o endereço que aparecer. O navegador vai
avisar que a conexão "não é particular": toque em Avançado > Continuar.
Para parar: Ctrl+C.
"""
import http.server
import socket
import ssl
import subprocess
from pathlib import Path

PORT = 8443
ROOT = Path(__file__).resolve().parent
WEB_DIR = ROOT / "build" / "web"
CERT_DIR = ROOT / "build" / "cert"
CERT = CERT_DIR / "cert.pem"
KEY = CERT_DIR / "key.pem"


def local_ip() -> str:
    # Descobre o IP da rede local (não envia nada pela internet).
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def make_cert(ip: str) -> None:
    CERT_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
        "-keyout", str(KEY), "-out", str(CERT), "-days", "365",
        "-subj", "/CN=Click Seguro (teste local)",
        "-addext", f"subjectAltName=IP:{ip},IP:127.0.0.1,DNS:localhost",
    ], check=True, capture_output=True)


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def end_headers(self):
        # Evita o celular guardar uma versão velha do jogo depois de reexportar.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    if not (WEB_DIR / "index.html").exists():
        raise SystemExit("Não achei build/web/index.html. Exporte o jogo no Godot primeiro.")
    ip = local_ip()
    if not CERT.exists() or not KEY.exists():
        make_cert(ip)
    server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(CERT, KEY)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    print(f"Click Seguro no ar! No celular (mesmo Wi-Fi), abra: https://{ip}:{PORT}")
    print("Aviso de 'conexão não particular' é normal: Avançado > Continuar.")
    print("Para parar: Ctrl+C")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
