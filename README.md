# AUCA Student Registration & Grading Engine (Oracle PL/SQL)

**Assignment IV: Advanced Oracle PL/SQL**
**Course:** Database Development with PL/SQL (INSY 8311)
**Instructor:** Eric Maniraguha · **Teaching Assistant:** Afanyu Emmanuel
**Group:** D · 27451

## Author

| # | Name | Student ID |
|---|------|------------|
| 1 | NSABIMANA Simon Brice | 27451 |

---

## 1. Overview

This project is a compact registration and grading back end for the Adventists University of Central Africa, written entirely in Oracle PL/SQL. It covers the full semester cycle:

1. Students from three departments enrol in courses.
2. Lecturers submit marks, singly or as a whole sheet.
3. The database turns marks into letter grades and grade points.
4. GPAs are recalculated, weighted by course credits.
5. Anything unexpected is recorded in a permanent error log.

All business rules live inside the database as stored procedures and functions, so they apply no matter which front end calls them.

### Business rules and where they live

| ID | Rule | Implemented in |
|----|------|----------------|
| R1 | Only ACTIVE students may enrol; a course cannot exceed its capacity; no duplicate enrollment for the same course and semester | `sp_enroll_student`, `fn_available_seats`, constraint `uq_enrollment` |
| R2 | Marks must be 0–100 and are converted to a letter grade | `sp_record_grade`, `fn_marks_to_grade` |
| R3 | A full marks sheet can be uploaded in one call; invalid rows are reported while valid rows are still saved | `sp_bulk_grade_upload` |
| R4 | Bonus marks can be added to an entire class, capped at 100 | `sp_apply_bonus_marks` |
| R5 | An enrollment can only be dropped if it has not been graded | `sp_drop_enrollment` |
| R6 | GPA is credit-weighted on a 4.0 scale, for one student or for everyone | `fn_calculate_gpa`, `sp_update_student_gpa`, `sp_update_all_gpas` |
| R7 | Class roster with average mark and grade distribution | `sp_class_report` |
| R8 | Listing of all students in a department | `sp_department_summary` |
| R9 | Unexpected errors are logged even if the main transaction rolls back | `sp_log_error` (autonomous transaction) |
| R10 | Demonstrates the speed advantage of bulk operations | `sp_performance_demo` |

### Grading scale

| Marks | Grade | Points |
|-------|-------|--------|
| 80–100 | A | 4.0 |
| 75–79 | B+ | 3.5 |
| 70–74 | B | 3.0 |
| 65–69 | C+ | 2.5 |
| 60–64 | C | 2.0 |
| 50–59 | D | 1.0 |
| 0–49 | F | 0.0 |

---

## 2. Data model

```
DEPARTMENTS (dept_id PK, dept_name UQ)
     │ 1                        │ 1
     │                          │
     ▼ N                        ▼ N
STUDENTS                      COURSES
 (student_id PK, email UQ,     (course_id PK, course_code UQ,
  dept_id FK, gpa, status)      credits, dept_id FK, max_capacity)
     │ 1                          │ 1
     │                            │
     ▼ N                          ▼ N
          ENROLLMENTS
          (enrollment_id PK, student_id FK, course_id FK,
           semester, marks, grade,
           UQ (student_id, course_id, semester))

ERROR_LOG   central table written by sp_log_error
PERF_DEMO   scratch table used by sp_performance_demo
```

Integrity is enforced with primary, foreign and unique keys plus `CHECK` constraints on status, GPA, credits, capacity, the marks range and the allowed grade values. A paired check guarantees that `marks` and `grade` are always filled in together or both left empty.

### Sample data highlights

The seed script is built to exercise specific scenarios:

- Two students share the surname **Ndayisaba**, which triggers `TOO_MANY_ROWS` in a lookup by last name.
- Student **1009** is `SUSPENDED`, so enrolment attempts must be refused.
- Student **1011** has no enrollments, which is useful for the GPA edge case.
- Course **105 (CS399)** has capacity 2 and is already full for semester `2026-A`.
- Several enrollments have `NULL` marks and grade, representing work not yet graded.

---

## 3. Project structure

```
.
├── README.md
├── .gitignore
├── install_all.sql          optional: runs the setup in the correct order
├── 00_schema/               01_create_tables.sql, 02_insert_sample_data.sql
├── 01_procedures/           sp_*.sql (one file per procedure)
├── 02_functions/            fn_*.sql (one file per function)
├── 03_tests/                test_success_cases.sql, test_error_cases.sql
├── screenshots/             <test_name>_output.png
└── docs/                    IMPLEMENTATION_NOTES.md
```

---

## 4. Installation and execution

**Prerequisite:** Oracle Database 12c or newer (the tests use `FETCH FIRST`). Use SQL Developer, SQLcl or SQL*Plus, connected to your own schema, and start every script from the repository root.

| Step | Action |
|------|--------|
| 1 | Run `00_schema/01_create_tables.sql` |
| 2 | Run `00_schema/02_insert_sample_data.sql` |
| 3 | Compile every file in `02_functions/` |
| 4 | Compile every file in `01_procedures/`, beginning with `sp_log_error.sql` |
| 5 | Run `03_tests/test_success_cases.sql`, then `03_tests/test_error_cases.sql` |
| 6 | Check the output and store your own screenshots in `screenshots/` (see `screenshots/README_RECAPTURE_REQUIRED.md`) |

> **Order matters.** The procedures call the functions and `sp_log_error`. Compiling functions first prevents "created with compilation errors" warnings. Running `@install_all.sql` performs steps 1–4 for you.

---

## 5. PL/SQL feature coverage

| Feature | Used in |
|---------|---------|
| User-defined record types | `sp_enroll_student`, `sp_class_report` |
| `%ROWTYPE` records | `sp_enroll_student`, `sp_drop_enrollment`, `sp_class_report`, `sp_department_summary` |
| Collections (associative arrays, nested tables) | `sp_bulk_grade_upload`, `sp_apply_bonus_marks`, `sp_update_all_gpas`, `sp_class_report`, `sp_performance_demo`, SQL type `t_number_tab` |
| Implicit cursor attributes (`SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`) | `sp_enroll_student`, `sp_record_grade`, `sp_drop_enrollment`, `sp_update_student_gpa` |
| Explicit cursors | OPEN/FETCH/CLOSE in `sp_class_report`; cursor FOR loop in `sp_department_summary` and `fn_calculate_gpa` |
| `BULK COLLECT` | `sp_apply_bonus_marks`, `sp_update_all_gpas` |
| `FORALL` with `SAVE EXCEPTIONS` style error handling | `sp_bulk_grade_upload`, `sp_apply_bonus_marks`, `sp_update_all_gpas`, `sp_performance_demo` |
| Stored procedures | 11 files in `01_procedures/` |
| Stored functions | 5 files in `02_functions/`, called from both SQL and PL/SQL in the tests |
| Predefined exceptions | `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX` |
| User-defined exceptions with `RAISE_APPLICATION_ERROR` | All procedures and functions, using codes -20001 to -20099 |

The full list of error codes is in `docs/IMPLEMENTATION_NOTES.md`.

---

## 6. AI assistance disclosure

> Complete this section truthfully before submitting.

- **AI tool(s) used:** to handle and debug errors and also helped me understand complicated and hard queries
