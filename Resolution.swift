//
//  Resolution.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

@objc class Resolution : NSObject {
	@objc var width		: UInt32
	@objc var height	: UInt32
	@objc var hiDPI		: Bool
		  var hiDPIFlag : [UInt32]

	static let defaultHDPIFlag : [UInt32] = [0x1, 0x200000]

	init(width : UInt32 = 0, height : UInt32 = 0, hiDPI : Bool = false, origin : [UInt32] = []) {
		self.width	   = width
		self.height	   = height
		self.hiDPI	   = hiDPI
		self.hiDPIFlag = hiDPI && (origin.count > 2) ? Array(origin[2...]) : Resolution.defaultHDPIFlag // For hiDPI toggle feature

		super.init()
	}

	static func parse(nsdata : NSData?) -> Resolution {
		if nsdata != nil {
			let d = swapUInt32Data(data: nsdata! as Data)
			let count = d.count / MemoryLayout<UInt32>.size

			var array = [UInt32](repeating: 0, count: count)
			(d as NSData).getBytes(&array, length: d.count)

			return Resolution(width:  array[0],
							  height: array[1],
							  hiDPI:  array.count > 2 && array[2...].allSatisfy({ $0 != 0 }),
							  origin: array)
		}

		return Resolution()
	}

	func toData() -> NSData {
		var d = Data()

		d.append(String(format: "%08X", self.width).hexadecimal!)
		d.append(String(format: "%08X", self.height).hexadecimal!)
		if self.hiDPI {
			for flag in hiDPIFlag {
				d.append(String(format: "%08X", flag).hexadecimal!)
			}
		}

		return d as NSData
	}
}

func ==(lhs: Resolution, rhs: Resolution) -> Bool {
	return (lhs.height == rhs.height)
		&& (lhs.width == rhs.width)
		&& (lhs.hiDPI == rhs.hiDPI)
}

func !=(lhs: Resolution, rhs: Resolution) -> Bool {
	return !(lhs == rhs)
}
