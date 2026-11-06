> **Project owner:** NSABIMANA Simon Brice | **Student ID:** 27451

# Implementation & Performance Notes

## 1. Design overview

The application is a university registration and grading system (see `README.md`). All business logic lives in **stored procedures and functions**; the tests only call them.

* **Functions** are small and side-effect free (no DML), so they can be used inside SQL: `fn_marks_to_grade`, `fn_grade_points`, `fn_calculate_gpa`, `fn_available_seats`, `fn_find_student_by_last_name`.
* **Procedures** perform the operations: enrol, grade, drop, bulk upload, bonus, GPA refresh, reports, error logging, performance demo.
* **Transactions:** procedures never `COMMIT`; the caller decides. The only exceptions are `sp_log_error` and `sp_performance_demo`, which use `PRAGMA AUTONOMOUS_TRANSACTION` so they cannot commit or roll back the caller's work.

## 2. Records

| Kind | Example |
|------|---------|
| `%ROWTYPE` | `l_student students%ROWTYPE` in `sp_enroll_student` holds a whole student row; `l_enrollment enrollments%ROWTYPE` in `sp_drop_enrollment` |
| User-defined | `t_enroll_summary` (name, course code, seats left) in `sp_enroll_student`; `t_roster_rec` receives each `FETCH` in `sp_class_report` |

## 3. Collections

| Type | Where | Why |
|------|-------|-----|
| Nested table (SQL type `t_number_tab`) | parameters of `sp_bulk_grade_upload` | lets a caller pass a list of ids and marks |
| Nested tables (local) | `sp_apply_bonus_marks`, `sp_update_all_gpas` | targets of `BULK COLLECT`; sized with `EXTEND` |
| Associative array indexed by `PLS_INTEGER` | `sp_bulk_grade_upload`, `sp_update_all_gpas`, `sp_performance_demo` | holds derived values at the same index as the source |
| Associative array indexed by `VARCHAR2` | `sp_class_report` | grade → number of students (`EXISTS`, `FIRST`, `NEXT`) |

## 4. Cursors

* **Implicit:** `INSERT … RETURNING` (`sp_enroll_student`), `UPDATE` (`sp_record_grade`, `sp_update_student_gpa`), `DELETE` (`sp_drop_enrollment`). `SQL%NOTFOUND` detects "no such enrollment"; `SQL%ROWCOUNT` reports affected rows.
* **Explicit, OPEN/FETCH/CLOSE:** `sp_class_report` – parameterised cursor, `%NOTFOUND`, and `%ISOPEN` check in the exception handler so the cursor is never leaked.
* **Explicit, cursor FOR loop:** `sp_department_summary` and `fn_calculate_gpa`.

## 5. Bulk processing and performance

**Problem with row-by-row code.** A `FOR` loop that runs an `INSERT`/`UPDATE` for every element switches between the PL/SQL engine and the SQL engine once *per row*. Each switch has a fixed cost, so 20,000 rows mean 20,000 context switches.

**Bulk solution.**

* `BULK COLLECT` fetches all rows into a collection in **one** switch (`sp_apply_bonus_marks`, `sp_update_all_gpas`).
* `FORALL` sends the whole collection to the SQL engine in **one** switch (`sp_bulk_grade_upload`, `sp_apply_bonus_marks`, `sp_update_all_gpas`, `sp_performance_demo`).
* The calculation between the two (bonus, grade, GPA) is done in memory in PL/SQL.

**Measuring it.** `sp_performance_demo(p_rows, …)` inserts the same rows row-by-row and then with `FORALL`, timing each with `DBMS_UTILITY.GET_TIME` (centiseconds).

| Rows | Row-by-row (cs) | FORALL (cs) | Speed-up |
|------|-----------------|-------------|----------|
| 20,000 | `<fill in from test S13>` | `<fill in from test S13>` | `<x times>` |

> Fill the table with the numbers printed by test S13 on your own database; they depend on the machine. FORALL is normally clearly faster, and the gap grows with the number of rows.

**Bulk error handling.**

* `FORALL … SAVE EXCEPTIONS` keeps going after a failing row and raises `ORA-24381` at the end. The handler reads `SQL%BULK_EXCEPTIONS` (`ERROR_INDEX`, `ERROR_CODE`).
* A statement that matches **no row** is *not* an error in Oracle, so `sp_bulk_grade_upload` also inspects `SQL%BULK_ROWCOUNT(i) = 0` to find unknown enrollment ids.
* The details are copied into local arrays **before** the autonomous logger runs, so no information is lost.
* `sp_bulk_grade_upload` is a "partial success" procedure: it returns the counts of updated/rejected rows and logs every rejected row. `sp_apply_bonus_marks` and `sp_update_all_gpas` raise `-20014` when any row fails.

**Other performance choices:** indexes on `enrollments(course_id, semester)` and `enrollments(student_id)` support the capacity check and GPA queries; `DETERMINISTIC` on the pure grade functions.

## 6. Exception-handling strategy

1. Every procedure and function has an exception section.
2. **Expected problems** (missing student, full course, …) are detected with `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`, `SQL%NOTFOUND`, or user-defined exceptions and turned into `RAISE_APPLICATION_ERROR` with a clear message.
3. **Business-rule errors pass through unchanged:** in `WHEN OTHERS`, `IF SQLCODE BETWEEN -20999 AND -20000 THEN RAISE;`.
4. **Unexpected errors are never swallowed:** they are written to `ERROR_LOG` by `sp_log_error` and re-raised as `-20099` including the original message.
5. Functions do not hide problems with fake values: no GPA of `0` for a student with no grades, no default grade for invalid marks – they raise.

### Error-code table

| Code | Meaning | Raised by |
|------|---------|-----------|
| -20001 | Student does not exist | `sp_enroll_student`, `fn_calculate_gpa` |
| -20002 | Student is not ACTIVE | `sp_enroll_student` |
| -20003 | Course does not exist | `sp_enroll_student`, `fn_available_seats`, `sp_apply_bonus_marks`, `sp_class_report` |
| -20004 | Course is full | `sp_enroll_student` |
| -20005 | Already enrolled (`DUP_VAL_ON_INDEX`) | `sp_enroll_student` |
| -20006 | Enrollment does not exist | `sp_record_grade`, `sp_drop_enrollment`, `sp_bulk_grade_upload` (logged) |
| -20007 | Enrollment already graded | `sp_drop_enrollment` |
| -20008 | Marks outside 0–100 | `sp_record_grade` |
| -20009 | Missing / invalid input | `sp_enroll_student`, `sp_bulk_grade_upload` |
| -20010 | Invalid marks | `fn_marks_to_grade` |
| -20011 | Unknown grade | `fn_grade_points` |
| -20012 | Bonus outside 1–20 | `sp_apply_bonus_marks` |
| -20013 | No graded enrollments to update | `sp_apply_bonus_marks` |
| -20014 | Some rows failed in a bulk update | `sp_apply_bonus_marks`, `sp_update_all_gpas` |
| -20015 | No enrollments for the report | `sp_class_report` |
| -20016 | Department does not exist | `sp_department_summary` |
| -20017 | Invalid row count | `sp_performance_demo` |
| -20020 | Student has no graded courses | `fn_calculate_gpa` |
| -20040 | Several students share a last name (`TOO_MANY_ROWS`) | `fn_find_student_by_last_name` |
| -20041 | No student with that last name (`NO_DATA_FOUND`) | `fn_find_student_by_last_name` |
| -20099 | Unexpected error (logged) | all procedures |

## 7. Test plan

* `test_success_cases.sql` – S1 … S13, one block per feature, using the sample data.
* `test_error_cases.sql` – E1 … E19; each block prints *expected code* next to the *actual* `SQLCODE`/`SQLERRM`. E7 and E12 also show the rows written to `ERROR_LOG`.
* Run the success file first, then the error file. Re-run `install_all.sql` to reset the data.
* Save one screenshot per test as `screenshots/<test_name>_output.png` (for example `S5_bulk_grade_upload_output.png`).

## 8. Limitations / possible extensions

* Single-semester sample data; no prerequisites or timetable clashes.
* GPA is recalculated on demand, not through a trigger.
* `BULK COLLECT … LIMIT` is not needed for this data size; for millions of rows, fetch in batches with `LIMIT`.
