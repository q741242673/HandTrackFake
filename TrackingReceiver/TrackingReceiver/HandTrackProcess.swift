//
//  HandTrackProcess.swift
//  TrackingReceiver
//  
//  Created by Yos on 2023
//  
//

import Foundation
import CoreGraphics
import SwiftUI
import Vision
import ARKit

class HandTrackProcess {

	// Real HandTracking (not Fake)
	let session = ARKitSession()
	var handTracking = HandTrackingProvider()

	func handTrackingStart() async {
		if handTrackFake.enableFake == false {
			do {
				var auths = HandTrackingProvider.requiredAuthorizations
				if HandTrackingProvider.isSupported {
					print("ARKitSession starting.")
					try await session.run([handTracking])
				}
			} catch {
				print("ARKitSession error:", error)
			}
		}
	}

	func publishHandTrackingUpdates(updateJob: @escaping(([[[SIMD3<Scalar>?]]]) -> Void)) async {

		// Fake HandTracking
		if handTrackFake.enableFake {
			DispatchQueue.main.async {
				Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
					var fingerJoints1 = [[SIMD3<Scalar>?]]()
					var fingerJoints2 = [[SIMD3<Scalar>?]]()
					if handTrackFake.currentJsonString.count>0 {
						if let dt3D = HandTrackJson3D(jsonStr: handTrackFake.currentJsonString, rotate: handTrackFake.rotateHands) {
							let handCount = dt3D.handJoints.count
							if handCount>0 {
								fingerJoints1 = dt3D.handJoints[0]
								print("\(handTrackFake.currentJsonString)")
							}
							if handCount>1 {
								fingerJoints2 = dt3D.handJoints[1]
							}
						}
					}
					// CALLBACK
					updateJob([fingerJoints1, fingerJoints2])
				}
			}
		}
		// Real HandTracking
		else {
			for await update in handTracking.anchorUpdates {
				var rightAnchor: HandAnchor?
				var leftAnchor:  HandAnchor?
				var fingerJoints1 = [[SIMD3<Scalar>?]]()
				var fingerJoints2 = [[SIMD3<Scalar>?]]()

				switch update.event {
				case .updated:
					let anchor = update.anchor
					guard anchor.isTracked else { continue }
					
					if anchor.chirality == .left {
						leftAnchor = anchor
					} else if anchor.chirality == .right {
						rightAnchor = anchor
					}
				default:
					break
				}
				
				do {
					if rightAnchor != nil && leftAnchor != nil {
						fingerJoints1 = try getFingerJoints(with: rightAnchor)
						fingerJoints2 = try getFingerJoints(with: leftAnchor)
					}
					else {
						if rightAnchor != nil {
							fingerJoints1 = try getFingerJoints(with: rightAnchor)
							fingerJoints2 = []
						}
						if leftAnchor != nil {
							fingerJoints1 = try getFingerJoints(with: leftAnchor)
							fingerJoints2 = []
						}
					}
				} catch {
					NSLog("Error")
				}
				
				if rightAnchor != nil && leftAnchor != nil {
					// CALLBACK
					updateJob([fingerJoints1, fingerJoints2])
				}
			}
		}
	}
	
	func monitorSessionEvents() async {
		if handTrackFake.enableFake == false {
			for await event in session.events {
				switch event {
				case .authorizationChanged(let type, let status):
					if type == .handTracking && status != .allowed {
						// Stop, ask the user to grant hand tracking authorization again in Settings.
					}
				@unknown default:
					print("Session event \(event)")
				}
			}
		}
	}
	
	func cv(a: HandAnchor, j: HandSkeleton.JointName) -> SIMD3<Scalar>? {
		guard let sk = a.handSkeleton else { return [] }
		let valSIMD4 = matrix_multiply(a.transform, sk.joint(j).rootTransform).columns.3
		return valSIMD4[SIMD3(0, 1, 2)]
	}
	
	// get finger joint position array (VisionKit coordinate)
	func getFingerJoints(with anchor: HandAnchor?) throws -> [[SIMD3<Scalar>?]] {
		do {
			guard let ac = anchor else { return [] }
			let fingerJoints: [[SIMD3<Scalar>?]] =
			[
				[cv(a:ac,j:.thumbTip),cv(a:ac,j:.thumbIntermediateTip),cv(a:ac,j:.thumbIntermediateBase),cv(a:ac,j:.thumbKnuckle)],
				[cv(a:ac,j:.indexFingerTip),cv(a:ac,j:.indexFingerIntermediateTip),cv(a:ac,j:.indexFingerIntermediateBase),cv(a:ac,j:.indexFingerKnuckle)],
				[cv(a:ac,j:.middleFingerTip),cv(a:ac,j:.middleFingerIntermediateTip),cv(a:ac,j:.middleFingerIntermediateBase),cv(a:ac,j:.middleFingerKnuckle)],
				[cv(a:ac,j:.ringFingerTip),cv(a:ac,j:.ringFingerIntermediateTip),cv(a:ac,j:.ringFingerIntermediateBase),cv(a:ac,j:.ringFingerKnuckle)],
				[cv(a:ac,j:.littleFingerTip),cv(a:ac,j:.littleFingerIntermediateTip),cv(a:ac,j:.littleFingerIntermediateBase),cv(a:ac,j:.littleFingerKnuckle)],
				[cv(a:ac,j:.wrist)]
			]
			return fingerJoints
		} catch {
			NSLog("Error")
		}
		return []
	}
}

