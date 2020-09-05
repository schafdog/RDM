//
//  Resolution.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

@objc class Resolution : NSObject {
    private var _width     : UInt32
    private var _height    : UInt32
    private var _hiDPI     : Bool
    private var _hiDPIFlag : [UInt32]

    static private let _defaultHiDPIFlag : [UInt32] = [0x1, 0x200000]

    // For NSObject properties

    @objc var width : UInt32 {
        get {
            return _hiDPI ? _width / 2 : _width
        }

        set(value) {
            _width = _hiDPI ? value * 2 : value
        }
    }

    @objc var height : UInt32 {
        get {
            return _hiDPI ? _height / 2 : _height
        }

        set(value) {
            _height = _hiDPI ? value * 2 : value
        }
    }

    @objc var hiDPI : Bool {
        get {
            return _hiDPI
        }

        set(value) {
            if _hiDPI != value {
                _hiDPI = value

                if value {
                    _width  *= 2
                    _height *= 2
                } else {
                    _width  /= 2
                    _height /= 2
                }
            }
        }
    }

    override init() {
        self._width = 0
        self._height = 0
        self._hiDPI = false
        self._hiDPIFlag = Resolution._defaultHiDPIFlag

        super.init()
    }

    private init(width : UInt32, height : UInt32, hiDPI : Bool, origin : [UInt32]) {
        self._width     = width
        self._height     = height
        self._hiDPI     = hiDPI
        self._hiDPIFlag = hiDPI && (origin.count > 2)
            ? Array(origin[2...]) : Resolution._defaultHiDPIFlag // For hiDPI toggle feature

        super.init()
    }

    convenience init(nsdata : NSData?) {
        if let nsdata = nsdata {
            let array = nsdata.getArrayOfSwappedBytes(asType: UInt32.self)
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
        if self._hiDPI {
            for flag in _hiDPIFlag {
                d.append(String(format: "%08X", flag).hexadecimal!)
            }
        }

        return d as NSData
    }

    static func ==(lhs: Resolution, rhs: Resolution) -> Bool {
        return (lhs._height    == rhs._height   )
            && (lhs._width     == rhs._width    )
            && (lhs._hiDPIFlag == rhs._hiDPIFlag)
    }
}
