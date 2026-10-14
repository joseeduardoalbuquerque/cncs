Deno.serve(async (req: Request) => {
 const headers={'Content-Type':'text/plain; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Access-Control-Allow-Origin':'*'};
 if(req.method==='OPTIONS')return new Response(null,{headers:{...headers,'Access-Control-Allow-Methods':'GET, HEAD, OPTIONS'}});
 if(!['GET','HEAD'].includes(req.method))return new Response('Método não permitido.',{status:405,headers});
 const match=new URL(req.url).pathname.match(/\/blacklist\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.txt$/i);
 if(!match)return new Response('Lista indisponível.',{status:404,headers});
 try{
 const key=Deno.env.get('SUPABASE_ANON_KEY')!;
 const response=await fetch(Deno.env.get('SUPABASE_URL')+'/rest/v1/rpc/public_blacklist',{method:'POST',headers:{apikey:key,Authorization:'Bearer '+key,'Content-Type':'application/json'},body:JSON.stringify({list_id:match[1]})});
 if(!response.ok)throw Error('Database request failed');
 const text=await response.json();
 if(text===null)return new Response('Lista indisponível.',{status:404,headers});
 return new Response(req.method==='HEAD'?null:text,{headers});
 }catch{return new Response('Serviço temporariamente indisponível.',{status:503,headers});}
});
