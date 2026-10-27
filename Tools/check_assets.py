"""Validate release assets without installing the app. Python standard library only."""
import hashlib,json,struct,wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]
icon=root/'Rewind/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
data=icon.read_bytes()
assert data[:8]==b'\x89PNG\r\n\x1a\n'
w,h,depth,color=struct.unpack('>IIBB',data[16:26])
assert (w,h,depth,color)==(1024,1024,8,2), (w,h,depth,color) # RGB with no alpha.
manifest=json.loads((icon.parent/'Contents.json').read_text())
assert manifest['images'][0]['filename']==icon.name
resources=root/'Rewind/Resources'
for theme in ['Original','SuperTape','Vintage']:
 front=(resources/(theme+'.png')).read_bytes();back=(resources/(theme+'SideB.png')).read_bytes()
 assert front!=back
 assert struct.unpack('>II',front[16:24])==struct.unpack('>II',back[16:24])==(1024,512)
source=resources/'Psx_Style_Cassette_Tape.usdz'
assert hashlib.sha256(source.read_bytes()).hexdigest()=='b13b115bf5664340275099bb1f6454a5d0ca1562f1b485c265706925c5a8864d'
with wave.open(str(resources/'TapeClick.wav')) as sound:
 assert sound.getnchannels()==1 and sound.getsampwidth()==2 and sound.getframerate()==48000
 samples=struct.unpack('<'+'h'*sound.getnframes(),sound.readframes(sound.getnframes()))
 assert max(map(abs,samples))<32767
 assert 0.08<len(samples)/48000<0.2
print('App icon, six compatible atlases, original USDZ checksum and unclipped click passed')
