import { Component, effect } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ThemeService } from './services/theme.service';
import { TodosComponent } from './pages/todos/todos.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, TodosComponent],
  template: '<router-outlet></router-outlet>',
})
export class AppComponent {
  title = 'angular-tailwind-webclient';

  constructor(private themeService: ThemeService) {
    // React to theme changes using effect
    effect(() => {
      const currentTheme = this.themeService.currentTheme();
      const isDark = this.themeService.darkMode();
      document.documentElement.setAttribute('data-theme', currentTheme);
      document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
    });
  }
}
