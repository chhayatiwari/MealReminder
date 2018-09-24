//
//  MealDay.swift
//  MealReminder
//
//  Created by Chhaya Tiwari on 9/24/18.
//  Copyright © 2018 chhayatiwari. All rights reserved.
//

import Foundation
struct MealDay {
    
    // MARK: Properties
    
    let food: String
    let time: String
    
    // MARK: Initializers
    
    init(dictionary: [String:AnyObject]) {
        food = (dictionary["food"] as! String)
        time = (dictionary["meal_time"] as! String)
        
    }
    
    static func dataForMeal(_ results: [[String:AnyObject]]) -> [MealDay] {
        
        var current = [MealDay]()
        
        // iterate through array of dictionaries, each deal is a dictionary
        for result in results {
            current.append(MealDay(dictionary: result))
        }
        
        return current
    }
    
}
