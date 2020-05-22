//
//  SourceEditorExtension.swift
//  GMLXcodeSourceEdit
//
//  Created by apple on 2020/5/22.
//  Copyright © 2020 GML. All rights reserved.
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
            commandInfo(name: "实现Copy协议", className: CopyEditorCommand.self),
            commandInfo(name: "get生成器", className: GetMethodBuilder.self)
        ]
    }
}

private extension SourceEditorExtension {
    func commandInfo(name: String, className: AnyClass) -> [XCSourceEditorCommandDefinitionKey : Any] {
        return commandInfo(name: name,
                           identifier: NSStringFromClass(className),
                           className: className)
    }
    
    func commandInfo(name: String, identifier: String, className: AnyClass) -> [XCSourceEditorCommandDefinitionKey : Any] {
        return [
            .nameKey : name,
            .identifierKey : identifier.linkMyDomainName,
            .classNameKey : className
        ]
    }
    
    
}

private extension String {
    var linkMyDomainName : String {
        return "com.gml.xcodesourceEdit." + self
    }
}
