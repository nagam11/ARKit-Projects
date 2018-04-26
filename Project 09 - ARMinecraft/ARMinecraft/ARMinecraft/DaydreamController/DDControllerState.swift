//
//  DDControllerState.swift
//  Daydream
//
//  Created by Sachin Patel on 1/17/17.
//  Copyright © 2017 Sachin Patel. All rights reserved.
//

import UIKit
import CoreMotion

/// Represents the state of a controller at a given time.
///
/// Note: `DDControllerState` is intended for use internally within `DDController`. To interface with controllers,
/// please call `DDController.startDaydreamControllerDiscovery()` and subscribe to the `DDControllerDidConnect`
/// notification. Then, access the touchpad and buttons from their associated values on `DDController`.
///
/// Note: Getting the `gyro`, `acceleration`, and `magnetometer` values are currently unsupported.
/// With some tweaks to the implementation of `getSignedDouble`, it may be possible to get correct values.
///
/// This class wouldn't be possible without Matteo Pisani's fantastic reverse engineering of the Daydream View controller:
/// https://hackernoon.com/how-i-hacked-google-daydream-controller-c4619ef318e4#.yjtxmhmec
///
internal class DDControllerState: CustomStringConvertible {
	/// The current point on the touchpad.
	/// Note: This value is equivalent to `CGPoint.zero` if the user's finger is not currently on the touchpad.
	private(set) var touchPoint: CGPoint
	
	/// The buttons currently being pressed on the controller.
	private(set) var buttons: Buttons
	
	/// The current values of the gyroscope.
	/// Bug: Gyroscope values are not currently parsed correctly.
	private(set) var gyro: CMAcceleration
	
	/// The current acceleration of the controller.
	/// Bug: Accelerometer values are not currently parsed correctly.
	private(set) var acceleration: CMAcceleration
	
	// The current values of the magnetometer.
	/// Bug: Magnetometer values are not currently parsed correctly.
	private(set) var magnetometer: CMAcceleration
	
	public var description: String {
		var result = "State: {"
		result += "\n\tGyro: (\(gyro.x), \(gyro.y), \(gyro.z))"
		result += "\n\tAcceleration: (\(acceleration.x), \(acceleration.y), \(acceleration.z))"
		result += "\n\tMagnetometer: (\(magnetometer.x), \(magnetometer.y), \(magnetometer.z))"
		result += "\n\tTouch: (\(touchPoint.x), \(touchPoint.y))"
		result += "\n\tButtons: \(buttons)"
		result += "\n}"
		return result
	}
	
	/// The bit string representing this controller state.
	private var bitstring: String
	
	/// A `OptionSet` used for representing which buttons are currently being pressed.
	struct Buttons: OptionSet, CustomStringConvertible {
		let rawValue: Int
		
		init(rawValue: Int) {
			self.rawValue = rawValue
		}
		
		var description: String {
			return String(rawValue, radix: 2)
		}
		
		static let click = Buttons(rawValue: 1 << 0)
		static let home = Buttons(rawValue: 1 << 1)
		static let app = Buttons(rawValue: 1 << 2)
		static let volumeDown = Buttons(rawValue: 1 << 3)
		static let volumeUp = Buttons(rawValue: 1 << 4)
	}
	
	/// The initializer for `DDControllerState`.
	/// - parameter data: A hex string from the Daydream View controller representing the state.
	init?(hexString: String) {
		do {
			bitstring = try DDControllerState.parse(hexString: hexString)
			
			let gyroX = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 14, to: 27)
			let gyroY = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 27, to: 40)
			let gyroZ = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 40, to: 53)
			gyro = CMAcceleration(x: gyroX, y: gyroY, z: gyroZ)
			
			let magX = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 53, to: 66)
			let magY = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 66, to: 79)
			let magZ = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 79, to: 92)
			magnetometer = CMAcceleration(x: magX, y: magY, z: magZ)
			
			let accX = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 92, to: 105)
			let accY = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 105, to: 118)
			let accZ = try DDControllerState.getSignedDouble(bitstring: bitstring, from: 118, to: 131)
			acceleration = CMAcceleration(x: accX, y: accY, z: accZ)
			
			let touchX = try DDControllerState.getInt(bitstring: bitstring, from: 131, to: 139)
			let touchY = try DDControllerState.getInt(bitstring: bitstring, from: 139, to: 147)
			touchPoint = CGPoint(x: touchX, y: touchY)
			
			// app only: 10000
			// app and home: 11000
			let buttonsBits = try DDControllerState.getInt(bitstring: bitstring, from: 147, to: 152)
			buttons = Buttons(rawValue: buttonsBits)
			
		} catch _ {
			return nil
		}
	}
	
	// MARK: - Parsing
	private enum ParseError: Error {
		case failed
	}
	
	/// Gets the bits between `from` and `to` in `bitstring` and returns the integer value.
	/// - parameter bitstring: A bitstring to be read.
	/// - parameter from: The start index, inclusive.
	/// - parameter to: The end index, exclusive.
	private class func getInt(bitstring: String, from: Int, to: Int) throws -> Int {
		let start = bitstring.index(bitstring.startIndex, offsetBy: from)
		let end = bitstring.index(bitstring.startIndex, offsetBy: to)
		//let part = bitstring.substring(with: start..<end)
        let part = bitstring[start..<end]
		guard let result = Int(part, radix: 2) else {
			throw ParseError.failed
		}
		return result
	}
	
	/// Gets the bits between `from` and `to` in `bitstring` and returns the signed double value.
	///
	/// Bug: This should interpret the bits as a two's complement value and return the signed double.
	///      It currently returns the same value as `getInt` would, causing `gyro`, `acceleration`, and `magnetometer`
	///      to be unsupported as of v1.0.
	///
	/// - parameter bitstring: A bitstring to be read.
	/// - parameter from: The start index, inclusive.
	/// - parameter to: The end index, exclusive.
	private class func getSignedDouble(bitstring: String, from: Int, to: Int) throws -> Double {
		let start = bitstring.index(bitstring.startIndex, offsetBy: from)
		let end = bitstring.index(bitstring.startIndex, offsetBy: to)
		//let part = bitstring.substring(with: start..<end)
		let part = bitstring[start..<end]
		guard let result = Int(part, radix: 2) else {
			throw ParseError.failed
		}
		
		// TODO: actually interpret the signed value. it's 13 bits, and the first is the sign.
		
		return Double(result)
	}
	
	/// Returns a bitstring from an input hex string.
	/// - parameter data: The input hex string.
	private class func parse(hexString: String) throws -> String {
		var bitchain = ""
		for i in stride(from: 2, to: hexString.count + 1, by: 2) {
			let start = hexString.index(hexString.startIndex, offsetBy: i-2)
			let end = hexString.index(hexString.startIndex, offsetBy: i)
			//let part = hexString.substring(with: start..<end)
            let part = hexString[start..<end]
			guard let hexInt = Int(part, radix: 16) else {
				throw ParseError.failed
			}
			let binString = String(hexInt, radix: 2)
			bitchain += DDControllerState.zeroPad(string: binString, to: 8)
		}
		return bitchain
	}
	
	/// Zero pads a bitstring to a given size.
	/// - parameter string: A bit string.
	/// - paramter size: The final desired zero-padded size.
	private class func zeroPad(string: String, to size: Int) -> String {
		var padded = string
		for _ in 0..<(size - string.count) {
			padded = "0" + padded
		}
		return padded
	}
}
