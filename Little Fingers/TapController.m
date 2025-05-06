//
//  TapController.m
//  Little Fingers
//
//  Created by Shaun Inman on 2/3/17.
//  Copyright © 2017 Shaun Inman. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TapController.h"

@interface TapController () {
	
}
+(void)listen;
+(void)ignore;
@end

CGKeyCode kSIKeyCodeL = (CGKeyCode)37; // TODO: make keyboard agnostic? http://stackoverflow.com/a/33584460/145965

BOOL isCommandDown = NO;
BOOL isOptionDown = NO;
BOOL isControlDown = NO;
BOOL isShiftDown = NO;
BOOL isLDown = NO;

BOOL isLocked = NO;
BOOL wasLocked = NO;

void lockChanged(void) {
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SINotificationLockChanged" object:nil]];
}

CGEventRef tapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	if (type == kCGEventFlagsChanged) {
		NSEventModifierFlags flags = [[NSEvent eventWithCGEvent:event] modifierFlags];
		
        isCommandDown = (flags & NSEventModifierFlagCommand) == NSEventModifierFlagCommand;
        isOptionDown = (flags & NSEventModifierFlagOption) == NSEventModifierFlagOption;
        isControlDown = (flags & NSEventModifierFlagControl) == NSEventModifierFlagControl;
        isShiftDown = (flags & NSEventModifierFlagShift) == NSEventModifierFlagShift;
	}
	
	CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
	if (type == kCGEventKeyDown) {
		if (keycode == kSIKeyCodeL) isLDown = YES;
	}
	else if (type == kCGEventKeyUp) {
		if (keycode == kSIKeyCodeL) isLDown = NO;
	}
	
	if (isShiftDown && isControlDown && isOptionDown && isCommandDown && isLDown) {
		isLDown = NO;

		isLocked = !isLocked;
		lockChanged();
		
		// TODO: hide/show mouse?
		if (isLocked) {
			[TapController ignore];
		}
		else {
			[TapController listen];
		}
		
		return NULL;
	}
	
	if (isLocked) {
		return NULL;
	}
	else {
		return event;
	}
}

BOOL isTapEnabled = NO;
CFMachPortRef listenEventTap;
CFMachPortRef ignoreEventTap;
CFRunLoopSourceRef	listenRunLoopSource;
CFRunLoopSourceRef	ignoreRunLoopSource;

@implementation TapController

-(id)init {
	self = [super init];
	if (self) {
		if (![TapController isAccessibilityEnabled]) {
			NSLog(@"Accessibility permissions not granted");
			return self;
		}
		
		CGEventMask listenEventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged);
		CGEventMask ignoreEventMask = kCGEventMaskForAllEvents;
		
		listenEventTap = CGEventTapCreate(kCGSessionEventTap,
										kCGHeadInsertEventTap,
										kCGEventTapOptionDefault,
										listenEventMask,
										tapCallback, NULL);
		ignoreEventTap = CGEventTapCreate(kCGSessionEventTap,
										kCGHeadInsertEventTap,
										kCGEventTapOptionDefault,
										ignoreEventMask,
										tapCallback, NULL);
		
		if (!listenEventTap || !ignoreEventTap) {
			NSLog(@"Failed to create event taps - please check accessibility permissions");
			return self;
		}
		
		listenRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, listenEventTap, 0);
		ignoreRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, ignoreEventTap, 0);
		
		if (!listenRunLoopSource || !ignoreRunLoopSource) {
			NSLog(@"Failed to create run loop sources");
			if (listenEventTap) CFRelease(listenEventTap);
			if (ignoreEventTap) CFRelease(ignoreEventTap);
			return self;
		}
		
		[TapController listen];
		isTapEnabled = YES;
		
		// disable lock during screensavers/sleep
		NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
		
		[dnc addObserver:self selector:@selector(pauseLock) name:@"com.apple.shutdownInitiated" object:nil];
		[dnc addObserver:self selector:@selector(pauseLock) name:@"com.apple.shieldWindowRaised" object:nil];
		[dnc addObserver:self selector:@selector(resumeLock) name:@"com.apple.shieldWindowLowered" object:nil];
		[dnc addObserver:self selector:@selector(resumeLock) name:@"com.apple.logoutCancelled" object:nil];
	}
	return self;
}

+(void)listen {
	if (isTapEnabled) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), ignoreRunLoopSource, kCFRunLoopCommonModes);
		CGEventTapEnable(ignoreEventTap, false);
	}
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), listenRunLoopSource, kCFRunLoopCommonModes);
	CGEventTapEnable(listenEventTap, true);
}

+(void)ignore {
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), listenRunLoopSource, kCFRunLoopCommonModes);
	CGEventTapEnable(listenEventTap, false);
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), ignoreRunLoopSource, kCFRunLoopCommonModes);
	CGEventTapEnable(ignoreEventTap, true);
}

+(BOOL)isAccessibilityEnabled {
	// First check if we already have permissions
	NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @NO};
	BOOL isTrusted = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
	
	if (!isTrusted) {
		// If not trusted, prompt for permissions
		options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
		isTrusted = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
	}
	
	return isTrusted;
}

+(BOOL)isLocked {
	return isLocked;
}

-(void)pauseLock {
	if (isLocked) {
		isLocked = NO;
		wasLocked = YES;
		lockChanged();
	}
}
-(void)resumeLock {
	if (wasLocked) {
		isLocked = YES;
		wasLocked = NO;
		lockChanged();
	}
}

-(void)dealloc {
	if (listenEventTap) {
		CFRelease(listenEventTap);
		listenEventTap = NULL;
	}
	if (ignoreEventTap) {
		CFRelease(ignoreEventTap);
		ignoreEventTap = NULL;
	}
	if (listenRunLoopSource) {
		CFRelease(listenRunLoopSource);
		listenRunLoopSource = NULL;
	}
	if (ignoreRunLoopSource) {
		CFRelease(ignoreRunLoopSource);
		ignoreRunLoopSource = NULL;
	}
	
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end
