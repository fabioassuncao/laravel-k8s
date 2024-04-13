## Step-by-Step Installation:

### Step 1:
The first time you start the system, create the `.env` file from the `.env.example` file using the following command:

```bash
cp .env.example .env
```

### Step 2:
Next, start the containers and build the application container using the command:

```bash
docker-compose up -d --build
```

### Step 3:
Check if the `vendor` folder has been created or already exists. If not, install PHP dependencies with the command:

```bash
docker-compose exec app composer install
```

### Step 4:
Wait a few seconds until the MySQL container is ready, and then execute the command to configure the database and perform the initial data load:

```bash
docker-compose exec app php artisan migrate --seed
```

With these steps, the system will be ready to be used for the first time.
