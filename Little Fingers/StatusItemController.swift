//
//  StatusItemController.swift
//  Little Fingers
//
//  Created by Shaun Inman on 2/3/17.
//  Copyright © 2017 Shaun Inman. All rights reserved.
//

import Cocoa

class StatusItemController: NSObject {
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	var isAccessibilityEnabled = false
	
	let aboutWindowController = AboutWindowController(windowNibName: NSNib.Name("AboutWindow"))
	
	override init() {
		super.init()
		
		checkAccessibility()
		
		buildMenu()
		
		if let button = statusItem.button {
			if let image = NSImage(named: NSImage.Name("off")) {
				image.isTemplate = true
				button.image = image
			}
		}
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(updateIcon),
		                                       name: SINotificationLockChanged,
		                                       object: nil)
	}
	
	func checkAccessibility() {
		isAccessibilityEnabled = TapController.isAccessibilityEnabled()
		if isAccessibilityEnabled {
			// delay allows about window to be repsonsive on launch, not sure why...
			Timer.scheduledTimer(timeInterval: 0.1,
			                     target: self,
			                     selector: #selector(showAbout),
			                     userInfo: nil,
			                     repeats: false)
		}
		else {
			// Give user a moment to see the System Settings before quitting
			Timer.scheduledTimer(timeInterval: 1.0,
			                     target: self,
			                     selector: #selector(quitApp),
			                     userInfo: nil,
			                     repeats: false)
		}
	}
	
	@objc func quitApp() {
		NSApp.terminate(nil)
	}
	
	func buildMenu() {
		let menu = NSMenu()
		menu.delegate = self
		
		let item = NSMenuItem()
		item.title = "About Little Fingers"
		item.action = #selector(showAbout)
		item.target = self
		menu.addItem(item)
		
		menu.addItem(NSMenuItem.separator())
		
		menu.addItem(NSMenuItem(title: "Quit Little Fingers", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
		
		statusItem.menu = menu
	}
	
    @objc func showAbout() {
		NSApp.activate(ignoringOtherApps: true)
		aboutWindowController.showWindow(NSApp.delegate)
	}
	
    @objc func updateIcon() {
		if let button = statusItem.button {
			if TapController.isLocked() {
				if let image = NSImage(named: NSImage.Name("on")) {
					image.isTemplate = true
					button.image = image
				}
			} else {
				if let image = NSImage(named: NSImage.Name("off")) {
					image.isTemplate = true
					button.image = image
				}
			}
		}
	}
}

extension StatusItemController : NSMenuDelegate {
	func menuWillOpen(_ menu: NSMenu) {
		(NSApp.delegate as! AppDelegate).hideWindows()
	}
	
	@objc func menuDidClose(_ menu: NSMenu) {
		Timer.scheduledTimer(timeInterval: 0,
		                     target: NSApp.delegate as! AppDelegate,
		                     selector: #selector(AppDelegate.hideApp),
		                     userInfo: nil,
		                     repeats: false)
	}
}
