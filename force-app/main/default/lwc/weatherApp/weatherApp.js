import { LightningElement } from 'lwc';
import getWeatherByCity from '@salesforce/apex/WeatherController.getWeatherByCity';
import searchCities from '@salesforce/apex/WeatherController.searchCities';
import getWeatherByCoordinates from '@salesforce/apex/WeatherController.getWeatherByCoordinates';

export default class WeatherApp extends LightningElement {
    city = '';
    weather = null;
    error = '';
    isLoading = false;
    lastSearchedCity = '';
    citySuggestions = [];
    showSuggestions = false;

    handleCityChange(event) {
        this.city = event.target.value;
        this.error = '';

        if (this.city && this.city.trim().length >= 3) {
            this.fetchCitySuggestions(this.city.trim());
        } else {
            this.citySuggestions = [];
            this.showSuggestions = false;
        }
    }

    async fetchCitySuggestions(query) {
        try {
            const result = await searchCities({ query });
            this.citySuggestions = result || [];
            this.showSuggestions = this.citySuggestions.length > 0;
        } catch (err) {
            this.citySuggestions = [];
            this.showSuggestions = false;
        }
    }

    handleSuggestionClick(event) {
        const selectedCity = event.currentTarget.dataset.city;
        this.city = selectedCity;
        this.showSuggestions = false;
        this.citySuggestions = [];
    }

    async handleSearch() {
        this.error = '';
        this.weather = null;
        this.showSuggestions = false;

        if (!this.city || !this.city.trim()) {
            this.error = 'Inserisci una città.';
            return;
        }

        this.isLoading = true;

        try {
            const trimmedCity = this.city.trim();
            const result = await getWeatherByCity({ city: trimmedCity });
            this.weather = result;
            this.lastSearchedCity = `${result.cityName}${result.country ? ', ' + result.country : ''}`;
        } catch (err) {
            this.error = err?.body?.message || 'Errore durante il recupero del meteo.';
        } finally {
            this.isLoading = false;
        }
    }

    async handleUseCurrentLocation() {
        this.error = '';
        this.weather = null;
        this.showSuggestions = false;

        if (!navigator.geolocation) {
            this.error = 'Geolocalizzazione non supportata dal browser.';
            return;
        }

        this.isLoading = true;

        navigator.geolocation.getCurrentPosition(
            async (position) => {
                try {
                    const latitude = position.coords.latitude;
                    const longitude = position.coords.longitude;

                    const result = await getWeatherByCoordinates({ latitude, longitude });
                    this.weather = result;
                    this.lastSearchedCity = `${result.cityName}${result.country ? ', ' + result.country : ''}`;
                } catch (err) {
                    this.error = err?.body?.message || 'Errore durante il recupero del meteo.';
                } finally {
                    this.isLoading = false;
                }
            },
            () => {
                this.error = 'Impossibile accedere alla posizione attuale.';
                this.isLoading = false;
            }
        );
    }

    get hasWeather() {
        return this.weather !== null;
    }

    get weatherCardClass() {
        return this.weather?.weatherTheme
            ? `weather-card ${this.weather.weatherTheme}`
            : 'weather-card theme-default';
    }

    get forecastDays() {
        const days = this.weather?.forecast || [];

        return days.map((day) => ({
            ...day,
            formattedData: this.capitalizeFirst(this.formatDateItalian(day.data))
        }));
    }

    get hasForecast() {
        return this.forecastDays.length > 0;
    }

    formatDateItalian(dateString) {
        if (!dateString) {
            return '';
        }

        const parts = dateString.split('-');
        if (parts.length !== 3) {
            return dateString;
        }

        const year = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10) - 1;
        const day = parseInt(parts[2], 10);

        const date = new Date(year, month, day);

        if (Number.isNaN(date.getTime())) {
            return dateString;
        }

        return new Intl.DateTimeFormat('it-IT', {
            weekday: 'short',
            day: 'numeric',
            month: 'short'
        }).format(date);
    }

    capitalizeFirst(text) {
        if (!text) {
            return '';
        }
        return text.charAt(0).toUpperCase() + text.slice(1);
    }
}