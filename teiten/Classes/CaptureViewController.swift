//
//  CaptureViewController.swift
//  test
//
//  Created by nakajijapan on 2014/07/11.
//  Copyright (c) 2014年 net.nakajijapan. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreMedia
import CoreVideo
import QuartzCore

let kAppHomePath = "\(NSHomeDirectory())/Teiten"
let kAppMoviePath = "\(NSHomeDirectory())/Movies/Teiten"

class CaptureViewController: NSViewController, MovieMakerDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    // timer
    var timer:NSTimer!
    var timeInterval = 0
    @IBOutlet var countDownLabel:NSTextField!
    
    // resolution
    var screenResolution = ScreenResolution.size1280x720.rawValue
    
    
    // background
    @IBOutlet var backgroundView:NSView!
    
    // camera
    var previewView:NSView!
    
    // image
    var captureSession:AVCaptureSession!
    var videoOutput:AVCaptureStillImageOutput!
    
    @IBOutlet var tableView:NSTableView!
    var entity = FileEntity()
    
    
    // indicator
    @IBOutlet weak var indicator: NSProgressIndicator!
    //var windowController:PreferenceWindowController!
    
    override func awakeFromNib() {
        // I don't know that is why also loaded three times...
        //println("\(__FUNCTION__) : \(__LINE__) \(self.windowController)")
    }
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        
        // make working directory
        let fileManager = NSFileManager.defaultManager()
        
        do {
            try fileManager.createDirectoryAtPath("\(kAppHomePath)/images", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory. error: \(error.description)")
        }
        
        do {
            try fileManager.createDirectoryAtPath("\(kAppMoviePath)", withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("failed to make directory error: \(error.description)")
        }
        
        //-------------------------------------------------
        // initialize - settings
        self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
        if self.timeInterval < 1 {
            self.timeInterval = 10
            NSUserDefaults.standardUserDefaults().setInteger(self.timeInterval, forKey: "TIMEINTERVAL")
        }
        
        self.screenResolution = NSUserDefaults.standardUserDefaults().integerForKey("SCREENRESOLUTION")
        
        NSUserDefaults.standardUserDefaults().setInteger(self.screenResolution, forKey: "SCREENRESOLUTION")
        print("self.screenResolution = \(self.screenResolution)")
        
        
        //-------------------------------------------------
        // initialize - timer
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerAction:", userInfo: nil, repeats: true)
        self.timer.fire()
        
        // notifications
        self.initNotification()
        
        //-------------------------------------------------
        // initialize
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        // Video
        let videoInput = try! AVCaptureDeviceInput(device: device)
        let videoOutput = AVCaptureStillImageOutput()
        self.videoOutput = videoOutput
        
        self.captureSession = AVCaptureSession()
        self.captureSession.addInput(videoInput as AVCaptureInput)
        self.captureSession.addOutput(videoOutput)
        
        // AVCaptureSessionPreset1280x720
        self.captureSession.sessionPreset = ScreenResolution(rawValue: 0)!.toSessionPreset()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = CGRect(x: 0, y: 0, width: 640, height: 360)
        
        self.previewView = NSView(frame: NSRect(x:0, y: 0, width: 640, height: 360))
        self.previewView.layer = previewLayer
        
        self.backgroundView.addSubview(self.previewView, positioned: NSWindowOrderingMode.Below, relativeTo: self.backgroundView)
        
        // start
        self.captureSession.startRunning()
        
        //-------------------------------------------------
        // 許可するドラッグタイプを設定
        let types = [NSImage.imageTypes().first!, NSFilenamesPboardType]
        self.tableView.registerForDraggedTypes(types)
        self.tableView.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal: false)
    }
    
    // MARK: - notifications
    func initNotification() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "updateTimeInterval:", name: "changeTimeInterval", object: nil)
        nc.addObserver(self, selector: "updateScreenResolution:", name: "didChangeScreenResolution", object: nil)
    }
    
    func updateTimeInterval(sender:NSNotification) {
        let interval = sender.userInfo!["timeInterval"] as! NSNumber
        self.timeInterval = interval.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(interval.integerValue, forKey: "TIMEINTERVAL")
    }
    
    
    func updateScreenResolution(sender:NSNotification) {
        
        let screenResolution = sender.userInfo!["screenResolution"] as! NSNumber
        self.screenResolution = screenResolution.integerValue
        NSUserDefaults.standardUserDefaults().setInteger(self.screenResolution, forKey: "SCREENRESOLUTION")
        
        /*
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = ScreenResolution(rawValue: self.screenResolution)!.toSessionPreset()
        self.captureSession.commitConfiguration()
        */
        
    }
    
    // MARK: - Actions
    
    func timerAction(sender:AnyObject!) {
        
        self.countDownLabel.stringValue = String(self.timeInterval)
        
        if self.timeInterval > 0 {
            self.timeInterval--
        } else if (self.timeInterval == 0) {
            self.timeInterval = NSUserDefaults.standardUserDefaults().integerForKey("TIMEINTERVAL")
            self.pushButtonCaptureImage(nil)
        }
    }
    
    @IBAction func pushButtonCaptureImage(sender:AnyObject!) {
        
        let connection = self.videoOutput.connections[0] as! AVCaptureConnection
        
        self.videoOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {(sambleBuffer, erro) -> Void in
            
            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sambleBuffer)
            let tmpImage = NSImage(data: data)!
            let targetSize = ScreenResolution(rawValue: self.screenResolution)!.toSize()
            let image = self.imageFromSize(tmpImage, size: targetSize)
            
            // convert to jpeg for writing file
            let data2 = image.TIFFRepresentation
            let bitmapImageRep = NSBitmapImageRep.imageRepsWithData(data2!)[0] as! NSBitmapImageRep
            let properties = [NSImageInterlaced: NSNumber(bool: true)]
            let resizedData:NSData? = bitmapImageRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: properties)
            
            // reload table
            self.entity.loadImage(image, data: resizedData!)
            
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.tableView.reloadData()
            })
            
        })
    }
    
    func imageFromSize(sourceImage:NSImage, size:NSSize) -> NSImage! {
        
        // extract NSBitmapImageRep from sourceImage, and take out CGImage
        let image = NSBitmapImageRep(data: sourceImage.TIFFRepresentation!)?.CGImage!
        
        // generate new bitmap size
        let width  = Int(size.width)
        let height = Int(size.height)
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4) * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.PremultipliedLast.rawValue
        let bitmapContext = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!
        
        // write source image to bitmap
        let bitmapRect = NSMakeRect(0.0, 0.0, size.width, size.height)
        
        CGContextDrawImage(bitmapContext, bitmapRect, image)
        
        // convert NSImage to bitmap
        let newImageRef = CGBitmapContextCreateImage(bitmapContext)!
        let newImage = NSImage(CGImage: newImageRef, size: size)
        
        return newImage
        
    }
    
    @IBAction func pushButtonCreateMovie(sender:AnyObject!) {
        
        let movieMaker = MovieMaker()
        movieMaker.delegate = self
        movieMaker.size = ScreenResolution(rawValue: self.screenResolution)?.toSize()
        
        // images
        let images = movieMaker.getImageList()
        
        // save path
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let date = NSDate()
        let path = "\(kAppMoviePath)/\(dateFormatter.stringFromDate(date)).mov"
        
        // Indicator Start
        self.indicator.hidden = false
        self.indicator.doubleValue = 0
        self.indicator.startAnimation(self.indicator)
        
        // generate movie
        movieMaker.writeImagesAsMovie(images, toPath: path) { () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // Indicator Stop
                self.indicator.doubleValue = 100.0
                self.indicator.stopAnimation(self.indicator)
                self.indicator.hidden = true
                
                // Alert
                let alert = NSAlert()
                alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                alert.messageText = "Complete!!"
                alert.informativeText = "finished generating movie"
                alert.runModal()
            })
            
        }
        
    }
    
    // MARK: - MovieMakerDelegate
    
    // add Image
    func movieMakerDidAddImage(current: Int, total: Int) {
        let nst = NSThread(target:self, selector:"countOne:", object:["current": current, "total": total])
        nst.start()
    }
    
    // refrect count number to label
    func countOne(params: [String:Int]) {
        let delta = 100.0 / Double(params["total"]!)
        self.indicator.incrementBy(Double(delta))
    }
    
    
    // MARK: - NSTableView data source
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 1
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeViewWithIdentifier("imageCell", owner: self)
        let imageView = view!.viewWithTag(1) as! NSImageView
        imageView.image = self.entity.image
        imageView.alphaValue = 0.6
        return view
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 80
    }
    
    // MARK: - Drag
    
    func tableView(tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.entity
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        print("prepareForSegue: \(segue.identifier)")
        print(sender)
        
    }
    
}