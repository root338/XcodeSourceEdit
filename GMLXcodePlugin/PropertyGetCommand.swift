//
//  PropertyGetCommand.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/23.
//

import Foundation
import XcodeKit

class PropertyGetCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        try! PropertyMethodBuilder().builderGetMethod(invocation: invocation)
        
        completionHandler(nil)
    }
    
}
