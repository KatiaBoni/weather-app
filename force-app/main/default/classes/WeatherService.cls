/**
 * @description       : 
 * @author            : KBoni
 * @group             : 
 * @last modified on  : 03-25-2026
 * @last modified by  : KBoni
**/
public with sharing class WeatherService {

    public static WeatherResult getWeatherByCity(String city) {
        Http http = new Http();

        HttpRequest geoReq = new HttpRequest();
        geoReq.setMethod('GET');
        geoReq.setEndpoint(
            'https://geocoding-api.open-meteo.com/v1/search?name=' +
            EncodingUtil.urlEncode(city, 'UTF-8') +
            '&count=1&language=it&format=json'
        );

        HttpResponse geoRes = http.send(geoReq);

        if (geoRes.getStatusCode() != 200) {
            throw new AuraHandledException('Errore durante la ricerca della città.');
        }

        Map<String, Object> geoData =
            (Map<String, Object>) JSON.deserializeUntyped(geoRes.getBody());

        List<Object> results = (List<Object>) geoData.get('results');

        if (results == null || results.isEmpty()) {
            throw new AuraHandledException('Città non trovata.');
        }

        Map<String, Object> firstResult = (Map<String, Object>) results[0];

        Decimal latitude = Decimal.valueOf(String.valueOf(firstResult.get('latitude')));
        Decimal longitude = Decimal.valueOf(String.valueOf(firstResult.get('longitude')));
        String resolvedName = String.valueOf(firstResult.get('name'));
        String country = String.valueOf(firstResult.get('country'));

        WeatherResult result = getWeatherByCoordinates(latitude, longitude);
        result.cityName = resolvedName;
        result.country = country;

        return result;
    }

    public static WeatherResult getWeatherByCoordinates(Decimal latitude, Decimal longitude) {
        Http http = new Http();

        HttpRequest weatherReq = new HttpRequest();
        weatherReq.setMethod('GET');
        weatherReq.setEndpoint(
            'https://api.open-meteo.com/v1/forecast?latitude=' +
            String.valueOf(latitude) +
            '&longitude=' +
            String.valueOf(longitude) +
            '&current=temperature_2m,precipitation,wind_speed_10m,relative_humidity_2m,weather_code' +
            '&daily=weather_code,temperature_2m_max,temperature_2m_min' +
            '&forecast_days=3&timezone=auto'
        );

        HttpResponse weatherRes = http.send(weatherReq);

        if (weatherRes.getStatusCode() != 200) {
            throw new AuraHandledException('Errore durante il recupero del meteo.');
        }

        Map<String, Object> weatherData =
            (Map<String, Object>) JSON.deserializeUntyped(weatherRes.getBody());

        Map<String, Object> currentData =
            (Map<String, Object>) weatherData.get('current');

        if (currentData == null || !currentData.containsKey('temperature_2m')) {
            throw new AuraHandledException('Dati meteo non disponibili.');
        }

        Map<String, Object> currentUnits =
            (Map<String, Object>) weatherData.get('current_units');

        Integer weatherCode = currentData.containsKey('weather_code')
            ? Integer.valueOf(String.valueOf(currentData.get('weather_code')))
            : null;

        WeatherResult result = new WeatherResult();

        Map<String, String> locationInfo = reverseGeocode(latitude, longitude);
        result.cityName = locationInfo.get('city');
        result.country = locationInfo.get('country');

        result.temperature = currentData.containsKey('temperature_2m')
            ? Decimal.valueOf(String.valueOf(currentData.get('temperature_2m')))
            : null;
        result.temperatureUnit = currentUnits != null && currentUnits.containsKey('temperature_2m')
            ? String.valueOf(currentUnits.get('temperature_2m'))
            : '°C';

        result.windSpeed = currentData.containsKey('wind_speed_10m')
            ? Decimal.valueOf(String.valueOf(currentData.get('wind_speed_10m')))
            : null;
        result.windSpeedUnit = currentUnits != null && currentUnits.containsKey('wind_speed_10m')
            ? String.valueOf(currentUnits.get('wind_speed_10m'))
            : 'km/h';

        result.precipitation = currentData.containsKey('precipitation')
            ? Decimal.valueOf(String.valueOf(currentData.get('precipitation')))
            : null;
        result.precipitationUnit = currentUnits != null && currentUnits.containsKey('precipitation')
            ? String.valueOf(currentUnits.get('precipitation'))
            : 'mm';

        result.humidity = currentData.containsKey('relative_humidity_2m')
            ? Decimal.valueOf(String.valueOf(currentData.get('relative_humidity_2m')))
            : null;
        result.humidityUnit = currentUnits != null && currentUnits.containsKey('relative_humidity_2m')
            ? String.valueOf(currentUnits.get('relative_humidity_2m'))
            : '%';

        result.weatherCode = weatherCode;
        result.weatherDescription = getWeatherDescription(weatherCode);
        result.weatherEmoji = getWeatherEmoji(weatherCode);
        result.weatherTheme = getWeatherTheme(weatherCode);
        result.forecast = buildForecast(weatherData);

        return result;
    }

    public static List<CitySuggestion> searchCities(String query) {
        if (String.isBlank(query) || query.trim().length() < 3) {
            return new List<CitySuggestion>();
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(
            'https://geocoding-api.open-meteo.com/v1/search?name=' +
            EncodingUtil.urlEncode(query.trim(), 'UTF-8') +
            '&count=5&language=it&format=json'
        );

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Errore durante la ricerca delle città.');
        }

        Map<String, Object> data =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        List<CitySuggestion> suggestions = new List<CitySuggestion>();
        List<Object> results = (List<Object>) data.get('results');

        if (results == null) {
            return suggestions;
        }

        for (Object item : results) {
            Map<String, Object> city = (Map<String, Object>) item;

            CitySuggestion suggestion = new CitySuggestion();
            suggestion.name = String.valueOf(city.get('name'));
            suggestion.country = String.valueOf(city.get('country'));
            suggestion.latitude = city.containsKey('latitude')
                ? Decimal.valueOf(String.valueOf(city.get('latitude')))
                : null;
            suggestion.longitude = city.containsKey('longitude')
                ? Decimal.valueOf(String.valueOf(city.get('longitude')))
                : null;
            suggestion.label = suggestion.name + ', ' + suggestion.country;

            suggestions.add(suggestion);
        }

        return suggestions;
    }

    private static Map<String, String> reverseGeocode(Decimal latitude, Decimal longitude) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(
            'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=' +
            String.valueOf(latitude) +
            '&longitude=' +
            String.valueOf(longitude) +
            '&localityLanguage=it'
        );

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            return new Map<String, String>{
                'city' => 'Posizione attuale',
                'country' => ''
            };
        }

        Map<String, Object> data =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        String city = '';
        String country = '';

        if (data.containsKey('city') && data.get('city') != null) {
            city = String.valueOf(data.get('city'));
        } else if (data.containsKey('locality') && data.get('locality') != null) {
            city = String.valueOf(data.get('locality'));
        } else {
            city = 'Posizione attuale';
        }

        if (data.containsKey('countryName') && data.get('countryName') != null) {
            country = String.valueOf(data.get('countryName'));
        }

        return new Map<String, String>{
            'city' => city,
            'country' => country
        };
    }

    private static List<ForecastDay> buildForecast(Map<String, Object> weatherData) {
        List<ForecastDay> forecastDays = new List<ForecastDay>();

        if (weatherData == null || !weatherData.containsKey('daily')) {
            return forecastDays;
        }

        Map<String, Object> dailyData = (Map<String, Object>) weatherData.get('daily');
        if (dailyData == null) {
            return forecastDays;
        }

        List<Object> dates = (List<Object>) dailyData.get('time');
        List<Object> maxTemps = (List<Object>) dailyData.get('temperature_2m_max');
        List<Object> minTemps = (List<Object>) dailyData.get('temperature_2m_min');
        List<Object> codes = (List<Object>) dailyData.get('weather_code');

        Integer size = 0;
        if (dates != null) size = dates.size();

        for (Integer i = 0; i < size; i++) {
            ForecastDay day = new ForecastDay();
            day.data = String.valueOf(dates[i]);
            day.tempMax = maxTemps != null && i < maxTemps.size() && maxTemps[i] != null
                ? Decimal.valueOf(String.valueOf(maxTemps[i]))
                : null;
            day.tempMin = minTemps != null && i < minTemps.size() && minTemps[i] != null
                ? Decimal.valueOf(String.valueOf(minTemps[i]))
                : null;

            Integer code = codes != null && i < codes.size() && codes[i] != null
                ? Integer.valueOf(String.valueOf(codes[i]))
                : null;

            day.weatherCode = code;
            day.weatherDescription = getWeatherDescription(code);
            day.weatherEmoji = getWeatherEmoji(code);

            forecastDays.add(day);
        }

        return forecastDays;
    }

    private static String getWeatherDescription(Integer code) {
        if (code == null) return 'Non disponibile';

        if (code == 0) return 'Sereno';
        if (code == 1 || code == 2) return 'Poco nuvoloso';
        if (code == 3) return 'Coperto';
        if (code == 45 || code == 48) return 'Nebbia';
        if (code == 51 || code == 53 || code == 55) return 'Pioviggine';
        if (code == 61 || code == 63 || code == 65) return 'Pioggia';
        if (code == 66 || code == 67) return 'Pioggia gelata';
        if (code == 71 || code == 73 || code == 75) return 'Neve';
        if (code == 77) return 'Granelli di neve';
        if (code == 80 || code == 81 || code == 82) return 'Rovesci';
        if (code == 85 || code == 86) return 'Rovesci di neve';
        if (code == 95) return 'Temporale';
        if (code == 96 || code == 99) return 'Temporale con grandine';

        return 'Condizioni variabili';
    }

    private static String getWeatherEmoji(Integer code) {
        if (code == null) return '🌍';

        if (code == 0) return '☀️';
        if (code == 1 || code == 2) return '🌤️';
        if (code == 3) return '☁️';
        if (code == 45 || code == 48) return '🌫️';
        if (code == 51 || code == 53 || code == 55) return '🌦️';
        if (code == 61 || code == 63 || code == 65) return '🌧️';
        if (code == 66 || code == 67) return '🧊';
        if (code == 71 || code == 73 || code == 75 || code == 77) return '❄️';
        if (code == 80 || code == 81 || code == 82) return '🌦️';
        if (code == 85 || code == 86) return '🌨️';
        if (code == 95 || code == 96 || code == 99) return '⛈️';

        return '🌍';
    }

    private static String getWeatherTheme(Integer code) {
        if (code == null) return 'theme-default';

        if (code == 0 || code == 1) return 'theme-sunny';
        if (code == 2 || code == 3 || code == 45 || code == 48) return 'theme-cloudy';
        if (code == 51 || code == 53 || code == 55 || code == 61 || code == 63 || code == 65 || code == 80 || code == 81 || code == 82) {
            return 'theme-rainy';
        }
        if (code == 71 || code == 73 || code == 75 || code == 77 || code == 85 || code == 86) {
            return 'theme-snowy';
        }
        if (code == 95 || code == 96 || code == 99) return 'theme-stormy';

        return 'theme-default';
    }
}