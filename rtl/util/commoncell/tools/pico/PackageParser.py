#!/usr/bin/python3

from distutils.log import error, fatal
from pathlib import Path
from sys import argv
import yaml


class Module:
    def __init__(self, root: Path, moduleMeta: dict) -> None:
        self.rtlPathList = []
        self.simPathList = []
        self.dependModuleList = []
        if moduleMeta.get("dependency"):
            for m in moduleMeta["dependency"]:
                self.dependModuleList.append(m)
        if moduleMeta.get("rtl"):
            for m in moduleMeta["rtl"]:
                self.rtlPathList.append(Path(root) / m)
        if moduleMeta.get("sim"):
            for m in moduleMeta["sim"]:
                self.simPathList.append(Path(root) / m)
        try:
            self.name = moduleMeta["name"]
            self.description = moduleMeta["description"]
            self.language = moduleMeta["language"]
        except yaml.YAMLError as e:
            error(e)


class PackageParser:
    def __init__(self, manifestPath: str):
        with open(manifestPath) as f:
            self.packageLocation = Path(manifestPath)
            ROOT = self.packageLocation.parent
            manifest = yaml.load(f, yaml.CLoader)
            self.dependPackageDict = {}
            self.ModuleDict = {}
            if manifest.get("Dependency"):
                for packagePath in manifest["Dependency"]:
                    filePath = Path(ROOT / packagePath)
                    package = PackageParser(filePath)
                    if not self.dependPackageDict.get(package.Name):
                        self.dependPackageDict[package.Name] = package
                        for (key, value) in package.ModuleDict.items():
                            if not self.ModuleDict.get(key):
                                self.ModuleDict[key] = value
            if manifest.get("Module"):
                for module in manifest["Module"]:
                    self.addModule(ROOT, module)
            try:
                self.Name = manifest["Name"]
                self.addModule(ROOT, self.packModule())
            except yaml.YAMLError as e:
                error(e)

    def packModule(self):
        packedModule = {}
        packedModule['name'] = self.Name
        packedModule['language'] = None
        packedModule['description'] = "package {}".format(self.Name)
        packedModule['dependency'] = []
        for module in self.ModuleDict:
            packedModule['dependency'].append(module)
        return packedModule
        

    def addModule(self, root: Path, moduleMeta: dict) -> None:
        self.ModuleDict[moduleMeta["name"]] = Module(root, moduleMeta)
        if moduleMeta.get("sim"):
            self.ModuleDict[moduleMeta["name"]+'_tb'] = Module(root, moduleMeta)

    def genModuleFileList(self, top: str, sim: bool):
        if self.ModuleDict.get(top):
            module = self.ModuleDict[top]
            filelist = []
            for dependModule in module.dependModuleList:
                for file in self.genModuleFileList(dependModule, False):
                    if file not in filelist:
                        filelist.append(file)
            for file in module.rtlPathList:
                absPath = str(file.absolute())
                if absPath not in filelist:
                    filelist.append((absPath,module.language))
            if sim:
                for file in module.simPathList:
                    absPath = str(file.absolute())
                    if absPath not in filelist:
                        filelist.append((absPath,module.language))
            return filelist
        else:
            fatal("Module {} doesn't exist".format(top))

    def genPackageFileList(self, sim: bool):
        filelist = []
        for module in self.ModuleDict:
            for file in self.genModuleFileList(module, sim):
                if file not in filelist :
                    filelist.append(file)
        return filelist
    
    def genVcsFileList(self, sim: bool):
        filelist = self.genPackageFileList(sim)
        vcsfilelist = []
        for file in filelist:
            vcsfilelist.append(file[0])
        return vcsfilelist
    
    def genEDAlizeFile(self,top: str, sim: bool):
        edalizeFileList = []
        filelist = self.genModuleFileList(top,sim)
        for (filePath,language) in filelist:
            if language == "SystemVerilog" : 
                edalizeFileList.append(
                    {'name' : filePath, 'file_type' : 'systemVerilogSource'}
                )
            elif language == "Verilog" :
                edalizeFileList.append(
                    {'name' : filePath, 'file_type' : 'verilogSource'}
                )
            elif language == "Vhdl":
                edalizeFileList.append(
                    {'name' : filePath, 'file_type' : 'vhdlSource'}
                )
        return edalizeFileList
            


if __name__ == "__main__":
    t = PackageParser(argv[1])
    for file in t.genVcsFileList(False):
        print(file)
