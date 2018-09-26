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
import UserNotifications

class HomeViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate {

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
        // Configure User Notification Center
        UNUserNotificationCenter.current().delegate = self

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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    func promtForNotification(week: String, time: String, subject: String) {
        // Request Notification Settings
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization(completionHandler: { (success) in
                    guard success else { return }
                    
                    // Schedule Local Notification
                    self.scheduleLocalNotification(week, "18", subject)
                })
            case .authorized:
                // Schedule Local Notification
                self.scheduleLocalNotification(week, "18", subject)
            case .denied:
                print("Application Not Allowed to Display Notifications")
            default:
                self.scheduleLocalNotification(week, "18", subject)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        // Request Authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            
            completionHandler(success)
        }
    }
    
    private func scheduleLocalNotification(_ week: String,_ time: String,_ subject: String) {
        
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = "Diet Plan"
        notificationContent.body = subject
        let today = Date()
        
        if getDayFromDate(date: today) == week {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: today)
        var dateComp:DateComponents = DateComponents()
        dateComp.day = components.day
        dateComp.month = components.month
        dateComp.year = components.year
            dateComp.hour = Int(time)! % 100
        dateComp.minute = 00
            // Add Trigger
        let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: true)
        
        
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
        }
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
                self.tableView.reloadData()
                for week in self.weeks {
                    for meal in self.mealOfDay[week]! {
                       self.promtForNotification(week: week, time: meal.time, subject: meal.food)
                    }
                }
            }
        }
        
    }
    
    func showAlert(_ msg: String) {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertController.Style.alert)
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
    
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
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
