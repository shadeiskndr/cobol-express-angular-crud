import { Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { NavbarComponent } from './components/navbar/navbar.component';
import { ThemeService } from './services/theme.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, NavbarComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent implements OnInit {
  title = 'angular-webclient';

  constructor(private themeService: ThemeService) {}

  ngOnInit() {
    // Initialize theme based on current preference
    this.themeService.darkMode$.subscribe((isDark) => {
      document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
    });
  }
}
