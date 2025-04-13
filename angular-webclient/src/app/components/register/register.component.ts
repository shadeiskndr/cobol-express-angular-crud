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
import { CommonModule } from '@angular/common'; // Import CommonModule for ngIf/@if
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-register',
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
  templateUrl: './register.component.html',
  styleUrl: './register.component.scss',
})
export class RegisterComponent {
  registerForm: FormGroup;
  isLoading = false;
  hidePassword = true; // Property to toggle password visibility

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {
    this.registerForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
    });
  }

  onSubmit(): void {
    if (this.registerForm.invalid || this.isLoading) {
      return; // Exit if form is invalid or already loading
    }

    this.isLoading = true;
    this.authService.register(this.registerForm.value).subscribe({
      next: (response) => {
        this.isLoading = false;
        // Assuming response structure includes success/error fields
        // Adjust based on your actual API response
        // Backend currently sends { message: 'User registered successfully' } or { error: '...' }
        if (response && response.success) {
          this.snackBar.open(
            'Registration successful! Please login.',
            'Close',
            {
              duration: 3000,
              panelClass: ['success-snackbar'], // Optional: for custom styling
            }
          );
          this.router.navigate(['/login']);
        } else {
          // Use error message from response if available, otherwise generic message
          const errorMessage =
            response?.error || 'Registration failed. Please try again.';
          this.snackBar.open(errorMessage, 'Close', {
            duration: 4000,
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
          'An error occurred during registration.';
        this.snackBar.open(errorMessage, 'Close', {
          duration: 4000, // Longer duration for errors
          panelClass: ['error-snackbar'], // Optional: for custom styling
        });
        console.error('Registration error:', error); // Log the full error for debugging
      },
    });
  }

  togglePasswordVisibility(): void {
    this.hidePassword = !this.hidePassword;
  }
}
