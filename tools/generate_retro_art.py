"""Deterministic, original low-resolution art for the first-person conversion.
Run with Python + Pillow only when changing the art; the game loads the PNGs.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random, math, wave, struct

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'first_person'
OUT.mkdir(parents=True, exist_ok=True)
rng = random.Random(7713)

def save_noise(im, name, strength=8):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            c = px[x,y]
            if len(c) == 4 and c[3] == 0:
                continue
            n = rng.randint(-strength,strength) + (2 if (x+y)%2 else -2)
            px[x,y] = tuple(max(0,min(255,v+n)) for v in c[:3]) + ((c[3],) if len(c)==4 else ())
    im.save(OUT / (name+'.png'))

for dream in (False, True):
    suffix = '_dream' if dream else ''
    bg = '#765a76' if dream else '#797545'
    vine = '#33253f' if dream else '#393f29'
    accent = '#b56191' if dream else '#b1a464'
    im = Image.new('RGB',(64,64),bg); d=ImageDraw.Draw(im)
    for x in range(0,64,16):
        d.line([(x,0),(x,63)],fill=accent,width=2)
        for y in range(0,64,16):
            d.polygon([(x+8,y+1),(x+13,y+8),(x+8,y+15),(x+3,y+8)],fill=vine)
            d.line([(x+8,y+4),(x+8,y+12)],fill=accent)
            d.point((x+6,y+7),fill='#d8888c')
    d.rectangle((0,0,63,6),fill='#352a28')
    d.line((0,7,63,7),fill=accent)
    d.rectangle((0,54,63,63),fill='#2a2527')
    for x in range(0,64,8):
        d.line((x,56,x,63),fill='#564431')
    save_noise(im,'wall'+suffix)
    # An original face woven into the wallpaper, not an imported portrait.
    face=im.copy(); d=ImageDraw.Draw(face)
    d.rectangle((12,10,52,51),fill='#392c37',outline='#b18b50',width=2)
    d.rectangle((16,13,48,48),outline='#725330',width=2)
    d.polygon([(26,15),(39,16),(45,26),(40,42),(31,47),(23,37),(20,25)],fill='#a99a64' if not dream else '#be8593')
    d.polygon([(22,24),(29,23),(30,29),(24,28)],fill='#262435')
    d.polygon([(34,23),(42,25),(40,29),(33,28)],fill='#262435')
    d.point((27,26),fill='#e6c4a0'); d.point((37,26),fill='#e6c4a0')
    d.line((32,27,30,35,34,35),fill='#635147',width=2)
    d.rectangle((28,39,36,40),fill='#4f283f')
    save_noise(face,'portrait'+suffix,5)
    eyes=im.copy(); d=ImageDraw.Draw(eyes)
    for cx in (18,46):
        d.polygon([(cx-11,27),(cx,22),(cx+11,28),(cx,33)],fill='#b0a36e')
        d.ellipse((cx-4,23,cx+3,32),fill='#251b2d')
        d.rectangle((cx-1,25,cx,28),fill='#db738e')
    d.line((14,43,32,47,51,41),fill='#302735',width=2)
    save_noise(eyes,'eyes'+suffix)
    # Uneven checkerboard, chipped and with tiny ritual marks.
    floor=Image.new('RGB',(64,64)); d=ImageDraw.Draw(floor)
    for y in range(64):
        for x in range(64):
            sx=x+int(2*math.sin(y*.16)); sy=y+int(2*math.sin(x*.16))
            dark=((sx//16)+(sy//16))%2==0
            col=('#3b304a' if dark else '#997384') if dream else ('#303831' if dark else '#9e8f57')
            d.point((x,y),fill=col)
    for _ in range(35):
        x,y=rng.randrange(64),rng.randrange(64)
        d.line((x,y,x+2,y+1),fill='#5e4c40')
    save_noise(floor,'floor'+suffix)
    ceiling=Image.new('RGB',(64,64),'#342536' if dream else '#3f382e'); d=ImageDraw.Draw(ceiling)
    for x in range(0,64,16):
        d.line((x,0,x,63),fill='#16171d',width=2)
        d.line((x+3,0,x+3,63),fill='#695041')
    d.rectangle((0,27,63,34),fill='#241e25')
    d.line((0,35,63,35),fill='#775947')
    save_noise(ceiling,'ceiling'+suffix)

wood=Image.new('RGB',(64,64),'#664531'); d=ImageDraw.Draw(wood)
for x in range(0,64,16):
    d.line((x,0,x,63),fill='#291e25',width=2)
    for k in range(4):
        xx=x+rng.randrange(2,15)
        d.line((xx,0,xx+1,63),fill='#8c6542' if k%2 else '#4a332b')
    for y in (5,57):d.rectangle((x+3,y,x+4,y+1),fill='#d1aa68')
save_noise(wood,'wood')

def canvas():
    im=Image.new('RGBA',(64,96)); return im,ImageDraw.Draw(im)

im,d=canvas()
# Long, uneven ears, a cracked porcelain muzzle, riveted limbs and hollow eyes.
d.ellipse((8,87,57,95),fill='#17121c')
d.polygon([(17,24),(13,2),(21,0),(25,25)],fill='#a99c62')
d.polygon([(37,23),(42,4),(49,8),(45,31)],fill='#898453')
d.line((17,3,21,21),fill='#5a3f45',width=3)
d.line((45,10,40,25),fill='#533341',width=2)
d.rectangle((19,51,44,78),fill='#77734c',outline='#342c35',width=2)
d.rectangle((21,77,29,87),fill='#504d42');d.rectangle((36,76,43,89),fill='#504d42')
d.rectangle((16,86,30,91),fill='#3e3436');d.rectangle((36,87,50,93),fill='#3e3436')
d.polygon([(18,52),(14,54),(10,75),(16,78),(23,57)],fill='#8b8155')
d.polygon([(43,53),(49,54),(54,78),(47,80),(39,58)],fill='#8b8155')
d.polygon([(15,27),(25,20),(42,22),(51,32),(47,49),(38,55),(22,51),(13,40)],fill='#b8a975',outline='#51433b')
d.polygon([(16,33),(28,31),(28,39),(18,42)],fill='#241f2a')
d.polygon([(34,31),(46,34),(44,43),(34,40)],fill='#241f2a')
d.rectangle((22,35,24,37),fill='#f5b5a4');d.rectangle((38,35,40,37),fill='#ef91ab')
d.polygon([(29,39),(34,40),(31,44),(28,43)],fill='#4a323c')
d.line((19,46,30,49,43,46),fill='#342332',width=2)
for x in range(22,43,4):d.rectangle((x,46,x+1,48),fill='#dfc894')
d.line((33,23,30,29,33,33),fill='#55434b')
for y in (58,66,73):d.ellipse((29,y,33,y+4),fill='#352e37',outline='#b29a5b')
for x,y in [(17,56),(12,73),(47,56),(50,76),(24,81),(40,82)]:d.rectangle((x,y,x+2,y+2),fill='#c2ac74')
save_noise(im,'animatronic',8)

im,d=canvas()
d.ellipse((8,88,57,95),fill='#17121c')
d.rectangle((16,47,49,90),fill='#54383b',outline='#a17b47',width=2)
d.polygon([(10,46),(19,39),(50,40),(56,47),(48,52),(15,51)],fill='#997148')
for x in (20,44):d.rectangle((x,55,x+3,89),fill='#a08051')
d.rectangle((12,27,53,45),fill='#442c3c',outline='#cdad64',width=2)
d.polygon([(12,27),(14,11),(48,9),(53,27)],fill='#79503e',outline='#c6a365')
d.rectangle((19,14,44,23),fill='#292131',outline='#bb8e58')
for x in range(21,45,4):d.line((x,16,x,21),fill='#8b5878')
d.rectangle((29,33,36,39),fill='#d6bb70');d.rectangle((32,35,33,39),fill='#3c293b')
d.line((53,35,60,35,60,30),fill='#e1c878',width=2)
for x,y in ((17,30),(47,30),(17,40),(47,40)):d.point((x,y),fill='#f1c986')
save_noise(im,'box',5)

im,d=canvas()
d.ellipse((4,89,60,95),fill='#17121c')
d.rectangle((8,58,56,91),fill='#4c3837');d.rectangle((5,55,59,63),fill='#a78452')
d.polygon([(14,61),(49,61),(45,90),(20,87)],fill='#69435e',outline='#ad7187')
d.line((23,70,41,81,31,64,23,80,42,71,23,70),fill='#d0a372',width=1)
for x,h in [(12,31),(49,20)]:
    d.rectangle((x-4,54,x+5,57),fill='#bda164')
    d.rectangle((x-1,h,x+2,54),fill='#ddd29b')
    d.line((x+2,h+5,x+4,h+11,x+2,h+17),fill='#b2a16b')
    d.polygon([(x,h-10),(x-3,h-3),(x,h),(x+3,h-3)],fill='#cf7e46')
    d.rectangle((x,h-6,x+1,h-2),fill='#ffe3a0')
d.polygon([(23,53),(30,31),(39,53)],fill='#312734',outline='#b69069')
d.ellipse((28,42,34,47),fill='#cb8690'); d.point((31,44),fill='#292131')
save_noise(im,'altar',5)

im,d=canvas()
d.rectangle((5,0,58,95),fill='#231e2b')
d.rectangle((7,2,56,94),fill='#9f774e')
d.rectangle((12,7,51,92),fill='#382a40',outline='#c6a16b',width=2)
d.rectangle((16,11,47,89),fill='#4d3652')
for y in range(12,87,8):
    d.line((19,y,44,y+3),fill='#775473')
    d.point((24,y+1),fill='#d89da1')
d.ellipse((20,25,44,56),outline='#be8793',width=2)
d.line((25,40,39,40,32,30,25,40,32,50,39,40),fill='#d6aa75',width=1)
d.ellipse((42,65,46,69),fill='#e3bd75')
d.rectangle((4,92,59,95),fill='#c1a272')
save_noise(im,'door',5)

im=Image.new('RGBA',(32,32)); d=ImageDraw.Draw(im)
d.polygon([(4,5),(26,3),(28,26),(6,28)],fill='#d0be88',outline='#806848')
for y in range(9,24,4):d.line((9,y,23,y-1),fill='#66525b')
im.save(OUT/'letter.png')

# Two quiet original drones; preserve the existing lullaby.wav byte-for-byte.
for dream in (False,True):
    rate=16000; count=rate*8
    with wave.open(str(ROOT/'audio'/('dream_drone.wav' if dream else 'cabin_drone.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate)
        data=[]
        for i in range(count):
            t=i/rate
            v=.18*math.sin(math.tau*(48 if dream else 40)*t)+.08*math.sin(math.tau*(72.125 if dream else 60.125)*t)
            v*=.65+.35*math.sin(math.pi*t/8)**2
            data.append(struct.pack('<h',int(v*32767)))
        out.writeframes(b''.join(data))
print('Generated original cabin textures, billboard sprites, and two ambient loops.')
