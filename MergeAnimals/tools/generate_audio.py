#!/usr/bin/env python3
"""Deterministic original synthesized audio, no source recordings or samples."""
import math, pathlib, random, struct, wave
ROOT=pathlib.Path(__file__).resolve().parents[1]/'assets/audio'
RATE=22050
EVENTS={
'button_click':(660,0.09),'menu_back':(460,0.12),'animal_drop':(400,0.16),
'soft_landing':(220,0.15),'animal_collision':(280,0.12),'small_merge':(620,0.23),
'medium_merge':(520,0.28),'large_merge':(400,0.35),'combo':(800,0.28),
'golden_merge':(700,0.65),'animal_discovered':(660,0.50),'achievement_unlocked':(780,0.55),
'challenge_success':(640,0.62),'challenge_failed':(320,0.48),'undo':(480,0.32),
'remove':(420,0.27),'rescue':(540,0.46),'game_over':(300,0.58),
'danger_warning':(330,0.32),'theme_unlocked':(740,0.50)}
def write(path,arr):
 path.parent.mkdir(parents=True,exist_ok=True)
 with wave.open(str(path),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE)
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v))*32767)) for v in arr))
for name,(freq,length) in EVENTS.items():
 n=int(RATE*length); data=[]
 for i in range(n):
  t=i/RATE; attack=min(1,t/0.012); release=max(0,1-t/length)**2
  # Unpitched transients are intentionally soft; each event has a distinct timbre.
  sweep=-0.22 if name in ('challenge_failed','game_over','menu_back') else 0.16
  phase=2*math.pi*freq*(t+sweep*t*t/(2*length))
  val=math.sin(phase)+0.23*math.sin(2*phase)+0.12*math.sin(3.01*phase)
  if name in ('golden_merge','achievement_unlocked','theme_unlocked','challenge_success'):
   val+=0.28*math.sin(phase*1.5)
  data.append(0.14*attack*release*val)
 write(ROOT/'sfx'/f'{name}.wav',data)
# Eight seconds; all voices fade to exact zero at the loop seam.
# Fixed chord/arpeggio patterns, analytic synthesis only. No external music.
for name,notes,pace in [('forest',[261.626,329.628,391.995,523.251],0.5),('sunset',[220,277.183,329.628,440],0.5),('snow',[293.665,369.994,440,587.33],1.0)]:
 length=8; n=RATE*length; data=[]
 for i in range(n):
  t=i/RATE; k=int(t/pace); local=t-k*pace; f=notes[k%len(notes)]
  env=min(1,local/0.025)*math.exp(-local*(3.2 if name=='snow' else 4.4))
  tone=math.sin(2*math.pi*f*local)+0.22*math.sin(2*math.pi*2*f*local)
  pad=math.sin(2*math.pi*notes[0]*0.5*t)+0.45*math.sin(2*math.pi*notes[2]*0.5*t)
  seam=min(1,t/0.10,(length-t)/0.10)
  data.append(seam*(0.055*env*tone+0.015*pad))
 write(ROOT/'music'/f'{name}.wav',data)
