# Weather APP - Salesforce LWC + Apex

## Descrizione del progetto
Questa è una semplice app meteo sviluppata in Salesforce usando **Lightning Web Components (LWC)** per il frontend e **Apex** per il backend.

L’app permette di:
- cercare una città e visualizzare il meteo attuale
- ricevere suggerimenti automatici dopo aver digitato almeno 3 lettere
- usare la posizione attuale del dispositivo per ottenere il meteo locale
- visualizzare temperatura, vento, precipitazioni e umidità
- vedere le previsioni dei prossimi 3 giorni
- mostrare emoji e una descrizione testuale delle condizioni meteo

Le informazioni meteo vengono recuperate tramite le API di **Open-Meteo**, mentre per ricavare la città dalla posizione attuale viene usato un servizio di **reverse geocoding**.

---

## Funzionalità principali
- Ricerca meteo per nome città
- Autocomplete delle città
- Meteo basato sulla posizione attuale
- Temperatura attuale
- Velocità del vento
- Precipitazioni
- Umidità
- Descrizione meteo con emoji
- Forecast di 3 giorni
- Gestione degli errori per città non trovate o problemi API

---

## Tecnologie utilizzate
- Salesforce
- Lightning Web Components (LWC)
- Apex
- Open-Meteo API
- BigDataCloud Reverse Geocoding API
- Visual Studio Code
- Salesforce CLI / SFDX

---

## Struttura del progetto
```text
force-app/main/default/
├── classes/
│   ├── WeatherController.cls
│   ├── WeatherService.cls
│   ├── WeatherResult.cls
│   ├── ForecastDay.cls
│   └── CitySuggestion.cls
│
└── lwc/
    └── weatherApp/
        ├── weatherApp.html
        ├── weatherApp.js
        ├── weatherApp.css
        └── weatherApp.js-meta.xml
