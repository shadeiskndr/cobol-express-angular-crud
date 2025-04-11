import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class ThemeService {
  private darkMode = new BehaviorSubject<boolean>(this.prefersDarkMode());
  public darkMode$ = this.darkMode.asObservable();

  constructor() {
    // Listen for changes in system preference
    window
      .matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', (e) => {
        this.darkMode.next(e.matches);
      });
  }

  private prefersDarkMode(): boolean {
    return (
      window.matchMedia &&
      window.matchMedia('(prefers-color-scheme: dark)').matches
    );
  }

  toggleTheme(): void {
    const isDark = !this.darkMode.value;
    this.darkMode.next(isDark);

    // Set the color-scheme property directly on the HTML element
    document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
  }
}
