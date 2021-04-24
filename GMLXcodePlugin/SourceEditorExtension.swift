//
//  SourceEditorExtension.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/23.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    /*
    func extensionDidFinishLaunching() {
        // If your extension needs to do any work at launch, implement this optional method.
    }
    */
    
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return [
            commandInfo(name: "Get Property Method", className: PropertyGetCommand.self)
        ]
    }
}

private extension SourceEditorExtension {
    func commandInfo(name: String, className: AnyClass) -> [XCSourceEditorCommandDefinitionKey : Any] {
        let classNameStr = NSStringFromClass(className)
        return commandInfo(name: name,
                           identifier: classNameStr,
                           className: classNameStr)
    }
    
    func commandInfo(name: String, identifier: String, className: String) -> [XCSourceEditorCommandDefinitionKey : Any] {
        return [
            .nameKey : name,
            .identifierKey : identifier.linkMyDomainName,
            .classNameKey : className
        ]
    }
    
    
}

private extension String {
    var linkMyDomainName : String {
        return "com.gml.xcodeplugin.xcodesourceEdit." + self
    }
}
