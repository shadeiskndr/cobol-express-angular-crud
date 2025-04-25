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
import {
  ReactiveFormsModule,
  FormControl,
  FormGroup,
  Validators,
} from '@angular/forms';
import { NgOptimizedImage } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { LoginRequest } from '../../models/user';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  imports: [
    MatCard,
    MatCardContent,
    MatCardActions,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    ReactiveFormsModule,
    MatIconModule,
    NgOptimizedImage,
  ],
})
export class LoginComponent {
  private authService = inject(AuthService);
  private router = inject(Router);

  form = new FormGroup({
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', [
      Validators.required,
      Validators.minLength(4),
    ]),
  });

  isLoading = false;
  errorMessage = '';

  onSubmit() {
    if (this.form.valid && !this.isLoading) {
      this.isLoading = true;
      this.errorMessage = '';

      const loginData: LoginRequest = {
        email: this.form.value.email!,
        password: this.form.value.password!,
      };

      this.authService.login(loginData).subscribe({
        next: (response) => {
          if (response.success) {
            this.router.navigate(['/todos']);
          } else {
            this.errorMessage = response.error || 'Login failed';
          }
          this.isLoading = false;
        },
        error: (error) => {
          this.errorMessage =
            error.error?.error || 'Login failed. Please try again.';
          this.isLoading = false;
        },
      });
    }
  }

  navigateToRegister() {
    this.router.navigate(['/register']);
  }
}
