//
//  ServiceProvider.swift
//  WWDC Top Shelf
//
//  Created by Guilherme Rambo on 23/12/15.
//  Copyright © 2015 Guilherme Rambo. All rights reserved.
//

import Foundation
import TVServices

class ServiceProvider: NSObject, TVTopShelfProvider {

    let sessionFetcher = FeaturedSessionsFetcher()
    
    var featuredSessions: [FeaturedSession]? {
        didSet {
            guard featuredSessions != nil else { return }
            
            NSNotificationCenter.defaultCenter().postNotificationName(TVTopShelfItemsDidChangeNotification, object: nil)
        }
    }
    
    override init() {
        super.init()
        
        sessionFetcher.fetchFeaturedSessions { sessions in
            self.featuredSessions = sessions
        }
    }

    // MARK: - TVTopShelfProvider protocol

    var topShelfStyle: TVTopShelfContentStyle {
        // Return desired Top Shelf style.
        return .Sectioned
    }

    var topShelfItems: [TVContentItem] {
        guard let featuredSessions = featuredSessions else { return [] }

        var items = [TVContentItem]()
        
        for session in featuredSessions {
            let item = TVContentItem(contentIdentifier: session.contentIdentifier)!
            item.title = session.title
            item.imageURL = NSURL(string: session.thumbnail)!
            item.imageShape = .HDTV
            item.playURL = session.playURL
            item.displayURL = session.displayURL
            
            items.append(item)
        }
        
        let containerIdentifier = TVContentIdentifier(identifier: "br.com.guilhermerambo.WWDC.Featured", container: nil)!
        let container = TVContentItem(contentIdentifier: containerIdentifier)!
        container.title = "Featured Session Videos"
        container.topShelfItems = items

        return [container]
    }

}

private extension FeaturedSession {
    
    private var contentIdentifierName: String {
        return "br.com.guilhermerambo.\(key)-\(title)"
    }
    
    var contentIdentifier: TVContentIdentifier {
        return TVContentIdentifier(identifier: contentIdentifierName, container: nil)!
    }
    
    var playURL: NSURL {
        return NSURL(string: "wwdc://play/\(key)")!
    }
    
    var displayURL: NSURL {
        return NSURL(string: "wwdc://show/\(key)")!
    }
    
}