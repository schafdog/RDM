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

func execAppleScript(_ script: String, withAdminPriv: Bool = false) -> NSDictionary? {
	var scr = script.trimmingCharacters(in: .whitespaces)

	let adminSuffix = " with administrator privileges"
	if withAdminPriv && (!scr.hasSuffix(adminSuffix)) {
		scr += adminSuffix
	}

	if let scriptObject = NSAppleScript(source: scr) {
		var error: NSDictionary?
		scriptObject.executeAndReturnError(&error)
		return error
	}

	return NSDictionary()
}

// For convenience
func execShellScript(_ script: String, withAdminPriv: Bool = false) -> NSDictionary? {
	return execAppleScript("do shell script \"\(script)\"", withAdminPriv: withAdminPriv)
}

func constructAlert(_ errDict: NSDictionary, style: NSAlert.Style = .critical) -> NSAlert {
	let alert = NSAlert()
	alert.alertStyle = style

	if let reason = errDict.object(forKey: "NSAppleScriptErrorBriefMessage") {
		alert.messageText = reason as! String
	} else {
		alert.messageText = "Unknown error, please try again."
		print(errDict)
	}

	return alert
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
