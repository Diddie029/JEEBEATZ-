-- schema.sql
-- Basic schema for Jeebeta Z (Postgres)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(255),
  is_admin BOOLEAN DEFAULT FALSE,
  mpesa_phone VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Beats
CREATE TABLE beats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  genre VARCHAR(100),
  price_kes INTEGER NOT NULL,      -- price in Kenyan Shillings (integer KES)
  description TEXT,
  cover_url TEXT,                  -- S3 URL or CDN path
  audio_url TEXT,                  -- S3 path for full audio (private)
  preview_url TEXT,                -- S3 public/short preview
  uploaded_by UUID REFERENCES users(id),
  downloads_count INTEGER DEFAULT 0,
  total_earnings_kes BIGINT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Purchases
CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  beat_id UUID REFERENCES beats(id) NOT NULL,
  amount_kes INTEGER NOT NULL,
  status VARCHAR(50) NOT NULL, -- pending, succeeded, failed
  transaction_ref TEXT,        -- mpesa transaction id or payment gateway ref
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Download history
CREATE TABLE downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_id UUID REFERENCES purchases(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  beat_id UUID REFERENCES beats(id) NOT NULL,
  downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Blog posts
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  body TEXT,
  author_id UUID REFERENCES users(id),
  featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Payments / Mpesa logs
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_id UUID REFERENCES purchases(id),
  mpesa_checkout_request_id TEXT,
  mpesa_transaction_id TEXT,
  status VARCHAR(50),
  raw_payload JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
