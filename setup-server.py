#!/usr/bin/env python3
"""
Fotograf Arsivleme - Kurulum Web Sunucusu
Web arayüzünden tüm ayarları yap
"""

import json
import os
import sys
import argparse
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler

class SetupHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        """HTML dosyasını serve et"""
        if self.path == '/' or self.path == '/setup':
            self.path = '/setup-web.html'
        return super().do_GET()

    def do_POST(self):
        """Setup bilgilerini al ve .env'yi güncelle"""
        if self.path != '/api/setup':
            self.send_error(404)
            return

        try:
            # Request body'yi oku
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode('utf-8'))

            # Validation
            openrouter_key = data.get('openrouterKey', '').strip()
            if not openrouter_key:
                self.send_json_error('OpenRouter API Key gerekli', 400)
                return

            if not openrouter_key.startswith('sk-or-'):
                self.send_json_error('Geçersiz OpenRouter API Key formatı', 400)
                return

            # .env dosyasını güncelle
            self.update_env(data)

            # Başarı yanıtı
            self.send_json_response({
                'status': 'success',
                'message': 'Kurulum tamamlandı!'
            })

        except Exception as e:
            print(f'❌ Hata: {e}')
            self.send_json_error(str(e), 500)

    def update_env(self, data):
        """
        .env dosyasını güncelle
        """
        # Script'in dizinindeki .env dosyasını bul
        script_dir = Path(__file__).parent
        env_file = script_dir / '.env'

        # Mevcut .env'yi oku
        env_content = env_file.read_text() if env_file.exists() else ''

        # Güncellemeler
        updates = {
            'OPENROUTER_API_KEY': data.get('openrouterKey', ''),
            'IMMICH_API_KEY': data.get('immichApiKey', ''),
            'ARCHIVE_PATH': data.get('archivePath', './photos/archive'),
            'UNMATCHED_PATH': data.get('unmatchedPath', './photos/unmatched'),
            'N8N_PASSWORD': data.get('n8nPassword', 'admin123'),
            'MATCH_WINDOW_MINUTES': str(data.get('matchWindow', '30')),
        }

        lines = env_content.split('\n') if env_content else []

        # Satır satır güncelle
        for key, value in updates.items():
            if value:
                pattern = f'{key}='
                found = False

                for i, line in enumerate(lines):
                    if line.startswith(pattern):
                        lines[i] = f'{key}={value}'
                        found = True
                        break

                if not found:
                    lines.append(f'{key}={value}')

        env_content = '\n'.join(lines)

        # .env dosyasını yaz
        env_file.write_text(env_content)
        print(f'✅ .env dosyası güncellendi')

    def send_json_response(self, data):
        """JSON yanıt gönder"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def send_json_error(self, message, status_code=400):
        """JSON hata gönder"""
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps({'error': message}).encode('utf-8'))

    def do_OPTIONS(self):
        """CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, format, *args):
        """Log sadece hataları"""
        if args and '404' in str(args[0]):
            super().log_message(format, *args)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=9000)
    args = parser.parse_args()

    # Script'in çalıştığı klasöre git
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    server_address = ('127.0.0.1', args.port)
    httpd = HTTPServer(server_address, SetupHandler)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f'Hata: {e}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
