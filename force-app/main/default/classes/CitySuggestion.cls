/**
 * @description       : 
 * @author            : KBoni
 * @group             : 
 * @last modified on  : 03-25-2026
 * @last modified by  : KBoni
**/
public with sharing class CitySuggestion {
    @AuraEnabled public String name;
    @AuraEnabled public String country;
    @AuraEnabled public Decimal latitude;
    @AuraEnabled public Decimal longitude;
    @AuraEnabled public String label;
}