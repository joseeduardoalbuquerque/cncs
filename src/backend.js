import { createClient } from '@supabase/supabase-js';
const config=window.CNCS_CONFIG;
export const client=config?.url && config?.key ? createClient(config.url,config.key,{auth:{flowType:'pkce',detectSessionInUrl:true}}) : null;
export const listURL=id=>`${config.url}/functions/v1/blacklist/${id}.txt`;
export async function api(path,method='GET',body){
 if(!client)throw Error('Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY nas variáveis do GitHub e publique novamente.');
 let result;
 if(path==='me') { const {data,error}=await client.auth.getSession();if(error)throw error;if(!data.session)return {user:null};result=await client.rpc('ensure_profile');if(result.error)throw result.error;return {user:result.data}; }
 if(path==='logout'){const {error}=await client.auth.signOut();if(error)throw error;return {ok:true};}
 if(path==='users')result=await client.from('profiles').select('id,email,name,status,admin').order('name');
 else if(path.startsWith('users/'))result=await client.rpc('set_user_status',{target:decodeURIComponent(path.slice(6)),new_status:body.status});
 else if(path==='lists' && method==='GET')result=await client.from('lists').select('*').order('updated',{ascending:false});
 else if(path==='lists' && method==='POST')result=await client.from('lists').insert({name:body.name}).select('id').single();
 else if(path.startsWith('lists/') && method==='PUT')result=await client.from('lists').update(body).eq('id',path.slice(6)).select('id').single();
 else if(path.startsWith('lists/') && method==='DELETE')result=await client.from('lists').delete().eq('id',path.slice(6)).select('id').single();
 else throw Error('Pedido desconhecido.');
 if(result.error)throw Error(result.error.message);return result.data;
}
export async function login(){const {error}=await client.auth.signInWithOAuth({provider:'google',options:{redirectTo:new URL('./',location.href).href,queryParams:{prompt:'select_account'}}});if(error)throw error;}
