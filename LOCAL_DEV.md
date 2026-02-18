# Local Development Guide

This guide describes how to set up and run the ShopMicro-Production project locally using Docker Compose.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.
- [Node.js](https://nodejs.org/) (optional, if you want to run services outside of Docker).

## Getting Started

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd ShopMicro-Production
    ```

2.  **Configure Environment Variables**:
    Copy the `.env.example` file to `.env`:
    ```bash
    cp .env.example .env
    ```
    *(Optional)*: Modify the `.env` file if you need to customize any settings.

3.  **Start the Application**:
    Use Docker Compose to build and start all services:
    ```bash
    docker compose up --build
    ```
    This command will:
    - Build the `backend` and `ml-service` images.
    - Start `postgres` and `redis` with health checks.
    - Start the `backend` with hot-reloading (via `nodemon`).
    - Start the `frontend` in development mode.
    - Start the `ml-service`.

4.  **Access the Services**:
    - **Frontend**: [http://localhost:3000](http://localhost:3000)
    - **Backend API**: [http://localhost:3001](http://localhost:3001)
    - **ML Service**: [http://localhost:5000](http://localhost:5000) (internal dev port 3002 mapped to 5000)
    - **PostgreSQL**: `localhost:5432`
    - **Redis**: `localhost:6379`

## Development Features

### Backend Hot Reloading
The `backend` service is configured with volume mounting and `nodemon`. Any changes you make to files in the `./backend` directory will trigger an automatic reload of the service inside the container.

### Frontend Development
The `frontend` service uses Vite's development server with HMR (Hot Module Replacement). Changes in the `./frontend` directory will be reflected in your browser instantly.

### Health Checks
Docker Compose is configured to use health checks for `postgres` and `redis`. Dependent services (`backend`, `ml-service`) will wait for these dependencies to be healthy before starting.

## Troubleshooting

- **Database Issues**: If the database doesn't initialize correctly, you can try resetting it by removing the volumes:
  ```bash
  docker compose down -v
  docker compose up --build
  ```
- **Port Conflicts**: Ensure that ports 3000, 3001, 5000, 5432, and 6379 are not being used by other applications on your system.
