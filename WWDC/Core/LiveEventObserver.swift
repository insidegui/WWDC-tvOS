//
//  LiveEventObserver.swift
//  WWDC
//
//  Created by Guilherme Rambo on 16/05/15.
//  Copyright (c) 2015 Guilherme Rambo. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

public let LiveEventNextInfoChangedNotification = "LiveEventNextInfoChangedNotification"
public let LiveEventTitleAvailableNotification = "LiveEventTitleAvailableNotification"
public let LiveEventWillStartPlayingNotification = "LiveEventWillStartPlayingNotification"
private let _sharedInstance = LiveEventObserver()

class LiveEventObserver: NSObject {

    var nextEvent: LiveSession? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(LiveEventNextInfoChangedNotification, object: nil)
        }
    }
    private var lastEventFound: LiveSession?
    private var timer: NSTimer?
    private var liveEventPlayerController: AVPlayerViewController?
    
    class func SharedObserver() -> LiveEventObserver {
        return _sharedInstance
    }
    
    private var parentViewController: UIViewController?
    func start(parent: UIViewController) {
        parentViewController = parent
        
        timer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "checkNow", userInfo: nil, repeats: true)
        checkNow()
    }
    
    func checkNow() {
        checkForLiveEvent { available, event in
            dispatch_async(dispatch_get_main_queue()) {
                if !available && self.liveEventPlayerController != nil {
                    self.liveEventPlayerController?.dismissViewControllerAnimated(true) {
                        self.liveEventPlayerController?.player?.pause()
                        self.liveEventPlayerController = nil
                    }

                    return
                }
                
                // an event is available
                if available && event != nil {
                    self.lastEventFound = event
                    self.showNotification(event!)
                }
            }
        }
        
        fetchNextLiveEvent { available, event in
            dispatch_async(dispatch_get_main_queue()) {
                self.nextEvent = event
            }
        }
    }
    
    private func doPlayEvent(event: LiveSession) {
        // we already have a live event playing, just return
        if liveEventPlayerController != nil {
            NSNotificationCenter.defaultCenter().postNotificationName(LiveEventTitleAvailableNotification, object: event.title)
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(LiveEventWillStartPlayingNotification, object: nil)

        liveEventPlayerController = buildPlayerViewController(event)
        parentViewController?.presentViewController(liveEventPlayerController!, animated: true) {
            self.liveEventPlayerController?.player?.play()
        }
    }
    
    // MARK: User notifications

    private var isShowingAlert = false
    private var userDecided = false

    func checkNowAndPlay() {
        if let event = lastEventFound {
            doPlayEvent(event)
        } else {
            checkNow()
        }
    }
    
    func showNotification(event: LiveSession) {
        guard !isShowingAlert && !userDecided && liveEventPlayerController == nil else { return }
        
        isShowingAlert = true
        
        let alert = UIAlertController(title: "Live session available", message: "\(event.title) is live right now. Would you like to watch It?", preferredStyle: .Alert)
        let yesAction = UIAlertAction(title: "Yes", style: .Default) { _ in
            self.userDecided = true
            self.isShowingAlert = true
            self.doPlayEvent(event)
        }
        let noAction = UIAlertAction(title: "No", style: .Cancel) { _ in
            self.userDecided = true
            self.isShowingAlert = false
        }
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        parentViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    private let _liveServiceURL = "http://wwdc.guilhermerambo.me/live.json"
    private let _liveNextServiceURL = "http://wwdc.guilhermerambo.me/next.json"
    
    private var liveURL: NSURL {
        get {
            sranddev()
            // adds a random number as a parameter to completely prevent any caching
            return NSURL(string: "\(_liveServiceURL)?t=\(rand())&s=\(NSDate.timeIntervalSinceReferenceDate())")!
        }
    }
    
    private var liveNextURL: NSURL {
        get {
            sranddev()
            // adds a random number as a parameter to completely prevent any caching
            return NSURL(string: "\(_liveNextServiceURL)?t=\(rand())&s=\(NSDate.timeIntervalSinceReferenceDate())")!
        }
    }
    
    let URLSession2 = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    
    func checkForLiveEvent(completionHandler: (Bool, LiveSession?) -> ()) {
        let task = URLSession2.dataTaskWithURL(liveURL) { data, response, error in
            if data == nil {
                completionHandler(false, nil)
                return
            }
            
            let jsonData = JSON(data: data!)
            let event = LiveSession(jsonObject: jsonData)
            
            if event.isLiveRightNow {
                completionHandler(true, event)
            } else {
                completionHandler(false, nil)
            }
        }
        task.resume()
    }
    
    func fetchNextLiveEvent(completionHandler: (Bool, LiveSession?) -> ()) {
        let task = URLSession2.dataTaskWithURL(liveNextURL) { data, response, error in
            if data == nil {
                completionHandler(false, nil)
                return
            }
            
            let jsonData = JSON(data: data!)
            let event = LiveSession(jsonObject: jsonData)
            
            if event.title != "" {
                completionHandler(true, event)
            } else {
                completionHandler(false, nil)
            }
        }
        task.resume()
    }
    
}


extension LiveEventObserver {
    func buildPlayerViewController(session: LiveSession) -> AVPlayerViewController! {
        let (controller, _) = PlayerBuilder.buildPlayerViewController(session.streamURL!.absoluteString, title: session.title, description: session.summary)
        
        return controller
    }
}