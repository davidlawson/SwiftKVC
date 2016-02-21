//
//  SwiftKVCTests.swift
//  SwiftKVCTests
//
//  Created by Bradley Hilton on 8/31/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import XCTest
@testable import SwiftKVC

class SwiftKVCTests: XCTestCase {
    
    var john: Person {
        return Person(firstName: "John", lastName: "Smith", age: 45)
    }
    
    var jacob: Person {
        return Person(firstName: "Jacob", middleName: "Tyler", lastName: "Smith", age: 36, friends: [jack, jane], bestFriend: jane)
    }
    
    var jack: Person {
        return Person(firstName: "Jack", lastName: "Smith", age: 51)
    }
    
    var jane: Person {
        return Person(firstName: "Jane", lastName: "Smith", age: 23)
    }
    
    func testPerson() {
        var person = john
        assert(person: john, sameAsPerson: person)
        person["firstName"] = jacob.firstName
        person["middleName"] = jacob.middleName
        person["lastName"] = jacob.lastName
        person["age"] = jacob.age
        person["friends"] = jacob.friends
        person["bestFriend"] = jacob.bestFriend
        assert(person: jacob, sameAsPerson: person)
    }
    
    func testNullabilty() {
        var person = john
        XCTAssert(person.middleName == nil)
        person["middleName"] = "Jacob"
        XCTAssert(person.middleName == "Jacob")
        person["firstName"] = nil
        XCTAssert(person.firstName == john.firstName)
    }
    
    func assert(person lh: Person, sameAsPerson rh: Person) {
        XCTAssert(lh.firstName == rh["firstName"] as? String)
        XCTAssert(lh.middleName == rh["middleName"] as? String)
        XCTAssert(lh.lastName == rh["lastName"] as? String)
        XCTAssert(lh.age == rh["age"] as? Int)
        XCTAssert(lh.friends == rh["friends"] as! [Person])
        XCTAssert(lh.bestFriend == rh["bestFriend"] as? Person)
    }
    
    struct StructA: Model
    {
        var int = 3
    }
    
    struct StructB: Model
    {
        var str = "str"
    }
    
    func testEncodingAndDecoding()
    {
        let sA = StructA(int: 4)
        let sAEnc: [String: Any] = try! sA.encode()
        
        let sB = StructB(str: "test")
        let sBEnc: [String: Any] = try! sB.encode()
        
        let types: [Model.Type] = [StructA.self, StructB.self]
        
        let decA: Any = try! SwiftKVC.decode(sAEnc, possibleTypes: types)
        let decB: Any = try! SwiftKVC.decode(sBEnc, possibleTypes: types)
        
        switch decA
        {
            case let dec as StructA:
                XCTAssertEqual(dec.int, 4)
            default:
                XCTFail()
        }
        
        switch decB
        {
            case let dec as StructB:
                XCTAssertEqual(dec.str, "test")
            default:
                XCTFail()
        }
    }
    
}

class Person : Model, Equatable {
    
    var firstName: String = ""
    var middleName: String?
    var lastName: String = ""
    var age: Int = 0
    var friends: [Person] = []
    var bestFriend: Person?
    
    var fullName: String {
        return firstName + (middleName != nil ? " \(middleName!) " : " ") + lastName
    }
    required init() {}
    init(firstName: String, middleName: String? = nil, lastName: String, age: Int, friends: [Person] = [], bestFriend: Person? = nil) {
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.age = age
        self.friends = friends
        self.bestFriend = bestFriend
    }
    
}

func == (lh: Person, rh: Person) -> Bool {
    return lh.fullName == rh.fullName
}
