import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import {
  MatCard,
  MatCardActions,
  MatCardContent,
} from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatIconModule } from '@angular/material/icon';
import { MatSelectModule } from '@angular/material/select';
import {
  ReactiveFormsModule,
  FormControl,
  FormGroup,
  Validators,
  AbstractControl,
} from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { RegisterRequest } from '../../models/user';
import { ThemeService } from '../../services/theme.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  imports: [
    MatCard,
    MatCardContent,
    MatCardActions,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    ReactiveFormsModule,
    MatIconModule,
  ],
})
export class RegisterComponent {
  private authService = inject(AuthService);
  private router = inject(Router);
  private themeService = inject(ThemeService);

  isDarkMode = this.themeService.darkMode;
  colorTheme = this.themeService.colorTheme;

  onThemeToggle() {
    this.themeService.toggleTheme();
  }

  onColorThemeChange(colorTheme: string) {
    this.themeService.setColorTheme(colorTheme);
  }

  form = new FormGroup(
    {
      username: new FormControl('', [
        Validators.required,
        Validators.minLength(3),
        Validators.maxLength(20),
      ]),
      email: new FormControl('', [Validators.required, Validators.email]),
      password: new FormControl('', [
        Validators.required,
        Validators.minLength(8),
        this.passwordStrengthValidator,
      ]),
      confirmPassword: new FormControl('', [Validators.required]),
    },
    { validators: this.passwordMatchValidator }
  );

  isLoading = false;
  errorMessage = '';
  hidePassword = true;
  hideConfirmPassword = true;

  // Custom validator for password strength
  passwordStrengthValidator(control: AbstractControl) {
    const value = control.value;
    if (!value) return null;

    const hasNumber = /[0-9]/.test(value);
    const hasUpper = /[A-Z]/.test(value);
    const hasLower = /[a-z]/.test(value);
    const hasSpecial = /[#?!@$%^&*-]/.test(value);

    const valid = hasNumber && hasUpper && hasLower && hasSpecial;
    if (!valid) {
      return { passwordStrength: true };
    }
    return null;
  }

  // Custom validator for password match
  passwordMatchValidator(control: AbstractControl) {
    const password = control.get('password');
    const confirmPassword = control.get('confirmPassword');

    if (!password || !confirmPassword) return null;

    return password.value === confirmPassword.value
      ? null
      : { passwordMismatch: true };
  }

  onSubmit() {
    if (this.form.valid && !this.isLoading) {
      this.isLoading = true;
      this.errorMessage = '';

      const registerData: RegisterRequest = {
        username: this.form.value.username!,
        email: this.form.value.email!,
        password: this.form.value.password!,
      };

      this.authService.register(registerData).subscribe({
        next: (response) => {
          if (response.success) {
            // Auto-login after successful registration
            const loginData = {
              email: registerData.email,
              password: registerData.password,
            };

            this.authService.login(loginData).subscribe({
              next: (loginResponse) => {
                if (loginResponse.success) {
                  this.router.navigate(['/todos']);
                } else {
                  // Registration successful but login failed, redirect to login
                  this.router.navigate(['/login']);
                }
                this.isLoading = false;
              },
              error: () => {
                // Registration successful but login failed, redirect to login
                this.router.navigate(['/login']);
                this.isLoading = false;
              },
            });
          } else {
            this.errorMessage = response.error || 'Registration failed';
            this.isLoading = false;
          }
        },
        error: (error) => {
          this.errorMessage =
            error.error?.error || 'Registration failed. Please try again.';
          this.isLoading = false;
        },
      });
    }
  }

  navigateToLogin() {
    this.router.navigate(['/login']);
  }

  getPasswordStrengthText(): string {
    const password = this.form.get('password')?.value || '';
    if (password.length === 0) return '';

    const hasNumber = /[0-9]/.test(password);
    const hasUpper = /[A-Z]/.test(password);
    const hasLower = /[a-z]/.test(password);
    const hasSpecial = /[#?!@$%^&*-]/.test(password);

    const strength = [hasNumber, hasUpper, hasLower, hasSpecial].filter(
      Boolean
    ).length;

    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  getPasswordStrengthColor(): string {
    const strength = this.getPasswordStrengthText();
    switch (strength) {
      case 'Weak':
        return 'text-red-500';
      case 'Fair':
        return 'text-orange-500';
      case 'Good':
        return 'text-yellow-500';
      case 'Strong':
        return 'text-green-500';
      default:
        return 'text-gray-500';
    }
  }
}
