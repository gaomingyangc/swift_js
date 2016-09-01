//
//  ViewController.swift
//  Test_js_swift
//
//  Created by gmy on 16/4/20.
//  Copyright © 2016年 dhc. All rights reserved.
//

import UIKit
import JavaScriptCore
class ViewController: UIViewController {
 
    var context = JSContext()
    var jsContext: JSContext?
    
    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        loadJS()
        
    }
    

    
    //MARK: - loadJS
    func loadJS() {
        let path = NSBundle.mainBundle().pathForResource("test", ofType: "html")
        let url = NSURL(fileURLWithPath: path!)
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    
    }
   
    // Swift 调用JS 方法 （无参数）
    @IBAction func swift_js_pargram(sender: AnyObject) {
        self.context.evaluateScript("Swift_JS1()")
//        self.webView.stringByEvaluatingJavaScriptFromString("Swift_JS1()") // 此方法也可行
    }
    
    // Swift 调用JS 方法 （有参数）
    @IBAction func swift_js_nopargam(sender: AnyObject) {
        self.context.evaluateScript("Swift_JS2('oc' ,'Swift')")
//        self.webView.stringByEvaluatingJavaScriptFromString("Swift_JS2('oc','swift')") // 此方法也可行
    }
    
    func menthod1() {
        print("JS调用了无参数swift方法")
    }
    
    func menthod2(str1: String, str2: String) {
        print("JS调用了有参数swift方法:参数为\(str1),\(str2)")
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print(error)
    }
}

extension ViewController: UIWebViewDelegate {
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let str = NSBundle.mainBundle().pathForResource("test", ofType: "html")
        let request = NSURLRequest(URL: NSURL(string: str!)!)
        let connecntion = NSURLConnection(request: request, delegate: self)
        connecntion?.start()
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        print("webViewDidStartLoad----")
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("webViewDidFinishLoad----")
        self.context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as! JSContext
        // JS调用了无参数swift方法
        let temp1: @convention(block) () ->() = {
            self.menthod1()
        }
        self.context.setObject(unsafeBitCast(temp1, AnyObject.self), forKeyedSubscript: "test1")
        
        // JS调用了有参数swift方法
        let temp2: @convention(block) () ->() = {
            let array = JSContext.currentArguments() // 这里接到的array中的内容是JSValue类型
            for object in array {
                print(object)
            }
            self.menthod2(array[0].toString(), str2: array[1].toString())
        }
        self.context.setObject(unsafeBitCast(temp2, AnyObject.self), forKeyedSubscript: "test2")
        
        // 模型注入的方法
        
        let model = JSObjCModel()
        model.controller = self
        model.jsContext = context
        self.jsContext = context
        
        // 这一步是将OCModel这个模型注入到JS中，在JS就可以通过OCModel调用我们公暴露的方法了。
        self.jsContext?.setObject(model, forKeyedSubscript: "OCModel")
        let url = NSBundle.mainBundle().URLForResource("test", withExtension: "html")
        self.jsContext?.evaluateScript(try? String(contentsOfURL: url!, encoding: NSUTF8StringEncoding));
        
        self.jsContext?.exceptionHandler = {
            (context, exception) in
            print("exception @", exception)
        }

    }
    
}

@objc protocol JavaScriptSwiftDelegate: JSExport {
    func callSystemCamera()
    
    func showAlert(title: String, msg: String)
    
    func callWithDict(dict: [String: AnyObject])
    
    func jsCallObjcAndObjcCallJsWithDict(dict: [String: AnyObject])
}

@objc class JSObjCModel: NSObject, JavaScriptSwiftDelegate {
    weak var controller: UIViewController?
    weak var jsContext: JSContext?
    
    func callSystemCamera() {
        print("js call objc method: callSystemCamera");
        
        let jsFunc = self.jsContext?.objectForKeyedSubscript("jsFunc");
        jsFunc?.callWithArguments([]);
    }
    
    func showAlert(title: String, msg: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: nil))
            self.controller?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // JS调用了我们的方法
    func callWithDict(dict: [String : AnyObject]) {
        print("js call objc method: callWithDict, args: %@", dict)
    }
    
    // JS调用了我们的方法
    func jsCallObjcAndObjcCallJsWithDict(dict: [String : AnyObject]) {
        print("js call objc method: jsCallObjcAndObjcCallJsWithDict, args: %@", dict)
        
        let jsParamFunc = self.jsContext?.objectForKeyedSubscript("jsParamFunc");
        let dict = NSDictionary(dictionary: ["age": 18, "height": 168, "name": "lili"])
        jsParamFunc?.callWithArguments([dict])
    }
}
extension ViewController: NSURLConnectionDelegate,NSURLConnectionDataDelegate {

    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        print("didReceiveData\(data)")
    }
    
    func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {
        print("request:\(request)response:\(response)")
        return request
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        
    }
    
    
}

//MARK: -  allowsAnyHTTPSCertificateForHost
extension NSURLRequest {
    static func allowsAnyHTTPSCertificateForHost(host: String) -> Bool {
        return true
    }
}
