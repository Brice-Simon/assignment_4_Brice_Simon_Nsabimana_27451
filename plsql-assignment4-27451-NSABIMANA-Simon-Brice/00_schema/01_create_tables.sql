-- =====================================================================
-- Assignment IV - University Registration & Grading System
-- File   : 00_schema/01_create_tables.sql
-- Purpose: Tables, relationships, constraints, sequences, SQL types.
-- Note   : Re-runnable. Existing objects of this project are dropped first.
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------- Clean-up (so the script can be run repeatedly) ----------
BEGIN
  FOR t IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('ENROLLMENTS','COURSES','STUDENTS',
                                  'DEPARTMENTS','ERROR_LOG','PERF_DEMO')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;

  FOR s IN (SELECT sequence_name
              FROM user_sequences
             WHERE sequence_name IN ('SEQ_STUDENT','SEQ_COURSE',
                                     'SEQ_ENROLLMENT','SEQ_ERROR_LOG')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;

  FOR ty IN (SELECT type_name FROM user_types WHERE type_name = 'T_NUMBER_TAB') LOOP
    EXECUTE IMMEDIATE 'DROP TYPE ' || ty.type_name || ' FORCE';
  END LOOP;
END;
/

-- ---------- Tables ----------
CREATE TABLE departments (
  dept_id    NUMBER(4)      CONSTRAINT pk_departments PRIMARY KEY,
  dept_name  VARCHAR2(100)  NOT NULL,
  CONSTRAINT uq_dept_name UNIQUE (dept_name)
);

CREATE TABLE students (
  student_id  NUMBER(6)      CONSTRAINT pk_students PRIMARY KEY,
  first_name  VARCHAR2(50)   NOT NULL,
  last_name   VARCHAR2(50)   NOT NULL,
  email       VARCHAR2(100)  NOT NULL,
  dept_id     NUMBER(4)      NOT NULL,
  gpa         NUMBER(3,2),
  status      VARCHAR2(10)   DEFAULT 'ACTIVE' NOT NULL,
  enrolled_on DATE           DEFAULT SYSDATE  NOT NULL,
  CONSTRAINT uq_student_email UNIQUE (email),
  CONSTRAINT ck_student_status CHECK (status IN ('ACTIVE','SUSPENDED','GRADUATED')),
  CONSTRAINT ck_student_gpa    CHECK (gpa BETWEEN 0 AND 4),
  CONSTRAINT fk_student_dept   FOREIGN KEY (dept_id) REFERENCES departments (dept_id)
);

CREATE TABLE courses (
  course_id    NUMBER(5)      CONSTRAINT pk_courses PRIMARY KEY,
  course_code  VARCHAR2(10)   NOT NULL,
  course_name  VARCHAR2(100)  NOT NULL,
  credits      NUMBER(1)      NOT NULL,
  dept_id      NUMBER(4)      NOT NULL,
  max_capacity NUMBER(3)      DEFAULT 40 NOT NULL,
  CONSTRAINT uq_course_code   UNIQUE (course_code),
  CONSTRAINT ck_course_credit CHECK (credits BETWEEN 1 AND 6),
  CONSTRAINT ck_course_cap    CHECK (max_capacity > 0),
  CONSTRAINT fk_course_dept   FOREIGN KEY (dept_id) REFERENCES departments (dept_id)
);

CREATE TABLE enrollments (
  enrollment_id NUMBER(8)     CONSTRAINT pk_enrollments PRIMARY KEY,
  student_id    NUMBER(6)     NOT NULL,
  course_id     NUMBER(5)     NOT NULL,
  semester      VARCHAR2(10)  NOT NULL,           -- e.g. '2026-B'
  marks         NUMBER(5,2),
  grade         VARCHAR2(2),
  enrolled_on   DATE          DEFAULT SYSDATE NOT NULL,
  CONSTRAINT uq_enrollment UNIQUE (student_id, course_id, semester),
  CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students (student_id),
  CONSTRAINT fk_enroll_course  FOREIGN KEY (course_id)  REFERENCES courses  (course_id),
  CONSTRAINT ck_enroll_marks_range CHECK (marks BETWEEN 0 AND 100),
  CONSTRAINT ck_enroll_grade_value CHECK (grade IN ('A','B+','B','C+','C','D','F')),
  -- marks and grade are always set together or both empty
  CONSTRAINT ck_enroll_marks_grade_pair CHECK (
        (marks IS NULL AND grade IS NULL)
     OR (marks IS NOT NULL AND grade IS NOT NULL))
);

CREATE INDEX ix_enroll_course_sem ON enrollments (course_id, semester);
CREATE INDEX ix_enroll_student    ON enrollments (student_id);

-- Central error log (written by sp_log_error through an autonomous transaction)
CREATE TABLE error_log (
  log_id        NUMBER         CONSTRAINT pk_error_log PRIMARY KEY,
  source_name   VARCHAR2(60)   NOT NULL,
  error_code    NUMBER,
  error_message VARCHAR2(4000),
  logged_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
  logged_by     VARCHAR2(30)   DEFAULT USER
);

-- Scratch table used only by sp_performance_demo (row-by-row vs FORALL)
CREATE TABLE perf_demo (
  id         NUMBER         CONSTRAINT pk_perf_demo PRIMARY KEY,
  payload    VARCHAR2(50),
  created_at DATE           DEFAULT SYSDATE
);

-- ---------- Sequences (start above the sample-data IDs) ----------
CREATE SEQUENCE seq_student    START WITH 2013 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_course     START WITH 207  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_enrollment START WITH 6019 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_error_log  START WITH 1    INCREMENT BY 1 NOCACHE;

-- ---------- SQL collection type (needed to pass lists into procedures) ----------
CREATE OR REPLACE TYPE t_number_tab AS TABLE OF NUMBER;
/

PROMPT Schema created successfully.
