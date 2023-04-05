/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import UIKit
import CoreLocation
import Alamofire

class WeatherVC: UITableViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager();
    var currentLocation: CLLocation!;
    var forecast: Forecast!;
    var forecasts = [Forecast]();
    @IBOutlet weak var currentCity: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        locationManager.delegate = self;
        locationManager.requestWhenInUseAuthorization();
        locationManager.startMonitoringSignificantLocationChanges();
        //forecast = Forecast();
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Services.sharedInstance.checkInternetConnection() {
            locationAuthStatus();
            downloadForecastData {
                log.info("Downloaded the weather forecast data.");
            }
        } else {
            let alertController = UIAlertController(title: "Please enable wifi connection in the settings menu.", message: "The internet connection is required.", preferredStyle: .alert);
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: "App-Prefs:root=WIFI")!)
                } else {
                    let settingsUrl = URL(string: "App-Prefs:root=WIFI")
                    if let url = settingsUrl {
                        UIApplication.shared.openURL(url);
                    } else {
                        log.info("incorrect URL provided!");
                    }
                }
                }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel); //dismissing the entrance of the URL
            
            alertController.addAction(settingsAction) //connect the submit button the UIAlertController
            alertController.addAction(cancelAction) //connect the cancel button the UIAlertController
            
            present(alertController, animated: true) //showing the URL entrance message
        }
        
    }
    
    func locationAuthStatus() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in //thread added
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self?.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self?.currentLocation = self?.locationManager.location;
            Services.sharedInstance.latitude = self?.currentLocation.coordinate.latitude;
            Services.sharedInstance.longtitude = self?.currentLocation.coordinate.longitude;
            //print(Services.sharedInstance.latitude, Services.sharedInstance.longtitude);
        } else {
            self?.locationManager.requestWhenInUseAuthorization();
            self?.locationAuthStatus();
            }
        }
    }
    
    func downloadForecastData(completed: @escaping DownloadComplete) {
        //Downloading forecast weather data for TableView
        //let forecastURL = URL(string: FORECAST_URL);
        DispatchQueue.global(qos: .background).async { [weak self] in //thread added
        Alamofire.request(forecastWeatherUrl()).responseJSON { response in
            let result = response.result;
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                for (key, value) in dict {
                    log.info("\(key) -> \(value)");
                }
                if let name = dict["city"] as? Dictionary<String, AnyObject>, let cityName = name["name"] as? String {
                    self?.currentCity.text = cityName.capitalized;
                    log.info(name);
                } else {
                    log.warning("Unable to infer the city based on the location provided.");
                }
                
                if let list = dict["list"] as? [Dictionary<String, AnyObject>] {
                    
                    for obj in list {
                        let forecast = Forecast(weatherDict: obj);
                        self?.forecasts.append(forecast);
                        //print(obj);
                    }
                    self?.forecasts.remove(at: 0);
                    self?.tableView.reloadData();
                }
            }
            completed();
            }
        }
    }
    /*
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    */
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecasts.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "weatherCell", for: indexPath) as? WeatherCell {
            
            let forecast = forecasts[indexPath.row];
            cell.configureCell(forecast: forecast);
            return cell;
        } else {
            return WeatherCell();
        }
    }
    
    @IBAction func reloadWeatherForecast(_ sender: UIRefreshControl) {
        tableView.reloadData();
        downloadForecastData {
            sender.endRefreshing();
        }
    }

}
