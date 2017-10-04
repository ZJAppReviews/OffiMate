//
//  BoostCard.swift
//  SingleSignUp
//
//  Created by Carlos Martin on 04/10/2017.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

enum BoostCardType: Int {
    case passion = 0
    case execution
}

internal class BoostCard: CustomStringConvertible {
    internal let id:         String
    internal let senderId:   String
    internal let receiverId: String
    internal let type:       BoostCardType
    internal let header:     String
    internal let message:    String
    
    public var description: String {
        return "BoostCard:\n├── id:          \(self.id)\n├── senderId:    \(self.senderId)\n├── receiverId:  \(self.receiverId)\n├── type:        \(self.type)\n├── header:      \(self.header)\n└── message:     \(self.message)\n"
    }
    
    init(id: String?=nil, senderId: String, receiverId: String, type: BoostCardType, header: String, message: String) {
        self.id =         id ?? "~unknown~"
        self.senderId =   senderId
        self.receiverId = receiverId
        self.type =       type
        self.header =     header
        self.message =    message
    }
}
