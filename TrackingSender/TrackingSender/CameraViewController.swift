//
//  CameraViewController.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/07/30.
//

import UIKit
import AVFoundation
import Vision

// MARK: CameraViewController

class CameraViewController: UIViewController {

	private var gestureProvider: HandTrackingProvider?
		
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		gestureProvider = HandTrackingProvider(baseView: self.view)
	}
	
	override func viewDidLayoutSubviews() {
		gestureProvider?.layoutSubviews()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		gestureProvider?.terminate()
		super.viewWillDisappear(animated)
	}
		
}

