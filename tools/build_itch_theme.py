from PIL import Image, ImageDraw, ImageFont, ImageOps
from pathlib import Path
import random, zipfile

ROOT=Path(__file__).resolve().parents[1]
SHOTS=ROOT/'promo'/'screenshots'
OUT=ROOT/'promo'/'itch-theme-handmade'
OUT.mkdir(exist_ok=True)
INK='#100b16'; PAPER='#e6dfc8'; PINK='#bc7796'; ACID='#d9e57b'
def font(n,kind='pixel'):
    p=ROOT/('assets/replacements_v2/ui/fonts/DotGothic16-Regular.ttf' if kind=='pixel' else 'assets/fonts/RubikGlitch-Regular.ttf' if kind=='title' else 'assets/fonts/SpecialElite-Regular.ttf')
    return ImageFont.truetype(str(p),n)
def label(im,text,xy,n=20,color=PAPER,kind='pixel'):
    ImageDraw.Draw(im).text(xy,text,font=font(n,kind),fill=color,stroke_width=0)
def fit_title(im,text,xy,width,size,color):
    f=font(size,'title')
    while f.getlength(text)>width:
        size-=1; f=font(size,'title')
    ImageDraw.Draw(im).text(xy,text,font=f,fill=color)
def shot(name,box,size):
    return ImageOps.fit(Image.open(SHOTS/name).convert('RGB').crop(box),size,method=Image.Resampling.NEAREST)
def rough_rule(im,y,x1,x2,color):
    d=ImageDraw.Draw(im); rng=random.Random(y)
    for x in range(x1,x2,4): d.rectangle((x,y+rng.randrange(-2,2),x+3,y+3),fill=color)

# Reuse the real wall texture, recoloured as a quiet, repeatable dark-purple tile.
texture=Image.open(ROOT/'assets/fever_dreams/textures/cabin/wallpaper_01.png').convert('L').resize((256,256),Image.Resampling.NEAREST)
tile=ImageOps.colorize(texture,black='#100b16',white='#342038')
tile.save(OUT/'02-background-tile.png')
def canvas(size):
    im=Image.new('RGB',size,INK)
    for x in range(0,size[0],256):
        for y in range(0,size[1],256): im.paste(tile,(x,y))
    return im

# Compact masthead: deliberate typography and rectangular strips of real gameplay.
banner=canvas((1280,320)); d=ImageDraw.Draw(banner)
d.rectangle((16,16,625,302),fill=PINK)
d.polygon([(9,10),(613,16),(619,293),(17,286)],fill=PAPER)
label(banner,'DEPARTMENT OF IMPOSSIBLE SLEEP',(31,28),16,INK,'type')
fit_title(banner,'THE LAST',(26,54),565,83,INK)
fit_title(banner,'LULLABY',(24,130),575,114,INK)
label(banner,'DO NOT WIND FORWARD.',(34,259),18,INK,'type')
panels=[('01-patient-confession.png',(435,65,750,415),'PATIENT / 004'),('06-ayush-the-keeper.png',(510,170,825,470),'AYUSH / KEEPER'),('02-rue-your-protector.png',(525,90,800,440),'RUE / PERFORMER')]
for i,(name,crop,tag) in enumerate(panels):
    x=640+i*210
    d.rectangle((x-3,14,x+200,305),fill=PINK if i==1 else PAPER)
    banner.paste(shot(name,crop,(198,248)),(x,18))
    d.rectangle((x,267,x+198,301),fill=INK)
    label(banner,tag,(x+7,275),13,ACID)
rough_rule(banner,315,0,1280,INK)
banner.save(OUT/'01-banner.png')

# Embed preview leaves a deliberately empty middle for itch's Run Game button.
embed=canvas((1280,720)); d=ImageDraw.Draw(embed)
d.rectangle((20,22,1260,152),fill=PAPER)
fit_title(embed,'THE LAST LULLABY',(45,40),1190,89,INK)
label(embed,'PATIENT FILE / 004',(32,177),19,ACID,'type')
label(embed,'THE KEEPER / AYUSH',(854,177),19,ACID,'type')
for x,name,crop in [(28,'01-patient-confession.png',(390,40,830,440)),(846,'06-ayush-the-keeper.png',(430,145,880,440))]:
    d.rectangle((x-5,212,x+405,608),fill=PINK)
    embed.paste(shot(name,crop,(400,382)),(x,217))
    rough_rule(embed,606,x-4,x+405,INK)
d.rectangle((452,214,821,608),fill=INK)
label(embed,'[ DREAM LINK ]',(507,250),24,PAPER)
label(embed,'AWAITING INPUT',(524,466),19,ACID)
label(embed,'HEADPHONES',(550,523),17,PINK)
label(embed,'RECOMMENDED',(541,547),17,PINK)
rough_rule(embed,640,28,1252,PAPER)
label(embed,'FOUR MUSIC BOXES. ONE WAY OUT.',(35,664),24,PAPER,'type')
label(embed,'WASD / MOUSE / E',(978,670),16,ACID)
embed.save(OUT/'03-embed-bg.png')

(OUT/'UPLOAD-GUIDE.txt').write_text('''BANNER: 01-banner.png (1280 x 320)
BACKGROUND: 02-background-tile.png (256 x 256). Choose Repeat/Tile if offered; do not stretch it.
EMBED BG: 03-embed-bg.png (1280 x 720). Middle is reserved for the Run Game button.

Page colours: BG #100B16 / BG2 #211629 / Text #EEE6CF / Link #D9E57B.

These files were composed with Pillow from real in-engine screenshots, the existing wallpaper texture, and the game's actual fonts. No new image generation was used. Some existing game art was originally AI-assisted; these are direct presentations of the game, not newly illustrated scenes.
Source assets and fonts retain their original credits in the project.
''',encoding='utf-8')
with zipfile.ZipFile(OUT/'TheLastLullaby-ItchTheme.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in OUT.iterdir():
        if p.suffix in ['.png','.txt']: z.write(p,p.name)
for p in OUT.glob('*.png'):
    with Image.open(p) as im: print(p.name, im.size, p.stat().st_size)
