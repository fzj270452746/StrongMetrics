import UIKit
import WebKit
import AppsFlyerLib

private var JSUAO = [String]()
//internal var HuntOrderKrajs = [String()]

//rechargeClick,amount,recharge,jsBridge,withdrawOrderSuccess,params,firstrecharge,firstCharge,charge,currency,addToCart,openWindow,deposit

let Brie = JSUAO[0]              //jsBridge
let amt = JSUAO[1]     //amount
let ren = JSUAO[2]      //currency
let OpWin = JSUAO[3]      //openWindow

//let diaChon = husnOjauehs[0]      //rechargeClick
//let amt = husnOjauehs[1]     //amount
//let chozh = husnOjauehs[2]      //recharge
//let Brie = husnOjauehs[3]              //jsBridge
//let hdrawo = husnOjauehs[4]   //withdrawOrderSuccess
//let rams = husnOjauehs[5]      //params
//let diyicicho = husnOjauehs[6]      //firstrecharge
//let diyichCha = husnOjauehs[7]    //firstCharge
//let geicho = husnOjauehs[8]         //charge
//let ren = husnOjauehs[9]      //currency
//let aTc = husnOjauehs[10]  //addToCart
//let OpWin = husnOjauehs[11]      //openWindow
//let deop = husnOjauehs[12]       //deposit


internal class AieunVcgyViewC: UIViewController,WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    var msjeiws: Hseshen?
    var kksmeo: WKWebView?
    
    private var kaoieus: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if msjeiws!.hhbaie != nil {
            view.backgroundColor = UIColor.init(hexString: msjeiws!.hhbaie!)
        }
        
        AppsFlyerLib.shared().appsFlyerDevKey = msjeiws!.woajen!
        AppsFlyerLib.shared().appleAppID = msjeiws!.auybse!
        AppsFlyerLib.shared().start { res, err in
            if (err != nil) {
                print(err as Any)
            }
        }
//        let aaq = ADJConfig(appToken: sinakeo!.qtzbzse!, environment: ADJEnvironmentProduction)
////        aaq?.delegate = self
//        Adjust.initSdk(aaq)
//        
        
        JSUAO = msjeiws!.dieny!.components(separatedBy: ",")
//        HuntOrderKrajs = [aTc,diaChon, diyicicho, hdrawo, geicho, chozh, diyichCha, deop]
        let usrScp = WKUserScript(source: msjeiws!.manjsuq!, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let usCt = WKUserContentController()
        usCt.addUserScript(usrScp)
        let cofg = WKWebViewConfiguration()
        cofg.userContentController = usCt
        cofg.allowsInlineMediaPlayback = true
        cofg.userContentController.add(self, name: Brie)
        cofg.defaultWebpagePreferences.allowsContentJavaScript = true
        kksmeo = WKWebView(frame: .zero, configuration: cofg)
        kksmeo!.allowsBackForwardNavigationGestures = true
        kksmeo?.uiDelegate = self
        kksmeo?.navigationDelegate = self
        view.addSubview(kksmeo!)
        
        
        kaoieus = msjeiws!.msjooi!
        kksmeo?.load(URLRequest(url:URL(string: kaoieus!)!))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let statusBarManager = ws.statusBarManager {
            
            let statusBarHeight = msjeiws!.msokenb!.contains("V") ? statusBarManager.statusBarFrame.height : 0
            let bottomHeight = msjeiws!.msokenb!.contains("I") ? view.safeAreaInsets.bottom : 0
            kksmeo?.frame = CGRectMake(0, statusBarHeight, view.bounds.width, view.bounds.height - statusBarHeight - bottomHeight)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
//        let nwv = WKWebView(frame: webView.bounds, configuration: configuration)
//        
//        let bck = UIButton(type: .custom)
//        bck.frame = CGRect(x: 10, y: 30, width: 100, height: 100)
//        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
//        bck.setImage(UIImage(systemName: "arrowshape.left.circle.fill", withConfiguration: config), for: .normal)
//        bck.addTarget(self, action: #selector(eabsuhd(_:)), for: .touchUpInside)
//        nwv.addSubview(bck)
//        
//        nwv.uiDelegate = self
//        nwv.navigationDelegate = self
//        webView.addSubview(nwv)
//        return nwv

        let ul = navigationAction.request.url
        if ((ul?.absoluteString.hasPrefix(webView.url!.absoluteString)) != nil) {
            UIApplication.shared.open(ul!)
//            webView.load(navigationAction.request)
        }
        return nil
    }
    
//    @objc private func eabsuhd(_ btn:UIButton) {
//        let v = btn.superview
//        v?.removeFromSuperview()
//    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Brie {
            let dic = message.body as! [String : String]
            Ewuinass(dic)
        }
    }
    
    override var shouldAutorotate: Bool {
        true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }
}


//internal class EachCompareNavigationController: UINavigationController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        isNavigationBarHidden = true
//    }
//    
//    override var shouldAutorotate: Bool {
//        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
//    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
//    }
//}
