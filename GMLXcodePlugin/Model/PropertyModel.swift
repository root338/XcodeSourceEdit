//
//  PropertyStruct.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/24.
//

import Foundation

struct PropertyStruct {
    struct Unit : OptionSet {
        var rawValue: String {
            return rawValueSet.joined(separator: ", ")
        }
        private(set) var rawValueSet: Set<String>
        
        static var atomic = Unit(rawValue: "atomic")
        static var nonatomic = Unit(rawValue: "nonatomic")
        static var copy = Unit(rawValue: "copy")
        static var strong = Unit(rawValue: "strong")
        static var assgin = Unit(rawValue: "assgin")
        static var weak = Unit(rawValue: "weak")
        static var nullable = Unit(rawValue: "nullable")
        static var readonly = Unit(rawValue: "readonly")
        static var readwrite = Unit(rawValue: "readwrite")
        
        init() {
            self.init(rawValue: "")
        }
        
        init(rawValue: String) {
            rawValueSet = Set(arrayLiteral: rawValue)
        }
        
        //MARK:- SetAlgebra
        mutating func formUnion(_ other: __owned PropertyStruct.Unit) {
            rawValueSet.formUnion(other.rawValueSet)
        }
        mutating func formIntersection(_ other: PropertyStruct.Unit) {
            rawValueSet.formIntersection(other.rawValueSet)
        }
        mutating func formSymmetricDifference(_ other: __owned PropertyStruct.Unit) {
            rawValueSet.formSymmetricDifference(other.rawValueSet)
        }
        func contains(_ member: PropertyStruct.Unit) -> Bool {
            return rawValueSet.isSuperset(of: member.rawValueSet)
        }
    }
    
    let unit : Unit?
    let className : String
    let existPointerMark : Bool
    let name : String
    
    func toOC() -> PropertyInfoModel {
        return PropertyInfoModel(
            units: unit?.rawValueSet,
            className: className,
            existPointerMark: existPointerMark,
            name: name
        )
    }
}

struct PropertyMethod {
    let item: PropertyStruct
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
