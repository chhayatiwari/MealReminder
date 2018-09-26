//
//  HomeViewController.swift
//  MealReminder
//
//  Created by Chhaya Tiwari on 9/24/18.
//  Copyright © 2018 chhayatiwari. All rights reserved.
//

import UIKit
import FSCalendar
import Alamofire
import SwiftyJSON
import SystemConfiguration

class HomeViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datelabel: UILabel!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    var weeks:[String] = ["monday", "wednesday", "thursday"]
    var mealOfDay:[String:[MealDay]] = [:]
    var day:String!
    var count = 0
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("EEEE, ddMMMMyyyy")
        return formatter
    }()
    
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInitials()
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        
        showMealForTheDay()
        calendar.setCurrentPage(Date(), animated: true)
        self.calendar.accessibilityIdentifier = "calendar"
        day = getDayFromDate(date: Date()).lowercased()
        
        if (day == "wednesday") || (day == "monday") || (day == "thursday"){
         tableView.reloadData()
        }
    }
    
    deinit {
        print("\(#function)")
    }
    
    func setInitials()
    {
        if UIDevice.current.model.hasPrefix("iPad") {
            self.calendarHeightConstraint.constant = 400
        }
        calendar.appearance.caseOptions = FSCalendarCaseOptions.weekdayUsesSingleUpperCase
        calendar.appearance.titleWeekendColor = UIColor.gray
        self.calendar.select(Date())
        datelabel.text = self.dateFormatter.string(from: Date())
        self.view.addGestureRecognizer(self.scopeGesture)
        self.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.calendar.scope = .week
    }
    

    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
    
    func getDayFromDate(date:Date) -> String {
        let dateFormatter = DateFormatter()
        let day = dateFormatter.weekdaySymbols[Calendar.current.component(.weekday, from: date)-1]
        return day
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        datelabel.text = self.dateFormatter.string(from: date)
        day = getDayFromDate(date: date).lowercased()
        tableView.reloadData()
        if (day == "monday" || day == "wednesday" || day == "thursday"){
            
            if monthPosition == .next || monthPosition == .previous {
                calendar.setCurrentPage(date, animated: true)
            }
        }
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        
            return true
    }
    
    // Api Call
    func showMealForTheDay() {
       
        let parameters = ["":""]
        Alamofire.request(APIRouter.mealApi(params: parameters )).responseJSON { (responseData) -> Void in
            if let response = (responseData.result.value)  {
                
                guard let swiftyJsonVar = JSON(response).dictionaryObject else {
                   return
                }
                guard let weekDiet = swiftyJsonVar["week_diet_data"] as? [String:AnyObject] else {
                        return
                }
                
                for week in self.weeks {
                    if let meal = weekDiet[week] as? [[String:AnyObject]] {
                        self.mealOfDay[week] = MealDay.dataForMeal(meal)
                           self.count += 1
                    }
                }
                for week in self.weeks {
                    for meal in self.mealOfDay[week]! {
                       self.scheduleNotification(week: week, time: meal.time, subject: meal.food)
                    }
                }
            }
        }
        
    }
    
    func scheduleNotification(week: String, time: String, subject: String) {
        
        let today = Date()
        if getDayFromDate(date: today) == week {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: today)
            var dateComp:DateComponents = DateComponents()
            dateComp.day = components.day
            dateComp.month = components.month
            dateComp.year = components.year
            dateComp.hour = Int(time)
            dateComp.minute = 00
            let date = calendar.date(from: dateComp)
            let localNotificationSilent = UILocalNotification()
            localNotificationSilent.fireDate = date
           // localNotificationSilent.repeatInterval = .day
            localNotificationSilent.alertBody = subject
            localNotificationSilent.alertAction = "swipe to hear!"
            localNotificationSilent.category = "PLAY_CATEGORY"
            UIApplication.shared.scheduleLocalNotification(localNotificationSilent)
            localNotificationSilent.fireDate = date
            
        }
        
    }
    
    func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    
        
       
    
    
    //TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let meal = mealOfDay[self.day] {
            return meal.count
        }
        else {
        return 0
        }
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShowMeal")
        
        if let meal = mealOfDay[self.day]  {
            let index = indexPath.row
            cell?.textLabel?.text = meal[index].time
            cell?.detailTextLabel?.text = meal[index].food
        }
        
        
        return cell!
    }
}

