CREATE DATABASE users_db;

\c users_db;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

INSERT INTO users (name, email) VALUES 
    ('Juan Pérez', 'juan.perez@example.com'),
    ('María García', 'maria.garcia@example.com'),
    ('Carlos López', 'carlos.lopez@example.com')
ON CONFLICT (email) DO NOTHING;

CREATE OR REPLACE VIEW user_stats AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN created_at > CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as users_last_week,
    COUNT(CASE WHEN created_at > CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as users_last_month
FROM users;

GRANT ALL PRIVILEGES ON DATABASE users_db TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

SELECT 'Base de datos inicializada correctamente' as status;