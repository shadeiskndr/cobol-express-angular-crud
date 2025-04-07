# COBOL-Express-Angular CRUD Application

This project is a full-stack CRUD application that demonstrates integration between legacy COBOL systems, a modern Express.js API, and an Angular frontend.

## Project Structure

The application consists of three main components:

```text
cobol-express-angular-crud/
├── angular-webclient/ # Angular 17+ frontend application
├── express-api/       # Express.js REST API middleware
└── cobol-backend/     # COBOL backend for data processing
```

## Components

### COBOL Backend

The COBOL backend handles data storage and core business logic:

- `customer-database.cbl`: COBOL program for customer data management
- `server.js`: Node.js wrapper to expose COBOL functionality
- Containerized with Docker for easy deployment

### Express API

The Express API serves as middleware between the frontend and COBOL backend:

- `customer-api.js`: REST API endpoints for customer operations
- `db-middleware.js`: Communication layer with COBOL backend
- Provides modern RESTful interface to legacy COBOL system

### Angular Frontend

The Angular frontend provides a modern user interface:

- Built with Angular 17+
- Responsive design for desktop and mobile devices
- Communicates with the Express API to perform CRUD operations

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js (v18+)
- Angular CLI

### Installation

1.  Clone the repository:

    ```bash
    git clone https://github.com/yourusername/cobol-express-angular-crud.git
    ```

    ```bash
    cd cobol-express-angular-crud
    ```

2.  Start the COBOL backend:

    ```bash
    cd cobol-backend
    ```

    ```bash
    docker build -t cobol-backend .
    ```

    ```bash
    docker run -d -p 3001:3001 --name cobol-backend cobol-backend
    ```

3.  Start the Express API:

    ```bash
    cd ../express-api
    ```

    ```bash
    npm install
    ```

    ```bash
    npm start
    ```

4.  Start the Angular frontend:

    ```bash
    cd ../angular-webclient
    ```

    ```bash
    npm install
    ```

    ```bash
    ng serve
    ```

5.  Access the application at [http://localhost:4200](http://localhost:4200)

## Development

Each component can be developed independently:

- **COBOL Backend**: Modify the COBOL programs and rebuild the Docker container
- **Express API**: Standard Node.js/Express development workflow
- **Angular Frontend**: Use Angular CLI for component generation and development

## Deployment

The application is containerized for easy deployment:

- Each component has its own Dockerfile
- Use Docker Compose for orchestrating all components together

## License

MIT License

## Acknowledgments

- This project demonstrates integration between legacy systems and modern web technologies
- Showcases how COBOL systems can be modernized without complete rewrites
- Provides a template for similar modernization efforts

_Note: This is a demonstration project showing how legacy COBOL systems can be integrated with modern web technologies._
