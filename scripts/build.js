import { mkdirSync, copyFileSync, writeFileSync, rmSync } from 'node:fs';
import { build } from 'esbuild';
const url=process.env.SUPABASE_URL || '',key=process.env.SUPABASE_PUBLISHABLE_KEY || '';
if(url && (!/^https:\/\/[a-z0-9-]+\.supabase\.co$/.test(url)))throw Error('SUPABASE_URL inválida: use https://<projeto>.supabase.co sem barra final');
if(key.startsWith('sb_secret_'))throw Error('Nunca publique uma chave secreta.');
if(key.startsWith('eyJ')){const payload=JSON.parse(Buffer.from(key.split('.')[1],'base64url').toString());if(payload.role!=='anon')throw Error('Apenas a chave anon/publishable pode ser pública.');}
if(process.env.CI && (!url || !key))throw Error('Configure as variáveis SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY no GitHub.');
rmSync('dist',{recursive:true,force:true});mkdirSync('dist');
for(const file of ['index.html','style.css'])copyFileSync('public/'+file,'dist/'+file);
writeFileSync('dist/config.js','window.CNCS_CONFIG='+JSON.stringify({url,key})+';');
await build({entryPoints:['src/app.js'],bundle:true,minify:true,outfile:'dist/app.js',platform:'browser',target:'es2022'});
