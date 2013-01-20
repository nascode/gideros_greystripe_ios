Greystripe iOS Plugin for Gideros
=======================

Greystripe iOS plugin for Gideros

Greystripe
------------
1. Add `greystripe.mm` to your XCode project
2. Download latest Greystripe SDK (this plugin is tested on version 4.1)
3. Add Greystripe iOSSDK4.1 folder to your XCode project
4. Add frameworks: 
 * AdSupport (set it to optional)
 * AddressBook
 * EventKit
 * MessageUI
 * MobileCoreService
 * SystemConfiguration
5. On XCode project property select Build Setting tab and find `Other Linker Flags` entry, then add `-all_load` and `-ObjC` flags

Usage
-----
After plugin installation, look at example project

Final Note
----------
This plugin has been tested on Gideros 2012.09.6 exported Xcodde project and XCode 4.5.2

The lua API is compatible with [Greystripe Android Plugin for Gideros](https://github.com/zaniar/gideros_greystripe)
