//
//  APIRouter.swift
//  MealReminder
//
//  Created by Chhaya Tiwari on 9/24/18.
//  Copyright © 2018 chhayatiwari. All rights reserved.
//

import Foundation
import Alamofire

enum APIRouter:URLRequestConvertible{
    case mealApi(params:Parameters)
    
    var method:HTTPMethod{
        switch self{
        case .mealApi:
            return .get
        }
        
    }
    static let baseUrlString = "https://naviadoctors.com/dummy/"
    
    var path:String{
        switch self{
        case .mealApi:
            return ""
        }
    }
    func asURLRequest() throws -> URLRequest {
        let url = try APIRouter.baseUrlString.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        //  urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        switch self {
        case .mealApi(let parameters):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            // print(urlRequest)
        }
        return urlRequest
    }
    
}
