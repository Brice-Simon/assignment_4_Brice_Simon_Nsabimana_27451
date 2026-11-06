# Assignment IV – Advanced Oracle PL/SQL: Adventists University of Central Africa Registration & Grading System

**Course:** Database Development with PL/SQL (INSY 8311)
**Instructor:** Eric Maniraguha | **Teaching Assistant:** Afanyu Emmanuel
**Class group:** 27451

## Project owner

| # | Full name | Student ID |
|---|-----------|------------|
| 1 | NSABIMANA Simon Brice | 27451 |

**Project owner:** NSABIMANA Simon Brice  |  **Student ID:** 27451

## 1. Application description

A small **university registration and grading system**. Students from several departments enrol in courses each semester, lecturers record marks, the system derives letter grades and calculates each student's GPA, and unexpected problems are written to a central error log.

### Requirements the application satisfies

| # | Requirement | Where it is implemented |
|---|-------------|-------------------------|
| R1 | Enrol only ACTIVE students, never beyond course capacity, never twice in the same course/semester | `sp_enroll_student`, `fn_available_seats`, `uq_enrollment` |
| R2 | Record marks (0–100) and derive a letter grade | `sp_record_grade`, `fn_marks_to_grade` |
| R3 | Upload a whole marks sheet at once and report bad rows without losing good ones | `sp_bulk_grade_upload` |
| R4 | Apply bonus marks to a whole class (capped at 100) | `sp_apply_bonus_marks` |
| R5 | Drop an enrollment only while it is still ungraded | `sp_drop_enrollment` |
| R6 | Calculate GPA (credit-weighted, 4.0 scale) for one or all students | `fn_calculate_gpa`, `sp_update_student_gpa`, `sp_update_all_gpas` |
| R7 | Print class rosters with average and grade distribution | `sp_class_report` |
| R8 | List the students of a department | `sp_department_summary` |
| R9 | Log unexpected errors permanently | `sp_log_error` (autonomous transaction) |
| R10 | Show why bulk processing is faster | `sp_performance_demo` |

**Grading scale:** 80–100 A (4.0) · 75–79 B+ (3.5) · 70–74 B (3.0) · 65–69 C+ (2.5) · 60–64 C (2.0) · 50–59 D (1.0) · below 50 F (0.0)

## 2. Database schema

```
DEPARTMENTS (dept_id PK, dept_name UQ)
     │1                         │1
     │                          │
     ▼N                         ▼N
STUDENTS (student_id PK,      COURSES (course_id PK, course_code UQ,
  email UQ, dept_id FK,         credits, dept_id FK, max_capacity)
  gpa, status)                       │1
     │1                              │
     ▼N                              ▼N
        ENROLLMENTS (enrollment_id PK, student_id FK, course_id FK,
                     semester, marks, grade,
                     UQ(student_id, course_id, semester))

ERROR_LOG  (central log written by sp_log_error)
PERF_DEMO  (scratch table used by sp_performance_demo)
```

Constraints include primary/foreign/unique keys, `CHECK` on status, GPA, credits, capacity, marks range, grade values, and a pair-check so `marks` and `grade` are always set together.

## 3. Repository layout

```
├── README.md
├── .gitignore
├── install_all.sql                 (optional helper: runs everything in the right order)
├── 00_schema/      01_create_tables.sql · 02_insert_sample_data.sql
├── 01_procedures/  sp_*.sql        (one file per procedure)
├── 02_functions/   fn_*.sql        (one file per function)
├── 03_tests/       test_success_cases.sql · test_error_cases.sql
├── screenshots/    <test_name>_output.png
└── docs/           IMPLEMENTATION_NOTES.md
```

## 4. How to run

Requires Oracle Database 12c or later (the tests use `FETCH FIRST`). Use SQL Developer, SQLcl or SQL*Plus connected to your own schema, and run from the repository root.

1. Run `00_schema/01_create_tables.sql`
2. Run `00_schema/02_insert_sample_data.sql`
3. Compile the **functions** in `02_functions/`
4. Compile the **procedures** in `01_procedures/` — start with `sp_log_error.sql`
5. Run `03_tests/test_success_cases.sql`, then `03_tests/test_error_cases.sql`
6. Verify the output and save fresh screenshots into `screenshots/`. The previous screenshots were removed because they showed the original dataset; see `screenshots/README_RECAPTURE_REQUIRED.md`.

> **Why functions before procedures?** The procedures call the functions (and `sp_log_error`), so compiling the functions first avoids "created with compilation errors" warnings. `@install_all.sql` does steps 1–4 automatically.

## 5. Concept coverage (checklist)

| Requirement | Where |
|-------------|-------|
| User-defined records | `sp_enroll_student`, `sp_class_report` |
| `%ROWTYPE` records | `sp_enroll_student`, `sp_drop_enrollment`, `sp_class_report`, `sp_department_summary` |
| Collections (associative array, nested table) | `sp_bulk_grade_upload`, `sp_apply_bonus_marks`, `sp_update_all_gpas`, `sp_class_report`, `sp_performance_demo`; SQL type `t_number_tab` |
| Implicit cursors (`SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`) | `sp_enroll_student`, `sp_record_grade`, `sp_drop_enrollment`, `sp_update_student_gpa` |
| Explicit cursors | OPEN/FETCH/CLOSE: `sp_class_report` · cursor FOR loop: `sp_department_summary`, `fn_calculate_gpa` |
| `BULK COLLECT` | `sp_apply_bonus_marks`, `sp_update_all_gpas` |
| `FORALL` + bulk error handling | `sp_bulk_grade_upload`, `sp_apply_bonus_marks`, `sp_update_all_gpas`, `sp_performance_demo` |
| Stored procedures | 11 files in `01_procedures/` |
| Stored functions | 5 files in `02_functions/` (called from SQL and PL/SQL in the tests) |
| Predefined exceptions | `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX` |
| User-defined exceptions + `RAISE_APPLICATION_ERROR` | all procedures/functions (codes -20001 … -20099) |

The error-code table is in `docs/IMPLEMENTATION_NOTES.md`.

## 6. AI assistance statement

AI assistance disclosure: complete this statement accurately before submission. Identify any AI tool used, describe the specific assistance received, and state which parts you personally reviewed, modified, executed and can explain. Do not claim database execution or group review unless it was actually completed.
