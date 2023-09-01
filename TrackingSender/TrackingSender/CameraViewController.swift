//
//  CameraViewController.swift
//
//  Copyright © 2023 Yos. All rights reserved.
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

