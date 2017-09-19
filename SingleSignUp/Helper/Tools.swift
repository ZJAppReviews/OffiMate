//
//  Tools.swift
//  SingleSignUp
//
//  Created by Carlos Martin on 23/08/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import Foundation
import UIKit
import Firebase

public class Tools {
    //place to create internal variables
}

//MARK:- BackEnd 
extension Tools {
    
}

//MARK:- Storyboard navigation
extension Tools {
    //.coverVertical .flipHorizontal .crossDissolve
    static func goToMain (vc: UIViewController) {
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() {
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .flipHorizontal
            vc.present(controller, animated: true, completion: nil)
        }
    }
    
    static func goToOnboard (vc: UIViewController) {
        if let controller = UIStoryboard(name: "Onboard", bundle: nil).instantiateInitialViewController() {
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .flipHorizontal
            vc.present(controller, animated: true, completion: nil)
        }
    }
    
    static func goToProfile (vc: UIViewController) {
        if let controller = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() {
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .flipHorizontal
            vc.present(controller, animated: true, completion: nil)
        }
    }
}

//MARK:- Validations
extension Tools {
    static func validateEmail (email: UITextField) -> Bool {
        if let _email = email.text {
            return self.validateEmail(email: _email)
        } else {
            return false
        }
    }
    
    static func validateEmail (email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    static func validateURL (url: String) -> Bool {
        let successful: Bool
        if let url = NSURL(string: url) {
            successful = UIApplication.shared.canOpenURL(url as URL)
        } else {
            successful = false
        }
        return successful
    }
    
    static func validatePassword (pass: UITextField) -> Bool {
        if let _pass = pass.text {
            return self.validatePassword(pass: _pass)
        } else {
            return false
        }
    }
    
    static func validatePassword (pass: String) -> Bool {
        let passRegEx = "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}"
        let passTest = NSPredicate(format:"SELF MATCHES %@", passRegEx)
        return passTest.evaluate(with: pass)
    }
}

//MARK:- Error View Animation
extension Tools {
    static func textFieldErrorAnimation (textField: UITextField) {
        textField.backgroundColor = UIColor.red
        UIView.animate(withDuration: 1, animations: {
            textField.alpha = 0.0
        }, completion: { (finished: Bool) in
            textField.backgroundColor = UIColor.white
            textField.alpha = 1
        })
    }
    
    static func cellViewErrorAnimation (cell: UITableViewCell) {
        let view = cell.contentView
        view.backgroundColor = UIColor.red
        UIView.animate(withDuration: 1, animations: {
            view.alpha = 0.0
        }) { (finished: Bool) in
            view.backgroundColor = UIColor.white
            view.alpha = 1
        }
    }
    
}

//MARK:- Others
extension Tools {
    static func randomString(length: Int?=12) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length! {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}
