//
//  TrackingReceiverApp.swift
//  TrackingReceiver
//  
//  Created by Yos on 2023
//  
//

import SwiftUI

@main
struct TrackingReceiverApp: App {
    var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.defaultSize(width: 100, height: 100)
		.windowStyle(.plain)

		ImmersiveSpace(id: "ImmersiveSpace") {
			ImmersiveView()
		}.immersionStyle(selection: .constant(.full), in: .automatic)
    }
}
