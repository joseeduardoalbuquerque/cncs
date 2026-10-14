import http from 'node:http';
import { readFileSync } from 'node:fs';
const files={'/':'index.html','/index.html':'index.html','/app.js':'app.js','/config.js':'config.js','/style.css':'style.css'};
http.createServer((req,res)=>{const file=files[new URL(req.url,'http://localhost').pathname];if(!file){res.writeHead(404);res.end();return;}try{const body=readFileSync('dist/'+file);res.writeHead(200,{'Content-Type':file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html','Cache-Control':'no-store'});res.end(body);}catch{res.writeHead(503);res.end('Execute npm run build primeiro.');}}).listen(Number(process.env.PORT || 3000),'0.0.0.0',()=>console.log('Static CNCS server ready'));
