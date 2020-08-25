//
//  CharEncDec.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

// For encoding
extension String {
	var hexadecimal: Data? {
		var data = Data(capacity: self.count / 2)

		let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
		regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
			let byteString = (self as NSString).substring(with: match!.range)
			let num = UInt8(byteString, radix: 16)!
			data.append(num)
		}

		guard data.count > 0 else { return nil }

		return data
	}
}

// For decoding
func swapUInt32Data(data : Data) -> Data {
	var mdata = data // make a mutable copy
	let count = data.count / MemoryLayout<UInt32>.size
	mdata.withUnsafeMutableBytes { (i32ptr: UnsafeMutablePointer<UInt32>) in
		for i in 0..<count {
			i32ptr[i] = i32ptr[i].byteSwapped
		}
	}
	return mdata
}
