# ARFlatWeather
Portable flat weather display in ARKit inspired by this [article](http://www.augment.com/blog/4-ways-augmented-reality-will-change-everyday-life/). I wrote a [few words](https://nagam11.github.io/nagam11.github.io/ARKit-Live-Weather-Dashboard/) about this project in my blog.

<img src="weather.gif" width="200">

## Features
* ARKit with SceneKit for image and text nodes.
* Live 3 day forecast data from OpenWeather API based on your location.
* AVSpeechSynthesizer on tap **(Click on the dashboard to activate)**


## Setup
1. Go to [OpenWeather API](https://openweathermap.org/api) and create a new API token.
2. Replace the API-TOKEN in the code, in the method getWeather() with your token.
3. Run on iPhone > 6s.

## TODOs
*  ~~Show live weather from OpenWeather API.~~
* ~~Fix image assignement (sunny,cloudy, rainy) based on data from API.~~
* Add weather display on specific location on click.
* ~~Get location from phone.~~


