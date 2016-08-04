//
//  ViewController.swift
//  imageToVideo
//
//  Created by Stanley Chiang on 8/4/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//
//run-time problems: didn't seem to output any file to camera roll 

import UIKit
import AVFoundation

class ViewController1: UIViewController {

    var choosenPhotos: [UIImage] = [] //*** your array of UIImages ***
    var outputSize = CGSizeMake(1280, 720)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadPhotos()
        build(outputSize: outputSize)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadPhotos(){
        for i in 0 ..< 12 {
            choosenPhotos.append(UIImage(named: "hand-\(i).png")!)
        }
        print("\(choosenPhotos.count) loaded")
    }
    
    //http://stackoverflow.com/questions/28968322/how-would-i-put-together-a-video-using-the-avassetwriter-in-swift
    
    func build(outputSize outputSize: CGSize) {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        guard let documentDirectory: NSURL = urls.first else {
            fatalError("documentDir Error")
        }
        
        let videoOutputURL = documentDirectory.URLByAppendingPathComponent("OutputVideo.mp4")
        
        if NSFileManager.defaultManager().fileExistsAtPath(videoOutputURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(videoOutputURL.path!)
            } catch {
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
        
        guard let videoWriter = try? AVAssetWriter(URL: videoOutputURL, fileType: AVFileTypeMPEG4) else {
            fatalError("AVAssetWriter error")
        }
        
        let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(float: Float(outputSize.width)), AVVideoHeightKey : NSNumber(float: Float(outputSize.height))]
        
        guard videoWriter.canApplyOutputSettings(outputSettings, forMediaType: AVMediaTypeVideo) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(unsignedInt: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(float: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(float: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if videoWriter.canAddInput(videoWriterInput) {
            videoWriter.addInput(videoWriterInput)
        }
        
        if videoWriter.startWriting() {
            videoWriter.startSessionAtSourceTime(kCMTimeZero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            let media_queue = dispatch_queue_create("mediaInputQueue", nil)
            
            videoWriterInput.requestMediaDataWhenReadyOnQueue(media_queue, usingBlock: { () -> Void in
                let fps: Int32 = 1
                let frameDuration = CMTimeMake(1, fps)
                
                var frameCount: Int64 = 0
                var appendSucceeded = true
                
                while (!self.choosenPhotos.isEmpty) {
                    if (videoWriterInput.readyForMoreMediaData) {
                        let nextPhoto = self.choosenPhotos.removeAtIndex(0)
                        let lastFrameTime = CMTimeMake(frameCount, fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        
                        if let pixelBuffer = pixelBuffer where status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, 0)
                            
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGBitmapContextCreate(data, Int(self.outputSize.width), Int(self.outputSize.height), 8, CVPixelBufferGetBytesPerRow(managedPixelBuffer), rgbColorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
                            
                            CGContextClearRect(context, CGRectMake(0, 0, CGFloat(self.outputSize.width), CGFloat(self.outputSize.height)))
                            
                            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
                            //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                            
                            let newSize:CGSize = CGSizeMake(nextPhoto.size.width * aspectRatio, nextPhoto.size.height * aspectRatio)
                            
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            
                            CGContextDrawImage(context, CGRectMake(x, y, newSize.width, newSize.height), nextPhoto.CGImage)
                            
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, 0)
                            
                            appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount+=1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWritingWithCompletionHandler { () -> Void in
                    print("\(frameCount) FINISHED!!!!!")
                }
            })
        }
    }

}

