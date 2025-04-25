import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router'; // Import Router
import { catchError, throwError } from 'rxjs'; // Import catchError and throwError
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router); // Inject Router
  const token = authService.getToken();

  if (token) {
    req = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`,
      },
    });
  }

  // Pass the request and handle potential errors in the response stream
  return next(req).pipe(
    catchError((error: any) => {
      // Check if it's an HTTP error and specifically a 401 Unauthorized
      if (error instanceof HttpErrorResponse && error.status === 401) {
        // Token is invalid or expired
        console.error('Unauthorized request (401). Logging out.', error);

        // Perform logout actions
        authService.logout();

        // Redirect to the login page
        // You might want to add query params like ?sessionExpired=true
        // to show a message on the login page.
        router.navigate(['/login']);

        // Optionally: Display a user-friendly message (e.g., using a snackbar/toast service)
        // alert('Your session has expired. Please log in again.');

        // Complete the stream with an error or return an empty observable
        // to prevent the original component from processing the error further
        // after logout and redirection have been initiated.
        // Re-throwing might be needed if some component specifically needs to react to 401
        // *before* the redirect, but often stopping the stream is cleaner here.
        return throwError(() => new Error('Session expired')); // Or return EMPTY;
      } else {
        // For all other errors, re-throw the error to be handled by other
        // error handlers or the component itself.
        return throwError(() => error);
      }
    })
  );
};
