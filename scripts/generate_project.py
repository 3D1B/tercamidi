#!/usr/bin/env python3
"""Generate the checked-in Xcode project using only Python's standard library."""
from pathlib import Path
import hashlib,json,plistlib
root=Path(__file__).resolve().parents[1]
objects={}
def uid(name):return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def obj(identity,isa,**kwargs):
 key=uid(identity);objects[key]={'isa':isa,**kwargs};return key
def ref(path,typ,tree='<group>',name=None):
 kw={'lastKnownFileType':typ,'path':path,'sourceTree':tree}
 if name:kw['name']=name
 return obj('file:'+path, 'PBXFileReference',**kw)
def group(name,children,path=None,isa='PBXGroup'):
 kw={'children':children,'sourceTree':'<group>'}
 if path:kw['path']=path
 else:kw['name']=name
 return obj('group:'+name,isa,**kw)
def build(name,**kw):return obj('build:'+name,'PBXBuildFile',**kw)
swift=[ref(p.name,'sourcecode.swift') for p in sorted((root/'App').glob('*.swift'))]
resources=[];localized=[]
for filename in ['Localizable.strings','InfoPlist.strings']:
 children=[ref(f'{lang}.lproj/{filename}','text.plist.strings',name=lang) for lang in ['en','de','sr']]
 variant=obj('variant:'+filename,'PBXVariantGroup',children=children,name=filename,sourceTree='<group>')
 localized.append(variant);resources.append(build(filename,fileRef=variant))
assets=ref('Assets.xcassets','folder.assetcatalog');resources.append(build('assets',fileRef=assets))
info=ref('Info.plist','text.plist.xml')
appgroup=group('App',swift+localized+[assets,info],path='App')
product=obj('product','PBXFileReference',explicitFileType='wrapper.application',includeInIndex=0,path='OpenHarmony.app',sourceTree='BUILT_PRODUCTS_DIR')
products=group('Products',[product])
coregroup=group('Core',[],path='Core')
main=group('Root',[appgroup,products])
package=obj('core-package','XCLocalSwiftPackageReference',relativePath='Core')
dep=obj('core-product','XCSwiftPackageProductDependency',package=package,productName='HarmonyCore')
sourcephase=obj('sources','PBXSourcesBuildPhase',buildActionMask=2147483647,files=[build('source:'+r,fileRef=r) for r in swift],runOnlyForDeploymentPostprocessing=0)
resourcephase=obj('resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=resources,runOnlyForDeploymentPostprocessing=0)
frameworkphase=obj('frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[build('core',productRef=dep)],runOnlyForDeploymentPostprocessing=0)
def configs(name,base):
 ids=[]
 for config in ['Debug','Release']:
  values=dict(base)
  if config=='Debug':values.update(SWIFT_OPTIMIZATION_LEVEL='-Onone',SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG',DEBUG_INFORMATION_FORMAT='dwarf')
  else:values.update(SWIFT_COMPILATION_MODE='wholemodule',DEBUG_INFORMATION_FORMAT='dwarf-with-dsym')
  ids.append(obj(name+config,'XCBuildConfiguration',buildSettings=values,name=config))
 return obj('configs:'+name,'XCConfigurationList',buildConfigurations=ids,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
projectconfigs=configs('project',{'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'16.0','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','ENABLE_USER_SCRIPT_SANDBOXING':'YES'})
targetconfigs=configs('app',{'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'org.openharmony.ios','MARKETING_VERSION':'0.1.0','CURRENT_PROJECT_VERSION':'1','TARGETED_DEVICE_FAMILY':'1,2','CODE_SIGN_STYLE':'Automatic','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_FILE':'App/Info.plist','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','SWIFT_EMIT_LOC_STRINGS':'YES'})
target=obj('app-target','PBXNativeTarget',buildConfigurationList=targetconfigs,buildPhases=[sourcephase,frameworkphase,resourcephase],buildRules=[],dependencies=[],name='OpenHarmony',packageProductDependencies=[dep],productName='OpenHarmony',productReference=product,productType='com.apple.product-type.application')
project=obj('project','PBXProject',attributes={'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'1600','TargetAttributes':{target:{'CreatedOnToolsVersion':'16.0'}}},buildConfigurationList=projectconfigs,compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','de','sr','Base'],mainGroup=main,packageReferences=[package],productRefGroup=products,projectDirPath='',projectRoot='',targets=[target])
def encode(value,depth=0):
 indent='\t'*depth
 if isinstance(value,dict):return '{\n'+''.join('\t'*(depth+1)+json.dumps(str(k))+' = '+encode(v,depth+1)+';\n' for k,v in value.items())+indent+'}'
 if isinstance(value,list):return '(\n'+''.join('\t'*(depth+1)+encode(v,depth+1)+',\n' for v in value)+indent+')'
 if isinstance(value,int):return str(value)
 return json.dumps(value,ensure_ascii=False)
p=root/'OpenHarmony.xcodeproj';p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':project})+'\n')
info={'CFBundleDisplayName':'OpenHarmony','CFBundleDevelopmentRegion':'en','CFBundleLocalizations':['de','en','sr'],'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL','CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)','LSRequiresIPhoneOS':True,'NSBluetoothAlwaysUsageDescription':'Connect Bluetooth MIDI keyboards.','NSBluetoothPeripheralUsageDescription':'Connect Bluetooth MIDI keyboards.','UISupportedInterfaceOrientations':['UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'UIRequiresFullScreen':True,'UILaunchScreen':{}}
(root/'App/Info.plist').write_bytes(plistlib.dumps(info))
scheme=p/'xcshareddata/xcschemes';scheme.mkdir(parents=True,exist_ok=True)
(scheme/'OpenHarmony.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="OpenHarmony.app" BlueprintName="OpenHarmony" ReferencedContainer="container:OpenHarmony.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="OpenHarmony.app" BlueprintName="OpenHarmony" ReferencedContainer="container:OpenHarmony.xcodeproj"/></BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated',p.name)
