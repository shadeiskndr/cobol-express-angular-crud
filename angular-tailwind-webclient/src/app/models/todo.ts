export interface TodoResponse {
  todos: Todo[];
}

export interface Todo {
  id: number;
  description: string;
  dueDate?: string;
  estimatedTime?: number;
  status: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED';
  userId?: number;
}
