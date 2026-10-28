const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
for(const project of ['With','WithLive']){
 const p=path.join(root,project+'.xcodeproj/project.pbxproj');
 const json=JSON.parse(cp.execFileSync('/usr/bin/plutil',['-convert','json','-o','-',p],{encoding:'utf8'}));
 assert(json.objects[json.rootObject]);
 for(const [id,obj]of Object.entries(json.objects)){
  if(obj.isa==='PBXFileReference'&&obj.sourceTree==='SOURCE_ROOT')assert(fs.existsSync(path.join(root,obj.path)),obj.path+' is missing');
  for(const field of ['buildConfigurationList','productReference','fileRef','mainGroup','productRefGroup','target','containerPortal','productRef','package'])if(obj[field])assert(json.objects[obj[field]],id+' missing '+field);
  for(const field of ['buildPhases','dependencies','children','targets','files','buildConfigurations','packageReferences','packageProductDependencies'])for(const ref of obj[field]||[])assert(json.objects[ref],id+' missing reference '+ref);
 }
 const packages=Object.values(json.objects).filter(x=>x.isa==='XCRemoteSwiftPackageReference');
 assert.equal(packages.length,project==='With'?0:1);
 const scheme=project==='With'?'WithDemo':'WithLive';assert(fs.existsSync(path.join(root,project+'.xcodeproj/xcshareddata/xcschemes/'+scheme+'.xcscheme')));
}
console.log('Both projects: all source paths, object references, shared schemes, and package separation verified.');
