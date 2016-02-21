//
//  Model.swift
//  Dynamic
//
//  Created by Bradley Hilton on 7/20/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

/**
    Enables dynamic, KVC-style behavior for native Swift classes and structures.

    Keep in mind the following caveats:
    - All properties must conform to the Property protocol
    - Properties may not be implicitly unwrapped optionals
*/
public protocol Model : Property
{
    // Required for decoding
    init()
}

extension Model {
    
    /** 
        Subscript for getting and setting model properties
    */
    public subscript (key: String) -> Property? {
        get {
            do {
                return try valueForKey(key)
            } catch {
                return nil
            }
        }
        set {
            do {
                try setValue(newValue, forKey: key)
            } catch {
                
            }
        }
    }
    
    public mutating func setValue(value: Property?, forKey key: String) throws {
        var offset = 0
        for child in Mirror(reflecting: self).children {
            guard let property = child.value.dynamicType as? Property.Type else { throw Error.TypeDoesNotConformToProperty(type: child.value.dynamicType) }
            if child.label == key {
                try self.codeValue(value, type: property, offset: offset)
                return
            } else {
                offset += property.size()
            }
        }
    }
    
    mutating func pointerAdvancedBy(offset: Int) -> UnsafePointer<Int> {
        if let object = self as? AnyObject {
            return UnsafePointer(bitPattern: unsafeAddressOf(object).hashValue).advancedBy(offset + 2)
        } else {
            return withUnsafePointer(&self) { UnsafePointer($0).advancedBy(offset) }
        }
    }
    
    mutating func codeValue(value: Property?, type: Any.Type, offset: Int) throws {
        let pointer = pointerAdvancedBy(offset)
        if let optionalPropertyType = type as? OptionalProperty.Type, let propertyType = optionalPropertyType.propertyType() {
            if var optionalValue = value {
                try x(optionalValue, isY: propertyType)
                optionalValue.codeOptionalInto(pointer)
            } else if let nilValue = type as? OptionalProperty.Type {
                nilValue.codeNilInto(pointer)
            }
        } else if var sureValue = value {
            try x(sureValue, isY: type)
            sureValue.codeInto(pointer)
        }
    }
    
    func x(x: Any, isY y: Any.Type) throws {
        if x.dynamicType == y {
        } else if let x = x as? AnyObject, let y = y as? AnyClass where x.isKindOfClass(y) {
        } else {
            throw Error.CannotSetTypeAsType(x: x.dynamicType, y: y)
        }
    }
    
    public func valueForKey(key: String) throws -> Property? {
        var value: Property?
        for child in Mirror(reflecting: self).children {
            if child.label == key && String(child.value) != "nil" {
                if let property = child.value as? OptionalProperty {
                    value = property.property()
                } else if let property = child.value as? Property {
                    value = property
                } else {
                    throw Error.TypeDoesNotConformToProperty(type: child.value.dynamicType)
                }
                break
            }
        }
        return value
    }
    
    public func encode() throws -> [String: Any]
    {
        var dict: [String: Any] = [:]
        
        for child in Mirror(reflecting: self).children
        {
            if let label = child.label
            {
                if let value = child.value as? Model
                {
                    dict[label] = try value.encode()
                    continue
                }
                
                let property: Property?
                if let optional = child.value as? OptionalProperty
                {
                    property = optional.property()
                }
                else if let value = child.value as? Property
                {
                    property = value
                }
                else
                {
                    throw Error.TypeDoesNotConformToProperty(type: child.value.dynamicType)
                }
                
                if let object = property
                {
                    dict[label] = object
                }
            }
        }
        
        return dict
    }
    
    public static func decode(dict: [String: Any]) throws -> Self
    {
        var obj = self.init()
        
        var offset = 0
        for child in Mirror(reflecting: obj).children
        {
            if let modelType = child.value.dynamicType as? Model.Type
            {
                if let label = child.label, entry = dict[label], value = entry as? [String: Any]
                {
                    try obj.codeValue(modelType.decode(value), type: modelType, offset: offset)
                }
                
                offset += modelType.size()
            }
            else if let propertyType = child.value.dynamicType as? Property.Type
            {
                if let label = child.label, entry = dict[label], value = entry as? Property
                {
                    try obj.codeValue(value, type: propertyType, offset: offset)
                }
                
                offset += propertyType.size()
            }
            else
            {
                throw Error.TypeDoesNotConformToProperty(type: child.value.dynamicType)
            }
        }
        
        return obj
    }
    
}