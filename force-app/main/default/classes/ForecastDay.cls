/**
 * @description       : 
 * @author            : KBoni
 * @group             : 
 * @last modified on  : 03-25-2026
 * @last modified by  : KBoni
**/
public with sharing class ForecastDay {
    @AuraEnabled public String data;
    @AuraEnabled public Decimal tempMax;
    @AuraEnabled public Decimal tempMin;
    @AuraEnabled public Integer weatherCode;
    @AuraEnabled public String weatherDescription;
    @AuraEnabled public String weatherEmoji;
}