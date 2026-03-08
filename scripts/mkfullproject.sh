#!/usr/bin/env bash

set -e

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "Uso: mkfullproject <nome_do_projeto>"
    exit 1
fi

echo "Criando projeto '$PROJECT_NAME'..."

mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

############################
# ROOT FILES
############################

cat <<EOF > README.md
# $PROJECT_NAME
EOF

################################
# DOCKER COMPOSE DEV
################################

cat <<EOF > docker-compose.dev.yml
version: "3.9"

services:
  db:
    image: postgres:latest
    container_name: ${PROJECT_NAME}_db
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: ${PROJECT_NAME}_db
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  backend:
    build: ./backend
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    env_file:
      - ./backend/.env
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  worker:
    build: ./backend
    command: celery -A app.worker worker --loglevel=info
    volumes:
      - ./backend:/app
    env_file:
      - ./backend/.env
    depends_on:
      - redis

  redis:
    image: redis:7

  frontend:
    build: ./frontend
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - "5173:5173"
    env_file:
      - ./frontend/.env

  volumes:
    db_data:
EOF

################################
# DOCKER COMPOSE PROD
################################

cat <<EOF > docker-compose.prod.yml
version: "3.9"

services:
  db:
    image: postgres:latest
    container_name: ${PROJECT_NAME}_db
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: ${PROJECT_NAME}_db
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  backend:
    build: ./backend
    ports:
      - "8000:8000"

  worker:
    build: ./backend
    command: celery -A app.worker worker --loglevel=info

  redis:
    image: redis:7

  frontend:
    build: ./frontend
    ports:
      - "80:5173"

  volumes:
    db_data:
EOF


cat <<EOF > .gitignore
.env
backend/.venv
backend/__pycache__
frontend/node_modules
frontend/dist
EOF


cat <<EOF > .env
PROJECT_NAME=$PROJECT_NAME
EOF

################################
# MAKEFILE
################################

cat <<EOF > Makefile
up:
	docker compose -f docker-compose.dev.yml up --build

down:
	docker compose -f docker-compose.dev.yml down

logs:
	docker compose -f docker-compose.dev.yml logs -f

migrate:
	docker compose exec backend alembic upgrade head

revision:
	docker compose exec backend alembic revision --autogenerate -m "migration"
EOF


################################
# BACKEND
################################

echo "Criando backend..."

mkdir backend
cd backend

python -m venv .venv

mkdir -p app/{routers,services,schemas,models,utils,core,db}

touch app/__init__.py
touch app/main.py
touch app/routers/__init__.py
touch app/services/__init__.py
touch app/schemas/__init__.py
touch app/models/__init__.py
touch app/utils/__init__.py
touch app/core/__init__.py
touch app/db/__init__.py

################################
# FASTAPI MAIN
################################

cat <<EOF > app/main.py
from fastapi import FastAPI

app = FastAPI(
    title="$PROJECT_NAME API",
    description="API para o projeto $PROJECT_NAME",
    version="0.1.0"
)

@app.get("/")
def read_root():
    return {"message": "API, $PROJECT_NAME is running!"}
EOF

################################
# SQLALCHEMY BASE
################################

cat <<EOF > app/db/base.py
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
EOF

################################
# SESSION ASYNC
################################

cat <<EOF > app/db/session.py
import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_async_engine(
    DATABASE_URL,
    echo=True
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)
EOF

################################
# CELERY
################################

cat <<EOF > app/worker.py
from celery import Celery
from config import REDIS_URL
import os

celery = Celery(
    "worker",
    broker=REDIS_URL,
    backend=REDIS_URL
)

@celery.task
def test_task():
    return "celery working"
EOF

################################
# MODELS IMPORT
################################

cat <<EOF > app/db/models.py
from .base import Base

# importe modelos aqui
# from app.models.user import User
EOF

################################
# CONFIG
################################

cat <<EOF > app/core/config.py
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
REDIS_URL = os.getenv("REDIS_URL")
EOF

##################################
# REQUIREMENTS
##################################

cat <<EOF > requirements.txt
fastapi
uvicorn[standard]
python-dotenv
pyydantic
sqlalchemy>2.0
alembic
asyncpg
celery
redis
watchfiles
ruff
black
EOF

##################################
# ENV
##################################

cat <<EOF > .env
APP_ENV=development
PORT=8000
DATABASE_URL=postgresql+asyncpg://user:password@db:5432/${PROJECT_NAME}_db
REDIS_URL=redis://redis:6379
EOF

##################################
# GITIGNORE
##################################

cat <<EOF > .gitignore
.venv
__pycache__
*.pyc
.env
EOF

##################################
# DOCKERFILE BACKEND
##################################

cat <<EOF > Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt || true

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
EOF

################################
# ALEMBIC INIT
################################

source .venv/bin/activate
pip install -r requirements.txt
alembic init alembic

################################
# ALEMBIC CONFIG
################################

cat <<EOF > alembic.ini
[alembic]
script_location = alembic
sqlalchemy.url = postgresql+asyncpg://user:password@db:5432/db
EOF

################################
# ALEMBIC ENV ASYNC
################################

cat <<'EOF' > alembic/env.py
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

from app.db.base import Base
from app.db import models

config = context.config

fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")

    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations():

    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online():
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
EOF

################################
# PRE-COMMIT
################################

cat <<EOF > .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff

  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
EOF

cd ..

################################
# FRONTEND
################################

echo "Criando frontend..."

npm create vite@latest frontend -- --template vue

cd frontend

npm install
npm install axios, pinia

cat <<EOF > src/services/api.js
import axios from "axios"

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
})
EOF


################################
# FRONTEND ENV
################################

cat <<EOF > .env
VITE_API_URL=http://localhost:8000
EOF


################################
# FRONTEND GITIGNORE
################################

cat <<EOF > .gitignore
node_modules
dist
.env
EOF


################################
# FRONTEND DOCKERFILE
################################

cat <<EOF > Dockerfile
FROM node:20

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5173

CMD ["npm","run","dev","--","--host"]
EOF

cd ..

################################
# INIT GIT
################################

git init

echo ""
echo "Projeto criado com sucesso!"
echo ""
echo "Estrutura:"
echo ""

tree -L 2

echo ""
echo "Para rodar:"
echo ""
echo "make up"