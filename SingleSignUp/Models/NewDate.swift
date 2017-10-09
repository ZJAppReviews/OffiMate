//
//  NewDate.swift
//  SingleSignUp
//
//  Created by Carlos Martin on 18/09/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import Foundation

class NewDate: CustomStringConvertible {
    let date:       Date
    let year:       Int64
    let month:      Int64
    let day:        Int64
    let hour:       Int64
    let minutes:    Int64
    let id:         Int64
    
    public var description: String {
        let syear =     String(year)
        let smonth =    (month > 9   ? "\(month)"   : "0\(month)")
        let sday =      (day > 9     ? "\(day)"     : "0\(day)")
        let shour =     (hour > 9    ? "\(hour)"    : "0\(hour)")
        let sminutes =  (minutes > 9 ? "\(minutes)" : "0\(minutes)")
        return "\(syear)-\(smonth)-\(sday) \(shour):\(sminutes)"
    }
    
    init(date: Date) {
        let calendar = Calendar.current
        self.date =     date
        self.year =     Int64(calendar.component(.year,   from: date))
        self.month =    Int64(calendar.component(.month,  from: date))
        self.day =      Int64(calendar.component(.day,    from: date))
        self.hour =     Int64(calendar.component(.hour,   from: date))
        self.minutes =  Int64(calendar.component(.minute, from: date))
        self.id =       (self.year * 100000000) + (self.month * 1000000) + (self.day * 10000) + (self.hour * 100) + self.minutes
    }
    
    init(id: Int64) throws {
        self.id = id
        self.year =     Int64( self.id/100000000)
        self.month =    Int64((self.id-year*100000000)/1000000)
        self.day =      Int64((self.id-(year*100000000)-(month*1000000))/10000)
        self.hour =     Int64((self.id-(year*100000000)-(month*1000000)-(day*10000))/100)
        self.minutes =  Int64( self.id-(year*100000000)-(month*1000000)-(day*10000)-(hour*100))
        let syear =     "\(year)"
        let smonth =    (month > 9   ? "\(month)"   : "0\(month)")
        let sday =      (day > 9     ? "\(day)"     : "0\(day)")
        let shour =     (hour > 9    ? "\(hour)"    : "0\(hour)")
        let sminutes =  (minutes > 9 ? "\(minutes)" : "0\(minutes)")
        let string = syear + "-" + smonth + "-" + sday + "T" + shour + ":" + sminutes
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let _date = dateFormatter.date(from: string) {
            self.date = _date
        } else {
            throw NSError(domain: "boom", code: 2, userInfo: nil)
        }
    }
    
    func getWeekNum() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: self.date)
    }
    
    func getWeekDay() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: self.date)
    }
    
    func getDayName(weekDayNum: Int?=nil) -> String {
        let _weekDay: Int
        
        if let _ = weekDayNum {
            _weekDay = weekDayNum!
        } else {
            _weekDay = self.getWeekDay()
        }
        
        switch _weekDay {
        case 1:
            return "Sunday"
        case 2:
            return "Monday"
        case 3:
            return "Tuesday"
        case 4:
            return "Wednesday"
        case 5:
            return "Thrusday"
        case 6:
            return "Friday"
        case 7:
            return "Saturday"
        default:
            return ""
        }
    }
}
