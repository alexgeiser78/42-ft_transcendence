// Fastify server using node.js that manages an API listening on port 3000

const fastify = require('fastify')({ logger: true }); //loading the fastify Framework and activate the logs
const sqlite3 = require('sqlite3').verbose(); // SQLite3 library
const fs = require('fs'); // File system library
const path = require('path'); // Path library
const bcrypt = require('bcrypt'); // Bcrypt library for hashing passwords

// Define a simple route
fastify.get('/', async (request, reply) => 
    {
    return { message: 'Pong!' };
    });

// Route to display all users
fastify.get('/users', async (request, reply) => {
    try 
    {
        // Query all users from the database asynchronously
        const rows = await new Promise((resolve, reject) => 
            {
            db.all('SELECT * FROM users', [], (err, rows) => 
            {
                if (err) 
                {
                    reject(err);
                } 
                else 
                {
                    resolve(rows);
                }
            });
        });

        // If no users are found
        if (rows.length === 0) 
            {
            return reply.status(404).send({ message: 'No users found' });
            }

        // Send the list of users only once
        return reply.send(rows);

    } 
    catch (error) 
    {
        console.error('Error retrieving users:', error);
        return reply.status(500).send({ message: 'Error retrieving users' });
    }
});


// Route to the SQLite database
const dbPath = path.join(__dirname, 'database.sqlite');

// Create or open the SQLite Database
const db = new sqlite3.Database(dbPath, (err) => 
    {
    if (err) 
        {
        console.error('Database opening failed', err.message);
        } 
    else 
    {
        console.log('Connection to database completed');
        const initSQL = fs.readFileSync(path.join(__dirname, 'init.sql'), 'utf8'); // Read and execute the SQL file to initialise the database
        db.exec(initSQL, (err) => {
            if (err) 
                {
                console.error('Error while executing the file init.sql:', err.message);
                }
            else {
                console.log('Database initiated successfully');
                }
        });
    }
});

// Promisified function to handle DB get
function dbGetAsync(query, params) 
{
    return new Promise((resolve, reject) => 
        {
            db.get(query, params, (err, row) => 
                {
                if (err) reject(err);
                    resolve(row);
                });
        });
}

// Promisified function to handle DB run
function dbRunAsync(query, params) 
{
    return new Promise((resolve, reject) => 
        {
        db.run(query, params, function (err) 
        {
            if (err) reject(err);
            resolve(this);
        });
        });
}

// Inscription route for a new user
fastify.post('/register', async (request, reply) => 
    {
    const { username, email, password } = request.body;

    // Check if the fields are filled
    if (!username || !email || !password) 
        {
        return reply.status(400).send({ message: 'All fields need to be filled' });
        }

    try {
        // Check if the user already exists
        const row = await dbGetAsync('SELECT * FROM users WHERE email = ? OR username = ?', [email, username]);

        if (row) 
            {
            return reply.status(400).send({ message: 'The username or email already exists' });
            }

        // Password hash
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        // Insert a new user in the database
        const result = await dbRunAsync('INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)', [username, email, hashedPassword]);

        // Successfully created user, return response
        return reply.status(201).send({ message: 'User successfully created', userId: result.lastID });

        } 
        catch (err) 
        {
            return reply.status(500).send({ message: 'Error while processing the request', error: err.message });
        }
    });

// Start the server
const start = async () => 
    {
    try 
    {
        await fastify.listen({ port: 3000, host: '0.0.0.0' });
        console.log('Server is running on http://localhost:3000');
    } 
    catch (err) 
    {
        fastify.log.error(err);
        process.exit(1);
    }
};

start();
