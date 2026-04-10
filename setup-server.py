#!/usr/bin/env python3
"""
🏥 Hospital Archive - Kurulum Web Sunucusu
Basit web arayüzünden tüm ayarları yap ve kurulumu başlat
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.parse

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
            content_length = int(self.headers['Content-Length'])
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

            # Docker'ı başlat
            self.start_docker()

            # Başarı yanıtı
            self.send_json_response({
                'status': 'success',
                'message': 'Kurulum başlatıldı, Docker servisleri başlanıyor...'
            })

        except Exception as e:
            print(f'❌ Hata: {e}')
            self.send_json_error(str(e), 500)

    def update_env(self, data):
        """
        .env dosyasını güncelle
        """
        env_file = Path('/Users/beysol/Agents/hospital-archive/.env')

        # Mevcut .env'yi oku
        env_content = env_file.read_text() if env_file.exists() else ''

        # Güncellemeler
        updates = {
            'OPENROUTER_API_KEY': data.get('openrouterKey', ''),
            'IMMICH_API_KEY': data.get('immichApiKey', ''),
            'UPLOAD_LOCATION': data.get('immichUploadPath', '/tmp/immich-uploads'),
            'ARCHIVE_PATH': data.get('archivePath', '/tmp/archive'),
            'UNMATCHED_PATH': data.get('unmatchedPath', '/tmp/unmatched'),
            'N8N_PASSWORD': data.get('n8nPassword', 'admin123'),
            'MATCH_WINDOW_MINUTES': str(data.get('matchWindow', '30')),
        }

        # Satır satır güncelle
        for key, value in updates.items():
            if value:  # Boş değerleri skip et
                pattern = f'{key}='
                lines = env_content.split('\n')
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

    def start_docker(self):
        """Docker servislerini başlat"""
        os.chdir('/Users/beysol/Agents/hospital-archive')

        print('🚀 Docker servisleri başlatılıyor...')

        try:
            # Eski servisleri durdur
            subprocess.run(['docker', 'compose', 'down'],
                         capture_output=True, timeout=30)

            # Images'ı pull et
            subprocess.run(['docker', 'compose', 'pull'],
                         capture_output=True, timeout=120)

            # Servisler başlat
            subprocess.run(['docker', 'compose', 'up', '-d'],
                         capture_output=True, timeout=60)

            print('✅ Docker servisleri başlatıldı')

        except subprocess.TimeoutExpired:
            print('⚠️  Docker işlemi timeout (devam et)')
        except Exception as e:
            print(f'⚠️  Docker başlatma hatası: {e}')

    def send_json_response(self, data):
        """JSON yanıt gönder"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def send_json_error(self, message, status_code=400):
        """JSON hata gönder"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps({'error': message}).encode('utf-8'))

    def end_headers(self):
        """CORS headers ekle"""
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def do_OPTIONS(self):
        """OPTIONS request'ini işle (CORS)"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()


def main():
    os.chdir('/Users/beysol/Agents/hospital-archive')

    port = 9000
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, SetupHandler)

    print('╔════════════════════════════════════════════════════════╗')
    print('║   🏥 Hospital Archive - KURULUM WEB UI                ║')
    print('╚════════════════════════════════════════════════════════╝')
    print('')
    print(f'🌐 Tarayıcını aç: http://localhost:{port}')
    print('')
    print('⏹  Durdurmak için: Ctrl+C')
    print('')

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n✅ Kurulum sunucusu kapatıldı')
        sys.exit(0)


if __name__ == '__main__':
    main()
