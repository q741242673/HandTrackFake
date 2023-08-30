//
//  ImmersiveView.swift
//  VisionGesture
//
//  Created by Yos Hashimoto on 2023/08/16.
//

import SwiftUI
#if targetEnvironment(simulator)
import RealityKit
import ARKit
#else
@preconcurrency import RealityKit
@preconcurrency import ARKit
#endif
import RealityKitContent
import SceneKit
import MultipeerConnectivity

typealias Scalar = Float

struct ImmersiveView: View {
	enum WhichHand: Int {
		case right = 0
		case left  = 1
	}
	enum WhichFinger: Int {
		case thumb  = 0
		case index
		case middle
		case ring
		case little
		case wrist
	}
	enum WhichJoint: Int {
		case tip = 0	// finger top
		case dip = 1	// first joint
		case pip = 2	// second joint
		case mcp = 3	// third joint
	}
	enum WhichJointNo: Int {
		case top = 0	// finger top
		case first = 1	// first joint
		case second = 2	// second joint
		case third = 3	// third joint
	}
	let wristJointIndex = 0

	@State var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	var defaultHand = WhichHand.right

	var handModel: HandModel = HandModel()
	let htFake = HandTrackFake()
	@State var logText: String = "Ready..."

	init(){
		textLog("init")
		htFake.initAsBrowser()
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
					//.font(.system(size: 32))
					.tag("text_view")
			}
			RealityView { content in
				content.add(handModel.setupContentEntity())
			}
		}	// ZStack
		.task {
			textLog("gestureProvider.publishHandTrackingUpdates")
			Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
				processHandPoseObservations(observations: [])
				displayHandJoints()
			}
		}
	}
	
	// MARK: Observation processing
	func processHandPoseObservations(observations: [HandAnchor?]) {

		var fingerJoints1 = [[SIMD3<Scalar>?]]()
		var fingerJoints2 = [[SIMD3<Scalar>?]]()
		
		var handCount = 0
		
		do {
			if htFake.currentJsonString.count>0 {
				if let dt3D = HandTrackJson3D(jsonStr: htFake.currentJsonString) {
					handCount = dt3D.handJoints.count
					if handCount>0 {
						fingerJoints1 = dt3D.handJoints[0]
						print("\(htFake.currentJsonString)")
					}
					if handCount>1 {
						fingerJoints2 = dt3D.handJoints[1]
					}
				}
			}
			else {
				handCount = 0
			}

			// decide which hand is right/left
			switch handCount {
			case 1:
				handJoints.removeAll()
				handJoints.insert(fingerJoints1, at: defaultHand.rawValue)
			case 2:
				let thumbPos1 = jointPosition(hand: fingerJoints1, finger: WhichFinger.thumb.rawValue, joint: WhichJoint.tip.rawValue)
				let thumbPos2 = jointPosition(hand: fingerJoints2, finger: WhichFinger.thumb.rawValue, joint: WhichJoint.tip.rawValue)
				guard let pos1=thumbPos1, let pos2=thumbPos2 else {
					return
				}
				handJoints.removeAll()
				if pos1.x < pos2.x {
					handJoints.append(fingerJoints2)	// WhichHand.right
					handJoints.append(fingerJoints1)
				}
				else {
					handJoints.append(fingerJoints1)	// WhichHand.right
					handJoints.append(fingerJoints2)
				}
			default:
				handJoints.removeAll()
			}
			
		} catch {
			textLog("Observation processing error.")
		}
	}

	// get joint position)
	func jointPosition(hand: [[SIMD3<Scalar>?]], finger: Int, joint: Int) -> SIMD3<Scalar>? {
		if finger==WhichFinger.wrist.rawValue {
			return hand[finger][wristJointIndex]
		}
		else {
			return hand[finger][joint]
		}
	}
	func jointPosition(hand: WhichHand, finger: WhichFinger, joint: WhichJoint) -> SIMD3<Scalar>? {
		
		var jnt = joint.rawValue
		if finger == .wrist { jnt = wristJointIndex }

		switch handJoints.count {
		case 1:
			return jointPosition(hand:handJoints[WhichHand.right.rawValue], finger:finger.rawValue, joint:jnt)
		case 2:
			return jointPosition(hand:handJoints[hand.rawValue], finger:finger.rawValue, joint:jnt)
		default:
			return nil
		}
	}

	// Display hand tracking
	static var lastState = MCSessionState.notConnected
	func displayHandJoints() {
		let nowState = htFake.sessionState
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
		if handJoints.count < 2 {
			handJoints.append([])
		}
	}
}

// MARK: Other job

extension ImmersiveView {

	func textLog(_ message: String) {
		DispatchQueue.main.async {
			logText = message+"\r"+logText
	//		_ = viewModel.addText(text: message)
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

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
