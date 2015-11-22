//
//  PlayerBuilder.swift
//  WWDC
//
//  Created by Guilherme Rambo on 22/11/15.
//  Copyright © 2015 Guilherme Rambo. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class PlayerBuilder {
    
    class func buildPlayerViewController(videoURL: String, title: String?, description: String?) -> (AVPlayerViewController, AVPlayer) {
        // build playerItem and It's metadata
        let playerItem = AVPlayerItem(URL: NSURL(string: videoURL)!)
        
        if let title = title {
            let titleMeta = AVMutableMetadataItem()
            titleMeta.locale = NSLocale.currentLocale()
            titleMeta.keySpace = AVMetadataKeySpaceCommon
            titleMeta.key = AVMetadataCommonKeyTitle
            titleMeta.value = title
            playerItem.externalMetadata.append(titleMeta)
        }
        if let description = description {
            let descriptionMeta = AVMutableMetadataItem()
            descriptionMeta.locale = NSLocale.currentLocale()
            descriptionMeta.keySpace = AVMetadataKeySpaceCommon
            descriptionMeta.key = AVMetadataCommonKeyDescription
            descriptionMeta.value = description
            playerItem.externalMetadata.append(descriptionMeta)
        }
        
        // build player and playerController
        let player = AVPlayer(playerItem: playerItem)
        
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        return (playerController, player)
    }
    
}
