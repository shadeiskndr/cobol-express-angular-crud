import { Component, OnInit, OnDestroy } from '@angular/core'; // Import OnDestroy
import { Router, RouterLink, NavigationEnd } from '@angular/router'; // Import NavigationEnd
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { User } from '../../models/user';
import { ThemeService } from '../../services/theme.service';
import { Subject } from 'rxjs'; // Import Subject
import { filter, takeUntil } from 'rxjs/operators'; // Import operators

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatMenuModule,
  ],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.scss',
})
export class NavbarComponent implements OnInit, OnDestroy {
  // Implement OnDestroy
  currentUser: User | null = null;
  isOnAuthPage: boolean = false; // Flag for auth pages
  private destroy$ = new Subject<void>(); // Subject for unsubscribing

  constructor(
    private authService: AuthService,
    private router: Router, // Inject Router
    public themeService: ThemeService
  ) {}

  ngOnInit(): void {
    this.authService.currentUser$
      .pipe(takeUntil(this.destroy$)) // Unsubscribe on destroy
      .subscribe((user) => {
        this.currentUser = user;
      });

    // Subscribe to router events to check the current route
    this.router.events
      .pipe(
        filter(
          (event): event is NavigationEnd => event instanceof NavigationEnd
        ), // Filter for NavigationEnd events
        takeUntil(this.destroy$) // Unsubscribe on destroy
      )
      .subscribe((event: NavigationEnd) => {
        // Check if the current URL is /login or /register
        this.isOnAuthPage =
          event.urlAfterRedirects === '/login' ||
          event.urlAfterRedirects === '/register';
      });

    // Initial check in case the app loads directly on an auth page
    this.isOnAuthPage =
      this.router.url === '/login' || this.router.url === '/register';
  }

  ngOnDestroy(): void {
    this.destroy$.next(); // Trigger the subject
    this.destroy$.complete(); // Complete the subject
  }

  toggleTheme(): void {
    this.themeService.toggleTheme();
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
