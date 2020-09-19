//
//  Utils.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import AppKit

let disabledProtections = [
    "System Integrity Protection status: disabled.",
    "System Integrity Protection status: disabled (Apple Internal).",
    "Filesystem Protections: disabled"
]

func isSIPActive() -> Bool {
    let p = Process()
    let pipe = Pipe()

    p.launchPath = "/bin/bash"
    p.arguments = ["-c", "csrutil status"]
    p.standardOutput = pipe
    p.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()

    return p.terminationStatus == 0 &&
        String(data: data, encoding: .utf8)!.split(separator: "\n").allSatisfy({
            return !disabledProtections.contains($0.trimmingCharacters(in: .whitespaces))
        })
}

func getAppSupportDir(withTrailingPath suffix: String = "") -> URL {
    if let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
        return URL(fileURLWithPath: appSupportDir).appendingPathComponent(suffix).standardizedFileURL
    } else {
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support") // Default
                                                      .appendingPathComponent(suffix)
                                                      .standardizedFileURL
    }
}

extension NSAppleScript {
    private static let adminSuffix = " with administrator privileges"

    enum ScriptType {
        case apple
        case shell

        public var prefix: String {
            switch self {
            case .shell:
                return "do shell script \""
            default:
                return ""
            }
        }

        public var suffix: String {
            switch self {
            case .shell:
                return "\""
            default:
                return ""
            }
        }
    }

    convenience init?(source: String, asType: ScriptType = .shell, withAdminPriv: Bool = false) {
        var scr = asType.prefix + source.trimmingCharacters(in: .whitespaces) + asType.suffix
        if withAdminPriv && !scr.hasSuffix(NSAppleScript.adminSuffix) {
            scr += NSAppleScript.adminSuffix
        }
        self.init(source: scr)
    }

    static func executeAndReturnError(source: String, asType: ScriptType = .shell, withAdminPriv: Bool = false) -> NSDictionary? {
        var error: NSDictionary? = nil
        if let script = NSAppleScript(source: source, asType: asType, withAdminPriv: withAdminPriv) {
            script.executeAndReturnError(&error)
        } else {
            error = NSDictionary()
        }
        return error
    }
}

public extension NSAlert {
    @objc convenience init(fromDict: NSDictionary, style: Style = .critical) {
        self.init()

        self.window.level = .floating
        self.alertStyle = style

        if let reason = fromDict.object(forKey: "NSAppleScriptErrorBriefMessage") {
            self.messageText = reason as! String
        } else {
            self.messageText = "Unknown error, please try again."
            print(fromDict)
        }
    }
}

extension Array {
    mutating func remove(at idxs: IndexSet) {
        guard var i = idxs.first, i < count else { return }

        var j = index(after: i)
        var k = idxs.integerGreaterThan(i) ?? endIndex

        while j != endIndex {
            if k != j {
                swapAt(i, j)
                formIndex(after: &i)
            } else {
                k = idxs.integerGreaterThan(k) ?? endIndex
            }
            formIndex(after: &j)
        }

        removeSubrange(i...)
    }
}

func gcdForResolution<T:BinaryInteger>(_ a: T, _ b: T, _ checkConvention: Bool = true) -> T {
    if a == 0 {
        return b
    } else if b == 0 {
        return a
    }

    // Resolution-specific
    if checkConvention {
        if a % 16 == 0 && a * 5 == b * 8 {
            return gcdForResolution(a / 16, b / 10, false)
        } else if a % 21 == 0 && a * 3 == b * 7 {
            return gcdForResolution(a / 21, b / 9, false)
        }
    }

    let r = a % b
    if r != 0 {
        return gcdForResolution(b, r, checkConvention)
    } else {
        return b
    }
}

extension Array where Element: BinaryInteger {
    mutating func simplify() {
        let gcd = self[1...].reduce(self[0]) { gcdForResolution($0, $1) }

        guard gcd != 0 && gcd != 1 && gcd != -1 else { return }

        for i in 0..<self.count {
            self[i] /= gcd
        }
    }
}
