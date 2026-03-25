/**
 * @description       : 
 * @author            : KBoni
 * @group             : 
 * @last modified on  : 03-25-2026
 * @last modified by  : KBoni
**/
public with sharing class WeatherResult {
    @AuraEnabled public String cityName;
    @AuraEnabled public String country;

    @AuraEnabled public Decimal temperature;
    @AuraEnabled public String temperatureUnit;

    @AuraEnabled public Decimal windSpeed;
    @AuraEnabled public String windSpeedUnit;

    @AuraEnabled public Decimal precipitation;
    @AuraEnabled public String precipitationUnit;

    @AuraEnabled public Decimal humidity;
    @AuraEnabled public String humidityUnit;

    @AuraEnabled public Integer weatherCode;
    @AuraEnabled public String weatherDescription;
    @AuraEnabled public String weatherEmoji;
    @AuraEnabled public String weatherTheme;

    @AuraEnabled public List<ForecastDay> forecast;
}