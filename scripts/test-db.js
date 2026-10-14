import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
const name='cncs-test-'+process.pid;
function docker(args,input){const r=spawnSync('docker',args,{input,encoding:'utf8'});if(r.status!==0)throw Error(r.stderr || r.stdout || 'Docker unavailable');return r.stdout;}
try{
 docker(['run','-d','--name',name,'-e','POSTGRES_PASSWORD=local-test-only','postgres:17']);
 let ready=false;for(let i=0;i<60;i++){const r=spawnSync('docker',['exec',name,'pg_isready','-U','postgres'],{stdio:'ignore'});if(r.status===0){ready=true;break;}await new Promise(r=>setTimeout(r,500));}if(!ready)throw Error('PostgreSQL not ready');
 for(const file of ['test/bootstrap.sql','supabase/schema.sql','supabase/schema.sql','test/permissions.sql'])docker(['exec','-i',name,'psql','-U','postgres','-v','ON_ERROR_STOP=1'],readFileSync(file));
 console.log('PostgreSQL: aprovação, isolamento, partilha, revogação e repetição do schema passaram.');
}finally{spawnSync('docker',['rm','-f',name],{stdio:'ignore'});}
