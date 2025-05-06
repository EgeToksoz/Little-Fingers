//
//  AppDelegate.swift
//  Little Fingers
//
//  Created by Shaun Inman on 2/3/17.
//  Copyright © 2017 Shaun Inman. All rights reserved.
//

import Cocoa

let SINotificationLockChanged = Notification.Name("SINotificationLockChanged")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var tapController:TapController!
	var statusItemController:StatusItemController!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSApplication.shared.setActivationPolicy(.accessory)
		
		let defaults = UserDefaults.standard
		defaults.register(defaults: ["autoLaunch": false,
		                             "firstRun": true])
		
        if defaults.bool(forKey: "firstRun") {
			defaults.set(false, forKey: "firstRun")
			LoginItems.addApp()
		}
		
		tapController = TapController()
		statusItemController = StatusItemController()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		
	}

	func applicationWillResignActive(_ notification: Notification) {
		hideWindows()
	}
	
	func windowWillClose() {
		NSApp.hide(nil)
	}
	
	func hideWindows() {
		for window in NSApp.windows {
			if window.isKind(of: NSPanel.self) && window.isVisible {
				window.orderOut(nil)
			}
		}
	}
	
	@objc func hideApp() {
		let visibleWindows = NSApp.windows.filter { $0.isKind(of: NSPanel.self) && $0.isVisible }.count
		if visibleWindows == 0 {
			NSApp.hide(nil)
		}
	}
}

