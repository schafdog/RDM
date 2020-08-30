//
//  Resolution.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

@objc class Resolution : NSObject {
	private var _width	   : UInt32
	private var _height	   : UInt32
	private var _hiDPIFlag : [UInt32]

	static private let _defaultHiDPIFlag : [UInt32] = [0x1, 0x200000]

	// For NSObject properties
	@objc var hiDPI : Bool

	@objc var width : UInt32 {
		get {
			return hiDPI ? _width / 2 : _width
		}

		set(value) {
			_width = hiDPI ? value * 2 : value
		}
	}

	@objc var height : UInt32 {
		get {
			return hiDPI ? _height / 2 : _height
		}

		set(value) {
			_height = hiDPI ? value * 2 : value
		}
	}

	override init() {
		self.hiDPI = false

		self._width = 0
		self._height = 0
		self._hiDPIFlag = Resolution._defaultHiDPIFlag

		super.init()
	}

	private init(width : UInt32, height : UInt32, hiDPI : Bool, origin : [UInt32]) {
		self.hiDPI		= hiDPI

		self._width		= width
		self._height	= height
		self._hiDPIFlag = hiDPI && (origin.count > 2)
			? Array(origin[2...]) : Resolution._defaultHiDPIFlag // For hiDPI toggle feature

		super.init()
	}

	convenience init(nsdata : NSData?) {
		if nsdata != nil {
			let d = swapUInt32Data(data: nsdata! as Data)
			let count = d.count / MemoryLayout<UInt32>.size

			var array = [UInt32](repeating: 0, count: count)
			(d as NSData).getBytes(&array, length: d.count)

			self.init(width:  array[0],
					  height: array[1],
					  hiDPI:  array.count > 2 && array[2...].allSatisfy { $0 != 0 },
					  origin: array)
		} else {
			self.init()
		}
	}

	func toData() -> NSData {
		var d = Data()

		d.append(String(format: "%08X", self._width).hexadecimal!)
		d.append(String(format: "%08X", self._height).hexadecimal!)
		if self.hiDPI {
			for flag in _hiDPIFlag {
				d.append(String(format: "%08X", flag).hexadecimal!)
			}
		}

		return d as NSData
	}

	static func ==(lhs: Resolution, rhs: Resolution) -> Bool {
		return (lhs._height	  == rhs._height	  )
			&& (lhs._width	  == rhs._width	  )
			&& (lhs._hiDPIFlag == rhs._hiDPIFlag)
	}
}
