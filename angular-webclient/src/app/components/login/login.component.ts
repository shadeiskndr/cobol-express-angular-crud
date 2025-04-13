import { Component } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
} from '@angular/forms';
import { Router, RouterLink } from '@angular/router'; // Import RouterLink
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatIconModule } from '@angular/material/icon'; // Import MatIconModule
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner'; // Import MatProgressSpinnerModule
import { CommonModule } from '@angular/common'; // Import CommonModule for ngIf
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule, // Add CommonModule
    ReactiveFormsModule,
    RouterLink, // Add RouterLink
    MatInputModule,
    MatButtonModule,
    MatCardModule,
    MatIconModule, // Add MatIconModule
    MatProgressSpinnerModule, // Add MatProgressSpinnerModule
  ],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
})
export class LoginComponent {
  loginForm: FormGroup;
  isLoading = false;
  hidePassword = true; // Property to toggle password visibility

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]],
    });
  }

  onSubmit(): void {
    if (this.loginForm.invalid || this.isLoading) {
      return; // Exit if form is invalid or already loading
    }

    this.isLoading = true;
    this.authService.login(this.loginForm.value).subscribe({
      next: (response) => {
        this.isLoading = false;
        // Assuming response structure includes success/error fields
        // Adjust based on your actual API response
        if (response && response.token) {
          // Check for a token or success indicator
          this.router.navigate(['/todos']);
        } else {
          // Use error message from response if available, otherwise generic message
          const errorMessage =
            response?.error || 'Login failed. Please check your credentials.';
          this.snackBar.open(errorMessage, 'Close', {
            duration: 3000,
            panelClass: ['error-snackbar'], // Optional: for custom styling
          });
        }
      },
      error: (error) => {
        this.isLoading = false;
        // Extract error message from backend response if possible
        const errorMessage =
          error.error?.error ||
          error.error?.message ||
          'An error occurred during login.';
        this.snackBar.open(errorMessage, 'Close', {
          duration: 4000, // Longer duration for errors
          panelClass: ['error-snackbar'], // Optional: for custom styling
        });
        console.error('Login error:', error); // Log the full error for debugging
      },
    });
  }

  togglePasswordVisibility(): void {
    this.hidePassword = !this.hidePassword;
  }
}
