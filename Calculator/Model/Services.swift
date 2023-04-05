/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import CoreLocation

class Services {
    
    static var sharedInstance = Services();
    private init() {
        
    }
    
    var latitude: Double?;
    var longtitude: Double?;

    func checkInternetConnection() -> Bool {
            if Connectivity.isConnectedToInternet {
                log.info("Connected");
                return true;
             } else {
                 log.info("No Internet");
                return false;
            }
        }
    
}
