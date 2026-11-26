"""Génère les GIF animés du README : bannière, parcours et équipe."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SORTIE = Path(__file__).resolve().parent.parent / 'docs' / 'readme'
POP = '/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf'
INT = '/usr/share/fonts/opentype/inter/Inter-Medium.otf'
INTS = '/usr/share/fonts/opentype/inter/Inter-SemiBold.otf'
F = lambda p, s: ImageFont.truetype(p, s)

BRUN, CREME = (42, 32, 28), (255, 250, 242)
ROUGE, SAFRAN, OLIVE, BLEU, AUB, OCRE = (224, 72, 43), (242, 163, 42), (91, 138, 58), (47, 109, 181), (139, 58, 98), (196, 122, 10)
DOUX, TRAIT = (117, 103, 94), (234, 223, 207)
SS = 2  # suréchantillonnage pour des bords lisses


def ease(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def enregistrer(images, nom, duree_ms):
    pal = [im.convert('P', palette=Image.ADAPTIVE, colors=128) for im in images]
    pal[0].save(SORTIE / nom, save_all=True, append_images=pal[1:], duration=duree_ms, loop=0, optimize=True, disposal=2)
    print(nom, len(images), 'images', (SORTIE / nom).stat().st_size // 1024, 'Ko')


# ------------------------------------------------------------------ bannière
def banniere():
    W, H, N = 1200, 380, 72
    phrases = ['Un planning de 21 repas, adapté à ton profil',
               'Des recettes adaptées à ta cuisine, même sans four',
               'Une liste de courses chiffrée en dinars']
    images = []
    for k in range(N):
        t = k / N
        im = Image.new('RGB', (W * SS, H * SS), BRUN)
        d = ImageDraw.Draw(im)
        s = lambda v: int(v * SS)
        # ronds qui flottent
        for cx, cy, r, c, ph in [(905, 120, 125, SAFRAN, 0), (1085, 290, 78, OLIVE, 2), (790, 300, 40, BLEU, 4), (1135, 60, 24, ROUGE, 1), (690, 70, 14, AUB, 3)]:
            dy = -10 * math.sin(2 * math.pi * t + ph)
            d.ellipse([s(cx - r), s(cy - r + dy), s(cx + r), s(cy + r + dy)], fill=c)
        # carte planning
        dy = -8 * math.sin(2 * math.pi * t + 2)
        d.rounded_rectangle([s(860), s(150 + dy), s(1110), s(300 + dy)], s(18), fill=CREME)
        d.text((s(882), s(165 + dy)), 'Lundi · 3 repas', font=F(POP, s(18)), fill=BRUN)
        d.rounded_rectangle([s(882), s(200 + dy), s(1088), s(212 + dy)], s(6), fill=TRAIT)
        p = 0.2 + 0.8 * ease(0.5 - 0.5 * math.cos(2 * math.pi * t))
        d.rounded_rectangle([s(882), s(200 + dy), s(882 + 196 * p), s(212 + dy)], s(6), fill=OLIVE)
        d.text((s(882), s(225 + dy)), f'{int(2090 * p):,} kcal'.replace(',', ' ') + ' sur 2 090', font=F(INT, s(16)), fill=DOUX)
        d.text((s(882), s(255 + dy)), '55,830 DT', font=F(POP, s(20)), fill=ROUGE)
        d.text((s(992), s(259 + dy)), 'sur 60 DT', font=F(INT, s(15)), fill=DOUX)
        # marmite + vapeur
        d.rounded_rectangle([s(70), s(70), s(162), s(162)], s(22), fill=ROUGE)
        for i, x in enumerate([102, 116, 130]):
            u = (t * 3 + i / 3) % 1
            a = math.sin(math.pi * u)
            y0 = 100 - 26 * u
            col = mix(ROUGE, (255, 255, 255), a)
            d.arc([s(x - 6), s(y0 - 16), s(x + 6), s(y0)], 90, 270, fill=col, width=s(5))
        d.rounded_rectangle([s(88), s(110), s(144), s(144)], s(9), outline='white', width=s(6))
        d.line([s(82), s(110), s(150), s(110)], fill='white', width=s(6))
        # titre lettre par lettre (en boucle)
        x = 180
        fT = F(POP, s(96))
        for i, ch in enumerate('Dbarti'):
            a = ease((t * N - 2 - i * 2) / 6) if t < 0.92 else ease((N - t * N) / 5)
            col = mix(BRUN, ROUGE if i >= 4 else (255, 255, 255), a)
            d.text((s(x), s(52 + 18 * (1 - a))), ch, font=fT, fill=col)
            x += fT.getlength(ch) / SS
        d.text((s(72), s(202)), 'Chnowa dbartek lyoum ?', font=F(POP, s(30)), fill=SAFRAN)
        # phrases qui défilent
        i = int(t * 3)
        u = (t * 3) % 1
        a = ease(u / 0.15) * ease((1 - u) / 0.15)
        d.text((s(72 + 12 * (1 - a)), s(266)), '›  ' + phrases[i], font=F(INT, s(24)), fill=mix(BRUN, (234, 223, 214), a))
        # puces
        for (x0, w, c, txt) in [(72, 118, ROUGE, 'Flutter'), (202, 118, BLEU, 'Android'), (332, 138, OLIVE, 'Agent IA')]:
            d.rounded_rectangle([s(x0), s(320), s(x0 + w), s(350)], s(15), fill=c)
            d.text((s(x0 + w / 2), s(335)), txt, font=F(INTS, s(15)), fill='white', anchor='mm')
        images.append(im.resize((W, H), Image.LANCZOS))
    enregistrer(images, 'banniere.gif', 80)


# ------------------------------------------------------------------ parcours
def parcours():
    W, H = 1200, 210
    etapes = [('Accès libre', 'visiteur ou compte', ROUGE), ('Questionnaire', '6 étapes', BLEU), ('Profil', 'besoin en kcal', OLIVE),
              ('Planning', '21 repas', OCRE), ('Recettes', 'adaptées à ta cuisine', AUB), ('Liste chiffrée', 'en dinars', ROUGE),
              ('Courses', 'magasin ou livraison', BLEU)]
    xs = [100 + i * 1000 / 6 for i in range(7)]
    N = 63
    images = []
    for k in range(N):
        prog = min(1.0, k / 49)  # la ligne avance, puis pause
        im = Image.new('RGB', (W * SS, H * SS), CREME)
        d = ImageDraw.Draw(im)
        s = lambda v: int(v * SS)
        d.line([s(100), s(80), s(1100), s(80)], fill=TRAIT, width=s(6))
        d.line([s(100), s(80), s(100 + 1000 * prog), s(80)], fill=ROUGE, width=s(6))
        for i, (lbl, sous, c) in enumerate(etapes):
            seuil = i / 6
            actif = prog >= seuil - 1e-6
            pulse = 1 + 0.18 * max(0.0, 1 - abs(prog - seuil) * 12) if actif else 1
            r = 34 * pulse
            col = c if actif else mix(c, CREME, 0.6)
            d.ellipse([s(xs[i] - r), s(80 - r), s(xs[i] + r), s(80 + r)], fill=col)
            d.text((s(xs[i]), s(80)), str(i + 1), font=F(POP, s(26)), fill='white', anchor='mm')
            d.text((s(xs[i]), s(140)), lbl, font=F(POP, s(17)), fill=BRUN if actif else mix(BRUN, CREME, 0.55), anchor='mm')
            d.text((s(xs[i]), s(166)), sous, font=F(INT, s(14)), fill=DOUX if actif else mix(DOUX, CREME, 0.55), anchor='mm')
        images.append(im.resize((W, H), Image.LANCZOS))
    enregistrer(images, 'parcours.gif', 120)


# ------------------------------------------------------------------ équipe
def equipe():
    membres = [('Youssef Kobbi', ROUGE), ('Yassine Affes', BLEU), ('Mohamed Amine Chakroun', OLIVE), ('Ghada Hajjem', OCRE), ('Rayen Touil', AUB)]
    W, H, N = 1200, 300, 60
    cw = 212
    gap = (W - 80 - 5 * cw) / 4
    images = []
    for k in range(N):
        t = k / N
        im = Image.new('RGB', (W * SS, H * SS), CREME)
        d = ImageDraw.Draw(im)
        s = lambda v: int(v * SS)
        d.text((s(W / 2), s(38)), "L'équipe Dbarti", font=F(POP, s(30)), fill=BRUN, anchor='mm')
        for i, (nom, c) in enumerate(membres):
            a = ease((t * N - i * 4) / 8)
            x = 40 + i * (cw + gap)
            y = 80 + 30 * (1 - a) - 6 * math.sin(2 * math.pi * t + i) * a
            fond = mix(CREME, (255, 255, 255), a)
            d.rounded_rectangle([s(x), s(y), s(x + cw), s(y + 190)], s(20), fill=fond, outline=mix(CREME, c, a), width=s(3))
            ini = ''.join(p[0] for p in nom.split()[::max(1, len(nom.split()) - 1)])[:2].upper()
            d.ellipse([s(x + cw / 2 - 42), s(y + 20), s(x + cw / 2 + 42), s(y + 104)], fill=mix(CREME, c, a))
            d.text((s(x + cw / 2), s(y + 62)), ini, font=F(POP, s(30)), fill=mix(CREME, (255, 255, 255), a), anchor='mm')
            mots = nom.split()
            lignes = [nom] if len(nom) <= 16 else [' '.join(mots[:-1]), mots[-1]]
            for j, l in enumerate(lignes):
                d.text((s(x + cw / 2), s(y + 128 + j * 24)), l, font=F(POP, s(17)), fill=mix(CREME, BRUN, a), anchor='mm')
        images.append(im.resize((W, H), Image.LANCZOS))
    enregistrer(images, 'equipe.gif', 90)


if __name__ == '__main__':
    banniere()
    parcours()
    equipe()
