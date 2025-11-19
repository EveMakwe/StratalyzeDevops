# Coffee Queue - Spring Boot Application

A simple Spring Boot application that simulates an office coffee queue.  
Orders move automatically from `NEW → BREWING → DONE` at scheduled intervals.

---

## PostgreSQL Database

- Ensure your PostgreSQL database is running and reachable before starting the application.
- Before running the application:
1. Create the PostgreSQL database:

```
CREATE DATABASE coffeequeue;
```

2. Execute the SQL script `createSchema.sql` (found in the root folder of this project) to create the required tables and schema.


## Build and Run

### 1. Build the application

Open a terminal in the project directory and run:

```
mvn clean install
```
This will compile the code and create the executable JAR file in the target/ directory.

### 2. Run the application with default settings
```
java -jar ./target/coffeequeue-0.0.1-SNAPSHOT.jar
```
By default, the application will use the settings in application.properties.

### 3. Customize database connection and server port
You can override the database connection details and application port using command-line arguments:

```
java -jar ./target/coffeequeue-0.0.1-SNAPSHOT.jar \
  --spring.datasource.url=jdbc:postgresql://<db-host>:<db-port>/coffeequeue \
  --server.port=<app-port> \
  --spring.datasource.username=<username> \
  --spring.datasource.password=<password>
```
Example:

```
java -jar ./target/coffeequeue-0.0.1-SNAPSHOT.jar \
  --spring.datasource.url=jdbc:postgresql://localhost:5432/coffeequeue \
  --server.port=8080 \
  --spring.datasource.username=postgres \
  --spring.datasource.password=postgres
```

### 4. API Endpoints
The Coffee Queue application exposes the following REST endpoints:

| Endpoint           | Method | Description                                        | Request Parameters                | Example Request | Example Response |
|-------------------|--------|----------------------------------------------------|----------------------------------|----------------|----------------|
| /health            | GET    | Checks if the application is running              | None                             | `GET /health` | `"OK"` |
| /order             | POST   | Creates a new coffee order for a customer         | `name` – customer’s name (String) | `POST /order?name=MickyMouse` | ```json { "id": 1, "customerName": "MickyMouse", "status": "NEW", "createdAt": "2025-10-29T10:00:00", "updatedAt": "2025-10-29T10:00:00" } ``` |
| /status            | GET    | Retrieves all orders for a specific customer      | `name` – customer’s name (String) | `GET /status?name=MickyMouse` | ```json [ { "id": 1, "customerName": "MickyMouse", "status": "NEW", "createdAt": "2025-10-29T10:00:00", "updatedAt": "2025-10-29T10:00:00" } ] ``` |
| /numberOfCoffees   | GET    | Returns a count of orders by status (`NEW`, `BREWING`, `DONE`) | None | `GET /numberOfCoffees` | ```json { "NEW": 2, "BREWING": 1, "DONE": 5 } ``` |



### 5. Notes
Order Processing: Orders will automatically transition from NEW → BREWING → DONE at scheduled intervals:

NEW → BREWING and BREWING → DONE every 1–3 seconds

**Timestamps**: **createdAt** is when the order was created; **updatedAt** is updated each time the status changes.
Example Flow:

```
# Create a new order for MickyMouse
POST /order?name=MickyMouse

# Check MickyMouse's orders
GET /status?name=MickyMouse

# See total orders by status
GET /numberOfCoffees
```

---
