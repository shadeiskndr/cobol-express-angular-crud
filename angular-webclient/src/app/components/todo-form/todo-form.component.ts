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
import { Todo } from '../../models/todo';
import { LoadingSpinnerComponent } from '../loading-spinner/loading-spinner.component';

@Component({
  selector: 'app-todo-form',
  standalone: true,
  imports: [
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
      dueDate: [null],
      estimatedTime: [0, [Validators.min(0)]],
    });
  }

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditMode = true;
      this.todoId = +id;
      this.loadTodo(this.todoId);
    } else {
      // Generate a random ID for new todos
      this.todoForm.addControl(
        'id',
        this.fb.control(
          Math.floor(10000 + Math.random() * 90000), // 5-digit number
          [Validators.required]
        )
      );
    }
  }

  loadTodo(id: number): void {
    this.isLoading = true;
    this.todoService.getTodoById(id).subscribe({
      next: (todo) => {
        this.todoForm.patchValue({
          description: todo.description,
          status: todo.status,
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
        this.router.navigate(['/todos']);
      },
    });
  }

  onSubmit(): void {
    if (this.todoForm.valid) {
      this.isLoading = true;

      const todoData: Todo = {
        ...this.todoForm.value,
        // Format the date to ISO string if it exists
        dueDate: this.todoForm.value.dueDate
          ? new Date(this.todoForm.value.dueDate).toISOString().split('T')[0]
          : undefined,
      };

      if (this.isEditMode && this.todoId) {
        this.todoService.updateTodo(this.todoId, todoData).subscribe({
          next: () => {
            this.snackBar.open('Todo updated successfully', 'Close', {
              duration: 3000,
            });
            this.router.navigate(['/todos']);
            this.isLoading = false;
          },
          error: (error) => {
            this.snackBar.open(
              'Error updating todo: ' + (error.error?.error || 'Unknown error'),
              'Close',
              { duration: 3000 }
            );
            this.isLoading = false;
          },
        });
      } else {
        this.todoService.createTodo(todoData).subscribe({
          next: () => {
            this.snackBar.open('Todo created successfully', 'Close', {
              duration: 3000,
            });
            this.router.navigate(['/todos']);
            this.isLoading = false;
          },
          error: (error) => {
            this.snackBar.open(
              'Error creating todo: ' + (error.error?.error || 'Unknown error'),
              'Close',
              { duration: 3000 }
            );
            this.isLoading = false;
          },
        });
      }
    }
  }

  cancel(): void {
    this.router.navigate(['/todos']);
  }
}
