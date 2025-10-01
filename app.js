require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Configuración de la base de datos PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'users_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

// Función para inicializar la base de datos
async function initializeDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Database initialized correctly');
  } catch (error) {
    console.error('Error initializing the database:', error);
  }
}

// Middleware de validación
const validateUser = (req, res, next) => {
  const { name, email } = req.body;
  
  if (!name || !email) {
    return res.status(400).json({
      error: 'Name and email are required fields'
    });
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      error: 'Email has an invalid format'
    });
  }
  
  next();
};

// Middleware de manejo de errores
const errorHandler = (error, req, res, next) => {
  console.error('Error:', error);
  
  if (error.code === '23505') { // Duplicate key error
    return res.status(409).json({
      error: 'El email ya está regi strado'
    });
  }
  
  res.status(500).json({
    error: 'Internal server error'
  });
};

// RUTAS DE LA API
// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'User Management Microservice'
  });
});

// Crear un nuevo usuario
app.post('/users', validateUser, async (req, res) => {
  try {
    const { name, email } = req.body;
    
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    
    res.status(201).json({
      message: 'User created successfully',
      user: result.rows[0]
    });
  } catch (error) {
    errorHandler(error, req, res);
  }
});

// Obtener información de un usuario por ID
app.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (isNaN(id)) {
      return res.status(400).json({
        error: 'ID must be a valid number'
      });
    }
    
    const result = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found'
      });
    }
    
    res.status(200).json({
      user: result.rows[0]
    });
  } catch (error) {
    errorHandler(error, req, res);
  }
});

// Obtener todos los usuarios (con paginación)
app.get('/users', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    
    const result = await pool.query(
      'SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    
    const countResult = await pool.query('SELECT COUNT(*) FROM users');
    const total = parseInt(countResult.rows[0].count);
    
    res.status(200).json({
      users: result.rows,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    errorHandler(error, req, res);
  }
});

// Actualizar información de un usuario (OPCIONAL)
app.put('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email } = req.body;
    
    if (isNaN(id)) {
      return res.status(400).json({
        error: 'ID must be a valid number'
      });
    }
    
    if (!name && !email) {
      return res.status(400).json({
        error: 'At least one field (name or email) must be provided'
      });
    }
    
    // Verificar si el usuario existe
    const userExists = await pool.query('SELECT id FROM users WHERE id = $1', [id]);
    if (userExists.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found'
      });
    }
    
    // Construir la consulta dinámicamente
    let updateFields = [];
    let values = [];
    let paramCount = 1;
    
    if (name) {
      updateFields.push(`name = $${paramCount}`);
      values.push(name);
      paramCount++;
    }
    
    if (email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({
          error: 'Invalid email format'
        });
      }
      updateFields.push(`email = $${paramCount}`);
      values.push(email);
      paramCount++;
    }
    
    updateFields.push('updated_at = CURRENT_TIMESTAMP');
    values.push(id);
    
    const query = `
      UPDATE users 
      SET ${updateFields.join(', ')} 
      WHERE id = $${paramCount} 
      RETURNING *
    `;
    
    const result = await pool.query(query, values);
    
    res.status(200).json({
      message: 'User updated successfully',
      user: result.rows[0]
    });
  } catch (error) {
    errorHandler(error, req, res);
  }
});

app.delete('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (isNaN(id)) {
      return res.status(400).json({
        error: 'ID must be a valid number'
      });
    }
    
    const result = await pool.query(
      'DELETE FROM users WHERE id = $1 RETURNING *',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found'
      });
    }
    
    res.status(200).json({
      message: 'User deleted successfully',
      user: result.rows[0]
    });
  } catch (error) {
    errorHandler(error, req, res);
  }
});

app.use('/', (req, res) => {
  res.status(404).json({
    error: 'Route not found'
  });
});

async function startServer() {
  try {
    await initializeDatabase();
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Health check available at: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('Error starting the server:', error);
    process.exit(1);
  }
}

process.on('SIGTERM', async () => {
  console.log('Closing server...');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('Closing server...');
  await pool.end();
  process.exit(0);
});

startServer();