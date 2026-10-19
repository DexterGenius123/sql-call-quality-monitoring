DROP TABLE IF EXISTS review_violations, quality_reviews, calls, violation_types, managers CASCADE;

CREATE TABLE managers (
    manager_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name       TEXT NOT NULL,
    team_name       TEXT NOT NULL,
    hired_at        DATE NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE calls (
    call_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    manager_id      INTEGER NOT NULL REFERENCES managers(manager_id),
    started_at      TIMESTAMPTZ NOT NULL,
    duration_sec    INTEGER NOT NULL CHECK (duration_sec BETWEEN 1 AND 14400),
    direction       TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    outcome         TEXT NOT NULL CHECK (outcome IN ('sale', 'follow_up', 'declined', 'no_answer')),
    recording_url   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (recording_url IS NULL OR recording_url ~ '^https?://')
);

CREATE TABLE quality_reviews (
    review_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    call_id              BIGINT NOT NULL UNIQUE REFERENCES calls(call_id) ON DELETE CASCADE,
    reviewer_name        TEXT NOT NULL,
    reviewed_at          TIMESTAMPTZ NOT NULL,
    greeting_score       SMALLINT NOT NULL CHECK (greeting_score BETWEEN 0 AND 20),
    needs_score          SMALLINT NOT NULL CHECK (needs_score BETWEEN 0 AND 30),
    solution_score       SMALLINT NOT NULL CHECK (solution_score BETWEEN 0 AND 30),
    closing_score        SMALLINT NOT NULL CHECK (closing_score BETWEEN 0 AND 20),
    comment              TEXT,
    total_score          SMALLINT GENERATED ALWAYS AS
        (greeting_score + needs_score + solution_score + closing_score) STORED
);

CREATE TABLE violation_types (
    violation_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code              TEXT NOT NULL UNIQUE,
    title             TEXT NOT NULL,
    severity          TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'critical'))
);

CREATE TABLE review_violations (
    review_id          BIGINT NOT NULL REFERENCES quality_reviews(review_id) ON DELETE CASCADE,
    violation_type_id  INTEGER NOT NULL REFERENCES violation_types(violation_type_id),
    PRIMARY KEY (review_id, violation_type_id)
);

CREATE INDEX idx_calls_started_at ON calls (started_at);
CREATE INDEX idx_calls_manager_started ON calls (manager_id, started_at DESC);
CREATE INDEX idx_reviews_reviewed_at ON quality_reviews (reviewed_at);

-- Межтабличное правило проверяется триггером: CHECK не допускает подзапросы.
CREATE OR REPLACE FUNCTION validate_review_time() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reviewed_at < (SELECT started_at FROM calls WHERE call_id = NEW.call_id) THEN
        RAISE EXCEPTION 'reviewed_at cannot be earlier than call start';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_review_time
BEFORE INSERT OR UPDATE ON quality_reviews
FOR EACH ROW EXECUTE FUNCTION validate_review_time();
