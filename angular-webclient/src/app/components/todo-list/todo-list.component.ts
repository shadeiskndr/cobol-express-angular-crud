import {
  Component,
  OnInit,
  ViewChild,
  AfterViewInit,
  OnDestroy,
} from '@angular/core';
import { Router } from '@angular/router';
import { MatTableDataSource, MatTableModule } from '@angular/material/table'; // Import MatTableDataSource
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator'; // Import MatPaginator
import { MatSort, MatSortModule } from '@angular/material/sort'; // Optional: Import MatSort for sorting
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips'; // Keep for status display
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import {
  MatBottomSheet,
  MatBottomSheetModule,
} from '@angular/material/bottom-sheet'; // Import MatBottomSheet
import { MatTooltipModule } from '@angular/material/tooltip'; // Import MatTooltipModule
import { TodoService } from '../../services/todo.service';
import { Todo } from '../../models/todo';
import { LoadingSpinnerComponent } from '../loading-spinner/loading-spinner.component';
import { ConfirmDialogComponent } from '../confirm-dialog/confirm-dialog.component'; // Import ConfirmDialogComponent
import {
  SearchTodoSheetComponent,
  SearchCriteria,
} from '../search-todo-sheet/search-todo-sheet.component'; // Import SearchTodoSheetComponent
import { DatePipe, NgClass, CommonModule } from '@angular/common'; // Import CommonModule
import { Subject } from 'rxjs';
import { takeUntil, filter } from 'rxjs/operators';

@Component({
  selector: 'app-todo-list',
  standalone: true,
  imports: [
    CommonModule, // Use CommonModule instead of NgClass/DatePipe individually if preferred
    DatePipe,
    NgClass,
    MatTableModule,
    MatPaginatorModule, // Add MatPaginatorModule
    MatSortModule, // Optional: Add MatSortModule
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatChipsModule,
    MatSnackBarModule,
    MatDialogModule,
    MatBottomSheetModule, // Add MatBottomSheetModule
    MatTooltipModule, // Add MatTooltipModule
    LoadingSpinnerComponent,
    ConfirmDialogComponent, // Add ConfirmDialogComponent
    SearchTodoSheetComponent, // Add SearchTodoSheetComponent
  ],
  templateUrl: './todo-list.component.html',
  styleUrl: './todo-list.component.scss',
})
export class TodoListComponent implements OnInit, AfterViewInit, OnDestroy {
  displayedColumns: string[] = [
    'description',
    'status',
    'dueDate',
    'estimatedTime',
    'actions',
  ];
  dataSource: MatTableDataSource<Todo> = new MatTableDataSource<Todo>([]); // Use MatTableDataSource
  isLoading = false;
  currentSearchCriteria: SearchCriteria | null = null; // Store current criteria
  private destroy$ = new Subject<void>(); // For unsubscribing

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort; // Optional: for sorting

  constructor(
    private todoService: TodoService,
    private router: Router,
    private snackBar: MatSnackBar,
    private dialog: MatDialog,
    private bottomSheet: MatBottomSheet // Inject MatBottomSheet
  ) {}

  ngOnInit(): void {
    this.loadTodos(); // Initial load
  }

  ngAfterViewInit(): void {
    // Connect paginator and sort after view is initialized
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort; // Optional: Connect sort
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadTodos(): void {
    this.isLoading = true;
    this.currentSearchCriteria = null; // Reset search criteria on full load
    this.todoService
      .getTodos()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data) => {
          this.dataSource.data = data;
          // Paginator and sort are connected in ngAfterViewInit
          this.isLoading = false;
        },
        error: (error) => {
          this.handleError('Error loading todos', error);
        },
      });
  }

  openSearchSheet(): void {
    const bottomSheetRef = this.bottomSheet.open(SearchTodoSheetComponent);

    bottomSheetRef
      .afterDismissed()
      .pipe(takeUntil(this.destroy$))
      .subscribe((result: SearchCriteria | 'reset' | null | undefined) => {
        if (result === 'reset') {
          this.resetSearch();
        } else if (result && typeof result === 'object') {
          // Check if it's a valid criteria object
          this.searchTodos(result);
        }
        // Do nothing if dismissed without action (result is null/undefined)
      });
  }

  searchTodos(criteria: SearchCriteria): void {
    if (!this.hasValidSearchCriteria(criteria)) {
      this.snackBar.open(
        'Please provide at least one search criteria',
        'Close',
        { duration: 3000 }
      );
      return;
    }

    this.isLoading = true;
    this.currentSearchCriteria = criteria; // Store the criteria
    this.todoService
      .searchTodos(criteria)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (data) => {
          this.dataSource.data = data;
          // Reset paginator to first page after search
          if (this.dataSource.paginator) {
            this.dataSource.paginator.firstPage();
          }
          this.isLoading = false;
          this.snackBar.open(
            `Found ${data.length} todos matching your criteria`,
            'Close',
            { duration: 3000 }
          );
        },
        error: (error) => {
          this.handleError('Error searching todos', error);
        },
      });
  }

  resetSearch(): void {
    this.loadTodos(); // Reload all todos
    this.snackBar.open('Filters reset. Showing all todos.', 'Close', {
      duration: 2000,
    });
  }

  refreshData(): void {
    this.isLoading = true;
    // Decide whether to reload all or re-apply current search
    if (this.currentSearchCriteria) {
      this.searchTodos(this.currentSearchCriteria);
      this.snackBar.open('Refreshed search results.', 'Close', {
        duration: 2000,
      });
    } else {
      this.loadTodos();
      this.snackBar.open('Refreshed todo list.', 'Close', { duration: 2000 });
    }
  }

  private hasValidSearchCriteria(criteria: any): boolean {
    return Object.keys(criteria).length > 0;
  }

  editTodo(id: number): void {
    this.router.navigate(['/todos/edit', id]);
  }

  deleteTodo(id: number): void {
    const dialogRef = this.dialog.open(ConfirmDialogComponent, {
      width: '350px',
      data: {
        title: 'Confirm Deletion',
        message: 'Are you sure you want to delete this todo?',
      },
    });

    dialogRef
      .afterClosed()
      .pipe(
        filter((result) => result === true), // Only proceed if confirmed
        takeUntil(this.destroy$)
      )
      .subscribe(() => {
        this.isLoading = true; // Optional: show loading during delete
        this.todoService
          .deleteTodo(id)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: () => {
              this.snackBar.open('Todo deleted successfully', 'Close', {
                duration: 3000,
                panelClass: ['success-snackbar'], // Optional success style
              });
              // Refresh data based on current view (all or filtered)
              this.refreshData();
            },
            error: (error) => {
              this.handleError('Error deleting todo', error);
            },
          });
      });
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'COMPLETED':
        return 'status-completed';
      case 'IN_PROGRESS':
        return 'status-in-progress';
      case 'PENDING':
        return 'status-pending';
      default:
        return '';
    }
  }

  addNewTodo(): void {
    this.router.navigate(['/todos/new']);
  }

  // Helper function for consistent error handling
  private handleError(message: string, error: any): void {
    this.isLoading = false;
    const errorMessage = error.error?.error || error.message || 'Unknown error';
    this.snackBar.open(`${message}: ${errorMessage}`, 'Close', {
      duration: 4000,
      panelClass: ['error-snackbar'], // Use error style
    });
    console.error(message, error); // Log for debugging
  }
}
