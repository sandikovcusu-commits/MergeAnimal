// Development-only renderer: npm install --prefix <dir> @resvg/resvg-js@2.6.2
// NODE_PATH=<dir>/node_modules node tools/render_animal_vectors.cjs
const {Resvg}=require('@resvg/resvg-js');
const fs=require('fs');const path=require('path');
const root=path.resolve(__dirname,'..');
const source=path.join(root,'art_source/vector_animals');
for (const name of fs.readdirSync(source).sort()) {
  const svg=fs.readFileSync(path.join(source,name,'normal.svg'));
  const png=new Resvg(svg,{fitTo:{mode:'width',value:512}}).render().asPng();
  fs.writeFileSync(path.join(root,'assets/animals',name,'normal.png'),png);
}
