//
//  DetailViewController.swift
//  WWDC
//
//  Created by Guilherme Rambo on 20/11/15.
//  Copyright © 2015 Guilherme Rambo. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class DetailViewController: UIViewController {

    var session: Session! {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    private func updateUI() {
        guard session != nil else { return }
        guard titleLabel != nil else { return }
        
        titleLabel.text = session.title
        subtitleLabel.text = session.subtitle
        descriptionView.text = session.summary
    }
    
    // MARK: Playback
    
    var player: AVPlayer?
    var timeObserver: AnyObject?

    @IBAction func watch(sender: UIButton) {
        let (playerController, newPlayer) = PlayerBuilder.buildPlayerViewController(session.ATVURL.absoluteString, title: session.title, description: session.summary)
        player = newPlayer
        
        presentViewController(playerController, animated: true) { [unowned self] in
            self.timeObserver = self.player?.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(5, 1), queue: dispatch_get_main_queue()) { currentTime in
                let progress = Double(CMTimeGetSeconds(currentTime)/CMTimeGetSeconds(self.player!.currentItem!.duration))
                
                WWDCDatabase.sharedDatabase.doChanges {
                    self.session!.progress = progress
                    self.session!.currentPosition = CMTimeGetSeconds(currentTime)
                }
            }
            
            if self.session.currentPosition > 0 {
                self.player?.seekToTime(CMTimeMakeWithSeconds(self.session.currentPosition, 1))
            }
            
            playerController.player?.play()
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
