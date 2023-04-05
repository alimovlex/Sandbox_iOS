/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import Foundation
import Alamofire

let LATITUDE = "lat=";
let LONGTITUDE = "&lon=";
let APP_ID = "&appid=";
let API_KEY = "dd901d59fd590a54f070075a96812a94";
            
let FORECAST_BASE_URL = "http://api.openweathermap.org/data/2.5/forecast?";
let API_UNITS = "&units=";
let API_METRIC_UNITS = "metric";
//let DAYS_COUNT = "&cnt=16";
typealias DownloadComplete = () -> ();

let mailServerHostname = "YOUR MAIL SERVER DOMAIN (IMAP/SMTP)";
let imapPort = 993;
let smtpPort = 465;
let mailLogin = "YOUR MAIL LOGIN";
let mailPassword = "YOUR MAIL PASSWORD";
let defaultSignature = """
 


 Sent with SynthMail for iOS.
""";

func forecastWeatherUrl () -> String {
    
    if let latitude = Services.sharedInstance.latitude, let longtitude = Services.sharedInstance.longtitude {
        return "\(FORECAST_BASE_URL)\(LATITUDE)\(latitude)\(LONGTITUDE)\(longtitude)\(APP_ID)\(API_KEY)\(API_UNITS)\(API_METRIC_UNITS)"
    } else {
        return "";
    }
}

struct Connectivity {
  static let sharedInstance = NetworkReachabilityManager()!
  static var isConnectedToInternet:Bool {
      return self.sharedInstance.isReachable
    }
}

//let stroka = "http://api.openweathermap.org/data/2.5/forecast/daily?lat=52&lon=86&cnt=10&appid=542ffd081e67f4512b705f89d2a611b2";

