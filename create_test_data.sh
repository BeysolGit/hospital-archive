#!/bin/bash

# Create test data for the Hospital Archive System

set -e

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${COLOR_BLUE}📸 Creating Test Data${NC}"
echo "===================="
echo ""

# Check if we have the necessary tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${COLOR_YELLOW}⚠️ $1 not found. Install with: brew install $1${NC}"
        return 1
    fi
}

# Create test data directory
mkdir -p test-data
cd test-data

echo "Creating test images..."
echo ""

# Test 1: Simple colored squares (JPEG)
echo -n "1. Creating test photo 1... "
python3 << 'PYTHON'
from PIL import Image, ImageDraw
import datetime
from piexif import Image as PILImage
import piexif

# Create a simple test image
img = Image.new('RGB', (800, 600), color=(73, 109, 137))
draw = ImageDraw.Draw(img)
draw.text((10, 10), "TEST PHOTO 1", fill=(255, 255, 255))
draw.text((10, 50), "Patient Photo", fill=(200, 200, 200))
draw.text((10, 90), f"Time: 2026-04-10 14:30:00", fill=(200, 200, 200))

# Save without EXIF first
img.save('test_photo1_no_exif.jpg', 'jpeg')

# Add EXIF data
exif_dict = {
    "0th": {
        piexif.ImageIFD.DateTime: b"2026:04:10 14:30:00",
    },
    "Exif": {
        piexif.ExifIFD.DateTimeOriginal: b"2026:04:10 14:30:00",
    }
}

exif_bytes = piexif.dump(exif_dict)
img.save('test_photo1.jpg', 'jpeg', exif=exif_bytes)

print("done")
PYTHON

echo -e "${COLOR_GREEN}✅${NC}"

# Test 2: Second patient photo (same time)
echo -n "2. Creating test photo 2... "
python3 << 'PYTHON'
from PIL import Image, ImageDraw
import piexif

img = Image.new('RGB', (800, 600), color=(137, 73, 109))
draw = ImageDraw.Draw(img)
draw.text((10, 10), "TEST PHOTO 2", fill=(255, 255, 255))
draw.text((10, 50), "Patient Photo", fill=(200, 200, 200))
draw.text((10, 90), f"Time: 2026-04-10 14:30:30", fill=(200, 200, 200))

img.save('test_photo2_no_exif.jpg', 'jpeg')

exif_dict = {
    "0th": {
        piexif.ImageIFD.DateTime: b"2026:04:10 14:30:30",
    },
    "Exif": {
        piexif.ExifIFD.DateTimeOriginal: b"2026:04:10 14:30:30",
    }
}

exif_bytes = piexif.dump(exif_dict)
img.save('test_photo2.jpg', 'jpeg', exif=exif_bytes)

print("done")
PYTHON

echo -e "${COLOR_GREEN}✅${NC}"

# Test 3: QR Code with patient info
echo -n "3. Creating test barcode (text label)... "
python3 << 'PYTHON'
from PIL import Image, ImageDraw
from datetime import datetime

# Create a hospital barcode label image (text-based)
img = Image.new('RGB', (600, 400), color=(255, 255, 255))
draw = ImageDraw.Draw(img)

# Draw text like a hospital label
label_text = """
HEMŞİRELİK KLİNİĞİ - HASTA BARKODU

Hasta Adı: Ahmet Yilmaz
Hasta ID: 12345
Doktor: Dr. Fatma Kaya
Bölüm: Radyoloji
Tarih: 10/04/2026
Saat: 14:30:00
Hastane: Merkez Hastanesi
Scan: [|||||| ]
"""

y_position = 20
for line in label_text.strip().split('\n'):
    draw.text((20, y_position), line.strip(), fill=(0, 0, 0))
    y_position += 30

img.save('test_barcode_label.jpg', 'jpeg')

print("done")
PYTHON

echo -e "${COLOR_GREEN}✅${NC}"

# Test 4: QR Code (if qrencode available)
echo -n "4. Creating QR code... "
if command -v qrencode &> /dev/null; then
    echo "AHMET_YILMAZ|12345|2026-04-10|14:30|Radyoloji|Merkez" | \
        qrencode -o test_qrcode.png -s 5
    echo -e "${COLOR_GREEN}✅${NC}"
else
    echo -e "${COLOR_YELLOW}⚠️ qrencode not installed (optional)${NC}"
fi

echo ""

# Test 5: Create test manifest
echo -n "5. Creating test manifest... "
cat > test_manifest.txt << 'EOF'
TEST DATA MANIFEST
==================

Images:
- test_photo1.jpg      : Patient photo (2026-04-10 14:30:00)
- test_photo2.jpg      : Patient photo (2026-04-10 14:30:30)
- test_barcode_label.jpg : Barcode label (Turkish hospital format)
- test_qrcode.png      : QR code (if qrencode installed)

Patient Information:
- Name: Ahmet Yilmaz
- ID: 12345
- Doctor: Dr. Fatma Kaya
- Department: Radyoloji
- Hospital: Merkez Hastanesi
- Date: 2026-04-10
- Time: 14:30:00

Expected Results After Processing:
- Archive folder: /tmp/archive/2026-04-10/Ahmet_Yilmaz/
- Photos: test_photo1.jpg, test_photo2.jpg, test_barcode_label.jpg
- SQLite entries: 3 (2 patient photos + 1 barcode)

Testing Steps:
1. Run: cd test-data
2. Test barcode decode:
   curl -F "file=@test_barcode_label.jpg" http://localhost:5001/decode
3. Test barcode parse:
   curl -F "file=@test_barcode_label.jpg" http://localhost:5001/parse
4. Index photos:
   curl -X POST http://localhost:5001/photo/index \
     -H "Content-Type: application/json" \
     -d '{"immich_id":"photo-1","taken_at":"2026-04-10T14:30:00Z"}'
5. Match:
   curl -X POST http://localhost:5001/match \
     -H "Content-Type: application/json" \
     -d '{"timestamp":"2026-04-10T14:30:00Z","patient_name":"Ahmet Yilmaz","window_minutes":30}'
6. Archive:
   curl -X POST http://localhost:5001/archive \
     -H "Content-Type: application/json" \
     -d '{"barcode_immich_id":"barcode-1","patient_photos":["photo-1","photo-2"],"patient_name":"Ahmet Yilmaz","date":"2026-04-10"}'
EOF

echo -e "${COLOR_GREEN}✅${NC}"

cd ..

echo ""
echo -e "${COLOR_BLUE}Test Data Summary${NC}"
echo "=================="
ls -lh test-data/
echo ""
echo -e "${COLOR_GREEN}✅ Test data created successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Run: ./test.sh"
echo "2. Test barcode decode:"
echo "   curl -F 'file=@test-data/test_barcode_label.jpg' http://localhost:5001/decode"
echo "3. Test barcode parse (requires OpenRouter API key):"
echo "   curl -F 'file=@test-data/test_barcode_label.jpg' http://localhost:5001/parse"
echo "4. See test-data/test_manifest.txt for full testing guide"
