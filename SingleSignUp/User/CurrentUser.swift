//
//  CurrentUser.swift
//  SingleSignUp
//
//  Created by Carlos Martin on 21/08/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class CurrentUser {
    static private(set) var name:       String!
    static private(set) var email:      String!
    static private(set) var password:   String!
    //FirebaseAuth user
    static var user: User!
    
    //MARK:- Public funtion
    static func isInit() -> Bool {
        if self.alreadyFetched() {
            return true
        } else if localFetch() {
            return true
        } else {
            return false
        }
    }
    
    static func localSave() throws {
        if self.name != nil && self.email != nil && self.password != nil {
            UserDefaults.standard.set(self.name,     forKey: "name")
            UserDefaults.standard.set(self.email,    forKey: "email")
            UserDefaults.standard.set(self.password, forKey: "password")
        } else {
            throw NSError(domain: "Some of the internal variables are nil", code: 0, userInfo: nil)
        }
    }
    
    static func localClean() {
        self.name = nil
        self.email = nil
        self.password = nil
        UserDefaults.standard.removeObject(forKey: "name")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "password")
    }
    
    static func setName(name: String) throws {
        if !name.isEmpty {
            self.name = name
        } else {
            throw NSError(domain: "Not valid name", code: 0, userInfo: nil)
        }
        
    }
    
    static func setEmail(email: String) throws {
        if Tools.validateEmail(email: email) {
            self.email = email
        } else {
            throw NSError(domain: "Not valid email", code: 0, userInfo: nil)
        }
    }
    
    static func setPassword(password: String) throws {
        if Tools.validatePassword(pass: password) {
            self.password = password
        } else {
            throw NSError(domain: "Not valid password", code: 0, userInfo: nil)
        }
    }
    
    static func setData(name: String, email: String, password: String) throws {
        do {
            try self.setName(name: name)
            try self.setEmail(email: email)
            try self.setPassword(password: password)
        } catch {
            throw NSError(domain: "Not valid input data", code: 0, userInfo: nil)
        }
    }
    
    //MARK:- Private local function
    private static func localFetch() -> Bool {
        if let name = UserDefaults.standard.string(forKey: "name"),
            let email = UserDefaults.standard.string(forKey: "email"),
            let password = UserDefaults.standard.string(forKey: "password"){
            self.name = name
            self.email = email
            self.password = password
            return true
        } else {
            return false
        }
    }
    
    private static func alreadyFetched() -> Bool {
        return self.name != nil && self.email != nil && self.password != nil
    }
}
