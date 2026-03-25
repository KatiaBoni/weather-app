/**
 * @description       : 
 * @author            : KBoni
 * @group             : 
 * @last modified on  : 03-25-2026
 * @last modified by  : KBoni
**/
public with sharing class WeatherController {
    @AuraEnabled(cacheable=false)
    public static WeatherResult getWeatherByCity(String city) {
        if (String.isBlank(city)) {
            throw new AuraHandledException('Inserisci il nome di una città.');
        }

        return WeatherService.getWeatherByCity(city.trim());
    }

    @AuraEnabled(cacheable=false)
    public static List<CitySuggestion> searchCities(String query) {
        return WeatherService.searchCities(query);
    }

    @AuraEnabled(cacheable=false)
    public static WeatherResult getWeatherByCoordinates(Decimal latitude, Decimal longitude) {
        if (latitude == null || longitude == null) {
            throw new AuraHandledException('Coordinate non valide.');
        }

        return WeatherService.getWeatherByCoordinates(latitude, longitude);
    }
}