"""Add original handwritten Side B notes to each existing attributed atlas."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import sys
root=Path(sys.argv[1])
hand=ImageFont.truetype('/System/Library/Fonts/Noteworthy.ttc',23)
letter=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf',31)
for name,note in [('Original','Summer ’98'),('SuperTape','The long way home'),('Vintage','Sunday, 4:12 pm')]:
 im=Image.open(root/(name+'.png')).convert('RGB');d=ImageDraw.Draw(im)
 # The original image's blank writing field maps to the top of the rendered tape.
 # Atlas vertical orientation is inverted on screen; flip the writing vertically to match.
 patch=Image.new('RGBA',(600,45));ink=ImageDraw.Draw(patch)
 ink.text((8,2),'Side B / '+note,font=hand,fill=(40,38,35,235))
 patch=patch.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
 im.paste(patch,(208,365),patch)
 # Replace the prominent side letter in the colored band.
 bg=im.getpixel((206,300));d.rectangle((193,251,227,290),fill=bg)
 mark=Image.new('RGBA',(34,39));ImageDraw.Draw(mark).text((5,-1),'B',font=letter,fill=(24,24,23,255))
 mark=mark.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
 im.paste(mark,(193,251),mark)
 im.save(root/(name+'SideB.png'))
