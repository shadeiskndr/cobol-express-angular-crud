import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class ThemeService {
  private darkMode = new BehaviorSubject<boolean>(this.getInitialTheme());
  public darkMode$ = this.darkMode.asObservable();

  constructor() {
    // Apply initial theme
    this.applyTheme(this.darkMode.value);

    // Listen for changes in system preference
    window
      .matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', (e) => {
        if (!this.hasStoredPreference()) {
          this.setTheme(e.matches);
        }
      });
  }

  private getInitialTheme(): boolean {
    // Check if user has a stored preference
    const storedTheme = localStorage.getItem('theme');
    if (storedTheme) {
      return storedTheme === 'dark';
    }

    // Fall back to system preference
    return this.prefersDarkMode();
  }

  private hasStoredPreference(): boolean {
    return localStorage.getItem('theme') !== null;
  }

  private prefersDarkMode(): boolean {
    return (
      window.matchMedia &&
      window.matchMedia('(prefers-color-scheme: dark)').matches
    );
  }

  private applyTheme(isDark: boolean): void {
    const htmlElement = document.documentElement;

    if (isDark) {
      htmlElement.classList.add('dark');
      htmlElement.style.colorScheme = 'dark';
    } else {
      htmlElement.classList.remove('dark');
      htmlElement.style.colorScheme = 'light';
    }
  }

  private setTheme(isDark: boolean): void {
    this.darkMode.next(isDark);
    this.applyTheme(isDark);
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
  }

  toggleTheme(): void {
    const newTheme = !this.darkMode.value;
    this.setTheme(newTheme);
  }

  setDarkMode(isDark: boolean): void {
    this.setTheme(isDark);
  }

  getCurrentTheme(): 'light' | 'dark' {
    return this.darkMode.value ? 'dark' : 'light';
  }
}
