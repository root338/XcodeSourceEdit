//
//  PropertyMethodBuilder.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/24.
//

import Foundation
import XcodeKit

class PropertyMethodBuilder: NSObject {
    lazy var findPropertyRE: NSRegularExpression = {
        let pattern = "@property[^;]*;"
        return try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
    }()
    lazy var findPropertyUnitRE: NSRegularExpression = {
        let pattern = "\\([^\\)\\(]+\\)"
        return try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
    }()
    lazy var codeHelper = CreationCodeHelper()
    
    convenience init(config: (Self) -> Void) {
        self.init()
        config(self)
    }
}

extension PropertyMethodBuilder {
    func builderGetMethod(invocation: XCSourceEditorCommandInvocation) throws {
        let buffer = invocation.buffer
        var methodText = String()
        
        func propertyGetMethod(text: String) {
            methodText.append(builderGetMethod(
                items: selectionProperty(content: text),
                spaceCharactersCount: buffer.tabWidth
            ).fullMethodText)
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
        if methodText.count == 0 { return }
        buffer.completeBuffer.append(methodText)
    }
}

fileprivate extension PropertyMethodBuilder {
    /// 获取选择的文本数组
    func selectContentText(invocation: XCSourceEditorCommandInvocation) -> [String]? {
        let buffer = invocation.buffer
        guard let selections = buffer.selections as? [XCSourceTextRange] else { return nil }
        guard let lines = buffer.lines as? [String] else { return nil }
        var selectTexts = [String]()
        for textRange in selections {
            var selectText = String()
            for line in textRange.start.line..<textRange.end.line {
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

fileprivate extension PropertyMethodBuilder {
    /// 解析属性内部有哪些内容
    func analysisProperty(content: String) -> PropertyStruct? {
        var text = content.deleteBlankCharacter
        text.removeLast()
        
        var propertyUnits : PropertyStruct.Unit?
        func insert(unit: String) {
            let propertyUnit = PropertyStruct.Unit(rawValue: unit)
            if propertyUnits == nil {
                propertyUnits = propertyUnit
            }else {
                propertyUnits?.insert(propertyUnit)
            }
        }
        if let result = findPropertyUnitRE.firstMatch(in: text, options: .reportProgress, range: text.rangeAll),
           let unitText = text.substring(range: result.range)?.substring(startOffset: 1, endOffset: 1) {
            let units = unitText.split(separator: ",")
            for unit in units {
                let onlyUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
                if onlyUnit.count == 0 { continue }
                insert(unit: onlyUnit)
            }
            guard let substring = text.substring(from: result.range.upperBound)?.deleteBlankCharacter else { return nil }
            text = substring
        }
        let existPointerMark: Bool
        let className: String
        let name: String
        if var pointerIndex = text.firstIndex(of: "*") {
            existPointerMark = true
            className = String(text[text.startIndex..<pointerIndex])
            text.formIndex(&pointerIndex, offsetBy: 1)
            name = String(text[pointerIndex..<text.endIndex])
        }else {
            existPointerMark = false
            guard let _className = text.substring(to: " ", includeMark: false) else { return nil }
            guard let _name = text.substring(from: " ", includeMark: false) else { return nil }
            className = _className
            name = _name
        }
        return PropertyStruct(unit: propertyUnits, className: className.deleteBlankCharacter, existPointerMark: existPointerMark, name: name.deleteBlankCharacter)
    }
    /// 获取属性
    func selectionProperty(content: String) -> [PropertyStruct] {
        var items = [PropertyStruct]()
        findPropertyRE.enumerateMatches(in: content, options: .reportProgress, range: content.rangeAll) { (result, flag, pointer) in
            guard let textResult = result,
                  let propertyText = content.substring(range: textResult.range),
                  let item = analysisProperty(content: propertyText)
            else { return }
            items.append(item)
        }
        return items
    }
    
    // IMP 方法类型声明
    typealias CreationCodeMethodType = @convention(c) (AnyObject, Selector, Any?) -> String

    /// 生成get方法
    func builderGetMethod(items: [PropertyStruct], spaceCharactersCount: Int) -> (methods: [PropertyMethod], fullMethodText: String) {
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
            let _name = "_\(item.name)"
            let method = addMethod()
            method.addLine(0) { "\n- (\(item.className)\(item.existPointerMark ? " *" : ""))\(item.name) {" }
            method.addLine(1) { "\(isClass ? "" : "<#")" }
            method.writeLine { "if (\(_name) == nil)\(isClass ? "" : "#>") {" }
            
            let selector = NSSelectorFromString("get\(item.className)CreationCode:")
            if codeHelper.responds(to: selector) {
                let setMethod = unsafeBitCast(codeHelper.method(for: selector), to: CreationCodeMethodType.self)
                let code = setMethod(codeHelper, selector, item.toOC())
                method.addLine(0) { config(code: code, tabCount: 2) }
            }else {
                method.addLine(2) { "<#\(_name) = [\(item.className) ];#>" }
            }
            method.addLine(1) { "}" }
            method.addLine(0) { "}" }
            methods.append(PropertyMethod(item: item, getMethod: method.text(), setMethod: nil))
            methodText.append(method.text())
        }
        return (methods, methodText)
    }
    
    
    /**
     static inline id _MASBoxValue(const char *type, ...) {
         va_list v;
         va_start(v, type);
         id obj = nil;
         if (strcmp(type, @encode(id)) == 0) {
             id actual = va_arg(v, id);
             obj = actual;
         } else if (strcmp(type, @encode(CGPoint)) == 0) {
             CGPoint actual = (CGPoint)va_arg(v, CGPoint);
             obj = [NSValue value:&actual withObjCType:type];
         } else if (strcmp(type, @encode(CGSize)) == 0) {
             CGSize actual = (CGSize)va_arg(v, CGSize);
             obj = [NSValue value:&actual withObjCType:type];
         } else if (strcmp(type, @encode(MASEdgeInsets)) == 0) {
             MASEdgeInsets actual = (MASEdgeInsets)va_arg(v, MASEdgeInsets);
             obj = [NSValue value:&actual withObjCType:type];
         } else if (strcmp(type, @encode(double)) == 0) {
             double actual = (double)va_arg(v, double);
             obj = [NSNumber numberWithDouble:actual];
         } else if (strcmp(type, @encode(float)) == 0) {
             float actual = (float)va_arg(v, double);
             obj = [NSNumber numberWithFloat:actual];
         } else if (strcmp(type, @encode(int)) == 0) {
             int actual = (int)va_arg(v, int);
             obj = [NSNumber numberWithInt:actual];
         } else if (strcmp(type, @encode(long)) == 0) {
             long actual = (long)va_arg(v, long);
             obj = [NSNumber numberWithLong:actual];
         } else if (strcmp(type, @encode(long long)) == 0) {
             long long actual = (long long)va_arg(v, long long);
             obj = [NSNumber numberWithLongLong:actual];
         } else if (strcmp(type, @encode(short)) == 0) {
             short actual = (short)va_arg(v, int);
             obj = [NSNumber numberWithShort:actual];
         } else if (strcmp(type, @encode(char)) == 0) {
             char actual = (char)va_arg(v, int);
             obj = [NSNumber numberWithChar:actual];
         } else if (strcmp(type, @encode(bool)) == 0) {
             bool actual = (bool)va_arg(v, int);
             obj = [NSNumber numberWithBool:actual];
         } else if (strcmp(type, @encode(unsigned char)) == 0) {
             unsigned char actual = (unsigned char)va_arg(v, unsigned int);
             obj = [NSNumber numberWithUnsignedChar:actual];
         } else if (strcmp(type, @encode(unsigned int)) == 0) {
             unsigned int actual = (unsigned int)va_arg(v, unsigned int);
             obj = [NSNumber numberWithUnsignedInt:actual];
         } else if (strcmp(type, @encode(unsigned long)) == 0) {
             unsigned long actual = (unsigned long)va_arg(v, unsigned long);
             obj = [NSNumber numberWithUnsignedLong:actual];
         } else if (strcmp(type, @encode(unsigned long long)) == 0) {
             unsigned long long actual = (unsigned long long)va_arg(v, unsigned long long);
             obj = [NSNumber numberWithUnsignedLongLong:actual];
         } else if (strcmp(type, @encode(unsigned short)) == 0) {
             unsigned short actual = (unsigned short)va_arg(v, unsigned int);
             obj = [NSNumber numberWithUnsignedShort:actual];
         }
         va_end(v);
         return obj;
     }
     */
}
