# COBOL-Express-Angular CRUD Application

This project is a full-stack Todo List CRUD web application demonstrating seamless integration between a legacy COBOL backend, a modern Express.js REST API, and an Angular frontend—all orchestrated with Docker Compose.

![Demo](https://raw.githubusercontent.com/shadeiskndr/shadeiskndr.github.io/main/uploads/todolist.gif)

## Project Structure

The application consists of three main Dockerized components:

```
cobol-express-angular-crud/
├── angular-webclient/   # Angular 17+ frontend (served by Nginx)
├── express-api/         # Express.js REST API (Node.js)
└── cobol-backend/       # COBOL backend (with Node.js socket server)
```

## Components

### COBOL Backend (`cobol-backend/`)

- **COBOL program (`combined-program.cbl`)**: Implements all business logic and data persistence for todos and users.
- **Node.js server (`server.js`)**: Exposes a TCP socket interface for the Express API to communicate with the COBOL program.
- **Entrypoint script (`entrypoint.sh`)**: Sets up environment and launches the backend services.
- **Data storage**: Uses indexed files for persistent storage, mapped to a Docker volume.

### Express API (`express-api/`)

- **Express.js server (`todo-api.js`)**: Provides RESTful endpoints for todo and user operations.
- **Authentication**: Uses JWT for secure user authentication.
- **Middleware**: Handles communication with the COBOL backend via TCP sockets.
- **Acts as a bridge** between the Angular frontend and the COBOL backend.
- **Environment variables**: Sensitive configuration (such as the JWT secret) is loaded from environment variables, typically via a `.env` file.

### Angular Frontend (`angular-webclient/`)

- **Angular 17+ SPA**: Modern, responsive UI for managing todos and user accounts.
- **Nginx**: Serves the built Angular app and proxies API requests to the Express API.
- **JWT Auth**: Handles login, registration, and session management.

## Environment Variables

### Using a `.env` File

The Express API requires certain environment variables for secure operation, such as the JWT secret.  
**Do not commit secrets directly to your repository.**

1. **Copy the example file:**

   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` and set a strong value for `JWT_SECRET`:**

   ```
   JWT_SECRET=your-very-strong-secret-here
   ```

3. **Docker Compose will automatically load variables from `.env` and inject them into the containers.**

### Example `.env.example`

```env
# Copy this file to .env and set your own secret!
JWT_SECRET=change-me-to-a-strong-secret
```

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/get-started) and [Docker Compose](https://docs.docker.com/compose/)
- (Optional for development) Node.js (v18+) and Angular CLI

### Quick Start (Recommended)

To build and start all services in the background, simply run:

```bash
docker-compose up -d
```

This will:

- Build all three containers (COBOL backend, Express API, Angular frontend)
- Start the services and set up networking and volumes automatically

Once all containers are running, access the application at:  
[http://localhost:80](http://localhost:80) (or [http://localhost](http://localhost))

### Stopping the Application

To stop all containers:

```bash
docker-compose down
```

### Development Workflow

Each component can be developed and tested independently:

- **COBOL Backend**: Edit COBOL or Node.js files in `cobol-backend/`, then rebuild the container.
- **Express API**: Standard Node.js/Express development in `express-api/`.
- **Angular Frontend**: Use Angular CLI in `angular-webclient/` for local development (`ng serve`), or rebuild the container for production.

## Deployment

- All components are containerized and orchestrated via Docker Compose.
- Persistent data is stored in a Docker volume (`cobol-data`).
- The system is suitable for local development, demos, or as a modernization template.

## Acknowledgments

- Demonstrates modernization and integration of legacy COBOL systems with modern web technologies.
- Provides a template for similar modernization efforts.

_Note: This is a demonstration project showing how legacy COBOL systems can be integrated with modern web technologies._
