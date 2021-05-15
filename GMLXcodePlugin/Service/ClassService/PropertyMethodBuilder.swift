//
//  PropertyMethodBuilder.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/24.
//

import Foundation
import XcodeKit

class PropertyMethodBuilder: NSObject {
    lazy var analysisService = OCFileAnalysisService()
    lazy var searchTextService = SearchTextRangeService()
    lazy var codeHelper = CreationCodeHelper()
    
    convenience init(config: (Self) -> Void) {
        self.init()
        config(self)
    }
}

extension PropertyMethodBuilder {
    func builderGetMethod(invocation: XCSourceEditorCommandInvocation) throws {
        let buffer = invocation.buffer
        func propertyGetMethod(text: String) {
            let (info, _) = analysisService.fileInfo(
                content: text,
                configuration: FileAnalysisConfiguration(
                    import: nil,
                    globalVariable: nil,
                    macro: nil,
                    typeDeclaration: nil,
                    typedef: nil,
                    protocol: nil,
                    class: ClassAnalysisConfiguration(
                        isGetClassInfo: true,
                        property: PropertyAnalysisConfiguration(),
                        method: nil
                    )
                )
            )
            if info.classStructs.count == 0 {
                let propertyInfo = analysisService.propertyStruct(content: text, configuration: PropertyAnalysisConfiguration())
                buffer.completeBuffer.append(
                    builderGetMethod(
                        items: transform(obj: propertyInfo) { $0.info },
                        spaceCharactersCount: buffer.tabWidth
                    ).fullMethodText
                )
            }else {
                let propertyDict = analysisService.mergeProperty(list: info.classStructs) { $0.info }
                for (className, propertys) in propertyDict {
                    searchTextService.classEndIndex(
                        content: text,
                        fileStruct: info) { (classStruct, _) in
                        guard let classInfo = classStruct?.info else { return false }
                        return classInfo.type == .implementation && classInfo.className == className
                    } result: { (classStruct, index) -> Bool in
                        let (_, text) = builderGetMethod(
                            items: transform(obj: propertys, analysisProperty: { $0 }),
                            spaceCharactersCount: buffer.tabWidth)
                        buffer.completeBuffer.insert(contentsOf: text, at: index)
                        return false
                    }
                }
                
            }
        }
        if buffer.selections.count > 0,
           buffer.selections.count == 1
            && !(buffer.selections.firstObject as! XCSourceTextRange).unselectedCharacters {
            guard let selectTexts = selectContentText(invocation: invocation) else { return }
            for selectText in selectTexts {
                propertyGetMethod(text: selectText)
            }
        }else {
            propertyGetMethod(text: buffer.completeBuffer)
        }
    }
}
//MARK:- Handle File
fileprivate extension PropertyMethodBuilder {
    /// 获取选择的文本数组
    func selectContentText(invocation: XCSourceEditorCommandInvocation) -> [String]? {
        let buffer = invocation.buffer
        guard let selections = buffer.selections as? [XCSourceTextRange] else { return nil }
        guard let lines = buffer.lines as? [String] else { return nil }
        var selectTexts = [String]()
        for textRange in selections {
            var selectText = String()
            for line in textRange.start.line ... textRange.end.line {
                var start: Int? = nil
                var end: Int? = nil
                if line == textRange.start.line {
                    start = textRange.start.column
                }
                if line == textRange.end.line {
                    end = textRange.end.column
                }
                let lineText = lines[line]
                guard let text = lineText.substring(from: start, to: end) else { continue }
                selectText.append(text)
            }
            selectTexts.append(selectText)
        }
        return selectTexts
    }
}
//MARK:- Method Builder
fileprivate extension PropertyMethodBuilder {
    
    // IMP 方法类型声明
    typealias CreationCodeMethodType = @convention(c) (AnyObject, Selector, Any?) -> String

    /// 生成get方法
    func builderGetMethod(items: [PropertyDetailInfo], spaceCharactersCount: Int) -> (methods: [PropertyMethod], fullMethodText: String) {
        if items.count == 0 { return ([], "") }
        var methods = [PropertyMethod]()
        var methodText = String()
        /**
         * 方法代码块
         * 获取生成的方法代码块(text: () -> String)
         * addLine: (Int, () -> String) -> Void 添加新的一行，传入前面包换几个 tab 键， 后面的方法返回这行实际内容
         * writeLine: (() -> String) -> Void 在已存在的最后一行继续添加代码
         */
        func addMethod() -> (text: () -> String, addLine: (Int, () -> String) -> Void, writeLine: (() -> String) -> Void) {
            var method = ""
            func addLine(_ tabCount: Int, setContent: () -> String) {
                if !method.isEmpty {
                    method.append("\n")
                }
                var text = " ".copy(count: spaceCharactersCount * tabCount)
                text.append(setContent())
                method.append(text)
            }
            func line(setContent: () -> String) {
                method.append(setContent())
            }
            return ({
                method
            }, addLine(_:setContent:), line(setContent:))
        }
        // 为代码块每行前面添加 tabCount * spaceCharactersCount 数量的空格
        func config(code: String, tabCount: Int) -> String {
            var newCode = String()
            var tmpCode = code
            let spaceCharacters = " ".copy(count: tabCount * spaceCharactersCount)
            
            func insert(line: String) {
                newCode.append(spaceCharacters)
                newCode.append(line)
            }
            while true {
                if let lineInfo = tmpCode.removeInFirst(to: "\n") {
                    insert(line: lineInfo.string)
                }else {
                    insert(line: tmpCode)
                    break
                }
            }
            return newCode
        }
        
        for item in items {
            
            let isClass = item.existPointerMark
            let _name = item.instanceVariableName
            let method = addMethod()
            method.addLine(0) { "\n- (\(item.className)\(item.existPointerMark ? " *" : ""))\(item.name) {" }
            method.addLine(1) { "\(isClass ? "" : "<#")" }
            method.writeLine { "if (\(_name) == nil)\(isClass ? "" : "#>") {" }
            
            let selector = NSSelectorFromString("get\(item.actualClassName)CreationCode:")
            if codeHelper.responds(to: selector) {
                let setMethod = unsafeBitCast(codeHelper.method(for: selector), to: CreationCodeMethodType.self)
                let code = setMethod(codeHelper, selector, item.toOC())
                method.addLine(0) { config(code: code, tabCount: 2) }
            }else {
                method.addLine(2) { "<#\(_name) = \(item.actualClassName).new;#>" }
            }
            method.addLine(1) { "}" }
            method.addLine(0) { "}\n" }
            methods.append(PropertyMethod(item: item, getMethod: method.text(), setMethod: nil))
            methodText.append(method.text())
        }
        return (methods, methodText)
    }
}
//MARK:- Property Info
fileprivate extension PropertyMethodBuilder {
    func transform<T>(obj: [T], analysisProperty: (T) -> PropertyInfo?) -> [PropertyDetailInfo] {
        var arr = [PropertyDetailInfo]()
        for item in obj {
            guard let propertyInfo = analysisProperty(item),
                  propertyInfo.className != nil,
                  propertyInfo.isExistPointerMark != nil
            else { continue }
            arr.append(
                PropertyDetailInfo(
                    unit: propertyInfo.unit ?? [],
                    className: propertyInfo.className!,
                    declarClassName: propertyInfo.declarClassName,
                    actualClassName: propertyInfo.actualClassName!,
                    existPointerMark: propertyInfo.isExistPointerMark!,
                    name: propertyInfo.name,
                    instanceVariableName: propertyInfo.instanceVariableName ?? "_\(propertyInfo.name)"
                )
            )
        }
        return arr
    }
}
