//
//  FileAnalysis.swift
//  GMLXcodeSourceEdit
//
//  Created by apple on 2020/5/22.
//  Copyright © 2020 GML. All rights reserved.
//

import Cocoa

enum FileAnalysisError : Error {
    case isEmpty
}

class FileAnalysis: NSObject {
    
    let content : String
    
    init(content: String) throws {
        guard !content.isEmpty else {
            throw FileAnalysisError.isEmpty
        }
        self.content = content
    }
    
    
}
