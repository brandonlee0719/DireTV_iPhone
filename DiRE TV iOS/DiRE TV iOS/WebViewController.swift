//
//  WebViewController.swift
//  DiRE TV iOS
//
//  Created by ARUN PRASATH on 01/09/22.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var eventURl =
          "https://vimeo.com/event/2171363/embed/11f17392b8?autoplay=1&loop=1&autopause=0&muted=0"
    var liveTimer = Timer()
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string: self.eventURl)
         let myRequest = URLRequest(url: myURL!)
        self.webView.load(myRequest)
        self.webView.backgroundColor = .black
        self.view.backgroundColor = .black
        liveTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(liveLoad), userInfo: nil, repeats: true)
    }
    
    
    @objc func liveLoad() {
         getLive(completion: { (val) in
             
             if val == false {
                 self.liveTimer.invalidate()
                 DispatchQueue.main.async {
                     if let topController = UIApplication.topViewController() as? WebViewController{
                         topController.dismiss(animated: false, completion: nil)
                     }
                 }
                 
             }
         })
     }
    
    
//    "toPhone"
    
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

}
