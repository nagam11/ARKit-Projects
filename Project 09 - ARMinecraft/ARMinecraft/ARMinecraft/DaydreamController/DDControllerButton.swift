//
//  DDControllerButton.swift
//  Daydream
//
//  Created by Sachin Patel on 1/18/17.
//  Copyright © 2017 Sachin Patel. All rights reserved.
//

import UIKit

/// A closure type for receiving events when the press state of a button changes.
/// - param button: The button calling this handler.
/// - param pressed: A boolean value representing whether or not the button is currently pressed.
typealias DDControllerButtonValueChangedHandler = (DDControllerButton, Bool) -> Void

/// A Daydream View controller button.
class DDControllerButton: NSObject {
	/// Set this closure if you want to be notified continuously of the value of this button.
	/// For the Daydream View controller, this closure will be called roughly 60 times per second if set.
	public var valueChangedHandler: DDControllerButtonValueChangedHandler?
	
	/// Set this closure if you want to be notified only when the press state of this button changes.
	public var pressedChangedHandler: DDControllerButtonValueChangedHandler?
	
	/// Set this closure if you want to be notified after the button has been pressed for one second.
	public var longPressHandler: DDControllerButtonValueChangedHandler?
	
	/// The button must receive 60 updates where `pressed == true` in order to call the `longPressHandler`.
	private static let longPressRequirement = 60
	
	/// Keep track of how many updates `pressed` has been equal to `true` for in order to handle long presses.
	private var consecutivelyPressedCount: Int
	
	/// Whether or not we've already called the long press handler for the current press.
	/// We use this value to avoid calling the long press handler multiple times if the user keeps the button pressed.
	private var hasCalledLongPressHandlerForCurrentPress: Bool
	
	/// The current press state of the button.
	public var pressed: Bool {
		didSet {
			// Call the press change handler when the value changes
			if oldValue != pressed {
				pressedChangedHandler?(self, pressed)
				
				// The press state changed, so we can call the long press handler again the next time a long press is detected.
				hasCalledLongPressHandlerForCurrentPress = false
			}
			
			// Only increment the `consecutivelyPressedCount` if `pressed == true`
			consecutivelyPressedCount = pressed ? (consecutivelyPressedCount + 1) : 0
			
			// Call the long press handler if the `longPressRequirement` has been met and we haven't already called it for the current press
			if !hasCalledLongPressHandlerForCurrentPress && consecutivelyPressedCount > DDControllerButton.longPressRequirement {
				longPressHandler?(self, pressed)
				consecutivelyPressedCount = 0
				hasCalledLongPressHandlerForCurrentPress = true
			}
			
			// Always call the value changed handler
			valueChangedHandler?(self, pressed)
		}
	}
	
	override init() {
		pressed = false
		consecutivelyPressedCount = 0
		hasCalledLongPressHandlerForCurrentPress = false
		super.init()
	}
}
