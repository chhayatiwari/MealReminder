//
//  GCDBlackBox.swift
//  MealReminder
//
//  Created by Chhaya Tiwari on 9/25/18.
//  Copyright © 2018 chhayatiwari. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
