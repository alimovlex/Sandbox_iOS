/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import UIKit

class WeatherCell: UITableViewCell {

    @IBOutlet weak var weatherIcon: UIImageView!;
    @IBOutlet weak var dayLabel: UILabel!;
    @IBOutlet weak var weatherType: UILabel!;
    @IBOutlet weak var highTemp: UILabel!
    @IBOutlet weak var lowTemp: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    func configureCell(forecast: Forecast) {
        lowTemp.text = forecast.lowTemp;
        highTemp.text = forecast.highTemp;
        weatherType.text = forecast.weatherType;
        weatherIcon.image = UIImage(named: forecast.weatherType)
        dayLabel.text = forecast.date;
        timeLabel.text = forecast.time;
    }

}
