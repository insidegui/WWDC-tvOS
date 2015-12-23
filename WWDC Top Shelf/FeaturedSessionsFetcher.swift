//
//  FeaturedSessionsFetcher.swift
//  WWDC
//
//  Created by Guilherme Rambo on 23/12/15.
//  Copyright © 2015 Guilherme Rambo. All rights reserved.
//

import Foundation

struct FeaturedSession {
    
    var key = ""
    var title = ""
    var summary = ""
    var thumbnail = ""
    
    init(json: JSON) {
        if let key = json["id"].string {
            self.key = key
        }
        if let title = json["title"].string {
            self.title = title
        }
        if let summary = json["summary"].string {
            self.summary = summary
        }
        if let thumbnail = json["img"].string {
            self.thumbnail = thumbnail
        }
    }
}

class FeaturedSessionsFetcher {

    private let serviceURL = "http://wwdc.guilhermerambo.me/featured.json"
    private let URLSession = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    
    func fetchFeaturedSessions(completionHandler: ([FeaturedSession]?) -> ()) {
        URLSession.dataTaskWithURL(NSURL(string: serviceURL)!) { data, response, error in
            guard let data = data else {
                print("Error fetching featured sessions for the top shelf \(error)")
                completionHandler(nil)
                return
            }
            
            let json = JSON(data: data)
            var featuredSessions = [FeaturedSession]()
            if let jsonSessions = json.array {
                for jsonSession in jsonSessions {
                    featuredSessions.append(FeaturedSession(json: jsonSession))
                }
                completionHandler(featuredSessions)
            } else {
                completionHandler(nil)
            }
        }.resume()
    }
    
}