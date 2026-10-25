"""Original stepping-stone app marks using only Python's standard library."""
import struct
import zlib
from pathlib import Path

def png(path, size):
    data = bytearray()
    for y in range(size):
        data.append(0)
        for x in range(size):
            u,v=x/size,y/size
            color=(255,248,237,255)
            if (u-.72)**2+(v-.24)**2 < .013:
                color=(242,174,57,255)
            if any(abs(u-cx)<.14 and abs(v-cy)<.065 for cx,cy in [(.27,.72),(.47,.53),(.67,.36)]):
                color=(40,118,110,255)
            data.extend(color)
    def chunk(kind, value):
        return struct.pack('>I', len(value))+kind+value+struct.pack('>I',zlib.crc32(kind+value)&0xffffffff)
    Path(path).write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(data))+chunk(b'IEND',b''))

for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    png(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png',size)
for size in [192,512]:
    for name in [f'Icon-{size}.png',f'Icon-maskable-{size}.png']:
        png(f'web/icons/{name}',size)
png('web/favicon.png',32)
