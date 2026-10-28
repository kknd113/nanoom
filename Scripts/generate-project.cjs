// Uses only Node's standard library. Run after changing source files or asset catalogs.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const uid = key => crypto.createHash('sha1').update(key).digest('hex').slice(0, 24).toUpperCase();
function walk(dir) { return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(dir,e.name)) : [path.join(dir,e.name)]); }
const swiftFiles = walk(path.join(root,'Sources')).filter(f=>f.endsWith('.swift')).map(f=>path.relative(root,f));
function serialize(value, level=0) {
  if(Array.isArray(value)) return '(\n'+value.map(v=>'\t'.repeat(level+1)+serialize(v,level+1)+',').join('\n')+'\n'+'\t'.repeat(level)+')';
  if(value && typeof value==='object') return '{\n'+Object.entries(value).map(([k,v])=>'\t'.repeat(level+1)+JSON.stringify(k)+' = '+serialize(v,level+1)+';').join('\n')+'\n'+'\t'.repeat(level)+'}';
  return JSON.stringify(String(value));
}
function project(live) {
 const objects={};
 const add=(key,object)=>{const id=uid(key);objects[id]=object;return id;};
 const projectID=uid('project'), targetID=uid('app-target'), testTargetID=uid('test-target');
 const sourceRefs=swiftFiles.map(file=>add('ref:'+file,{isa:'PBXFileReference',lastKnownFileType:'sourcecode.swift',path:file,sourceTree:'SOURCE_ROOT'}));
 const sourceBuilds=sourceRefs.map(ref=>add('build:'+ref,{isa:'PBXBuildFile',fileRef:ref}));
 const assetRef=add('assets',{isa:'PBXFileReference',lastKnownFileType:'folder.assetcatalog',path:'Sources/Assets.xcassets',sourceTree:'SOURCE_ROOT'});
 const assetBuild=add('assets-build',{isa:'PBXBuildFile',fileRef:assetRef});
 const infoRef=add('info',{isa:'PBXFileReference',lastKnownFileType:'text.plist.xml',path:'Configuration/Info.plist',sourceTree:'SOURCE_ROOT'});
 const appName=live?'WithLive':'WithDemo';
 const productRef=add('product',{isa:'PBXFileReference',explicitFileType:'wrapper.application',path:appName+'.app',sourceTree:'BUILT_PRODUCTS_DIR'});
 const sourcePhase=add('sources-phase',{isa:'PBXSourcesBuildPhase',buildActionMask:'2147483647',files:sourceBuilds,runOnlyForDeploymentPostprocessing:'0'});
 const resourcePhase=add('resources-phase',{isa:'PBXResourcesBuildPhase',buildActionMask:'2147483647',files:[assetBuild],runOnlyForDeploymentPostprocessing:'0'});
 const packageProducts=[],frameworkBuilds=[];let packages=[];
 if(live){
   const packageRef=add('firebase',{isa:'XCRemoteSwiftPackageReference',repositoryURL:'https://github.com/firebase/firebase-ios-sdk.git',requirement:{kind:'exactVersion',version:'13.1.1'}});
   packages=[packageRef];
   for(const name of ['FirebaseCore','FirebaseAuth','FirebaseFirestore']){
    const product=add('package:'+name,{isa:'XCSwiftPackageProductDependency',package:packageRef,productName:name});packageProducts.push(product);
    frameworkBuilds.push(add('link:'+name,{isa:'PBXBuildFile',productRef:product}));
   }
 }
 const frameworkPhase=add('frameworks-phase',{isa:'PBXFrameworksBuildPhase',buildActionMask:'2147483647',files:frameworkBuilds,runOnlyForDeploymentPostprocessing:'0'});
 function configList(key, settings) {
   const cs=['Debug','Release'].map(name=>add(key+name,{isa:'XCBuildConfiguration',name,buildSettings:{...settings,...(name==='Debug'?{SWIFT_OPTIMIZATION_LEVEL:'-Onone',DEBUG_INFORMATION_FORMAT:'dwarf',ENABLE_TESTABILITY:'YES'}:{SWIFT_OPTIMIZATION_LEVEL:'-O',DEBUG_INFORMATION_FORMAT:'dwarf-with-dsym'})}}));
   return add(key+'list',{isa:'XCConfigurationList',buildConfigurations:cs,defaultConfigurationIsVisible:'0',defaultConfigurationName:'Release'});
 }
 const shared={CLANG_ENABLE_MODULES:'YES',SDKROOT:'iphoneos',IPHONEOS_DEPLOYMENT_TARGET:'18.0',SWIFT_VERSION:'5.0',SWIFT_STRICT_CONCURRENCY:'targeted'};
 const projectConfig=configList('projectconfig',shared);
 const appConfig=configList('appconfig',{
  PRODUCT_NAME:appName,PRODUCT_MODULE_NAME:'With',PRODUCT_BUNDLE_IDENTIFIER:live?'com.example.with.live':'com.example.with.demo',
  CODE_SIGN_STYLE:'Automatic',DEVELOPMENT_TEAM:'',INFOPLIST_FILE:'Configuration/Info.plist',GENERATE_INFOPLIST_FILE:'NO',TARGETED_DEVICE_FAMILY:'1',
  ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME:'WithAccent',SWIFT_EMIT_LOC_STRINGS:'YES',ENABLE_PREVIEWS:'YES',
  LD_RUNPATH_SEARCH_PATHS:['$(inherited)','@executable_path/Frameworks'],
  ...(live?{SWIFT_ACTIVE_COMPILATION_CONDITIONS:'$(inherited) FIREBASE_ENABLED',CODE_SIGN_ENTITLEMENTS:'Configuration/WithLive.entitlements'}:{})
 });
 objects[targetID]={isa:'PBXNativeTarget',buildConfigurationList:appConfig,buildPhases:[sourcePhase,frameworkPhase,resourcePhase],buildRules:[],dependencies:[],name:appName,productName:appName,productReference:productRef,productType:'com.apple.product-type.application',packageProductDependencies:packageProducts};
 let targets=[targetID],products=[productRef],testRefs=[];
 if(!live){
  const testFile='Tests/DemoPrayerRepositoryTests.swift';const ref=add('testref',{isa:'PBXFileReference',lastKnownFileType:'sourcecode.swift',path:testFile,sourceTree:'SOURCE_ROOT'});testRefs=[ref];
  const build=add('testbuild',{isa:'PBXBuildFile',fileRef:ref});
  const testSource=add('testsources',{isa:'PBXSourcesBuildPhase',buildActionMask:'2147483647',files:[build],runOnlyForDeploymentPostprocessing:'0'});
  const testFramework=add('testframeworks',{isa:'PBXFrameworksBuildPhase',buildActionMask:'2147483647',files:[],runOnlyForDeploymentPostprocessing:'0'});
  const testProduct=add('testproduct',{isa:'PBXFileReference',explicitFileType:'wrapper.cfbundle',path:'WithTests.xctest',sourceTree:'BUILT_PRODUCTS_DIR'});products.push(testProduct);
  const proxy=add('proxy',{isa:'PBXContainerItemProxy',containerPortal:projectID,proxyType:'1',remoteGlobalIDString:targetID,remoteInfo:appName});
  const dependency=add('testdependency',{isa:'PBXTargetDependency',target:targetID,targetProxy:proxy});
  const config=configList('testconfig',{PRODUCT_NAME:'WithTests',PRODUCT_BUNDLE_IDENTIFIER:'com.example.with.tests',GENERATE_INFOPLIST_FILE:'YES',CODE_SIGN_STYLE:'Automatic',TARGETED_DEVICE_FAMILY:'1',BUNDLE_LOADER:'$(TEST_HOST)',TEST_HOST:'$(BUILT_PRODUCTS_DIR)/WithDemo.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/WithDemo',LD_RUNPATH_SEARCH_PATHS:['$(inherited)','@executable_path/Frameworks','@loader_path/Frameworks']});
  objects[testTargetID]={isa:'PBXNativeTarget',buildConfigurationList:config,buildPhases:[testSource,testFramework],buildRules:[],dependencies:[dependency],name:'WithTests',productName:'WithTests',productReference:testProduct,productType:'com.apple.product-type.bundle.unit-test'};targets.push(testTargetID);
 }
 const sources=add('sourcesgroup',{isa:'PBXGroup',children:sourceRefs,name:'Sources',sourceTree:'<group>'});
 const resources=add('resourcesgroup',{isa:'PBXGroup',children:[assetRef,infoRef],name:'Resources',sourceTree:'<group>'});
 const tests=add('testsgroup',{isa:'PBXGroup',children:testRefs,name:'Tests',sourceTree:'<group>'});
 const productsGroup=add('productsgroup',{isa:'PBXGroup',children:products,name:'Products',sourceTree:'<group>'});
 const main=add('maingroup',{isa:'PBXGroup',children:[sources,resources,tests,productsGroup],sourceTree:'<group>'});
 objects[projectID]={isa:'PBXProject',attributes:{LastUpgradeCheck:'2700',BuildIndependentTargetsInParallel:'YES',TargetAttributes:{[targetID]:{CreatedOnToolsVersion:'27.1',...(live?{SystemCapabilities:{'com.apple.SignInWithApple':{enabled:'1'}}}:{})}}},buildConfigurationList:projectConfig,compatibilityVersion:'Xcode 14.0',developmentRegion:'en',hasScannedForEncodings:'0',knownRegions:['en','Base'],mainGroup:main,productRefGroup:productsGroup,projectDirPath:'',projectRoot:'',targets,packageReferences:packages};
 const name=live?'WithLive':'With';const dir=path.join(root,name+'.xcodeproj');fs.mkdirSync(path.join(dir,'xcshareddata/xcschemes'),{recursive:true});
 fs.writeFileSync(path.join(dir,'project.pbxproj'),'// !$*UTF8*$!\n'+serialize({archiveVersion:'1',classes:{},objectVersion:'56',objects,rootObject:projectID})+'\n');
 const ref=`<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${targetID}" BuildableName="${appName}.app" BlueprintName="${appName}" ReferencedContainer="container:${name}.xcodeproj"/>`;
 const testable=live?'':`<TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${testTargetID}" BuildableName="WithTests.xctest" BlueprintName="WithTests" ReferencedContainer="container:${name}.xcodeproj"/></TestableReference>`;
 fs.writeFileSync(path.join(dir,'xcshareddata/xcschemes',appName+'.xcscheme'),`<?xml version="1.0" encoding="UTF-8"?><Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">${ref}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>${testable}</Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">${ref}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES"><BuildableProductRunnable runnableDebuggingMode="0">${ref}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>`);
}
const assets=path.join(root,'Sources/Assets.xcassets');fs.mkdirSync(assets,{recursive:true});fs.writeFileSync(path.join(assets,'Contents.json'),JSON.stringify({info:{author:'xcode',version:1}},null,2));
const colors={WithPaper:['fafbfc','141b26'],WithInk:['24354a','e9f0fa'],WithAccent:['4c6f9b','a7c6ed'],WithSoft:['eaf0f8','26354c']};
for(const [name,values]of Object.entries(colors)){
 const dir=path.join(assets,name+'.colorset');fs.mkdirSync(dir,{recursive:true});
 const rgb=hex=>({'color-space':'srgb',components:{red:String(parseInt(hex.slice(0,2),16)/255),green:String(parseInt(hex.slice(2,4),16)/255),blue:String(parseInt(hex.slice(4,6),16)/255),alpha:'1.000'}});
 fs.writeFileSync(path.join(dir,'Contents.json'),JSON.stringify({colors:[{idiom:'universal',color:rgb(values[0])},{idiom:'universal',appearances:[{appearance:'luminosity',value:'dark'}],color:rgb(values[1])}],info:{author:'xcode',version:1}},null,2));
}
project(false);project(true);console.log('Generated With.xcodeproj (no packages) and WithLive.xcodeproj (Firebase 13.1.1).');
