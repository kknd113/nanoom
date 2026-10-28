// Run against the dedicated Nanoom project with FIREBASE_CONFIG JSON and CLEANUP_FILE.
// Creates synthetic accounts, never sends email, deletes those accounts in finally.
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, deleteUser } from 'firebase/auth';
import { getFirestore, doc, collection, writeBatch, setDoc, getDoc, getDocs, updateDoc, deleteDoc, serverTimestamp, Timestamp, Bytes, query, orderBy, limit, terminate } from 'firebase/firestore';
import { randomUUID } from 'node:crypto';
import { writeFileSync } from 'node:fs';
const config = JSON.parse(process.env.FIREBASE_CONFIG);
const run = randomUUID().replaceAll('-','');
const groupID = `verification-${run}`;
const invitationID = randomUUID().replaceAll('-','');
const clients = [];
let checks = 0;
const cleanup = { groupID, invitationID, users: [] };
async function client(label, authenticated=true) {
  const app = initializeApp(config, label+run);
  const auth = getAuth(app), db = getFirestore(app);
  const value = { app, auth, db };
  clients.push(value);
  if (authenticated) {
    const { user } = await createUserWithEmailAndPassword(auth, `nanoom-${label}-${run}@example.com`, randomUUID()+'Aa1!');
    value.uid = user.uid;
    cleanup.users.push(user.uid);
    writeFileSync(process.env.CLEANUP_FILE, JSON.stringify(cleanup));
  }
  return value;
}
async function allowed(name, fn) { await fn(); checks++; console.log(`PASS ${name}`); }
async function denied(name, fn) {
  try { await fn(); } catch(e) {
    if (e.code === 'permission-denied') { checks++; console.log(`PASS deny ${name}`); return; }
    throw e;
  }
  throw new Error(`Unexpectedly allowed: ${name}`);
}
function memberBatch(c, token) {
  const batch = writeBatch(c.db);
  batch.set(doc(c.db,`groups/${groupID}/members/${c.uid}`), {displayName: 'Verification '+c.uid.slice(0,4), inviteID: token, joinedAt: serverTimestamp()});
  batch.set(doc(c.db,`users/${c.uid}/groupMemberships/${groupID}`), {joinedAt: serverTimestamp()});
  return batch;
}
try {
  const a = await client('owner'), b = await client('member'), outsider = await client('outsider'), guest = await client('guest',false);
  const group = doc(a.db,`groups/${groupID}`);
  const prayerPath = `groups/${groupID}/prayers/prayer`;
  const prayer = doc(a.db, prayerPath);
  const initial = {authorID:a.uid,body:'Synthetic server verification. No personal prayer data.',createdAt:serverTimestamp(),deleted:false};
  await denied('unauthenticated group query',()=>getDocs(collection(guest.db,'groups')));
  await allowed('atomic private group creation',async()=> {
    const batch=memberBatch(a,'');
    batch.set(group,{name:'Integration verification',ownerID:a.uid,createdAt:serverTimestamp()});
    await batch.commit();
  });
  await allowed('server prayer creation',()=>setDoc(prayer,initial));
  await allowed('app prayer query',()=>getDocs(query(collection(a.db,`groups/${groupID}/prayers`),orderBy('createdAt','desc'),limit(100))));
  await allowed('app own membership query',()=>getDocs(query(collection(a.db,`users/${a.uid}/groupMemberships`),limit(1))));
  await denied('outsider group read',()=>getDoc(doc(outsider.db,`groups/${groupID}`)));
  await denied('outsider prayer read',()=>getDoc(doc(outsider.db,prayerPath)));
  await denied('join without invitation',()=>memberBatch(outsider,'').commit());
  await denied('fake private membership index',()=>setDoc(doc(outsider.db,`users/${outsider.uid}/groupMemberships/${groupID}`),{joinedAt:serverTimestamp()}));
  await denied('read another user index',()=>getDocs(collection(b.db,`users/${a.uid}/groupMemberships`)));
  await denied('oversized body on create',()=>setDoc(doc(a.db,`groups/${groupID}/prayers/oversize`),{...initial,body:'x'.repeat(2001)}));
  await denied('oversized body on update',()=>updateDoc(prayer,{body:'x'.repeat(2001)}));
  await denied('author spoof on create',()=>setDoc(doc(a.db,`groups/${groupID}/prayers/spoof`),{...initial,authorID:b.uid}));
  await denied('author change',()=>updateDoc(prayer,{authorID:b.uid}));
  await denied('creation timestamp change',()=>updateDoc(prayer,{createdAt:Timestamp.fromMillis(0)}));
  await denied('required field omitted',()=>setDoc(doc(a.db,`groups/${groupID}/prayers/missing`),{body:'No author'}));
  await denied('schema pollution create',()=>setDoc(doc(a.db,`groups/${groupID}/prayers/polluted`),{...initial,isAdmin:true}));
  await denied('schema pollution update',()=>updateDoc(prayer,{isAdmin:true}));
  await denied('body type corruption',()=>updateDoc(prayer,{body:42}));
  await denied('owner role transfer',()=>updateDoc(group,{ownerID:b.uid}));
  await denied('public profile leak',()=>getDoc(doc(b.db,`users/${a.uid}`)));
  const invite = {groupID,groupName:'Integration verification',ownerID:a.uid,createdAt:serverTimestamp(),expiresAt:Timestamp.fromMillis(Date.now()+3600000)};
  await denied('outsider invite creation',()=>setDoc(doc(outsider.db,`invitations/${'b'.repeat(32)}`),{...invite,ownerID:outsider.uid}));
  await denied('expired invite creation',()=>setDoc(doc(a.db,`invitations/${'e'.repeat(32)}`),{...invite,expiresAt:Timestamp.fromMillis(0)}));
  await allowed('owner issues invitation',()=>setDoc(doc(a.db,`invitations/${invitationID}`),invite));
  await denied('invitation enumeration',()=>getDocs(collection(b.db,'invitations')));
  await allowed('recipient reads exact invitation',()=>getDoc(doc(b.db,`invitations/${invitationID}`)));
  await allowed('invited account joins atomically',()=>memberBatch(b,invitationID).commit());
  await allowed('member reads server prayer',async()=>{
    const result=await getDoc(doc(b.db,prayerPath));
    if(result.data()?.body!==initial.body) throw new Error('Server round trip mismatch');
  });
  await allowed('member list query',()=>getDocs(collection(b.db,`groups/${groupID}/members`)));
  await denied('member changes another prayer',()=>updateDoc(doc(b.db,prayerPath),{body:'Hijack'}));
  await denied('member adds author update',()=>setDoc(doc(b.db,prayerPath+'/updates/foreign'),{authorID:b.uid,body:'Hijack',createdAt:serverTimestamp()}));
  await allowed('author appends update',()=>setDoc(doc(a.db,prayerPath+'/updates/one'),{authorID:a.uid,body:'A synthetic update',createdAt:serverTimestamp()}));
  await allowed('member reads update query',()=>getDocs(query(collection(b.db,prayerPath+'/updates'),orderBy('createdAt'))));
  const reaction=doc(b.db,prayerPath+`/reactions/${b.uid}`);
  await allowed('member prays once',()=>setDoc(reaction,{createdAt:serverTimestamp()}));
  await denied('duplicate prayer reaction',()=>setDoc(reaction,{createdAt:serverTimestamp()}));
  await denied('owner self reaction',()=>setDoc(doc(a.db,prayerPath+`/reactions/${a.uid}`),{createdAt:serverTimestamp()}));
  await allowed('member removes own reaction',()=>deleteDoc(reaction));
  const photoPath = `groups/${groupID}/memberPhotos/${b.uid}`;
  const photo = { image: Bytes.fromUint8Array(new Uint8Array([255,216,255,217])), updatedAt: serverTimestamp() };
  await allowed('member uploads own photo',()=>setDoc(doc(b.db,photoPath),photo));
  await allowed('group member reads avatar',()=>getDoc(doc(a.db,photoPath)));
  await allowed('app avatar collection query',()=>getDocs(collection(a.db,`groups/${groupID}/memberPhotos`)));
  await denied('outsider reads profile photo',()=>getDoc(doc(outsider.db,photoPath)));
  await denied('unauthenticated photo read',()=>getDoc(doc(guest.db,photoPath)));
  await denied('another member replaces photo',()=>setDoc(doc(a.db,photoPath),photo));
  await denied('another member deletes photo',()=>deleteDoc(doc(a.db,photoPath)));
  await denied('oversized photo create',()=>setDoc(doc(a.db,`groups/${groupID}/memberPhotos/${a.uid}`),{...photo,image:Bytes.fromUint8Array(new Uint8Array(65537))}));
  await denied('oversized photo update',()=>updateDoc(doc(b.db,photoPath),{image:Bytes.fromUint8Array(new Uint8Array(65537)),updatedAt:serverTimestamp()}));
  await denied('photo schema pollution',()=>updateDoc(doc(b.db,photoPath),{email:'private@example.com',updatedAt:serverTimestamp()}));
  await denied('photo timestamp tampering',()=>updateDoc(doc(b.db,photoPath),{updatedAt:Timestamp.fromMillis(0)}));
  await denied('photo wrong type',()=>updateDoc(doc(b.db,photoPath),{image:'not bytes',updatedAt:serverTimestamp()}));
  await allowed('owner updates own photo',()=>updateDoc(doc(b.db,photoPath),photo));
  await allowed('owner removes own photo',()=>deleteDoc(doc(b.db,photoPath)));
  await denied('spoofed invitation group name',()=>setDoc(doc(a.db,`invitations/${'f'.repeat(32)}`),{...invite,groupName:'Another group'}));
  await allowed('owner revokes invitation',()=>deleteDoc(doc(a.db,`invitations/${invitationID}`)));
  await denied('join with revoked invitation',()=>memberBatch(outsider,invitationID).commit());
  await allowed('owner erases main prayer text',()=>updateDoc(prayer,{body:'',deleted:true}));
  await denied('deleted thread child read',()=>getDocs(collection(b.db,prayerPath+'/updates')));
  await denied('orphan child write',()=>setDoc(doc(a.db,`groups/${groupID}/prayers/missing/updates/no`),{authorID:a.uid,body:'No parent',createdAt:serverTimestamp()}));
  await denied('revive deleted prayer',()=>updateDoc(prayer,{body:'Revived',deleted:false}));
  console.log(`PASS ${checks} live checks`);
} finally {
  for (const c of clients) {
    if(c.auth.currentUser) await deleteUser(c.auth.currentUser).catch(e=>console.error('Account cleanup failed',e.code));
    await terminate(c.db);
    await deleteApp(c.app);
  }
}
