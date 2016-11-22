#import <Preferences/Preferences.h>
#import <notify.h>
#import <objc/runtime.h>
#include <spawn.h>

extern "C" CFArrayRef CPBitmapCreateImagesFromData(CFDataRef cpbitmap, void*, int, void*);
extern NSString* PSDeletionActionKey;

typedef enum PSCellType {
	PSGroupCell,
	PSLinkCell,
	PSLinkListCell,
	PSListItemCell,
	PSTitleValueCell,
	PSSliderCell,
	PSSwitchCell,
	PSStaticTextCell,
	PSEditTextCell,
	PSSegmentCell,
	PSGiantIconCell,
	PSGiantCell,
	PSSecureEditTextCell,
	PSButtonCell,
	PSEditTextViewCell,
} PSCellType;

static int   spotlightIndex  = 0;
static BOOL  useSettingsIcon = YES;
static float iconAlpha       = 1.0f;
static float insetAlpha      = 1.0f;
static BOOL  insetMasked     = YES;
static BOOL  insetMono       = NO;


@interface KeyboardStateListener : NSObject {
	BOOL _isVisible;
}
+ (KeyboardStateListener *)sharedInstance;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;
@end

static KeyboardStateListener *sharedKeyboardInstance;

@implementation KeyboardStateListener

+ (KeyboardStateListener *)sharedInstance
{
	return sharedKeyboardInstance;
}

+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	sharedKeyboardInstance = [[self alloc] init];
	[pool release];
}

- (BOOL)isVisible
{
	return _isVisible;
}

- (void)didShow
{
	_isVisible = YES;
}

- (void)didHide
{
	_isVisible = NO;
}

- (id)init
{
	if ((self = [super init])) {
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(didShow) name:UIKeyboardDidShowNotification object:nil];
		[center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
	}
	return self;
}

@end

@interface PSEditTextRightCell : PSEditableTableCell
@end

@implementation PSEditTextRightCell

-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	PSEditTextRightCell *editTextCell = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	((UITextField *)[editTextCell textField]).textAlignment = NSTextAlignmentRight;
	((UITextField *)[editTextCell textField]).layer.sublayerTransform = CATransform3DMakeTranslation(-20, 0, 0);
	
	return editTextCell;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	//NSMutableCharacterSet *characterSet = [NSMutableCharacterSet whitespaceCharacterSet];
	//[characterSet addCharactersInString:@"%"];
	
	//[self setValue:[[textField text] stringByTrimmingCharactersInSet:characterSet]];
    [self setValue:@""];
    
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self _setValueChanged];
}

@end

/*
@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
@end
*/

@interface AdiunctaDefinitionCell : PSTableCell { // <PreferencesTableCustomView> {
    //UILabel *term;
    //UILabel *definition;
}

@end

@implementation AdiunctaDefinitionCell

//- (id)initWithSpecifier:(PSSpecifier *)specifier
- (id)initWithStyle:(int)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier
{
    //self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"definitionCell" specifier:specifier];
    
    if (self) {
        
        int width = [[UIScreen mainScreen] bounds].size.width;
        
        CGRect termFrame = CGRectMake(0, 5, width, 40);
        CGRect definitionFrame = CGRectMake(0, 35, width, 60);
        
        UILabel *term = [[UILabel alloc] initWithFrame:termFrame];
        [term setNumberOfLines:1];
        [term setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48]];
        [term setText:@"Adiuncta"];
        [term setBackgroundColor:[UIColor clearColor]];
        [term setTextColor:[UIColor blackColor]];
        [term setTextAlignment:NSTextAlignmentCenter];
        
        UILabel *definition = [[UILabel alloc] initWithFrame:definitionFrame];
        [definition setNumberOfLines:2];
        [definition setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18]];
        [definition setText:@"noun, subst. pl. from adiungō\nattached, joined, yoked (as cattle)"];
        [definition setBackgroundColor:[UIColor clearColor]];
        [definition setTextColor:[UIColor blackColor]];
        [definition setTextAlignment:NSTextAlignmentCenter];
        
        NSMutableAttributedString *attributedDefinition = [[NSMutableAttributedString alloc] initWithAttributedString:definition.attributedText];

        [attributedDefinition addAttribute:NSForegroundColorAttributeName 
                     value:[UIColor colorWithRed:66.0/255.0 green:165.0/255.0 blue:245.0/255.0 alpha:1]
                     range:NSMakeRange(0, 29)];
        [attributedDefinition addAttribute:NSFontAttributeName
                     value: [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:18]
                     range:NSMakeRange(0, 29)];
        [attributedDefinition addAttribute:NSForegroundColorAttributeName 
                     value:[UIColor blackColor]
                     range:NSMakeRange(29, 36)];
        [definition setAttributedText:attributedDefinition];
        
        // release attributedDefinition
        [attributedDefinition release];
        attributedDefinition = nil;
        
        // add subviews
        [self addSubview:term];
        [self addSubview:definition];
        
        // release term
        [term release];
        term = nil;
        
        // release definition
        [definition release];
        definition = nil;
    }
    
    return self;
}

/*
- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	// Return a custom cell height.
	return 70.0f;
}
*/

@end

static UIImage *createIcon(UIImage *icon, CGSize size, NSString *settingsIconPath, NSString *spotlightIconMask) {
    // obtain the settings icon from the path obtained earlier
    UIImage *settingsIcon = useSettingsIcon ? [UIImage imageWithContentsOfFile:settingsIconPath] : nil;
    
    // create an image context with the specified size, non-opaque, and device-scaled
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    // get the context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // anti-alias, because we're clipping and resizing
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    
    CGImageRef bundleMask;
    
    // if we've got an icon mask from anemone, use it (cry first)
    if ( spotlightIconMask ) {
        // get the icon mask image
        UIImage *iconMask = [UIImage imageWithContentsOfFile:spotlightIconMask];
        
        // we need to create the mask from the spotlightIconMask's CGImage
        CGImageRef maskRef = [iconMask CGImage];
        
        // coregraphics doesn't like anemone's icon masks, so we need to invert the alpha mask 
        CGFloat decode[] = { CGFloat(1), CGFloat(0),  // alpha (flipped)
                             CGFloat(0), CGFloat(1),  // red   (no change)
                             CGFloat(0), CGFloat(1),  // green (no change)
                             CGFloat(0), CGFloat(1)   // blue  (no change)
                           };
                             
        // now, we're going to create a mask using the properties of the original image, but we're going to use the custom decode array to flip the alpha channel
        CGImageRef mask = CGImageCreate(CGImageGetWidth(maskRef), CGImageGetHeight(maskRef), CGImageGetBitsPerComponent(maskRef), CGImageGetBitsPerPixel(maskRef), CGImageGetBytesPerRow(maskRef), CGImageGetColorSpace(maskRef), CGImageGetBitmapInfo(maskRef), CGImageGetDataProvider(maskRef), decode, CGImageGetShouldInterpolate(maskRef), CGImageGetRenderingIntent(maskRef));
        
        // if we'll need it, create the inset mask as well
        if ( insetMasked ) {
            // push the current context
            UIGraphicsPushContext(context);
            
            // create an inset context with the specified size, non-opaque, and device-scaled
            UIGraphicsBeginImageContextWithOptions(icon.size, NO, 0.0);

            // get the inset context
            CGContextRef insetContext = UIGraphicsGetCurrentContext();

            // anti-alias, because we're clipping and resizing
            CGContextSetShouldAntialias(insetContext, true);
            CGContextSetAllowsAntialiasing(insetContext, true);

            // draw a resized icon mask for the inset
            [iconMask drawInRect:CGRectMake(0, 0, icon.size.width, icon.size.height)];

            // and store it in our iconMask UIImage
            iconMask = UIGraphicsGetImageFromCurrentImageContext(); 

            // we need to create the inset mask from the resized iconMask's CGImage
            CGImageRef maskRef = [iconMask CGImage];

            // coregraphics doesn't like anemone's icon masks, but the alpha is already flipped above, so just create the image
            CGFloat decode[] = { CGFloat(0), CGFloat(1),  // alpha (no change)
                                 CGFloat(0), CGFloat(1),  // red   (no change)
                                 CGFloat(0), CGFloat(1),  // green (no change)
                                 CGFloat(0), CGFloat(1)   // blue  (no change)
                               };

            // now, we're going to create a bundle mask using the properties of the resized image, but we're going to use the custom decode array to flip the alpha channel
            bundleMask = CGImageCreate(CGImageGetWidth(maskRef), CGImageGetHeight(maskRef), CGImageGetBitsPerComponent(maskRef), CGImageGetBitsPerPixel(maskRef), CGImageGetBytesPerRow(maskRef), CGImageGetColorSpace(maskRef), CGImageGetBitmapInfo(maskRef), CGImageGetDataProvider(maskRef), decode, CGImageGetShouldInterpolate(maskRef), CGImageGetRenderingIntent(maskRef));

            // end the inset context
            UIGraphicsEndImageContext();
            // restore the previous context
            UIGraphicsPopContext();
        }
        
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
    if ( useSettingsIcon ) {
        [settingsIcon drawInRect:CGRectMake(0, 0, size.width, size.height) blendMode:kCGBlendModeNormal alpha:iconAlpha];
    }
    
    if ( insetMono ) {      
        CIImage *iconCIImage = [[CIImage alloc] initWithImage:icon];
        CIImage *monoCIImage = [iconCIImage imageByApplyingFilter:@"CIColorControls" withInputParameters:@{kCIInputSaturationKey : @0.0}];
        icon = [UIImage imageWithCIImage:monoCIImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        
        [iconCIImage release];
        iconCIImage = nil;
    }
    
    if ( insetMasked ) {
        // push the current context
        UIGraphicsPushContext(context);
        
        // create an image context with the specified size, non-opaque, and device-scaled
        UIGraphicsBeginImageContextWithOptions(icon.size, NO, 0.0);
        // get the context
        CGContextRef insetContext = UIGraphicsGetCurrentContext();
        
        // anti-alias, because we're clipping and resizing
        CGContextSetShouldAntialias(insetContext, true);
        CGContextSetAllowsAntialiasing(insetContext, true);
        
        if ( spotlightIconMask && bundleMask ) {
            // clip the inset context using the bundle mask
            CGContextClipToMask(insetContext, CGRectMake(0, 0, icon.size.width, icon.size.height), bundleMask);
            // release the mask
            CGImageRelease(bundleMask);
        } else {
            // re-round the corners with a UIBezierPath rounded rect to try to smooth out the edges
            CGContextAddPath(insetContext, CGPathCreateCopy([UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, icon.size.width, icon.size.height) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(10.0f/57.0f * icon.size.width, icon.size.height)].CGPath));
            // clip the context with the added path
            CGContextClip(insetContext);
        }
        
        // draw the inset
        [icon drawInRect:CGRectMake(0, 0, icon.size.width, icon.size.height)];
        // now get back the masked inset
        icon = UIGraphicsGetImageFromCurrentImageContext();
        // end the inset context
        UIGraphicsEndImageContext();
        // restore the previous context
        UIGraphicsPopContext();
    }
    
    if ( useSettingsIcon ) {
        // draw the bundle icon in the corner of the rectangle of the specified size
        [icon drawInRect:CGRectMake(size.width - icon.size.width - 3, size.height - icon.size.height - 3, icon.size.width, icon.size.height) blendMode:kCGBlendModeNormal alpha:insetAlpha];
    } else {
        // draw the icon centered without resizing.
        [icon drawInRect:CGRectMake(size.width/2 - icon.size.width/2, size.height/2 - icon.size.height/2, icon.size.width, icon.size.height) blendMode:kCGBlendModeNormal alpha:insetAlpha];
    }
    
    // get the new icon back from the current context
    UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();  
    // end the image context
    UIGraphicsEndImageContext();

    // return the new icon
    return newIcon;
}

@interface AdiunctaPreviewCell : PSTableCell { //<PreferencesTableCustomView> {
}
@end

@implementation AdiunctaPreviewCell
//- (id)initWithSpecifier:(PSSpecifier *)specifier
- (id)initWithStyle:(int)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier
{
	//self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"previewCell" specifier:specifier];
        
	if (self) {
	    self.clipsToBounds = YES;
	    //self.contentView.backgroundColor = [UIColor grayColor];
	    // dark slate
	    self.contentView.backgroundColor = [UIColor colorWithRed:47.0/255.0 green:79.0/255.0 blue:79.0/255.0 alpha:1];
	    
	    int scale = (int)[UIScreen mainScreen].scale;
		NSString *scaleFactor = scale > 1 ? [NSString stringWithFormat:@"@%dx", scale] : @"";
		CGFloat width = [[UIScreen mainScreen] bounds].size.width;
		
		UIToolbar *toolBar = [[UIToolbar alloc] init];
        [toolBar setFrame:CGRectMake(0,10,width,80)];
        [toolBar setAlpha:0.2];
        
        [self addSubview:toolBar];
        [toolBar release];
        toolBar = nil;
        
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(85,0,width-85,100)];
		[label setFont:[UIFont systemFontOfSize:15]];
		[label setText:@"Adiuncta"];
		[label setTextColor:[UIColor whiteColor]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTextAlignment:NSTextAlignmentLeft];
		
		[self addSubview:label];
		[label release];
		label = nil;
		
		NSString *settingsIconPath = !CFPreferencesCopyAppValue(CFSTR("SettingsIconPath"), CFSTR("net.bearlike.adiuncta")) ? [NSString stringWithFormat:@"/Applications/Preferences.app/AppIcon60x60%@.png", scaleFactor] : (id)CFPreferencesCopyAppValue(CFSTR("SettingsIconPath"),  CFSTR("net.bearlike.adiuncta"));
		NSString *spotlightIconMask = !CFPreferencesCopyAppValue(CFSTR("SpotlightIconMask"), CFSTR("net.bearlike.adiuncta")) ? nil : (id)CFPreferencesCopyAppValue(CFSTR("SpotlightIconMask"),  CFSTR("net.bearlike.adiuncta"));
		
		/*
		NSData *wallpaperData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"];
		CFDataRef wallpaperDataRef = (__bridge CFDataRef)wallpaperData;
		NSArray *imageArray = (__bridge NSArray *)CPBitmapCreateImagesFromData(wallpaperDataRef, NULL, 1, NULL);
		UIImage *wallpaper = [UIImage imageWithCGImage:(CGImageRef)imageArray[0]];
        UIImageView *wallpaperView = [[UIImageView alloc] initWithImage:wallpaper];
		
		[imageArray release];
		imageArray = nil;
	
		UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];    
        effectView.frame = wallpaperView.bounds;
        [wallpaperView addSubview:effectView];
        
        [wallpaperView addSubview:toolBar];
        
		[self addSubview:wallpaperView];
        [self sendSubviewToBack:wallpaperView];
        */
        
		UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(15,20,60,60)];
		[imgView setContentMode:UIViewContentModeCenter];
        imgView.image = createIcon([UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/Adiuncta.bundle/icon%@.png", scaleFactor]], CGSizeMake(60,60), settingsIconPath, spotlightIconMask);
        
        [self addSubview:imgView];
        
        [imgView release];
        imgView = nil;
	}
	return self;
}

/*
- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	// Return a custom cell height.
	return 100.0f;
}
*/
@end

@interface AdiunctaListController: PSListController { }
@end

@implementation AdiunctaListController
- (id)specifiers {
	
	if (_specifiers == nil) {
		
		NSMutableArray *specifiers = [NSMutableArray array];
		
		PSSpecifier *spec;
		PSTextFieldSpecifier *fieldSpec;
        
        CFPreferencesAppSynchronize(CFSTR("net.bearlike.adiuncta"));
        useSettingsIcon = !CFPreferencesCopyAppValue(CFSTR("UseSettingsIcon"), CFSTR("net.bearlike.adiuncta")) ? YES  : [(id)CFPreferencesCopyAppValue(CFSTR("UseSettingsIcon"),  CFSTR("net.bearlike.adiuncta")) boolValue];
        iconAlpha       = !CFPreferencesCopyAppValue(CFSTR("IconAlpha"),       CFSTR("net.bearlike.adiuncta")) ? 1.0f : [(id)CFPreferencesCopyAppValue(CFSTR("IconAlpha"),        CFSTR("net.bearlike.adiuncta")) floatValue];
        insetAlpha      = !CFPreferencesCopyAppValue(CFSTR("InsetAlpha"),      CFSTR("net.bearlike.adiuncta")) ? 1.0f : [(id)CFPreferencesCopyAppValue(CFSTR("InsetAlpha"),       CFSTR("net.bearlike.adiuncta")) floatValue];
        insetMasked     = !CFPreferencesCopyAppValue(CFSTR("InsetMasked"),     CFSTR("net.bearlike.adiuncta")) ? YES  : [(id)CFPreferencesCopyAppValue(CFSTR("InsetMasked"),      CFSTR("net.bearlike.adiuncta")) boolValue];
        insetMono       = !CFPreferencesCopyAppValue(CFSTR("InsetMono"),       CFSTR("net.bearlike.adiuncta")) ? NO   : [(id)CFPreferencesCopyAppValue(CFSTR("InsetMono"),        CFSTR("net.bearlike.adiuncta")) boolValue];
        
        spotlightIndex  = !CFPreferencesCopyAppValue(CFSTR("SpotlightIndex"),  CFSTR("net.bearlike.adiuncta")) ? 0    : [(id)CFPreferencesCopyAppValue(CFSTR("SpotlightIndex"),   CFSTR("net.bearlike.adiuncta")) intValue];
        
        spec = [PSSpecifier preferenceSpecifierNamed:nil target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
		[spec setProperty:[AdiunctaDefinitionCell class] forKey:@"cellClass"];
        [spec setProperty:@"95" forKey:@"height"];
		[specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Search Result Position:" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
		[specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Place Below" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:[PSListItemsController class] cell:PSLinkListCell edit:nil];
		[spec setValues:@[@0, @1, @2] titles:@[@"Top", @"Top Hits", @"Applications"]];
        [spec setIdentifier:@"spotlightIndex"];
		[specifiers addObject:spec];
        
		spec = [PSSpecifier preferenceSpecifierNamed:@"Search Result Rendering:" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Use Settings Icon" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:nil cell:PSSwitchCell edit:nil];
		[spec setIdentifier:@"useSettingsIcon"];
		[specifiers addObject:spec];
		
        fieldSpec = [PSTextFieldSpecifier preferenceSpecifierNamed:@"Settings Icon Opacity" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:nil cell:PSEditTextCell edit:nil];
        [fieldSpec setIdentifier:@"iconAlpha"];
        [fieldSpec setProperty:@"Settings Icon Opacity" forKey:@"label"];
        [fieldSpec setProperty:[PSEditTextRightCell class] forKey:@"cellClass"];
        [fieldSpec setProperty:@(YES) forKey:@"enabled"];
        [fieldSpec setKeyboardType:UIKeyboardTypeNumberPad autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
        [specifiers addObject:fieldSpec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Bundle Icon Masked" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:nil cell:PSSwitchCell edit:nil];
		[spec setIdentifier:@"insetMasked"];
		[specifiers addObject:spec];
        
		spec = [PSSpecifier preferenceSpecifierNamed:@"Bundle Icon Monochrome" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:nil cell:PSSwitchCell edit:nil];
		[spec setIdentifier:@"insetMono"];
		[specifiers addObject:spec];
		
        fieldSpec = [PSTextFieldSpecifier preferenceSpecifierNamed:@"Bundle Icon Opacity" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:nil cell:PSEditTextCell edit:nil];
        [fieldSpec setIdentifier:@"insetAlpha"];
        [fieldSpec setProperty:@"Bundle Icon Opacity" forKey:@"label"];
        [fieldSpec setProperty:[PSEditTextRightCell class] forKey:@"cellClass"];
        [fieldSpec setProperty:@(YES) forKey:@"enabled"];
        [fieldSpec setKeyboardType:UIKeyboardTypeNumberPad autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
        [specifiers addObject:fieldSpec];
        
        /*
		spec = [PSSpecifier preferenceSpecifierNamed:@"Apply Settings:" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
		[specifiers addObject:spec];
		
        spec = [PSSpecifier preferenceSpecifierNamed:@"Apply Settings" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
		[spec setButtonAction:@selector(applySettings)];
		[specifiers addObject:spec];
		*/
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Preview:" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
		[specifiers addObject:spec];
        
		spec = [PSSpecifier preferenceSpecifierNamed:nil target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
		[spec setProperty:[AdiunctaPreviewCell class] forKey:@"cellClass"];
        [spec setProperty:@"100" forKey:@"height"];
		[specifiers addObject:spec];
        
		spec = [PSSpecifier preferenceSpecifierNamed:@"Contribute:" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Buy /u/fecaleagle a Fish!" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
		[spec setButtonAction:@selector(sendDonation)];
		[specifiers addObject:spec];
		
		_specifiers = [specifiers copy];
	}
	
	return _specifiers;
}

- (void)applySettings {
    [self dismissKeyboard];
    
    // post notification to tweak
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("net.bearlike.adiuncta/settingschanged"), NULL, NULL, TRUE);
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (id)getValueForSpecifier:(PSSpecifier*)specifier {
    // synchronize settings
    CFPreferencesAppSynchronize(CFSTR("net.bearlike.adiuncta"));
    // get value per identifier...
    if ([[specifier identifier] isEqualToString:@"spotlightIndex"]) {
        spotlightIndex  = !CFPreferencesCopyAppValue(CFSTR("SpotlightIndex"),  CFSTR("net.bearlike.adiuncta")) ? 0    : [(id)CFPreferencesCopyAppValue(CFSTR("SpotlightIndex"),  CFSTR("net.bearlike.adiuncta")) intValue];
        return [NSNumber numberWithInt:spotlightIndex];
    } else if ([[specifier identifier] isEqualToString:@"useSettingsIcon"]) {
        useSettingsIcon = !CFPreferencesCopyAppValue(CFSTR("UseSettingsIcon"), CFSTR("net.bearlike.adiuncta")) ? YES  : [(id)CFPreferencesCopyAppValue(CFSTR("UseSettingsIcon"), CFSTR("net.bearlike.adiuncta")) boolValue];
        return [NSNumber numberWithBool:useSettingsIcon];
    } else if ([[specifier identifier] isEqualToString:@"iconAlpha"]) {
        iconAlpha       = !CFPreferencesCopyAppValue(CFSTR("IconAlpha"),       CFSTR("net.bearlike.adiuncta")) ? 1.0f : [(id)CFPreferencesCopyAppValue(CFSTR("IconAlpha"),       CFSTR("net.bearlike.adiuncta")) floatValue];
        NSString *value = [NSString stringWithFormat:@"%d%%", (int)(iconAlpha*100)];
        return value;
	} else if ([[specifier identifier] isEqualToString:@"insetAlpha"]) {
        insetAlpha      = !CFPreferencesCopyAppValue(CFSTR("InsetAlpha"),      CFSTR("net.bearlike.adiuncta")) ? 1.0f : [(id)CFPreferencesCopyAppValue(CFSTR("InsetAlpha"),      CFSTR("net.bearlike.adiuncta")) floatValue];
        NSString *value = [NSString stringWithFormat:@"%d%%", (int)(insetAlpha*100)];
        return value;
    } else if ([[specifier identifier] isEqualToString:@"insetMasked"]) {
        insetMasked     = !CFPreferencesCopyAppValue(CFSTR("InsetMasked"),     CFSTR("net.bearlike.adiuncta")) ? YES  : [(id)CFPreferencesCopyAppValue(CFSTR("InsetMasked"),     CFSTR("net.bearlike.adiuncta")) boolValue];
        return [NSNumber numberWithBool:insetMasked];
    } else if ([[specifier identifier] isEqualToString:@"insetMono"]) {
        insetMono       = !CFPreferencesCopyAppValue(CFSTR("InsetMono"),       CFSTR("net.bearlike.adiuncta")) ? NO   : [(id)CFPreferencesCopyAppValue(CFSTR("InsetMono"),       CFSTR("net.bearlike.adiuncta")) boolValue];
        return [NSNumber numberWithBool:insetMono];
    }
    
	return nil;
}

-(void)setValue:(id)value forSpecifier:(PSSpecifier*)specifier {
    // set value per identifier...
    if ([[specifier identifier] isEqualToString:@"spotlightIndex"]) {
        spotlightIndex = [value intValue];
         CFPreferencesSetAppValue(CFSTR("SpotlightIndex"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &spotlightIndex), CFSTR("net.bearlike.adiuncta"));
    } else if ([[specifier identifier] isEqualToString:@"useSettingsIcon"]) {
        useSettingsIcon = [value boolValue];
        CFPreferencesSetAppValue(CFSTR("UseSettingsIcon"), [value boolValue] ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("net.bearlike.adiuncta"));
    } else if ([[specifier identifier] isEqualToString:@"iconAlpha"]) {       
		NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
	
		NSMutableCharacterSet *characterSet = [NSMutableCharacterSet whitespaceCharacterSet];
		[characterSet addCharactersInString:@"-%%"];
		
		value = [value stringByTrimmingCharactersInSet:characterSet];
		value = [value stringByReplacingOccurrencesOfString:@"-" withString:@""];
		value = [value stringByReplacingOccurrencesOfString:@"%%" withString:@""];
		
		int number = [[numberFormatter numberFromString:value] intValue];
		
		[numberFormatter release];
		numberFormatter = nil;
		
		if ( ![value isEqualToString:@""] && [value length] > 0 ) {
			
			if ( number > 100 ) {
				number = 100;
			}
			
			if ( number < 0 ) {
				number = 0;
			}
		} else {
            number = 100;
        }
        
        iconAlpha = number/100.0f;
        
        CFPreferencesSetAppValue(CFSTR("IconAlpha"), CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &iconAlpha), CFSTR("net.bearlike.adiuncta"));
	} else if ([[specifier identifier] isEqualToString:@"insetAlpha"]) {
		NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
	
		NSMutableCharacterSet *characterSet = [NSMutableCharacterSet whitespaceCharacterSet];
		[characterSet addCharactersInString:@"-%%"];
		
		value = [value stringByTrimmingCharactersInSet:characterSet];
		value = [value stringByReplacingOccurrencesOfString:@"-" withString:@""];
		value = [value stringByReplacingOccurrencesOfString:@"%%" withString:@""];
		
		int number = [[numberFormatter numberFromString:value] intValue];
		
		[numberFormatter release];
		numberFormatter = nil;
		
		if ( ![value isEqualToString:@""] && [value length] > 0 ) {
			
			if ( number > 100 ) {
				number = 100;
			}
			
			if ( number < 0 ) {
				number = 0;
			}
		} else {
            number = 100;
        }
        
        insetAlpha = number/100.0f;
        
        CFPreferencesSetAppValue(CFSTR("InsetAlpha"), CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &insetAlpha), CFSTR("net.bearlike.adiuncta"));
	} else if ([[specifier identifier] isEqualToString:@"insetMasked"]) {
        insetMasked = [value boolValue];
        CFPreferencesSetAppValue(CFSTR("InsetMasked"), [value boolValue] ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("net.bearlike.adiuncta"));
    } else if ([[specifier identifier] isEqualToString:@"insetMono"]) {
        insetMono = [value boolValue];
        CFPreferencesSetAppValue(CFSTR("InsetMono"), [value boolValue] ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("net.bearlike.adiuncta"));
    }
	//dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
	    [self reloadSpecifiers];
	//});
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)sendDonation {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=TVSP8BNMBJ9GU"]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
    UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(applySettings)];
    
	self.navigationItem.rightBarButtonItem = applyButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [applyButton release];
    applyButton = nil;
    
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	tap.cancelsTouchesInView = NO;
	[self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
	[self.view endEditing:YES];
}

@end