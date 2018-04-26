//
//  DDControllerTouchpad.swift
//  Daydream
//
//  Created by Sachin Patel on 1/18/17.
//  Copyright © 2017 Sachin Patel. All rights reserved.
//

import UIKit

/// A closure type for receiving events when the current point on the touchpad changes.
/// - param touchpad: The touch pad calling this handler.
/// - param point: The new point on the touch pad.
typealias DDControllerTouchpadPointChangedHandler = (DDControllerTouchpad, CGPoint) -> Void

/// A Daydream View controller touch pad.
class DDControllerTouchpad: NSObject {
	/// Set this closure if you want to be notified when the point on the touch pad changes.
	public var pointChangedHandler: DDControllerTouchpadPointChangedHandler?
	
	/// The current point being tapped on the touch pad.
	public var point: CGPoint {
		didSet {
			pointChangedHandler?(self, point)
		}
	}
	
	/// The button underneath the touch pad on the Daydream View controller.
	private(set) var button: DDControllerButton
	
	override init() {
		point = CGPoint.zero
		button = DDControllerButton()
		
		super.init()
	}
}
