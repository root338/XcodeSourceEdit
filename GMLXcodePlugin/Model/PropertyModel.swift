//
//  PropertyDetailInfo.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/24.
//

import Foundation

struct PropertyDetailInfo {
    var unit: PropertyUnit
    var className: String
    /// 范型声明
    let declarClassName: String?
    /// 实际类名
    let actualClassName: String
    var existPointerMark: Bool
    var name: String
    var instanceVariableName: String
    
    func toOC() -> PropertyInfoModel {
        return PropertyInfoModel(
            units: unit.rawValueSet,
            className: className,
            existPointerMark: existPointerMark,
            declarClassName: declarClassName,
            actualClassName: actualClassName,
            name: name,
            instanceVariableName: instanceVariableName
        )
    }
}

struct PropertyMethod {
    let item: PropertyDetailInfo
    var getMethod: String?
    var setMethod: String?
}

class PropertyInfoModel : NSObject {
    let units: Set<String>?
    let mClassName : String
    /// 范型声明
    let declarClassName: String?
    /// 实际类名
    let actualClassName: String
    let existPointerMark : Bool
    let name : String
    let instanceVariableName: String
    init(units: Set<String>,
         className: String,
         existPointerMark: Bool,
         declarClassName: String?,
         actualClassName: String,
         name: String,
         instanceVariableName: String) {
        self.units = units
        self.mClassName = className
        self.existPointerMark = existPointerMark
        self.actualClassName = actualClassName
        self.declarClassName = declarClassName
        self.name = name
        self.instanceVariableName = instanceVariableName
        super.init()
    }
}
