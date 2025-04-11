import { Component, OnInit } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
} from '@angular/forms';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '../../services/auth.service';
import { User } from '../../models/user';
import { LoadingSpinnerComponent } from '../loading-spinner/loading-spinner.component';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatInputModule,
    MatButtonModule,
    MatCardModule,
    LoadingSpinnerComponent,
  ],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.scss',
})
export class ProfileComponent implements OnInit {
  profileForm: FormGroup;
  currentUser: User | null = null;
  isLoading = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private snackBar: MatSnackBar
  ) {
    this.profileForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
    });
  }

  ngOnInit(): void {
    this.loadUserProfile();
  }

  loadUserProfile(): void {
    this.isLoading = true;
    this.authService.getProfile().subscribe({
      next: (user) => {
        this.currentUser = user;
        this.profileForm.patchValue({
          username: user.username,
          email: user.email,
        });
        this.isLoading = false;
      },
      error: (error) => {
        this.snackBar.open(
          'Error loading profile: ' + (error.error?.error || 'Unknown error'),
          'Close',
          { duration: 3000 }
        );
        this.isLoading = false;
      },
    });
  }

  onSubmit(): void {
    if (this.profileForm.valid) {
      this.isLoading = true;
      this.authService.updateProfile(this.profileForm.value).subscribe({
        next: (user) => {
          this.currentUser = user;
          this.snackBar.open('Profile updated successfully', 'Close', {
            duration: 3000,
          });
          this.isLoading = false;
        },
        error: (error) => {
          this.snackBar.open(
            'Error updating profile: ' +
              (error.error?.error || 'Unknown error'),
            'Close',
            { duration: 3000 }
          );
          this.isLoading = false;
        },
      });
    }
  }
}
