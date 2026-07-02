#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import sys
import threading
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler

PORTA = 8080
STATE_JSON = os.path.expanduser("~/.cache/walset/state.json")

imagem_atual = None
imagem_mtime = 0

def obter_wallpaper():
    global imagem_atual, imagem_mtime
    if not os.path.exists(STATE_JSON):
        print(f"Erro: {STATE_JSON} não encontrado")
        return False
    try:
        with open(STATE_JSON) as f:
            data = json.load(f)
        wall = data.get("wallpaper")
        if not wall:
            print("Erro: campo 'wallpaper' não encontrado")
            return False
        wall = os.path.expanduser(wall)
        if os.path.exists(wall):
            imagem_atual = wall
            imagem_mtime = os.path.getmtime(wall)
            print(f"✓ Wallpaper carregado: {wall}")
            return True
        else:
            print(f"Arquivo não existe: {wall}")
            return False
    except Exception as e:
        print(f"Erro ao ler JSON: {e}")
        return False

def monitorar():
    global imagem_mtime
    while True:
        subprocess.run(['inotifywait', '-q', '-e', 'modify', STATE_JSON])
        print("🔄 Mudança detectada no state.json")
        if obter_wallpaper():
            imagem_mtime = os.path.getmtime(imagem_atual)
            print(f"🖼️  Novo wallpaper: {imagem_atual}")

class ImageHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Qualquer caminho (/, /favicon.ico, etc.) serve a imagem
        if not imagem_atual or not os.path.exists(imagem_atual):
            self.send_error(404, "Wallpaper não encontrado")
            return
        try:
            with open(imagem_atual, 'rb') as f:
                data = f.read()
            ext = os.path.splitext(imagem_atual)[1].lower()
            content_type = 'image/jpeg'
            if ext == '.png':
                content_type = 'image/png'
            elif ext == '.gif':
                content_type = 'image/gif'
            elif ext == '.webp':
                content_type = 'image/webp'

            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.send_header('Access-Control-Allow-Origin', '*')
            # Cabeçalhos anti-cache agressivos
            self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
            # ETag baseado no timestamp da imagem
            self.send_header('ETag', f'"{int(imagem_mtime)}"')
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_error(500, f"Erro: {e}")

    def log_message(self, format, *args):
        # Desliga logs para não poluir
        pass

def main():
    if not obter_wallpaper():
        print("Falha ao carregar wallpaper. Encerrando.")
        sys.exit(1)

    # Inicia thread de monitoramento
    t = threading.Thread(target=monitorar, daemon=True)
    t.start()

    # Inicia servidor HTTP
    server = HTTPServer(('0.0.0.0', PORTA), ImageHandler)
    print(f"🚀 Servidor rodando em http://localhost:{PORTA}")
    print("Use esta URL no Bonjourr ou no navegador.")
    print("Quando o wallpaper mudar, o servidor atualiza automaticamente.")
    print("Aperte F5 no navegador (ou espere o Bonjourr buscar novamente) para ver a nova imagem.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()

if __name__ == '__main__':
    main()