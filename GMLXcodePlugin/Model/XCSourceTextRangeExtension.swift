//
//  XCSourceTextRangeExtension.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/24.
//

import XcodeKit

extension XCSourceTextRange {
    var unselectedCharacters: Bool {
        return start.line == end.line && start.column == end.column
    }
}
