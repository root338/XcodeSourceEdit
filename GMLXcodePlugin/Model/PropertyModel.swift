//
//  PropertyItem.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/24.
//

import Foundation

struct PropertyItem {
    struct PropertyUnit : OptionSet {
        var rawValue: String
        var rawValueSet: Set<String>
        mutating func formUnion(_ other: __owned PropertyItem.PropertyUnit) {
            
            rawValueSet.formUnion(other.rawValueSet)
        }
        
        mutating func formIntersection(_ other: PropertyItem.PropertyUnit) {
            rawValueSet.formIntersection(other.rawValueSet)
        }
        
        mutating func formSymmetricDifference(_ other: __owned PropertyItem.PropertyUnit) {
            rawValueSet.formSymmetricDifference(other.rawValueSet)
        }
        func contains(_ member: PropertyItem.PropertyUnit) -> Bool {
            return rawValueSet.isSuperset(of: member.rawValueSet)
        }
        
        init() {
            self.init(rawValue: "")
        }
        
        init(rawValue: String) {
            self.rawValue = rawValue
            rawValueSet = Set(arrayLiteral: rawValue)
        }
        
        static var atomic = PropertyUnit(rawValue: "atomic")
        static var nonatomic = PropertyUnit(rawValue: "nonatomic")
        static var copy = PropertyUnit(rawValue: "copy")
        static var strong = PropertyUnit(rawValue: "strong")
        static var assgin = PropertyUnit(rawValue: "assgin")
        static var weak = PropertyUnit(rawValue: "weak")
        static var nullable = PropertyUnit(rawValue: "nullable")
        static var readonly = PropertyUnit(rawValue: "readonly")
        static var readwrite = PropertyUnit(rawValue: "readwrite")
    }
    
    let unit : PropertyUnit?
    let className : String
    let existPointerMark : Bool
    let name : String
    
    func toOC() -> PropertyInfoModel {
        return PropertyInfoModel(units: unit?.rawValueSet,
                                 className: className,
                                 existPointerMark: existPointerMark,
                                 name: name)
    }
}

struct PropertyMethod {
    let item: PropertyItem
    var getMethod: String?
    var setMethod: String?
}

class PropertyInfoModel : NSObject {
    let units: Set<String>?
    let mClassName : String
    let existPointerMark : Bool
    let name : String
    init(units: Set<String>?, className: String, existPointerMark: Bool, name: String) {
        self.units = units
        self.mClassName = className
        self.existPointerMark = existPointerMark
        self.name = name
        super.init()
    }
}
