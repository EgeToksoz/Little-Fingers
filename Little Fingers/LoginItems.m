//
//  LoginItems.m
//  Day-O
//
//  Created by Shaun Inman on 10/20/11.
//  Copyright (c) 2011 Shaun Inman. All rights reserved.
//

#import "LoginItems.h"
#import <ServiceManagement/ServiceManagement.h>

// TODO: this code is deprecated, consider using SMLoginItemSetEnabled
// http://martiancraft.com/blog/2015/01/login-items/
// https://github.com/kgn/LaunchAtLoginHelper
// https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLoginItems.html#//apple_ref/doc/uid/10000172i-SW5-SW1

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@implementation LoginItems

+(BOOL)appAlreadyExists
{
	return [self isLoginItemEnabled];
}

+(void)addApp
{
	[self setLoginItemEnabled:YES];
}

+(void)removeApp
{
	[self setLoginItemEnabled:NO];
}

+(BOOL)isLoginItemEnabled
{
	BOOL enabled = NO;
	CFArrayRef loginItems = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
	if (loginItems) {
		NSArray *items = (__bridge_transfer NSArray *)loginItems;
		NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
		for (NSDictionary *item in items) {
			if ([item[@"Label"] isEqualToString:bundleIdentifier]) {
				enabled = YES;
				break;
			}
		}
	}
	return enabled;
}

+(void)setLoginItemEnabled:(BOOL)enabled
{
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	if (!SMLoginItemSetEnabled((__bridge CFStringRef)bundleIdentifier, enabled)) {
		NSLog(@"Failed to set login item status");
	}
}

@end

#pragma GCC diagnostic pop
