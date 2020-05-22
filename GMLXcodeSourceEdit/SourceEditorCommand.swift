//
//  SourceEditorCommand.swift
//  GMLXcodeSourceEdit
//
//  Created by apple on 2020/5/22.
//  Copyright © 2020 GML. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        
        completionHandler(nil)
    }
    
}
