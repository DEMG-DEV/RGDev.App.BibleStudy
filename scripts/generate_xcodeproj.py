#!/usr/bin/env python3
"""
generate_xcodeproj.py
Generates a first-class native macOS Xcode project 'BibleStudy.xcodeproj'
Configured as an official macOS Application (.app bundle) with:
- CFBundleIdentifier = com.rgdev.BibleStudy
- SQLite3 linking
- Embedded resources (Bibles.sqlite)
- Modern SwiftUI App lifecycle
- Full compatibility with macOS 14+ / 15+ / Sonoma / Sequoia
"""

import os
import hashlib

def make_uuid(name):
    # Generates a reproducible 24-character hex PBX UUID
    h = hashlib.sha1(name.encode("utf-8")).hexdigest()
    return h[:24].upper()

def main():
    proj_dir = "BibleStudy.xcodeproj"
    os.makedirs(proj_dir, exist_ok=True)

    sources = [
        "BibleStudy/Sources/App/BibleStudyApp.swift",
        "BibleStudy/Sources/Models/BibleBook.swift",
        "BibleStudy/Sources/Models/BibleVerse.swift",
        "BibleStudy/Sources/Models/StudyNote.swift",
        "BibleStudy/Sources/Models/AppState.swift",
        "BibleStudy/Sources/Database/BibleDatabase.swift",
        "BibleStudy/Sources/Database/StudyNotesStore.swift",
        "BibleStudy/Sources/Database/AppleNotesBridge.swift",
        "BibleStudy/Sources/Views/MainView.swift",
        "BibleStudy/Sources/Views/SidebarView.swift",
        "BibleStudy/Sources/Views/ChapterPickerPopover.swift",
        "BibleStudy/Sources/Views/ParallelReaderView.swift",
        "BibleStudy/Sources/Views/RedLetterText.swift",
        "BibleStudy/Sources/Views/OmniboxSearchView.swift",
        "BibleStudy/Sources/Views/StudyNotesInspectorView.swift"
    ]

    resource_file = "BibleStudy/Sources/Resources/Bibles.sqlite"

    # UUIDs
    proj_uuid = make_uuid("PROJECT_BibleStudy")
    main_group_uuid = make_uuid("GROUP_Main")
    sources_group_uuid = make_uuid("GROUP_Sources")
    resources_group_uuid = make_uuid("GROUP_Resources")
    products_group_uuid = make_uuid("GROUP_Products")

    target_uuid = make_uuid("TARGET_BibleStudy")
    product_file_uuid = make_uuid("PRODUCT_BibleStudy_app")

    sources_build_phase_uuid = make_uuid("PHASE_Sources")
    resources_build_phase_uuid = make_uuid("PHASE_Resources")
    frameworks_build_phase_uuid = make_uuid("PHASE_Frameworks")

    config_list_proj_uuid = make_uuid("CONFIGLIST_Project")
    config_list_target_uuid = make_uuid("CONFIGLIST_Target")

    cfg_debug_proj_uuid = make_uuid("CONFIG_Debug_Project")
    cfg_release_proj_uuid = make_uuid("CONFIG_Release_Project")

    cfg_debug_target_uuid = make_uuid("CONFIG_Debug_Target")
    cfg_release_target_uuid = make_uuid("CONFIG_Release_Target")

    # File references
    source_file_refs = {}
    source_build_refs = {}
    for s in sources:
        fname = os.path.basename(s)
        f_uuid = make_uuid(f"FILE_REF_{s}")
        b_uuid = make_uuid(f"BUILD_REF_{s}")
        source_file_refs[s] = (f_uuid, fname)
        source_build_refs[s] = b_uuid

    res_f_uuid = make_uuid(f"FILE_REF_{resource_file}")
    res_b_uuid = make_uuid(f"BUILD_REF_{resource_file}")

    pbx = []
    pbx.append("// !$*UTF8*$!")
    pbx.append("{")
    pbx.append("\tarchiveVersion = 1;")
    pbx.append("\tclasses = {")
    pbx.append("\t};")
    pbx.append("\tobjectVersion = 56;")
    pbx.append("\tobjects = {")

    # PBXBuildFile
    pbx.append("/* Begin PBXBuildFile section */")
    for s, b_uuid in source_build_refs.items():
        f_uuid, fname = source_file_refs[s]
        pbx.append(f"\t\t{b_uuid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_uuid} /* {fname} */; }};")
    pbx.append(f"\t\t{res_b_uuid} /* Bibles.sqlite in Resources */ = {{isa = PBXBuildFile; fileRef = {res_f_uuid} /* Bibles.sqlite */; }};")
    pbx.append("/* End PBXBuildFile section */\n")

    # PBXFileReference
    pbx.append("/* Begin PBXFileReference section */")
    pbx.append(f"\t\t{product_file_uuid} /* BibleStudy.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BibleStudy.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for s, (f_uuid, fname) in source_file_refs.items():
        pbx.append(f"\t\t{f_uuid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{s}\"; sourceTree = \"<group>\"; }};")
    pbx.append(f"\t\t{res_f_uuid} /* Bibles.sqlite */ = {{isa = PBXFileReference; lastKnownFileType = file; path = \"{resource_file}\"; sourceTree = \"<group>\"; }};")
    pbx.append("/* End PBXFileReference section */\n")

    # PBXFrameworksBuildPhase
    pbx.append("/* Begin PBXFrameworksBuildPhase section */")
    pbx.append(f"\t\t{frameworks_build_phase_uuid} /* Frameworks */ = {{")
    pbx.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXFrameworksBuildPhase section */\n")

    # PBXGroup
    pbx.append("/* Begin PBXGroup section */")
    # Main group
    pbx.append(f"\t\t{main_group_uuid} = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{sources_group_uuid} /* Sources */,")
    pbx.append(f"\t\t\t\t{resources_group_uuid} /* Resources */,")
    pbx.append(f"\t\t\t\t{products_group_uuid} /* Products */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    # Sources group
    pbx.append(f"\t\t{sources_group_uuid} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for s, (f_uuid, fname) in source_file_refs.items():
        pbx.append(f"\t\t\t\t{f_uuid} /* {fname} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = Sources;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    # Resources group
    pbx.append(f"\t\t{resources_group_uuid} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{res_f_uuid} /* Bibles.sqlite */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = Resources;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    # Products group
    pbx.append(f"\t\t{products_group_uuid} /* Products */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{product_file_uuid} /* BibleStudy.app */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = Products;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")
    pbx.append("/* End PBXGroup section */\n")

    # PBXNativeTarget
    pbx.append("/* Begin PBXNativeTarget section */")
    pbx.append(f"\t\t{target_uuid} /* BibleStudy */ = {{")
    pbx.append("\t\t\tisa = PBXNativeTarget;")
    pbx.append(f"\t\t\tbuildConfigurationList = {config_list_target_uuid} /* Build configuration list for PBXNativeTarget \"BibleStudy\" */;")
    pbx.append("\t\t\tbuildPhases = (")
    pbx.append(f"\t\t\t\t{sources_build_phase_uuid} /* Sources */,")
    pbx.append(f"\t\t\t\t{frameworks_build_phase_uuid} /* Frameworks */,")
    pbx.append(f"\t\t\t\t{resources_build_phase_uuid} /* Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tbuildRules = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdependencies = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = BibleStudy;")
    pbx.append("\t\t\tproductName = BibleStudy;")
    pbx.append(f"\t\t\tproductReference = {product_file_uuid} /* BibleStudy.app */;")
    pbx.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    pbx.append("\t\t};")
    pbx.append("/* End PBXNativeTarget section */\n")

    # PBXProject
    pbx.append("/* Begin PBXProject section */")
    pbx.append(f"\t\t{proj_uuid} /* Project object */ = {{")
    pbx.append("\t\t\tisa = PBXProject;")
    pbx.append("\t\t\tattributes = {")
    pbx.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    pbx.append("\t\t\t\tLastUpgradeCheck = 1600;")
    pbx.append("\t\t\t};")
    pbx.append(f"\t\t\tbuildConfigurationList = {config_list_proj_uuid} /* Build configuration list for PBXProject \"BibleStudy\" */;")
    pbx.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    pbx.append("\t\t\tdevelopmentRegion = es;")
    pbx.append("\t\t\thasScannedForEncodings = 0;")
    pbx.append("\t\t\tknownRegions = (")
    pbx.append("\t\t\t\tes,")
    pbx.append("\t\t\t\tBase,")
    pbx.append("\t\t\t);")
    pbx.append(f"\t\t\tmainGroup = {main_group_uuid};")
    pbx.append(f"\t\t\tproductRefGroup = {products_group_uuid} /* Products */;")
    pbx.append("\t\t\tprojectDirPath = \"\";")
    pbx.append("\t\t\tprojectRoot = \"\";")
    pbx.append("\t\t\ttargets = (")
    pbx.append(f"\t\t\t\t{target_uuid} /* BibleStudy */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t};")
    pbx.append("/* End PBXProject section */\n")

    # PBXResourcesBuildPhase
    pbx.append("/* Begin PBXResourcesBuildPhase section */")
    pbx.append(f"\t\t{resources_build_phase_uuid} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append(f"\t\t\t\t{res_b_uuid} /* Bibles.sqlite in Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXResourcesBuildPhase section */\n")

    # PBXSourcesBuildPhase
    pbx.append("/* Begin PBXSourcesBuildPhase section */")
    pbx.append(f"\t\t{sources_build_phase_uuid} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for s, b_uuid in source_build_refs.items():
        fname = os.path.basename(s)
        pbx.append(f"\t\t\t\t{b_uuid} /* {fname} in Sources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXSourcesBuildPhase section */\n")

    # XCBuildConfiguration
    pbx.append("/* Begin XCBuildConfiguration section */")
    # Project configs
    pbx.append(f"\t\t{cfg_debug_proj_uuid} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    pbx.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    pbx.append("\t\t\t\tENABLE_TESTABILITY = YES;")
    pbx.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    pbx.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    pbx.append("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;")
    pbx.append("\t\t\t\tSDKROOT = macosx;")
    pbx.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{cfg_release_proj_uuid} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    pbx.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    pbx.append("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    pbx.append("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;")
    pbx.append("\t\t\t\tSDKROOT = macosx;")
    pbx.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")

    # Target configs
    pbx.append(f"\t\t{cfg_debug_target_uuid} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append("\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
    pbx.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    pbx.append("\t\t\t\tENABLE_HARDENED_RUNTIME = YES;")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = \"BibleStudy\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.reference\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = \"Copyright © 2026 RGDev. All rights reserved.\";")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/../Frameworks\";")
    pbx.append("\t\t\t\tMARKETING_VERSION = 1.0;")
    pbx.append("\t\t\t\tOTHER_LDFLAGS = (\"$(inherited)\", \"-lsqlite3\");")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.rgdev.BibleStudy;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{cfg_release_target_uuid} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append("\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
    pbx.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    pbx.append("\t\t\t\tENABLE_HARDENED_RUNTIME = YES;")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = \"BibleStudy\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.reference\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = \"Copyright © 2026 RGDev. All rights reserved.\";")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/../Frameworks\";")
    pbx.append("\t\t\t\tMARKETING_VERSION = 1.0;")
    pbx.append("\t\t\t\tOTHER_LDFLAGS = (\"$(inherited)\", \"-lsqlite3\");")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.rgdev.BibleStudy;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCBuildConfiguration section */\n")

    # XCConfigurationList
    pbx.append("/* Begin XCConfigurationList section */")
    pbx.append(f"\t\t{config_list_proj_uuid} /* Build configuration list for PBXProject \"BibleStudy\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{cfg_debug_proj_uuid} /* Debug */,")
    pbx.append(f"\t\t\t\t{cfg_release_proj_uuid} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Release;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{config_list_target_uuid} /* Build configuration list for PBXNativeTarget \"BibleStudy\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{cfg_debug_target_uuid} /* Debug */,")
    pbx.append(f"\t\t\t\t{cfg_release_target_uuid} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCConfigurationList section */\n")

    pbx.append("\t};")
    pbx.append(f"\trootObject = {proj_uuid} /* Project object */;")
    pbx.append("}")

    pbx_path = os.path.join(proj_dir, "project.pbxproj")
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write("\n".join(pbx) + "\n")

    print(f"Generated {pbx_path} successfully.")

if __name__ == "__main__":
    main()
