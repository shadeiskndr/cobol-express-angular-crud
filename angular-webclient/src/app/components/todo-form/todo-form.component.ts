import { Component, OnInit } from '@angular/core';
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
} from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { TodoService } from '../../services/todo.service';
import { Todo } from '../../models/todo'; // Keep Todo model
import { LoadingSpinnerComponent } from '../loading-spinner/loading-spinner.component';
import { CommonModule } from '@angular/common'; // Import CommonModule for @if

@Component({
  selector: 'app-todo-form',
  standalone: true,
  imports: [
    CommonModule, // Add CommonModule
    ReactiveFormsModule,
    MatInputModule,
    MatButtonModule,
    MatCardModule,
    MatSelectModule,
    MatDatepickerModule,
    MatNativeDateModule,
    LoadingSpinnerComponent,
  ],
  templateUrl: './todo-form.component.html',
  styleUrl: './todo-form.component.scss',
})
export class TodoFormComponent implements OnInit {
  todoForm: FormGroup;
  isEditMode = false;
  todoId: number | null = null;
  isLoading = false;

  constructor(
    private fb: FormBuilder,
    private todoService: TodoService,
    private route: ActivatedRoute,
    private router: Router,
    private snackBar: MatSnackBar
  ) {
    this.todoForm = this.fb.group({
      description: ['', [Validators.required]],
      status: ['PENDING', [Validators.required]],
      dueDate: [null], // Keep null for optional date
      estimatedTime: [0, [Validators.min(0)]], // Keep default 0
    });
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      this.isEditMode = true;
      this.todoId = +idParam; // Convert string param to number
      this.loadTodo(this.todoId);
    }
  }

  loadTodo(id: number): void {
    this.isLoading = true;
    this.todoService.getTodoById(id).subscribe({
      next: (todo) => {
        this.todoForm.patchValue({
          description: todo.description,
          status: todo.status,
          // Ensure date is handled correctly for patching
          dueDate: todo.dueDate ? new Date(todo.dueDate) : null,
          estimatedTime: todo.estimatedTime || 0,
        });
        this.isLoading = false;
      },
      error: (error) => {
        this.snackBar.open(
          'Error loading todo: ' + (error.error?.error || 'Unknown error'),
          'Close',
          { duration: 3000 }
        );
        this.isLoading = false;
        this.router.navigate(['/todos']); // Navigate away on error
      },
    });
  }

  onSubmit(): void {
    if (this.todoForm.valid) {
      this.isLoading = true;

      // Prepare data - use Partial<Todo> as ID is missing for create
      // Get values directly from the form
      const formValue = this.todoForm.value;
      const todoData: Partial<Todo> = {
        description: formValue.description,
        status: formValue.status,
        // Format date correctly for backend (YYYY-MM-DD or undefined)
        dueDate: formValue.dueDate
          ? new Date(formValue.dueDate).toISOString().split('T')[0]
          : undefined, // Send undefined if null/empty
        estimatedTime: formValue.estimatedTime || 0, // Ensure 0 if null/undefined
      };

      if (this.isEditMode && this.todoId !== null) {
        // UPDATE: Pass the ID separately to the service method
        this.todoService.updateTodo(this.todoId, todoData).subscribe({
          next: () => {
            this.snackBar.open('Todo updated successfully', 'Close', {
              duration: 3000,
            });
            this.router.navigate(['/todos']);
            // No need to set isLoading = false here due to navigation
          },
          error: (error) => {
            this.snackBar.open(
              'Error updating todo: ' + (error.error?.error || 'Unknown error'),
              'Close',
              { duration: 3000 }
            );
            this.isLoading = false; // Keep form accessible on error
          },
        });
      } else {
        // CREATE: Call createTodo with data *without* an ID
        this.todoService.createTodo(todoData).subscribe({
          next: (createdTodo) => {
            // Backend returns the created todo with ID
            console.log('Todo created successfully with ID:', createdTodo.id); // Log the received ID
            this.snackBar.open('Todo created successfully', 'Close', {
              duration: 3000,
            });
            this.router.navigate(['/todos']);
            // No need to set isLoading = false here due to navigation
          },
          error: (error) => {
            this.snackBar.open(
              'Error creating todo: ' + (error.error?.error || 'Unknown error'),
              'Close',
              { duration: 3000 }
            );
            this.isLoading = false; // Keep form accessible on error
          },
        });
      }
    } else {
      // Mark fields as touched to show validation errors
      this.todoForm.markAllAsTouched();
      this.snackBar.open('Please correct the errors in the form', 'Close', {
        duration: 3000,
      });
    }
  }

  // Add a cancel method to navigate back
  cancel(): void {
    this.router.navigate(['/todos']);
  }
}
