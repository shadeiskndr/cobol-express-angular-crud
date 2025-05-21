import { Injectable, signal, effect, computed } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class ThemeService {
  private static readonly AVAILABLE_COLOR_THEMES = ['purple', 'ocean']; // Add more color themes here
  
  private _colorTheme = signal<string>(this.getInitialColorTheme());
  private _darkMode = signal<boolean>(this.getInitialDarkMode());
  
  public colorTheme = this._colorTheme.asReadonly();
  public darkMode = this._darkMode.asReadonly();
  public currentTheme = computed(() => `${this._colorTheme()}-${this._darkMode() ? 'dark' : 'light'}`);

  constructor() {
    // Apply initial theme
    this.applyTheme();

    // React to theme changes using effect
    effect(() => {
      this.applyTheme();
    });

    // Listen for changes in system preference
    window
      .matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', (e) => {
        if (!this.hasStoredPreference()) {
          this._darkMode.set(e.matches);
        }
      });
  }

  private getInitialColorTheme(): string {
    // Check if user has a stored preference
    const storedColorTheme = localStorage.getItem('colorTheme');
    if (storedColorTheme && ThemeService.AVAILABLE_COLOR_THEMES.includes(storedColorTheme)) {
      return storedColorTheme;
    }

    // Fall back to first available color theme
    return ThemeService.AVAILABLE_COLOR_THEMES[0];
  }

  private getInitialDarkMode(): boolean {
    // Check if user has a stored preference
    const storedDarkMode = localStorage.getItem('darkMode');
    if (storedDarkMode !== null) {
      return storedDarkMode === 'true';
    }

    // Fall back to system preference
    return this.prefersDarkMode();
  }

  private hasStoredPreference(): boolean {
    return localStorage.getItem('darkMode') !== null || localStorage.getItem('colorTheme') !== null;
  }

  private prefersDarkMode(): boolean {
    return (
      window.matchMedia &&
      window.matchMedia('(prefers-color-scheme: dark)').matches
    );
  }

  private applyTheme(): void {
    const htmlElement = document.documentElement;
    const theme = this.currentTheme();
    htmlElement.setAttribute('data-theme', theme);
    htmlElement.style.colorScheme = this._darkMode() ? 'dark' : 'light';
  }

  toggleTheme(): void {
    const newDarkMode = !this._darkMode();
    this._darkMode.set(newDarkMode);
    localStorage.setItem('darkMode', newDarkMode.toString());
  }

  setColorTheme(colorTheme: string): void {
    if (ThemeService.AVAILABLE_COLOR_THEMES.includes(colorTheme)) {
      this._colorTheme.set(colorTheme);
      localStorage.setItem('colorTheme', colorTheme);
    }
  }

  setDarkMode(isDark: boolean): void {
    this._darkMode.set(isDark);
    localStorage.setItem('darkMode', isDark.toString());
  }

  getCurrentTheme(): string {
    return this.currentTheme();
  }

  getCurrentColorTheme(): string {
    return this._colorTheme();
  }

  getAvailableColorThemes(): string[] {
    return ThemeService.AVAILABLE_COLOR_THEMES;
  }
}
