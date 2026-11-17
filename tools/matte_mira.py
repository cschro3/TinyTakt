# Schneidet Mira aus dem Konzeptbild frei (Alpha-Matte, Closed-Form-Matting).
# Aufruf: python3 tools/matte_mira.py <Ordner mit mira_character_concept.png>  → mira_full.png (RGBA)
# Benötigt: numpy pillow scipy opencv-python-headless pymatting. Prototyp-Werkzeug, siehe docs/art/PROTOTYP_ASSETS.md
import numpy as np, cv2, sys
from PIL import Image
from scipy import ndimage as ndi
from pymatting import estimate_alpha_cf, estimate_foreground_ml

import sys
D=sys.argv[1].rstrip('/')+'/' if len(sys.argv)>1 else 'references/'
rgb=np.array(Image.open(D+'mira_character_concept.png').convert('RGB'))
im=rgb.astype(int)
H,W,_=im.shape
chroma=im.max(2)-im.min(2)
bgl=(chroma<=6)&(im.min(2)>=212)
lab,n=ndi.label(bgl)
sizes=ndi.sum(bgl,lab,range(1,n+1))
border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
bg=np.zeros_like(bgl)
for i in range(1,n+1):
    if i in border:   # nur randverbundener Hintergrund (eingeschlossene helle Flächen sind Fell)
        bg|=(lab==i)
print('Hintergrundanteil',bg.mean().round(3),'Komponenten',n)
fg_hard=ndi.binary_erosion(~bg,iterations=5)
bg_hard=ndi.binary_erosion(bg,iterations=2)
tri=np.full((H,W),0.5)
tri[fg_hard]=1.0
tri[bg_hard]=0.0
img=rgb.astype(np.float64)/255
alpha=estimate_alpha_cf(img,tri)
fg=estimate_foreground_ml(img,alpha)
alpha=np.clip(alpha,0,1)
# Kleine Reste (Alpha < 3 %) hart auf 0
alpha[alpha<0.03]=0
out=np.dstack([np.clip(fg,0,1),alpha])
out=(out*255+0.5).astype(np.uint8)
Image.fromarray(out,'RGBA').save('mira_full.png')
ys,xs=np.where(alpha>0.02)
print('bbox',xs.min(),xs.max(),ys.min(),ys.max())
