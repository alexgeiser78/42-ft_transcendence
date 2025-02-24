// Fastify server using node.js that manages an API listening on port 3000
// and answers with JSON when we acccess to the root(/)

const fastify = require('fastify')({ logger: true }); //loading the fastify Framework and activate the logs
const sqlite3 = require('sqlite3').verbose(); //
const fs = require('fs'); //
const path = require('path'); //

// Define a simple route
fastify.get('/', async (request, reply) =>   //creates a route which listen get request on (/), (request, reply ) => {...} fonction to execute when the route is called, async is usefull for db request
    {
    return { message: 'Hello, Fastify!' };
    });

// Route to the SQLite database
const dbPath = path.join(__dirname, 'database.sqlite');

// Create or open the SQLite Database
const db = new sqlite3.Database(dbPath, (err) => //new + create DB
    {
    if (err) 
        {
            console.error('Database opening failed', err.message);
        } 
    else 
        {
            console.log('Connection to database completed');
            const initSQL = fs.readFileSync(path.join(__dirname, 'init.sql'), 'utf8'); // Read and execute the SQL file to initialise the database
            db.exec(initSQL, (err) => 
            {
                if (err) 
                {
                    console.error('Error while executing the file init.sql:', err.message);
                } 
                else 
                {
                    console.log('Database initiated succesfully');
                }
            });
        }
    });

// Inscription route for a new user
fastify.post('/register', async (request, reply) => 
    {
        const { username, email, password } = request.body;
  
        // Check if the fields are filled
        if (!username || !email || !password) 
        {
            return reply.status(400).send({ message: 'All fields needs to be filled' });
        }
  
        // Check if the user already exists
        db.get('SELECT * FROM users WHERE email = ? OR username = ?', [email, username], async (err, row) => 
            {
            if (row)
                {
                    return reply.status(400).send({ message: 'The username or email already exist' });
                }
  
                // Password hash
                const bcrypt = require('bcrypt');
                const saltRounds = 10;
                const hashedPassword = await bcrypt.hash(password, saltRounds);
  
                // Insert a new user n the database
                db.run('INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)', [username, email, hashedPassword], function (err) 
                {
                if (err)
                    {
                        return reply.status(500).send({ message: 'Erreur lors de la création de l\'utilisateur' });
                    }
                return reply.status(201).send({ message: 'Utilisateur créé avec succès', userId: this.lastID });
                });
            });
    });

// Start the server
const start = async () => //create a start function 
    {
        try 
        {
            await fastify.listen({ port: 3000, host: '0.0.0.0' });
            console.log('Server is running on http://localhost:3000');
        } 
        catch (err) 
        {
        fastify.log.error(err); //if error catch pints in console: fastify.log.error(err)
        process.exit(1);  //stops the program
        }
    };

start();
