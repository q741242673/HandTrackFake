//
//  ImmersiveView.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import SwiftUI
import RealityKit
import ARKit
import RealityKitContent
import SceneKit
import MultipeerConnectivity

typealias Scalar = Float

var gestureAloha: Gesture_Aloha?

struct ImmersiveView: View {
	let handTrackProcess: HandTrackProcess = HandTrackProcess()
	var handModel: HandModel = HandModel()
	@State var logText: String = "Ready..."

	init(){
		textLog("init")
		handTrackFake.initAsBrowser()
	}
	var body: some View {
		ZStack {
			// TextLog console
			RealityView { content, attachments in
				let ent = Entity()
				ent.scale = [4.0, 4.0, 4.0]
				ent.position = SIMD3(x: 0, y: 1.5, z: -2)
				ent.generateCollisionShapes(recursive: true)
				content.add(ent)
				if let textAttachement = attachments.entity(for: "text_view") {
					textAttachement.position = SIMD3(x: 0, y: 0, z: 0)
					ent.addChild(textAttachement)
				}
			} attachments: {
				Text(logText)
					.frame(width: 1000, height: 690, alignment: .topLeading)
					.multilineTextAlignment(.leading)
					.background(Color.blue)
					.foregroundColor(Color.white)
					.tag("text_view")
			}
			RealityView { content in
				content.add(handModel.setupContentEntity())
			}
		}	// ZStack
		.task {
			await handTrackProcess.handTrackingStart()
			gestureAloha = Gesture_Aloha(delegate: self)
		}
		.task {
			textLog("publishHandTrackingUpdates")
			// Hand tracking loop
			await handTrackProcess.publishHandTrackingUpdates(updateJob: { (fingerJoints) -> Void in
				displayHandJoints(handJoints: fingerJoints)
				gestureAloha?.checkGesture(handJoints: fingerJoints)
			})
		}
		.task {
			await handTrackProcess.monitorSessionEvents()
		}
	}
	
	// Display hand tracking
	static var lastState = MCSessionState.notConnected
	func displayHandJoints(handJoints: [[[SIMD3<Scalar>?]]]) {
		let nowState = handTrackFake.sessionState
		if nowState != ImmersiveView.lastState {
			switch nowState {
			case .connected:
				textLog("HandTrackFake connected.")
			case .connecting:
				textLog("HandTrackFake connecting...")
			default:
				textLog("HandTrackFake not connected.")
			}
			ImmersiveView.lastState = nowState
		}

		switch handJoints.count {
		case 1:
			handModel.setHandJoints(left : handJoints[0], right: nil)
			handModel.showFingers()
		case 2:
			handModel.setHandJoints(left : handJoints[0], right: handJoints[1])
			handModel.showFingers()
		default:
			handModel.setHandJoints(left : nil, right: nil)
			handModel.showFingers()
		}
		if HandTrackProcess.handJoints.count < 2 {
			HandTrackProcess.handJoints.append([])
		}
	}
}

// MARK: Gesture delegate job

extension ImmersiveView: GestureDelegate {

	func gesture(gesture: GestureBase, event: GestureDelegateEvent) {
		if gesture is Gesture_Aloha {
			handle_gestureAloha(event: event)
		}
	}
	
	// Aloha
	func handle_gestureAloha(event: GestureDelegateEvent) {
		switch event.type {
		case .Moved2D:
			break
		case .Moved3D:
			textLog("Aloha: gesture 3D")
//			set_points(pos: event.location as! [SIMD3<Scalar>])
		case .Moved4D:
			textLog("Aloha: gesture 4D")
			if let pnt = event.location[0] as? simd_float4x4 {
//				viewModel.moveGlove(pnt)
			}
		case .Began:
			break
		case .Ended:
			break
		case .Canceled:
			break
		case .Fired:
			break
		default:
			break
		}
	}

}

// MARK: Other job

extension ImmersiveView {

	func textLog(_ message: String) {
		DispatchQueue.main.async {
			logText = message+"\r"+logText
		}
	}

	func triangleCenterWithAxis(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> simd_float4x4? {
		guard
			let j1 = joint1,
			let j2 = joint2,
			let j3 = joint3
		else {
			return nil
		}
		// center of triangle
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)

		let xAxis = normalize(j2 - j1)
		let yAxis = normalize(j3 - h1)
		let zAxis = normalize(cross(xAxis, yAxis))

		let triangleCenterWorldTransform = simd_matrix(
			SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
			SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
			SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
			SIMD4(ct.x, ct.y, ct.z, 1)
		)
		return triangleCenterWorldTransform
	}

}

// MARK: Preview

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
