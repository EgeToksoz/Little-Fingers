//
//  AboutWindowController.swift
//  Little Fingers
//
//  Created by Shaun Inman on 2/5/17.
//  Copyright © 2017 Shaun Inman. All rights reserved.
//

import SwiftUI
import Cocoa

// TODO: launch at login checkbox is unresponsive at launch...
// TODO: credits text view doesn't scroll at launch either
// TODO: window controls don't work either? wth
// TODO: kinda fixed by delaying opening by a fraction of a second

struct AboutView: View {
	@State public var isAutoLaunch: Bool
	let bundle = Bundle.main
	let plist = Bundle.main.infoDictionary!
	
	init() {
		let defaults = UserDefaults.standard
		_isAutoLaunch = State(initialValue: defaults.bool(forKey: "autoLaunch"))
	}
	
	var body: some View {
		VStack(spacing: 20) {
			Image(nsImage: NSApp.applicationIconImage ?? NSImage())
				.resizable()
				.frame(width: 64, height: 64)
			
			Text(plist["CFBundleName"] as? String ?? "")
				.font(.title)
				.foregroundColor(.primary)
			
			Text("\(plist["CFBundleShortVersionString"] as? String ?? "") (\(plist["CFBundleVersion"] as? String ?? ""))")
				.font(.subheadline)
				.foregroundColor(.secondary)
			
			ScrollView {
				if let creditsPath = bundle.path(forResource: "Credits", ofType: "rtf"),
				   let creditsData = try? Data(contentsOf: URL(fileURLWithPath: creditsPath)),
				   let creditsString = try? NSAttributedString(data: creditsData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
					Text(AttributedString(creditsString))
						.padding()
				}
			}
			.frame(height: 120)
			
			Toggle("Launch at login", isOn: $isAutoLaunch)
				.onChange(of: isAutoLaunch) { newValue in
					UserDefaults.standard.set(newValue, forKey: "autoLaunch")
					do {
						if newValue {
							try SMAppService.mainApp.register()
						} else {
							try SMAppService.mainApp.unregister()
						}
					} catch {
						print("Failed to set login item status: \(error.localizedDescription)")
					}
				}
				.padding(.horizontal)
		}
		.padding(.top, 50)
		.padding(.bottom, 50)
		.frame(width: 330, height: 380)
	}
}

class AboutWindowController: NSWindowController {
	override func windowDidLoad() {
		super.windowDidLoad()
		
		let contentView = AboutView()
		let hostingController = NSHostingController(rootView: contentView)
		window?.contentViewController = hostingController
		window?.titlebarAppearsTransparent = true
		window?.styleMask.remove(.resizable)
		window?.center()
	}
	
	override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		let defaults = UserDefaults.standard
		let stillAutoLaunch = SMAppService.mainApp.status == .enabled
		let didAutoLaunch = defaults.bool(forKey: "autoLaunch")
		
		if stillAutoLaunch != didAutoLaunch {
			defaults.set(stillAutoLaunch, forKey: "autoLaunch")
			if let hostingController = window?.contentViewController as? NSHostingController<AboutView> {
				hostingController.rootView.isAutoLaunch = stillAutoLaunch
			}
		}
	}
}
