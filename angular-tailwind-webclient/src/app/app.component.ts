import { Component } from '@angular/core';
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
  constructor(private themeService: ThemeService) {}

  ngOnInit() {
    // Initialize theme based on current preference
    this.themeService.darkMode$.subscribe((isDark) => {
      document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
    });
  }
}
