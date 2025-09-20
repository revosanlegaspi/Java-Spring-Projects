-- This script sets up the database schema for the examination system.
-- It's idempotent and optimized for performance and data integrity.

-- Stop execution on any error to ensure the database schema is created consistently.
\set ON_ERROR_STOP on

-- Connect to the default 'postgres' database.
\c postgres;

-- Drop the database if it exists to allow for a clean setup.
-- This is intended for development environments.
DROP DATABASE IF EXISTS "Examiner_IO_DB" WITH (FORCE);

-- Create the new database.
CREATE DATABASE "Examiner_IO_DB"
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Connect to the new database.
\c "Examiner_IO_DB";

-------------------------------------------------------------------
-- TABLE DEFINITIONS
-------------------------------------------------------------------

-- User information
CREATE TABLE IF NOT EXISTS users (
    user_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('STUDENT', 'TEACHER', 'ADMIN')),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    updated_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    created_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by VARCHAR(255) NOT NULL
);

-- Exam details
CREATE TABLE IF NOT EXISTS exams (
    exam_id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    created_by_user_id BIGINT NOT NULL,
    updated_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    created_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
CREATE INDEX idx_exams_created_by ON exams (created_by_user_id);

-- Question details
CREATE TABLE IF NOT EXISTS questions (
    question_id BIGSERIAL PRIMARY KEY,
    exam_id BIGINT NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('SINGLE_CHOICE', 'MULTI_SELECT')),
    updated_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    created_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    FOREIGN KEY (exam_id) REFERENCES exams(exam_id) ON DELETE CASCADE
);
CREATE INDEX idx_questions_exam_id ON questions (exam_id);

-- Answer choices for questions
CREATE TABLE IF NOT EXISTS choices (
    choice_id BIGSERIAL PRIMARY KEY,
    question_id BIGINT NOT NULL,
    choice_text VARCHAR(255) NOT NULL,
    is_correct BOOLEAN NOT NULL,
    updated_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    created_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE
);
CREATE INDEX idx_choices_question_id ON choices (question_id);

-- Student attempts on exams
CREATE TABLE IF NOT EXISTS attempts (
    attempt_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    exam_id BIGINT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    score INT,
    updated_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    created_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(exam_id) ON DELETE CASCADE,
    CONSTRAINT chk_end_time_after_start CHECK (end_time IS NULL OR end_time >= start_time)
);
CREATE INDEX idx_attempts_user_exam ON attempts (user_id, exam_id);

-- Submitted answers for each question in an attempt
CREATE TABLE IF NOT EXISTS submitted_answers (
    submitted_answer_id BIGSERIAL PRIMARY KEY,
    attempt_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    option_id BIGINT NOT NULL,
    updated_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    created_dt TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    FOREIGN KEY (attempt_id) REFERENCES attempts(attempt_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE,
    FOREIGN KEY (option_id) REFERENCES options(option_id) ON DELETE CASCADE
);
CREATE INDEX idx_submitted_answers_composite ON submitted_answers (attempt_id, question_id, option_id);