//
//  iPadViewController.swift
//  DiRE TV iOS
//
//  Created by ARUN PRASATH on 01/09/22.
//

import UIKit
import AVKit
import AVFoundation
import MarqueeLabel
import Network

class iPadViewController: UIViewController {

    @IBOutlet weak var playerView: VideoPlayerView!
    @IBOutlet weak var tickerView: UIView!
    @IBOutlet weak var marqueeTextValues: MarqueeLabel!
    @IBOutlet weak var dateTimeText: UILabel!
    @IBOutlet weak var whiteLogo: UIImageView!
    @IBOutlet weak var NoInternetLabel: UILabel!
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    var videosList = [String]()
    var tickerData = NSMutableAttributedString()
    var tickerData1 = NSMutableAttributedString()
    var isOffline = false
    var eventURl =
          "https://vimeo.com/event/2171363/embed/11f17392b8?autoplay=1&loop=1&autopause=0&muted=0"
    
    var timer = Timer()
    var playerAVView:AVPlayer!
    var tickerTimer = Timer()
    var liveTimer = Timer()
    var CheckTimer = Timer()
//    var reachability: Reachability?
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    var internetConnection = false
    
    deinit {
        timer.invalidate()
        tickerTimer.invalidate()
        liveTimer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override class func attemptRotationToDeviceOrientation() {
        print("adfsdf")
    }

    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask  {
        return [UIInterfaceOrientationMask.landscapeLeft, UIInterfaceOrientationMask.landscapeRight]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        whiteLogo.alpha = 0.5
        whiteLogo.isHidden = true
        tickerView.isHidden = true
        playerView.bringSubviewToFront(whiteLogo)
        playerView.backgroundColor = .clear
        self.playVideo()
        self.NoInternetLabel.isHidden = true
        if self.internetConnection == true {
            self.view.backgroundColor = .black
            if playerIndex == 0 || playerIndex == -1 || (playerIndex + 1) == self.videosList.count {
                getVideos(completion: { (videos) in
                    DispatchQueue.main.async {
                        self.videosList = videos
                        playerIndex = 0
                        self.checkPreload()
                    }
                })
            }
        }
    }
    
    @objc func liveLoad() {
         getLive(completion: { (value) in
             if value == true {
                 self.liveTimer.invalidate()
                 self.playerView.pause(reason: .userInteraction)
                 DispatchQueue.main.async {
                     let vc = self.storyboard?.instantiateViewController(withIdentifier: "iPadWebViewController") as! iPadWebViewController
                     vc.modalPresentationStyle = .fullScreen
                     self.present(vc, animated: true, completion: nil)
                 }
             }
         })
     }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print(playerIndex , "PlayerIndex")
    }
    
    func checkPreload() {
        let urls = self.videosList
            .suffix(from: min(playerIndex + 1, videosList.count))
            .prefix(1)
        print(urls,"url")
        if (!urls.isEmpty) {
            if let urlValue = URL(string: urls.first!) {
                VideoPreloadManager.shared.set(waiting: Array(arrayLiteral: urlValue))
                VideoPreloadManager.shared.start()
            }
        }
    }
    
    @objc func tickerFunc() {
        self.tickerData = NSMutableAttributedString(string: "")
        fetchTickerData(completion: { (ticker) in
            print(ticker.items?.count, "ticker.items?.count")
            let map = ticker.items?.map({ (items) -> NSMutableAttributedString in
                let attri = NSMutableParagraphStyle()
                attri.lineBreakMode = .byCharWrapping
                attri.alignment = .center
                attri.allowsDefaultTighteningForTruncation = false
                
                let titleAttributes : [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.paragraphStyle: attri,
                    NSAttributedString.Key.baselineOffset: 15,
                    NSAttributedString.Key.foregroundColor: UIColor.black,
                    NSAttributedString.Key.font: UIFont.Robotos(.bold, size: 35)
                        /*UIFont.systemFont(ofSize: 30, weight: .bold)*/]
                let contentOtherAttributes : [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.paragraphStyle: attri,
                    NSAttributedString.Key.baselineOffset : 15,
                    NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.Robotos(.regular, size: 35)
                        /*UIFont.systemFont(ofSize: 30, weight: .regular)*/,]
                let iOtherAttributes : [NSAttributedString.Key : Any]  = [
                    NSAttributedString.Key.paragraphStyle: attri,
                    NSAttributedString.Key.foregroundColor: UIColor.red, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 80, weight: .bold)]
                let titleText = NSMutableAttributedString.init(string: "\(items.title ?? "")     ")
                titleText.addAttributes(titleAttributes, range: NSRange(location: 0, length: titleText.length))
                /*(string: "\(itemsV.title ?? "")    ", attributes: titleAttributes)*/
                let contentText = NSMutableAttributedString.init(string: "\(items.content ?? "")")
                contentText.addAttributes(contentOtherAttributes, range: NSRange(location: 0, length: contentText.length))
                
                /*(string: "\(itemsV.content ?? "")  ", attributes: contentOtherAttributes)*/
                let iText = NSMutableAttributedString.init(string: " I ")
                iText.addAttributes(iOtherAttributes, range: NSRange(location: 0, length: iText.length))
                /*(string: "I ", attributes: iOtherAttributes)*/
                
                iText.append(titleText)
                iText.append(contentText)
                self.tickerData.append(iText)
                return self.tickerData
            })
            DispatchQueue.main.async {
                self.marqueeTextValues.contentMode = .center
                self.marqueeTextValues.baselineAdjustment = .alignCenters
                self.marqueeTextValues.attributedText = self.tickerData
                self.marqueeTextValues.speed = MarqueeLabel.SpeedLimit.duration(300)
                self.marqueeTextValues.forceScrolling = false
                self.marqueeTextValues.animationCurve = .linear
                self.marqueeTextValues.fadeLength = 3.0
                self.marqueeTextValues.animationDelay = 0.5
               
            }
        })
    }
    
    

    
    @objc func tick() {
        let foramt = DateFormatter()
        foramt.dateFormat = "HH : mm"
        dateTimeText.text = foramt.string(from: Date())
        dateTimeText.textColor = .black
        dateTimeText.font = UIFont.systemFont(ofSize: 35)
    }
    
    
    private func playVideo() {
        let path = Bundle.main.path(forResource: "splash_background", ofType: "mp4")!
        let videoURL = URL(fileURLWithPath: path)
        playerView.play(for: videoURL)
       
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
                         object: playerView.playerLayer.player?.currentItem
        )
    }
    
    
   @objc func playerDidFinishPlaying(_ note: NSNotification) {
       monitor.start(queue: queue)

       monitor.pathUpdateHandler = { pathUpdateHandler in
           print(pathUpdateHandler.status)
           if pathUpdateHandler.status == .satisfied {
               print("Internet connection is on.")
               DispatchQueue.main.async {
                   self.internetConnection = true
                   self.NoInternetLabel.isHidden = true
                   self.timer = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
                   self.tickerTimer = Timer.scheduledTimer(timeInterval: 300.0, target: self, selector: #selector(self.tickerFunc), userInfo: nil, repeats: true)
                   self.liveTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.liveLoad), userInfo: nil, repeats: true)
                   
                   self.getVideos(completion: { (videos) in
                       DispatchQueue.main.async {
                           print("ksjndjksnjnsdjnf")
                           self.playerView.isHidden = false
                           self.playerView.playerLayer.isHidden = false
                           self.videosList = videos
                           playerIndex = 0
                           self.checkPreload()
                           self.tickerFunc()
                           self.playVideoUrl()
                       }
                   })
               }
              
           } else {
               print("There's no internet connection.")
               DispatchQueue.main.async {
                  
                   self.playerView.isHidden = true
                   self.playerView.playerLayer.isHidden = true
                   self.internetConnection = false
                   self.NoInternetLabel.isHidden = false
                   self.playerView.pause(reason: .userInteraction)
                   self.whiteLogo.isHidden = true
                   self.tickerView.isHidden = true
                   self.timer.invalidate()
                   self.tickerTimer.invalidate()
                   self.liveTimer.invalidate()
               }
           }
       }
    }
    
 
    
    func playVideoUrl() {
        self.whiteLogo.isHidden = false
        self.tickerView.isHidden = false
        print(playerIndex)
        guard let videoURL = URL(string: self.videosList[playerIndex]) else { return }
        playerView.playerLayer.videoGravity = .resizeAspect
        playerView.play(for: videoURL)
        playerView.player?.playImmediately(atRate: 1.0)
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying1),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerView.playerLayer.player?.currentItem)
    }
    
    
    func fromwebview() {
        getVideos(completion: { (videos) in
            DispatchQueue.main.async {
                self.videosList = videos
                playerIndex = 0
                self.checkPreload()
            }
        })
    }
    
    @objc func playerDidFinishPlaying1(_ note: NSNotification) {
        playVideoUrl()
        checkPreload()
     }
    
    func getVideos(completion: @escaping ([String])-> ()) {
        let urlString = "https://tv.dire.it/api/Videos/getallvideos?page=0&size=10&category=all"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let json = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String : Any]
                        let videos = json["videos"] as! NSArray
                        var frnd = [String]()
                        for val in videos {
                            if let vid = val as? [String : Any] {
                                frnd.append(vid["mp4url"] as! String)
                            }
                        }
                       print(frnd)
                      completion(frnd)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
    
    func getLive(completion: @escaping (Bool)-> ()) {
        let urlString = "https://tv.dire.it/api/Videos/getlivestatus"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let json = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String : Any]
                        let isLive = json["isLive"] as! Bool
                      completion(isLive)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
    
    
    func fetchTickerData(completion: @escaping (TickerData)-> ()) {
        let urlString = "https://api.rss2json.com/v1/api.json?rss_url=https://www.dire.it/feed/ultimenews&api_key=nfrmkxownjdzgy2n5vtuwkhav7w8ivakwqyz6wtj&count=100"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let jsonDecoder = JSONDecoder()
                        let responseModel = try jsonDecoder.decode(TickerData.self, from: data)
                        completion(responseModel)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
}


        /*
         func loadFirstVideo() {
             let path = Bundle.main.path(forResource: "dire_tv", ofType: "mp4")!
             let videoURL = URL(fileURLWithPath: path)
             playerView.play(for: videoURL)
             NotificationCenter.default
                 .addObserver(self,
                 selector: #selector(playerDidFirstFinishPlaying),
                 name: .AVPlayerItemDidPlayToEndTime,
                              object: playerView.playerLayer.player?.currentItem)
              playerView.playerLayer.player?.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 1, preferredTimescale: 1), queue: .main, using: { _ in
                  if self.playerView.playerLayer.player?.currentItem?.status == .readyToPlay {
                      self.whiteLogo.isHidden = false
                      self.tickerView.isHidden = false
                  }
              })
         }
         
         @objc func playerDidFirstFinishPlaying(_ note: NSNotification) {
             playerIndex = 0
             playVideoUrl()
             checkPreload()
          }
         */


//    @objc func tickerApi() {
//        fetchTickerData(completion: { (ticker) in
//            if let items = ticker.items {
//                self.tickerData = NSMutableAttributedString(string: "")
//                for itemsV in items {
//                    let attri = NSMutableParagraphStyle()
//                    attri.lineBreakMode = .byCharWrapping
//                    attri.alignment = .center
//                    attri.allowsDefaultTighteningForTruncation = false
//
//                    let titleAttributes : [NSAttributedString.Key : Any] = [
//                        NSAttributedString.Key.paragraphStyle: attri,
//                        NSAttributedString.Key.baselineOffset: 15,
//                        NSAttributedString.Key.foregroundColor: UIColor.black,
//                        NSAttributedString.Key.font: UIFont.Robotos(.bold, size: 35)
//                            /*UIFont.systemFont(ofSize: 30, weight: .bold)*/]
//                    let contentOtherAttributes : [NSAttributedString.Key : Any] = [
//                        NSAttributedString.Key.paragraphStyle: attri,
//                        NSAttributedString.Key.baselineOffset : 15,
//                        NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.Robotos(.regular, size: 35)
//                            /*UIFont.systemFont(ofSize: 30, weight: .regular)*/,]
//                    let iOtherAttributes : [NSAttributedString.Key : Any]  = [
//                        NSAttributedString.Key.paragraphStyle: attri,
//                        NSAttributedString.Key.foregroundColor: UIColor.red, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 80, weight: .bold)]
//                    let titleText = NSMutableAttributedString.init(string: "\(itemsV.title ?? "")     ")
//                    titleText.addAttributes(titleAttributes, range: NSRange(location: 0, length: titleText.length))
//                    /*(string: "\(itemsV.title ?? "")    ", attributes: titleAttributes)*/
//                    let contentText = NSMutableAttributedString.init(string: "\(itemsV.content ?? "")")
//                    contentText.addAttributes(contentOtherAttributes, range: NSRange(location: 0, length: contentText.length))
//
//                    /*(string: "\(itemsV.content ?? "")  ", attributes: contentOtherAttributes)*/
//                    let iText = NSMutableAttributedString.init(string: " I ")
//                    iText.addAttributes(iOtherAttributes, range: NSRange(location: 0, length: iText.length))
//                    /*(string: "I ", attributes: iOtherAttributes)*/
//
//                    iText.append(titleText)
//                    iText.append(contentText)
//                    self.tickerData.append(iText)
//
//                }
//                print(self.tickerData)
//            }
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
//                self.marqueeTextValues.contentMode = .center
//                self.marqueeTextValues.baselineAdjustment = .alignCenters
//                self.marqueeTextValues.attributedText = self.tickerData
//                self.marqueeTextValues.speed = MarqueeLabel.SpeedLimit.duration(300)
////                self.marqueeTextValues.type = .continuous
//                self.marqueeTextValues.forceScrolling = false
//                self.marqueeTextValues.animationCurve = .linear
//                self.marqueeTextValues.fadeLength = 3.0
//            })
//        })
//    }
