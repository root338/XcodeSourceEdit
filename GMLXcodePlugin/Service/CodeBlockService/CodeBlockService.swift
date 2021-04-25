//
//  CodeBlockService.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/25.
//

import Foundation

protocol PropertyMethodService {
    func get() -> Self
    func set() -> Self
    
}

class CodeBlockService: NSObject {
    var tabWidth = 4
    
}

extension CodeBlockService {
//    func builderMethod(_ item: PropertyStruct, setCodeBlock: () -> Void) -> String {
//        
//    }
}
