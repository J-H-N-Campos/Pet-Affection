CREATE USER petaffection WITH PASSWORD 'petaffection';
CREATE DATABASE petaffection OWNER petaffection;
-- Univates"VML

CREATE TABLE cad_person (
    id              SERIAL PRIMARY KEY,
    dt_register     TIMESTAMP   NOT NULL,
    name            TEXT        NOT NULL,
    cpf_cnpj        TEXT        NOT NULL,
    birth_date      DATE,
    gender          TEXT,
    photo           TEXT,
    password        TEXT        NOT NULL,
    email           TEXT        NOT NULL,
    phone           TEXT        NOT NULL,
    code_auth       INT,
    token           TEXT        NOT NULL
); 

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE cad_person TO petaffection;
GRANT USAGE, SELECT ON SEQUENCE cad_person_id_seq TO petaffection;

CREATE TABLE cad_breed (
    id              SERIAL PRIMARY KEY,
    dt_register     TIMESTAMP   NOT NULL,
    name            TEXT        NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE cad_breed TO petaffection;
GRANT USAGE, SELECT ON SEQUENCE cad_breed_id_seq TO petaffection;

CREATE TABLE cad_pet (
    id              SERIAL PRIMARY KEY,
    dt_register     TIMESTAMP   NOT NULL,
    name            TEXT        NOT NULL,
    breed_id        INT         NOT NULL,
    person_id       INT         NOT NULL,
    photo           TEXT        NOT NULL,
    birth_date      DATE,
    gender          TEXT,
    rg              TEXT,
    weight          FLOAT,
    height          FLOAT,
    primary_color   TEXT,
    type            TEXT        NOT NULL,

    FOREIGN KEY (breed_id)  REFERENCES cad_breed(id),
    FOREIGN KEY (person_id) REFERENCES cad_person(id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE cad_pet TO petaffection;
GRANT USAGE, SELECT ON SEQUENCE cad_pet_id_seq TO petaffection;

CREATE TABLE cad_photo_lost_pet (
    id              SERIAL PRIMARY KEY,
    dt_register     TIMESTAMP   NOT NULL,
    latitude        TEXT        NOT NULL,
    longitude       TEXT        NOT NULL,
    photo           TEXT        NOT NULL,
    person_id       INT         NOT NULL,
    breed_id        INT         NOT NULL,
    primary_color   TEXT        NOT NULL,
    rg              TEXT,
    gender          TEXT,
    name            TEXT,
    status          TEXT        NOT NULL,
    
    FOREIGN KEY (person_id) REFERENCES cad_person(id),
    FOREIGN KEY (breed_id)  REFERENCES cad_breed(id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE cad_photo_lost_pet TO petaffection;
GRANT USAGE, SELECT ON SEQUENCE cad_photo_lost_pet_id_seq TO petaffection;