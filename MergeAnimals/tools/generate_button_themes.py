"""Generate eight editable Godot Theme resources with four distinct button states."""
from pathlib import Path
palettes={'forest':('#a7c889','#bddb9b','#86aa6e','#bec8b4'), 'earth':('#c49b79','#dbb18c','#a47f61','#c7b8ad'), 'sunset':('#e8a77b','#f5bf96','#c77f57','#d5c0b3'), 'snow':('#aacdd4','#c7e3e7','#85afb9','#c0c9ca'), 'gold':('#e6bd5c','#f1d47f','#bc923c','#c9c0a4'), 'berry':('#c99091','#dda9a9','#ae7175','#cbb9ba'), 'sky':('#99c2de','#b9d8ec','#77a5c7','#b6c5cd'), 'cream':('#f1ddad','#fbebc5','#d4bf8d','#ddd5c3')}
def color(h):
 h=h.lstrip('#'); return 'Color('+', '.join(str(round(int(h[i:i+2],16)/255,5)) for i in (0,2,4))+', 1)'
out=Path(__file__).resolve().parents[1]/'assets/ui/themes';out.mkdir(parents=True,exist_ok=True)
for name,colors in palettes.items():
 lines=['[gd_resource type="Theme" load_steps=5 format=3]','']
 for state,bg in zip(('normal','hover','pressed','disabled'),colors):
  lines += [f'[sub_resource type="StyleBoxFlat" id="{state}"]', f'bg_color = {color(bg)}','border_width_left = 2','border_width_top = 2','border_width_right = 2','border_width_bottom = 2',f'border_color = {color("#654b3a")}','corner_radius_top_left = 10','corner_radius_top_right = 10','corner_radius_bottom_right = 10','corner_radius_bottom_left = 10','content_margin_left = 10.0','content_margin_right = 10.0','content_margin_top = 5.0','content_margin_bottom = 5.0','']
 lines += ['[resource]']+[f'Button/styles/{state} = SubResource("{state}")' for state in ('normal','hover','pressed','disabled')]+[f'Button/colors/font_color = {color("#30271e")}',f'Button/colors/font_hover_color = {color("#30271e")}',f'Button/colors/font_pressed_color = {color("#30271e")}',f'Button/colors/font_disabled_color = {color("#756e68")}', '']
 (out/f'{name}.tres').write_text('\n'.join(lines))
print('Generated',len(palettes),'editable themes')
