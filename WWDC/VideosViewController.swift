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
        
        tableView.remembersLastFocusedIndexPath = true
        
        loadSessions()
    }

    // MARK: Data loading

    var sessionYears: [Int]! {
        guard let sessionGroups = sessionGroups else { return nil}
        
        return [Int](sessionGroups.keys).sort { $0 > $1 }
    }
    var sessionGroups: [Int:Results<Session>]! {
        didSet {
            guard sessionGroups != nil else { return }
            
            let previouslySelectedPath = tableView.indexPathForSelectedRow
            
            tableView.reloadData()
            
            if sessionGroups.keys.count > 0 {
                tableView.selectRowAtIndexPath(previouslySelectedPath ?? NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: .Top)
            }
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
        sessionGroups = WWDCDatabase.sharedDatabase.sessionsGroupedByYear
    }
    
    // MARK: Table View
    
    private struct Storyboard {
        static let videoCellIdentifier = "video"
        static let detailSegueIdentifier = "detail"
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sessionGroups.keys.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(sessionYears[section])"
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard sessionGroups != nil else { return 0 }

        return sessionGroups[sessionYears[section]]!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.videoCellIdentifier)!
        
        let sectionSessions = sessionGroups[sessionYears[indexPath.section]]!
        let session = sectionSessions[indexPath.row]
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
        guard let indexPath = context.nextFocusedIndexPath else { return }
        
        selectSessionAtIndexPath(indexPath)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Storyboard.detailSegueIdentifier {
            let detailController = segue.destinationViewController as! DetailViewController
            detailController.session = selectedSession
        }
    }
    
    private func selectSessionAtIndexPath(indexPath: NSIndexPath) {
        tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .Middle)
        
        let sectionSessions = sessionGroups[sessionYears[indexPath.section]]!
        selectedSession = sectionSessions[indexPath.row]
    }
    
    private func indexPathForSessionWithKey(key: String) -> NSIndexPath? {
        guard let session = WWDCDatabase.sharedDatabase.realm.objectForPrimaryKey(Session.self, key: key) else { return nil }
        
        var sections = [Int](sessionGroups.keys)
        sections.sortInPlace { $0 > $1 }
        
        guard let section = sections.indexOf(session.year) else { return nil }
        guard let row = sessionGroups[session.year]?.indexOf(session) else { return nil }

        return NSIndexPath(forRow: row, inSection: section)
    }
    
    // MARK: Session displaying and playback from URLs
    
    private var detailViewController: DetailViewController? {
        guard let splitController = parentViewController?.parentViewController else { return nil }
        guard splitController.childViewControllers.count > 1 else { return nil }
        
        return splitController.childViewControllers[1] as? DetailViewController
    }
    
    func displaySession(key: String) {
        guard let indexPath = indexPathForSessionWithKey(key) else { return }
        
        selectSessionAtIndexPath(indexPath)
    }

    func playSession(key: String) {
        displaySession(key)
        
        guard let detailVC = detailViewController else { return }
        
        detailVC.watch(nil)
    }

}

