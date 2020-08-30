//
//  Utils.swift
//  RDM-2
//
//  Created by JNR on 26/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

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
