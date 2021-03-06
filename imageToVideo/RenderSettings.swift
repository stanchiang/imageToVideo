//
//  RenderSettings.swift
//  imageToVideo
//
//  Created by Stanley Chiang on 8/4/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//
//http://stackoverflow.com/a/36290742/1079379

import UIKit
import AVFoundation

struct RenderSettings {
    
    var width: CGFloat = 1280
    var height: CGFloat = 720
    var fps: Int32 = 2   // 2 frames per second
    var avCodecKey = AVVideoCodecH264
    var videoFilename = "render"
    var videoFilenameExt = "mp4"
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var outputURL: NSURL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = NSFileManager.defaultManager()
        if let tmpDirURL = try? fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true) {
            return tmpDirURL.URLByAppendingPathComponent(videoFilename)!.URLByAppendingPathExtension(videoFilenameExt)!
        }
        fatalError("URLForDirectory() failed")
    }
}

