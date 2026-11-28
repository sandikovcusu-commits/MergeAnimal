// Development renderer, @resvg/resvg-js 2.6.2; source remains editable SVG.
const {Resvg}=require('@resvg/resvg-js');
const fs=require('fs'),path=require('path'),root=path.resolve(__dirname,'..');
for(const name of fs.readdirSync(path.join(root,'art_source/vector_animals')).sort())
 for(const expression of ['blink','happy','surprise']) {
  const svg=fs.readFileSync(path.join(root,'art_source/vector_animals',name,expression+'.svg'));
  fs.writeFileSync(path.join(root,'assets/animals',name,expression+'.png'),new Resvg(svg,{fitTo:{mode:'width',value:256}}).render().asPng());
 }
