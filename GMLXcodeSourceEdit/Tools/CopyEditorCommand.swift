//
//  CopyEditorCommand.swift
//  GMLXcodeSourceEdit
//
//  Created by apple on 2020/5/22.
//  Copyright © 2020 GML. All rights reserved.
//

import Cocoa
import XcodeKit

class CopyEditorCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        
        completionHandler(nil)
    }
    
}
