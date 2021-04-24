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
    func analysisProperty(content: String) -> PropertyItem? {
        var text = content.deleteBlankCharacter
        text.removeLast()
        
        var propertyUnits : PropertyItem.PropertyUnit?
        func insert(unit: String) {
            let propertyUnit = PropertyItem.PropertyUnit(rawValue: unit)
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
        return PropertyItem(unit: propertyUnits, className: className.deleteBlankCharacter, existPointerMark: existPointerMark, name: name.deleteBlankCharacter)
    }
    /// 获取属性
    func selectionProperty(content: String) -> [PropertyItem] {
        var items = [PropertyItem]()
        findPropertyRE.enumerateMatches(in: content, options: .reportProgress, range: content.rangeAll) { (result, flag, pointer) in
            guard let textResult = result,
                  let propertyText = content.substring(range: textResult.range),
                  let item = analysisProperty(content: propertyText)
            else { return }
            items.append(item)
        }
        return items
    }
    /// 生成get方法
    func builderGetMethod(items: [PropertyItem], spaceCharactersCount: Int) -> (methods: [PropertyMethod], fullMethodText: String) {
        if items.count == 0 { return ([], "") }
        var methods = [PropertyMethod]()
        var methodText = String()
        
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
        
        for item in items {
            let isClass = item.existPointerMark
            let _name = "_\(item.name)"
            let method = addMethod()
            method.addLine(0) { "\n- (\(item.className)\(item.existPointerMark ? " *" : ""))\(item.name) {" }
            method.addLine(1) { "\(isClass ? "" : "<#")" }
            method.writeLine { "if (\(_name) == nil)\(isClass ? "" : "#>") {" }
            method.addLine(2) { "<##>" }
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
