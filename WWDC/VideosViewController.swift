//
//  ViewController.swift
//  WWDC
//
//  Created by Guilherme Rambo on 19/11/15.
//  Copyright © 2015 Guilherme Rambo. All rights reserved.
//

import UIKit
import RealmSwift

class VideosViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSessions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Data loading

    var sessions: Results<Session>! {
        didSet {
            guard sessions != nil else { return }

            let previouslySelectedRow = tableView.indexPathForSelectedRow
            
            tableView.reloadData()
            
            tableView.selectRowAtIndexPath(previouslySelectedRow ?? NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: .Top)
        }
    }
    
    func loadSessions() {
        fetchLocalSessions()
        
        WWDCDatabase.sharedDatabase.sessionListChangedCallback = { newSessionKeys in
            print("\(newSessionKeys.count) new session(s) available")

            self.fetchLocalSessions()
        }
        WWDCDatabase.sharedDatabase.refresh()
    }
    
    func fetchLocalSessions() {
        sessions = WWDCDatabase.sharedDatabase.standardSessionList
    }
    
    // MARK: Table View
    
    private struct Storyboard {
        static let videoCellIdentifier = "video"
        static let detailSegueIdentifier = "detail"
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard sessions != nil else { return 0 }
        
        return sessions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.videoCellIdentifier)!
        
        let session = sessions[indexPath.row]
        cell.textLabel?.text = session.title
        
        return cell
    }
    
    // MARK: Session selection
    
    var selectedSession: Session? {
        didSet {
            guard selectedSession != nil else { return }
            
            performSegueWithIdentifier(Storyboard.detailSegueIdentifier, sender: nil)
        }
    }
    
    override func tableView(tableView: UITableView, didUpdateFocusInContext context: UITableViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard let selectedPath = context.nextFocusedIndexPath else { return }
        
        selectedSession = sessions[selectedPath.row]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Storyboard.detailSegueIdentifier {
            let detailController = segue.destinationViewController as! DetailViewController
            detailController.session = selectedSession
        }
    }


}

