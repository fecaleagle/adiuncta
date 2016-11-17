#import <objc/runtime.h>

@interface SPSearchResult : NSObject
@property (nonatomic,retain) NSString * bundleID;
@property (assign,nonatomic) long long description_maxlines;
@property (nonatomic,retain) NSString * resultDescription;
@property (nonatomic,retain) NSString * type;
@property (nonatomic,retain) NSString * url;
- (NSString *)bundleID; 
- (NSString *)title;
- (void)setBundleID:(NSString *)arg1;
- (void)setHasAssociatedUserActivity:(BOOL)arg1;
- (void)setHasNumberOfSummaryLines:(BOOL)arg1;
- (void)setNumberOfSummaryLines:(unsigned)arg1;
- (void)setSummary:(id)arg1;
- (void)setSearchResultDomain:(unsigned)arg1;
- (void)setTitle:(NSString *)arg1;
- (void)setUserActivityEligibleForPublicIndexing:(BOOL)arg1;
- (void)setUrl:(NSString *)arg1;
@end

@interface SPSearchResultSection
@property (nonatomic, retain) NSString *displayIdentifier;
@property (nonatomic) unsigned int domain;
@property (nonatomic, retain) NSString *category;
// utilized methods
- (void)addResults:(SPSearchResult *)arg1;
- (unsigned long long)resultsCount;
- (void)setCategory:(NSString *)arg1;
- (void)setDisplayIdentifier:(NSString *)arg1;
- (void)setDomain:(unsigned)arg1;
@end

@interface SPUISearchModel
// hooked methods
- (void)addSections:(id)arg1 ;
- (id)cachedImageForResult:(id)arg1 inSection:(id)arg2;
// utilized methods
- (void)cacheImage:(id)arg1 forResult:(id)arg2 inSection:(id)arg3;
- (NSString *)queryString;
- (SPSearchResultSection*)sectionAtIndex:(unsigned int)arg1;
// new methods
- (NSMutableArray *)updateSectionsWithSections:(NSMutableArray *)arg1;

@end

static NSDictionary *labels;
static int           scale = 1;
static NSString     *device = @"~iphone";
static NSString     *settingsIconPath;
static NSString     *spotlightIconMask;

static void loadBundles() {
    // if labels is allocated, release it
    if ( labels ) {
        [labels release];
        labels = nil;
    }
    
    NSString *scaleFactor = scale > 1 ? [NSString stringWithFormat:@"@%dx", scale] : @"";
    
    settingsIconPath = [[[NSString alloc] initWithFormat:@"/Applications/Preferences.app/AppIcon60x60%@.png", scaleFactor] retain];

    NSString *tweakRoot = @"prefs:root=%@";
    
    // check for PreferenceOrganizer2
    if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer2.dylib"] ) {
        //NSLog(@"Adiuncta: PreferenceOrganizer2 is installed");
        tweakRoot = @"prefs:root=Tweaks&path=%@";
    }
    //NSLog(@"Adiuncta: tweakRoot = %@", tweakRoot);
    
    // check for Anemone
    if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Anemone.dylib"] ) {
        //NSLog(@"Adiuncta: Anemone is installed");
        if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/User/Library/Preferences/com.anemoneteam.anemone.plist"] ) {
            NSDictionary *themes = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.anemoneteam.anemone.plist"];
            
            for (NSString *key in themes) {
                //NSLog(@"Adiuncta: %@", key);
                if ( [[[themes objectForKey:key] objectForKey:@"Enabled"] boolValue] ) {
                    // phew, found the perfect icon! that was easy...
                    if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/com.apple.Preferences%@.png", key, scaleFactor]] ) {
                        [settingsIconPath release];
                        settingsIconPath = nil;
                        settingsIconPath = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/IconBundles/com.apple.Preferences%@.png", key, scaleFactor] retain];
                    // take the large icon and get the hell out
                    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/com.apple.Preferences-large.png", key]] ) {
                        [settingsIconPath release];
                        settingsIconPath = nil;
                        settingsIconPath = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/IconBundles/com.apple.Preferences-large.png", key] retain];
                    // else if we've got the appropriate directory to enumerate...
                    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles", key]] ) {
                        // enumerate all files and folders under IconBundles for the given theme.
                        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/IconBundles/", key]];
                        // declare some objects to be used in the enumeration loop
                        NSString *iconFile;
                        NSMutableArray *candidates = [[NSMutableArray alloc] init];
                        
                        // while we have another file to check...
                        while ( (iconFile = [enumerator nextObject]) ) {
                            NSLog(@"Adiuncta: looping for icon in key %@", key);
                            // if we've got a potential icon for settings, add it to the candidates array
                            if ( [iconFile hasPrefix:@"com.apple.Preferences"] ) {
                                [candidates addObject:iconFile];
                            }
                        }
                        
                        // if we've got a candidate, or god-forbid more than one...
                        if ( [candidates count] > 0 ) {
                            // if we've got multiple candidates, let's try to find the best one
                            if ( [candidates count] > 1 ) {
                                BOOL foundIcon = NO;
                                NSString *goodCandidate = nil;
                                
                                for ( NSString *candidate in candidates ) {
                                    // if we've got one that matches scaleFactor, use it
                                    if ( [candidate containsString:scaleFactor] ) {
                                        foundIcon = YES;
                                    // or if we've got one that matches "large", consider it a good candidate
                                    } else if ( [candidate containsString:@"large"] ) {
                                        goodCandidate = [NSString stringWithString:candidate];
                                    }
                                    
                                    // if we found something better than a random guess, use it
                                    if ( foundIcon ) {
                                        [settingsIconPath release];
                                        settingsIconPath = nil;
                                        settingsIconPath = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@", key, candidate] retain];
                                        // bug out of this abomination.
                                        break;
                                    }
                                }
                                
                                // if we didn't find the exact icon in the array, check if we found a good one, and if not, then just use the first one in the candidates array
                                if ( !foundIcon ) {
                                    [settingsIconPath release];
                                    settingsIconPath = nil;
                                    if ( goodCandidate ) {
                                        settingsIconPath = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@", key, goodCandidate] retain];
                                    } else {
                                        settingsIconPath = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@", key, [candidates objectAtIndex:0]] retain];
                                    }
                                }
                            // thankfully, we just have one candidate, so use it
                            } else {
                                [settingsIconPath release];
                                settingsIconPath = nil;
                                settingsIconPath = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/IconBundles/%@", key, [candidates objectAtIndex:0]] retain];
                            }
                        }
                        
                        // release candidates
                        [candidates release];
                        candidates = nil;
                    }
                    
                    // phew, found a perfect mask! that was easy...
                    if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png", key, scaleFactor, device]] ) {
                        if ( spotlightIconMask ) {
                            [spotlightIconMask release];
                            spotlightIconMask = nil;
                        }
                        spotlightIconMask = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@%@.png", key, scaleFactor, device] retain];
                    // take the iphone mask and get the hell out
                    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@~iphone.png", key, scaleFactor]] ) {
                        if ( spotlightIconMask ) {
                            [spotlightIconMask release];
                            spotlightIconMask = nil;
                        }
                        spotlightIconMask = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/AppIconMask%@~iphone.png", key, scaleFactor] retain];
                    // else if we've got the appropriate directory to enumerate...
                    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework", key]] ) {
                        // enumerate all files and folders under IconBundles for the given theme.
                        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[NSString stringWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework", key]];
                        // declare some objects to be used in the enumeration loop
                        NSString *maskFile;
                        NSMutableArray *candidates = [[NSMutableArray alloc] init];
                        
                        // while we have another file to check...
                        while ( (maskFile = [enumerator nextObject]) ) {
                            NSLog(@"Adiuncta: looping for mask in key %@", key);
                            // if we've got a potential mask for use in Spotlight, add it to the candidates array
                            if ( [maskFile hasPrefix:@"AppIconMask"] ) {
                                [candidates addObject:maskFile];
                            }
                        }
                        
                        // if we've got a candidate, or god-forbid more than one...
                        if ( [candidates count] > 0 ) {
                            // if we've got multiple candidates, let's try to find the best one
                            if ( [candidates count] > 1 ) {
                                BOOL foundIcon = NO;
                                NSString *goodCandidate = nil;
                                
                                for ( NSString *candidate in candidates ) {
                                    // if we've got one that matches scaleFactor, use it
                                    if ( [candidate containsString:scaleFactor] && [candidate containsString:device] ) {
                                        foundIcon = YES;
                                    // or if we've got one that matches the scaleFactor at least, hold onto it.
                                    } else if ( [candidate containsString:scaleFactor] ) {
                                        goodCandidate = [NSString stringWithString:candidate];
                                    }
                                    
                                    // if we found the ideal candidate, use it
                                    if ( foundIcon ) {
                                        if ( spotlightIconMask ) {
                                            [spotlightIconMask release];
                                            spotlightIconMask = nil;
                                        }
                                        spotlightIconMask = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/%@", key, candidate] retain];
                                        // bug out of this abomination.
                                        break;
                                    }
                                }
                                
                                // if we didn't find the exact mask in the array, check if we found a good one, and if not, then just use the first one in the candidates array
                                if ( !foundIcon ) {
                                    if ( spotlightIconMask ) {
                                        [spotlightIconMask release];
                                        spotlightIconMask = nil;
                                    }
                                    
                                    if ( goodCandidate ) {
                                        spotlightIconMask = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/%@", key, goodCandidate] retain];
                                    } else {
                                        spotlightIconMask = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/%@", key, [candidates objectAtIndex:0]] retain];
                                    }
                                }
                            // thankfully, we just have one candidate, so use it
                            } else {
                                if ( spotlightIconMask ) {
                                    [spotlightIconMask release];
                                    spotlightIconMask = nil;
                                }
                                spotlightIconMask = [[[NSString alloc] initWithFormat:@"/Library/Themes/%@.theme/Bundles/com.apple.mobileicons.framework/%@", key, [candidates objectAtIndex:0]] retain];
                            }
                        }
                        
                        // release candidates
                        [candidates release];
                        candidates = nil;
                    }
                }
            }
        }
    }
    
    // enumerate all files and folders under PreferenceLoader
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:@"/Library/PreferenceLoader/Preferences/"];
    
    // declare some objects to be used in the enumeration loop
    NSString *plistFile;
    NSDictionary *plistContent;
    NSDictionary *plistEntry;
    NSDictionary *resultWithIcon;
    SPSearchResult *searchResult;
    NSString *label;
    NSString *icon;
    NSString *iconPath;
    NSString *iconExtension;
    
    // create temporary mutable dictionary
    NSMutableDictionary *labelsMutable = [[NSMutableDictionary alloc] init];
    
    // while we have another file to check...
    while ( (plistFile = [enumerator nextObject]) ) {
        // if we've got a .plist
        if ( [[plistFile pathExtension] isEqualToString: @"plist"] ) {
            // load the content and get the "entry" key
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", plistFile]];
            plistEntry = [plistContent objectForKey:@"entry"];
            
            // get label and icon
            label = [plistEntry objectForKey:@"label"];
            icon = [plistEntry objectForKey:@"icon"];
            
            // if we don't have a full path, then we need to find the icon relative to the bundle
            if ( ![icon hasPrefix:@"/"] ) {
                // if we have a bundle, find the icon relative to the bundle
                if ( [plistEntry objectForKey:@"bundle"] ) {
                    icon = [NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/%@", [plistEntry objectForKey:@"bundle"], icon];
                // else, get the icon from under PreferenceLoader
                } else {
                    // if the icon exists in a folder under Preferences, extract it from the plist path
                    if ( [[plistFile pathComponents] count] > 1 ) {
                        icon = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@/%@", [[plistFile pathComponents] objectAtIndex:0], icon];
                    // otherwise, just get it out of the Preferences root
                    } else {
                        icon = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", icon];
                    }
                }
            }
            
            // get the full icon path without the extension
            iconPath = [icon stringByDeletingPathExtension];
            // get the icon extension
            iconExtension = [icon pathExtension];
            
            searchResult = [[objc_getClass("SPSearchResult") alloc] init];
            
            // bundle identifier (for cache icon lookup)
            [searchResult setBundleID:label];  
            // title
            [searchResult setTitle:label];          
            // important – sync with section domain
            [searchResult setSearchResultDomain:19];
            // important - set URL of preference panel
            //[searchResult setUrl:[NSString stringWithFormat:@"%@=%@", tweakRoot, [label stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            [searchResult setUrl:[NSString stringWithFormat:tweakRoot, [label stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            // not important - use later to check result type
            searchResult.type = @"Settings";
            // recommended – user activity / indexing
            [searchResult setHasAssociatedUserActivity:NO];
            [searchResult setUserActivityEligibleForPublicIndexing:NO];
            
            // first, look for an icon that matches the scale factor
            if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@%@.%@", iconPath, scaleFactor, iconExtension]] ) {
                resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", [NSString stringWithFormat:@"%@%@.%@", iconPath, scaleFactor, iconExtension], @"icon", nil];
                [labelsMutable setObject:resultWithIcon forKey:label];
            // check for a 3x icon first - spotlight icons are bigger than bundle icons, so we always want the largest icon available
            } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@%@.%@", iconPath, @"@3x", iconExtension]] ) {
                resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", [NSString stringWithFormat:@"%@%@.%@", iconPath, @"@3x", iconExtension], @"icon", nil];
                [labelsMutable setObject:resultWithIcon forKey:label];
            // check for a 2x icon
            } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@%@.%@", iconPath, @"@2x", iconExtension]] ) {
                resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", [NSString stringWithFormat:@"%@%@.%@", iconPath, @"@2x", iconExtension], @"icon", nil];
                [labelsMutable setObject:resultWithIcon forKey:label];
            // check for the original icon
            } else {
                resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", [NSString stringWithFormat:@"%@.%@", iconPath, iconExtension], @"icon", nil];
                [labelsMutable setObject:resultWithIcon forKey:label];
            }
            
            // release searchResult
            [searchResult release];
            searchResult = nil;
            
            // release plistContent
            [plistContent release];
            plistContent = nil;
        }
    }
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *name = [[[locale displayNameForKey:NSLocaleIdentifier value:language] componentsSeparatedByString:@" "] objectAtIndex:0];
    //NSLog(@"Adiuncta: displayName = '%@'", name);
    language = [language stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    //NSLog(@"Adiuncta: language = '%@'", language);
    
    // release the locale
    [locale release];
    locale = nil;
    
    // don't know whether ipad has its own strings table, but try to use it
    if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings%@.strings", language, device]] ) {
        plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings%@.strings", language, device]];
    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings%@.strings", [language substringToIndex:2], device]] ) {
        plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings%@.strings", [language substringToIndex:2], device]];
    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings%@.strings", name, device]] ) {
        plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings%@.strings", name, device]];
    } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/English.lproj/Settings%@.strings", device]] ) {
        plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/English.lproj/Settings%@.strings", device]];
    }
    
    // should only conceivably get to this on an iPad... look for iphone strings
    if ( !plistContent ) {
        if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings~iphone.strings", language]] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings~iphone.strings", language]];
        } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings~iphone.strings", [language substringToIndex:2]]] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings~iphone.strings", [language substringToIndex:2]]];
        } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings~iphone.strings", name]] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings~iphone.strings", name]];
        } else if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/English.lproj/Settings~iphone.strings"] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/English.lproj/Settings~iphone.strings"];
        }
    }
    
    // iOS, you make me cry, try looking for generics.
    if ( !plistContent ) {
        if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings.strings", language]] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings.strings", language]];
        } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings.strings", [language substringToIndex:2]]] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings.strings", [language substringToIndex:2]]];
        } else if ( [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings.strings", name]] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/%@.lproj/Settings.strings", name]];
        } else if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/English.lproj/Settings.strings"] ) {
            plistContent = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/System/Library/PrivateFrameworks/PreferencesUI.framework/English.lproj/Settings.strings"];
        }
    }
    
    // if we were able to pull the plist info, add the stock bundles...
    if ( plistContent ) {   
        // Airplane Mode
        
        label = [plistContent objectForKey:@"Airplane Mode"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"AirplaneMode%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Wi-Fi
        
        label = [plistContent objectForKey:@"WIFI"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"WiFi%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=WIFI"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Bluetooth
        
        label = [plistContent objectForKey:@"BLUETOOTH"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"Bluetooth%@.png", scaleFactor]];

        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=Bluetooth"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Cellular
        
        label = [plistContent objectForKey:@"CELLULAR"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"CellularData%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=MOBILE_DATA_SETTINGS_ID"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Personal Hotspot
        
        label = [plistContent objectForKey:@"PERSONAL_HOTSPOT"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"PersonalHotspot%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=INTERNET_TETHERING"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Carrier
        
        label = [plistContent objectForKey:@"CARRIER"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"Carrier%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=Carrier"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Notifications
        
        label = [plistContent objectForKey:@"NOTIFICATIONS"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"NotificationCenter%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=NOTIFICATIONS_ID"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Control Center
        
        label = [plistContent objectForKey:@"CONTROLCENTER"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"ControlCenter%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=ControlCenter"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Do Not Disturb
        
        label = [plistContent objectForKey:@"DO_NOT_DISTURB"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"DND%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=DO_NOT_DISTURB"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // General
        
        label = [plistContent objectForKey:@"General"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"General%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=General"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Display & Brightness
        
        label = [plistContent objectForKey:@"Display"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"Display%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=DISPLAY"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Wallpaper
        
        label = [plistContent objectForKey:@"Wallpaper"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"Wallpaper%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=Wallpaper"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Sounds
        label = [plistContent objectForKey:@"Sounds"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"Sounds%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=Sounds"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Touch ID & Passcode
        
        label = [plistContent objectForKey:@"TOUCHID_PASSCODE"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"TouchID%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=TOUCHID_PASSCODE"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Battery
        
        label = [plistContent objectForKey:@"BATTERY_USAGE"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"BatteryUsage%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:@"BatteryID"];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=BATTERY_USAGE"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
        
        // Privacy
        
        label = [plistContent objectForKey:@"Privacy"];
        icon = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/Preferences.framework/%@", [NSString stringWithFormat:@"Privacy%@.png", scaleFactor]];
        
        searchResult = [[objc_getClass("SPSearchResult") alloc] init];
        // bundle identifier (for cache icon lookup)
        [searchResult setBundleID:label];  
        // title
        [searchResult setTitle:label];          
        // important – sync with section domain
        [searchResult setSearchResultDomain:19];
        // important - set URL of preference panel
        [searchResult setUrl:@"prefs:root=Privacy"];
        // not important - use later to check result type
        searchResult.type = @"Settings";
        // recommended – user activity / indexing
        [searchResult setHasAssociatedUserActivity:NO];
        [searchResult setUserActivityEligibleForPublicIndexing:NO];
        
        resultWithIcon = [NSDictionary dictionaryWithObjectsAndKeys:searchResult, @"result", icon, @"icon", nil];
        [labelsMutable setObject:resultWithIcon forKey:label];
        
        // release searchResult
        [searchResult release];
        searchResult = nil;
    }
    
    // retain a non-mutable copy
    labels = [[[NSDictionary alloc] initWithDictionary:labelsMutable] retain];
    
    // release the temporary mutable dictionary
    [labelsMutable release];
    labelsMutable = nil;
}

/*
static CGImageRef createMaskWithImage(CGImageRef image) {
    int maskWidth               = CGImageGetWidth(image);
    int maskHeight              = CGImageGetHeight(image);
    //  round bytesPerRow to the nearest 16 bytes, for performance's sake
    int bytesPerRow             = (maskWidth + 15) & 0xfffffff0;
    int bufferSize              = bytesPerRow * maskHeight;

    //  allocate memory for the bits 
    CFMutableDataRef dataBuffer = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CFDataSetLength(dataBuffer, bufferSize);

    //  the data will be 8 bits per pixel, no alpha
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef ctx            = CGBitmapContextCreate(CFDataGetMutableBytePtr(dataBuffer),
                                                        maskWidth, maskHeight,
                                                        8, bytesPerRow, colourSpace, kCGImageAlphaNone);
    //  drawing into this context will draw into the dataBuffer.
    CGContextDrawImage(ctx, CGRectMake(0, 0, maskWidth, maskHeight), image);
    CGContextRelease(ctx);

    //  now make a mask from the data.
    CGDataProviderRef dataProvider  = CGDataProviderCreateWithCFData(dataBuffer);
    CGImageRef mask                 = CGImageMaskCreate(maskWidth, maskHeight, 8, 8, bytesPerRow,
                                                        dataProvider, NULL, FALSE);

    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colourSpace);
    CFRelease(dataBuffer);

    return mask;
}
*/

static UIImage *createIcon(UIImage *icon, CGSize size) {
    // obtain the settings icon from the path obtained earlier
    UIImage *background = [UIImage imageWithContentsOfFile:settingsIconPath];
    
    // create an image context with the specified size, non-opaque, and device-scaled
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    // get the context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // anti-alias, because we're clipping and resizing
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    
    // if we've got an icon mask from anemone, use it (cry first)
    if ( spotlightIconMask ) {
        // we need to create the mask from the spotlightIconMask's CGImage
        CGImageRef maskRef = [[UIImage imageWithContentsOfFile:spotlightIconMask] CGImage];
        
        // coregraphics doesn't like anemone's icon masks, so we need to invert the alpha mask 
        CGFloat decode[] = { CGFloat(1), CGFloat(0),  // alpha (flipped)
                             CGFloat(0), CGFloat(1),  // red   (no change)
                             CGFloat(0), CGFloat(1),  // green (no change)
                             CGFloat(0), CGFloat(1)   // blue  (no change)
                           };
                             
        // now, we're going to create a mask using the properties of the original image, but we're going to use the custom decode array to flip the alpha channel
        CGImageRef mask    =  CGImageCreate(CGImageGetWidth(maskRef), CGImageGetHeight(maskRef), CGImageGetBitsPerComponent(maskRef), CGImageGetBitsPerPixel(maskRef), CGImageGetBytesPerRow(maskRef), CGImageGetColorSpace(maskRef), CGImageGetBitmapInfo(maskRef), CGImageGetDataProvider(maskRef), decode, CGImageGetShouldInterpolate(maskRef), CGImageGetRenderingIntent(maskRef));
        
        // clip the context using the mask
        CGContextClipToMask(context, CGRectMake(0, 0, size.width, size.height), mask);
        
        // release the mask
        CGImageRelease(mask);
    } else {       
        // re-round the corners with a UIBezierPath rounded rect to try to smooth out the edges
        CGContextAddPath(context, CGPathCreateCopy([UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(10.0f/57.0f * size.width, size.height)].CGPath));
        // clip the context with the added path
        CGContextClip(context);
    }
    
    // draw the fill color in a rectangle of the specified size
    //CGContextSetRGBFillColor(context, 255.0f/255.0f, 255.0f/255.0f, 255.0f/255.0f, 0.75f);
    //CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    
    // draw the settings icon in a rectangle of the specified size
    [background drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // draw the bundle icon in the corner of the rectangle of the specified size
    // considered masking the bundle icon as well, but I don't feel like it's worth the performance overhead
    [icon drawInRect:CGRectMake(size.width - icon.size.width - 1, size.height - icon.size.height - 1, icon.size.width, icon.size.height)];
    
    // get the new icon back from the current context
    UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();  
    // end the image context
    UIGraphicsEndImageContext();

    // return the new icon
    return newIcon;
}

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    if ( !labels || [labels count] == 0 ) {
        // register the bundles and identify the ssociated icons
        loadBundles();
    }
}

%end

%hook SPUISearchModel 

- (UIImage *)cachedImageForResult:(SPSearchResult *)result inSection:(id)section {
    // get the cached image for the specified result
    UIImage *cachedImage = %orig(result, section);
    
    // if a cached image is not available and we have a settings result, let's try to get the image
    if ( !cachedImage && [[result type] isEqual:@"Settings"] ) {
        // get the icon path for the title
        NSString *iconPath = [[labels objectForKey:[result title]] objectForKey:@"icon"];
        if ( iconPath ) {
            // the image will be resized to 60x60 on a non-retina device, 120x120 on a 2x retina device, and 180x180 on a 3x retina device
            // makes no sense - the stated spotlight icon size is 40x40, but for some reason, iOS 9 uses a 120x120 image on a 2x retina device, when it should be 80x80 according to the documentation
            // need feedback from testers to confirm that this (60x60) is consistent across all 64-bit devices
            //if ( scale == 3 ) {
                cachedImage = createIcon([UIImage imageWithContentsOfFile:iconPath], CGSizeMake(60, 60));
            //} else if ( scale == 2 ) {
                //cachedImage = createIcon([UIImage imageWithContentsOfFile:iconPath], [UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/AppIcon60x60@2x.png"], CGSizeMake(60, 60));
            //} else {
                //cachedImage = createIcon([UIImage imageWithContentsOfFile:iconPath], [UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/AppIcon60x60.png"], CGSizeMake(60, 60));
            //}
            
            // cache the image - caching is based on the result bundleID
            [self cacheImage:cachedImage forResult:result inSection:section];
        }
    }
    
    return cachedImage;
}

%new
- (NSMutableArray *)updateSectionsWithSections:(NSMutableArray *)arg1 {
    // create new section
    SPSearchResultSection *newSection = [[%c(SPSearchResultSection) alloc] init];
    // do displayIdentifier and category do anything useful for us?
    [newSection setDisplayIdentifier:@"Settings"];
    [newSection setCategory:@"Settings"];
    // domain 19 is "Settings" field, which is a URL-based domain
    [newSection setDomain:19];

    // sort the keys
    NSArray * sortedKeys = [[labels allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    // we have no result to add
    BOOL addResult = NO;
    
    // for each label (tweak name) in our sorted keys...
    for (NSString *label in sortedKeys) {
        // reset flag
        addResult = NO;
        
        // if the query length greater than 2, we're doing a substring match
        if ( [[self queryString] length] > 2 ) {
            // less performant, but diacritic-friendly
            if ( [label rangeOfString:[self queryString] options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [label length])].location != NSNotFound ) {
            	addResult = YES;
            }
            //if ( [[label lowercaseString] containsString:[[self queryString] lowercaseString]] ) {
                //addResult = YES;
            //}
        // if the query length is less than 2, we're doing a prefix match
        } else if ( [[self queryString] length] > 0 ) {
            // less performant, but diacritic-friendly
            if ( [label rangeOfString:[self queryString] options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [[self queryString] length])].location != NSNotFound ) {
            	addResult = YES;
            }
            //if ( [[label lowercaseString] hasPrefix:[[self queryString] lowercaseString]] ) {
                //addResult = YES;
            //}
        }
        
        // if we have a match
        if ( addResult ) {            
            // add the search result to the new section
            [newSection addResults:[[labels objectForKey:label] objectForKey:@"result"]];
        }
    }
    
    // if we have new results to add...
    if ( [newSection resultsCount] > 0 ) {
        // insert them into the existing sections
        [arg1 insertObject:newSection atIndex:0];
    }
    
    // return the sections either way
    return arg1;
}

- (void)addSections:(NSMutableArray *)arg1 {
    // call the original implementation after adding our section if appropriate
    %orig([self updateSectionsWithSections:arg1]);
}
%end

%ctor {
    // get the device
    device = ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) ? @"~ipad" : @"~iphone";
    
    // get the device scale
    if ( [UIScreen mainScreen].scale == 3.0f ) {
        //scaleFactor = @"@3x";
        scale = 3;
    } else if ( [UIScreen mainScreen].scale == 2.0f ) {
        //scaleFactor = @"@2x";
        scale = 2;
    }
}