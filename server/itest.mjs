process.env.KORSHI_NO_LISTEN='1';
const { app } = await import('./dist/index.js');
const srv = app.listen(0);
await new Promise(r=>srv.once('listening',r));
const base = 'http://127.0.0.1:'+srv.address().port;
let pass=0, fail=0;
const ok=(c,m)=>{ if(c){pass++}else{fail++;console.log('  FAIL:',m)} };
const J = r => r.json();
// admin login
let r = await fetch(base+'/api/auth/admin/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:'admin@korshi.kz',password:'admin123'})});
let a = await J(r); ok(r.status===200 && a.token,'admin login'); const AT=a.token;
ok((await fetch(base+'/api/auth/admin/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:'admin@korshi.kz',password:'wrong'})})).status===401,'admin bad pw 401');
// admin endpoints need auth
ok((await fetch(base+'/api/admin/stats')).status===401,'stats needs auth');
let stats = await J(await fetch(base+'/api/admin/stats',{headers:{authorization:'Bearer '+AT}}));
ok(stats.residents===3 && stats.reportsTotal===3,'admin stats counts');
// resident login by invite code
r = await fetch(base+'/api/auth/resident/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:'+7 777 123 45 67',secret:'ab12-48'})});
let rl = await J(r); ok(r.status===200 && rl.token,'resident login by code (case-insens, formatted phone)'); const RT=rl.token;
ok((await fetch(base+'/api/auth/resident/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:'+77771234567',secret:'nope'})})).status===401,'resident bad code 401');
const RH={authorization:'Bearer '+RT};
// home/updates/polls/contacts
let home = await J(await fetch(base+'/api/home',{headers:RH}));
ok(home.announcement.title && Array.isArray(home.today) && home.poll.question,'home payload');
ok(home.contacts.length>0 && home.partner.phone,'home contacts+partner');
let upd = await J(await fetch(base+'/api/updates',{headers:RH}));
ok(upd.pinned.title && upd.latest.length>0,'updates payload');
let polls = await J(await fetch(base+'/api/polls',{headers:RH}));
ok(polls.active.options.length===2 && polls.active.voted===false,'polls active not voted');
let cts = await J(await fetch(base+'/api/contacts',{headers:RH}));
ok(cts.important.length===4 && cts.services.length===4 && cts.partners.length===3,'contacts groups');
// reports list (own)
let reps = await J(await fetch(base+'/api/reports',{headers:RH}));
ok(reps.length===3 && reps[0].steps.length>0,'resident reports list');
let det = await J(await fetch(base+'/api/reports/r1',{headers:RH}));
ok(det.description && det.detailSteps.length>0 && det.chairmanUpdates.length>0,'report detail r1');
// create report
r = await fetch(base+'/api/reports',{method:'POST',headers:{...RH,'content-type':'application/json'},body:JSON.stringify({category:'water',description:'Тестовая заявка',location:'ул. Мереке, 12'})});
let nr = await J(r); ok(r.status===201 && nr.id && nr.status==='waitingResponse','create report');
ok((await J(await fetch(base+'/api/reports',{headers:RH}))).length===4,'report appears in list');
// vote
const optId = polls.active.options[0] && (await J(await fetch(base+'/api/polls',{headers:RH}))) ; 
let pollsFull = await J(await fetch(base+'/api/admin/polls',{headers:{authorization:'Bearer '+AT}}));
// get option id from DB via vote on p1 option 1
r = await fetch(base+'/api/polls/p1/vote',{method:'POST',headers:{...RH,'content-type':'application/json'},body:JSON.stringify({optionId:1})});
ok(r.status===200,'vote ok');
let pv = await J(await fetch(base+'/api/polls',{headers:RH}));
ok(pv.active.voted===true,'voted reflected');
// admin: create announcement + delete
r = await fetch(base+'/api/admin/announcements',{method:'POST',headers:{authorization:'Bearer '+AT,'content-type':'application/json'},body:JSON.stringify({type:'event',title:'Тест',message:'м'})});
let na = await J(r); ok(r.status===201 && na.id,'create announcement');
ok((await fetch(base+'/api/admin/announcements/'+na.id,{method:'DELETE',headers:{authorization:'Bearer '+AT}})).status===200,'delete announcement');
// admin: invite resident
r = await fetch(base+'/api/admin/residents/invite',{method:'POST',headers:{authorization:'Bearer '+AT,'content-type':'application/json'},body:JSON.stringify({phone:'+77001112222',address:'ул. Новая, 1',name:'Тест Тестов'})});
let inv = await J(r); ok(r.status===201 && /^[A-Z0-9]{4}-[A-Z0-9]{2}$/.test(inv.activationCode),'invite code format');
// new resident can log in with the code
ok((await fetch(base+'/api/auth/resident/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:'+77001112222',secret:inv.activationCode})})).status===200,'invited resident logs in');
// set password then login with password
ok((await fetch(base+'/api/auth/resident/password',{method:'POST',headers:{...RH,'content-type':'application/json'},body:JSON.stringify({password:'mypass1'})})).status===200,'set password');
ok((await fetch(base+'/api/auth/resident/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:'+77771234567',secret:'mypass1'})})).status===200,'login with new password');
ok((await fetch(base+'/api/auth/resident/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:'+77771234567',secret:'AB12-48'})})).status===200,'invite code still works after password set');
// admin patch report status
r = await fetch(base+'/api/admin/reports/r2',{method:'PATCH',headers:{authorization:'Bearer '+AT,'content-type':'application/json'},body:JSON.stringify({status:'inProgress',contractor:'X LLP'})});
let pr = await J(r); ok(r.status===200 && pr.status==='inProgress' && pr.contractor==='X LLP','admin patch report');
r = await fetch(base+'/api/admin/reports/r2/update',{method:'POST',headers:{authorization:'Bearer '+AT,'content-type':'application/json'},body:JSON.stringify({body:'Обновление от председателя'})});
let ur = await J(r); ok(ur.chairmanUpdates.at(-1).body==='Обновление от председателя','admin add update');
srv.close();
console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
process.exit(fail?1:0);
