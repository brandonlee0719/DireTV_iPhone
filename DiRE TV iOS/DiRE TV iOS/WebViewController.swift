//
//  WebViewController.swift
//  DiRE TV iOS
//
//  Created by ARUN PRASATH on 01/09/22.
//

import UIKit
import WebKit

protocol fromsecondVC {
    func valueFromSecond()
}

class WebViewController: UIViewController, WKUIDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var eventURl =
          "https://vimeo.com/event/2171363/embed/11f17392b8?autoplay=1&loop=1&autopause=0&muted=0"
    var liveTimer = Timer()
    
     var delegate : fromsecondVC?
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string: self.eventURl)
         let myRequest = URLRequest(url: myURL!)
        self.webView.load(myRequest)
//        self.webView.navigationDelegate = self
        self.webView.backgroundColor = .black
        self.view.backgroundColor = .black
        liveTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(liveLoad), userInfo: nil, repeats: true)
    }
    
    
    deinit {
        self.liveTimer.invalidate()
    }
    
    @objc func liveLoad() {
        print("Live Funtion calls")
         getLive(completion: { (val) in
             print(val)
             if val == false {
                 print("comes here?")
                 self.liveTimer.invalidate()
                 DispatchQueue.main.async {
                     self.dismiss(animated: true, completion: {
                         self.delegate?.valueFromSecond()
                     })
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
extension WebViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
           print("Started to load")
       }

       func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
           print("Finished loading")
       }
       
       
       func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                    decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
           if let response = navigationResponse.response as? HTTPURLResponse {
               print(response.statusCode, "response.statusCode")
               if response.statusCode >= 400 {
                   print("POPOPOPOPOPOP")
//                   self.navigationController?.popViewController(animated: false)
               }
           }
           decisionHandler(.allow)
       }
       func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
           print(error.localizedDescription, "Failed status")
       }
       
       func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
           print(navigation , "navigation")
       }
       
       func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
           print(error.localizedDescription, "didFail")
       }
       
       func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
           print(navigation , "didCommit")
       }
    
       func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
           if(navigationAction.navigationType == .other) {
               decisionHandler(.allow)
               return
           } else {
               decisionHandler(.cancel)
               return
           }
           decisionHandler(.allow)
       }


}
