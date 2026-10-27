"""Synthesize Rewind's original short mechanical click; no sampled recordings.
Usage: python3 Tools/make_click.py Rewind/Resources/TapeClick.wav
"""
import math, random, struct, sys, wave
from pathlib import Path
rate=48000;duration=0.145;rng=random.Random(2002)
samples=[];low=0
for n in range(round(rate*duration)):
 t=n/rate;noise=rng.uniform(-1,1);low += 0.36*(noise-low)
 sample=0
 # A light plastic strike, followed by a quieter latch seating into place.
 for start,gain in [(0.004,0.65),(0.029,0.34)]:
  age=t-start
  if age<0:continue
  attack=min(1,age/0.0007)
  strike=(noise-low)*math.exp(-age/0.0028)
  body=sum(math.sin(2*math.pi*f*age)*a*math.exp(-age/tau)
           for f,a,tau in [(410,.5,.012),(930,.25,.008),(1840,.12,.005)])
  sample+=gain*attack*(0.48*strike+body)
 fade=min(1,t/0.001)*min(1,(duration-t)/0.012)
 samples.append(sample*fade)
peak=max(map(abs,samples));samples=[v*.45/peak for v in samples]
p=Path(sys.argv[1]);p.parent.mkdir(parents=True,exist_ok=True)
with wave.open(str(p),'wb') as w:
 w.setparams((1,2,rate,0,'NONE','not compressed'))
 w.writeframes(b''.join(struct.pack('<h',round(v*32767)) for v in samples))
assert abs(samples[0])<1e-9 and max(map(abs,samples))<1
print(f'{len(samples)/rate:.3f}s mono PCM, peak {max(map(abs,samples)):.2f}')
