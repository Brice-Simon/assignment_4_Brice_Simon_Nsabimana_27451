# Implementation & Performance Notes

**Project:** AUCA Student Registration & Grading Engine
**Author:** NSABIMANA Simon Brice (27451)

---

## 1. Architecture at a glance

This is a registration and grading system (see `README.md`). The business rules sit in the database as stored subprograms, and the test scripts do nothing except call them.

**Functions** are small, contain no DML, and can therefore be called from plain SQL:
`fn_marks_to_grade`, `fn_grade_points`, `fn_calculate_gpa`, `fn_available_seats`, `fn_find_student_by_last_name`.

**Procedures** carry out the actual operations: enrolling, grading, dropping, bulk upload, bonus marks, GPA refresh, reporting, error logging and the performance demo.

**Transaction policy:** no procedure issues a `COMMIT`; the caller owns the transaction. Two exceptions exist, `sp_log_error` and `sp_performance_demo`. Both run under `PRAGMA AUTONOMOUS_TRANSACTION`, so their commits never touch the caller's uncommitted work.

---

## 2. Record types

| Kind | Where it is used |
|------|------------------|
| `%ROWTYPE` | `l_student students%ROWTYPE` in `sp_enroll_student` holds a complete student row. `l_enrollment enrollments%ROWTYPE` does the same job in `sp_drop_enrollment`. |
| User-defined | `t_enroll_summary` (student name, course code, seats left) in `sp_enroll_student`. `t_roster_rec` receives every `FETCH` in `sp_class_report`. |

---

## 3. Collection types

| Collection | Location | Purpose |
|------------|----------|---------|
| Nested table (SQL type `t_number_tab`) | Parameters of `sp_bulk_grade_upload` | Allows the caller to pass a list of enrollment ids and a list of marks |
| Nested tables (local) | `sp_apply_bonus_marks`, `sp_update_all_gpas` | Receive `BULK COLLECT` results; grown with `EXTEND` |
| Associative array, `PLS_INTEGER` index | `sp_bulk_grade_upload`, `sp_update_all_gpas`, `sp_performance_demo` | Stores each computed value at the same subscript as its source row |
| Associative array, `VARCHAR2` index | `sp_class_report` | Maps grade to student count (uses `EXISTS`, `FIRST`, `NEXT`) |

---

## 4. Cursor usage

**Implicit cursors**
- `INSERT ... RETURNING` in `sp_enroll_student`
- `UPDATE` in `sp_record_grade` and `sp_update_student_gpa`
- `DELETE` in `sp_drop_enrollment`

`SQL%NOTFOUND` detects a missing enrollment, and `SQL%ROWCOUNT` reports how many rows were affected.

**Explicit cursors, manual control**
`sp_class_report` uses a parameterised cursor with `OPEN`/`FETCH`/`CLOSE` and `%NOTFOUND`. Its exception handler tests `%ISOPEN` first, so the cursor is never left open after an error.

**Explicit cursors, FOR loop**
`sp_department_summary` and `fn_calculate_gpa`.

---

## 5. Bulk processing and performance

### Why row-by-row is slow
When a PL/SQL loop runs one `INSERT` or `UPDATE` per element, control passes between the PL/SQL engine and the SQL engine on every iteration. Each hand-over has a fixed cost, so 20,000 rows cost 20,000 context switches.

### The bulk alternative
- **`BULK COLLECT`** reads all the rows into a collection in a single switch (`sp_apply_bonus_marks`, `sp_update_all_gpas`).
- **`FORALL`** sends the entire collection back to SQL in a single switch (`sp_bulk_grade_upload`, `sp_apply_bonus_marks`, `sp_update_all_gpas`, `sp_performance_demo`).
- Between the two steps, the calculations (bonus, grade, GPA) happen in PL/SQL memory.

### Measurement
`sp_performance_demo(p_rows, ...)` inserts the same number of rows twice, once in a loop and once with `FORALL`, and times each run with `DBMS_UTILITY.GET_TIME` (centiseconds).

| Rows | Loop (cs) | FORALL (cs) | Speed-up |
|------|-----------|-------------|----------|
| 20,000 | `<copy from test S13>` | `<copy from test S13>` | `<x times>` |

These figures depend on your machine, so fill them in from the output of test S13 on your own database. `FORALL` is usually much faster, and the gap widens as the row count grows.

### Handling failures in bulk
- `FORALL ... SAVE EXCEPTIONS` continues past a failing row and raises `ORA-24381` once it finishes. The handler then reads `SQL%BULK_EXCEPTIONS` (`ERROR_INDEX`, `ERROR_CODE`).
- Oracle does not treat "no row matched" as an error. For that reason `sp_bulk_grade_upload` also checks `SQL%BULK_ROWCOUNT(i) = 0` to spot unknown enrollment ids.
- Error details are copied into local arrays before the autonomous logger is called, so nothing is lost.
- **Partial-success behaviour:** `sp_bulk_grade_upload` returns the number of rows updated and rejected, and logs each rejected row. In contrast, `sp_apply_bonus_marks` and `sp_update_all_gpas` raise `-20014` if any row fails.

### Other performance decisions
- Indexes on `enrollments(course_id, semester)` and `enrollments(student_id)` speed up the capacity check and the GPA queries.
- The pure grade functions are declared `DETERMINISTIC`.

---

## 6. Exception-handling strategy

1. Every procedure and function has its own exception section.
2. Predictable problems (unknown student, full course and so on) are caught through `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`, `SQL%NOTFOUND` or user-defined exceptions, then converted to `RAISE_APPLICATION_ERROR` with a readable message.
3. Business-rule errors travel upward unchanged. In each `WHEN OTHERS` block, the first statement is `IF SQLCODE BETWEEN -20999 AND -20000 THEN RAISE;`.
4. Unexpected errors are never hidden. They are saved to `ERROR_LOG` by `sp_log_error` and re-raised as `-20099` with the original message attached.
5. Functions never return placeholder values: there is no GPA of 0 for a student without grades and no default grade for invalid marks. They raise an error instead.

### Error codes

| Code | Meaning | Raised in |
|------|---------|-----------|
| -20001 | Student not found | `sp_enroll_student`, `fn_calculate_gpa` |
| -20002 | Student status is not ACTIVE | `sp_enroll_student` |
| -20003 | Course not found | `sp_enroll_student`, `fn_available_seats`, `sp_apply_bonus_marks`, `sp_class_report` |
| -20004 | Course has no free seats | `sp_enroll_student` |
| -20005 | Duplicate enrollment (`DUP_VAL_ON_INDEX`) | `sp_enroll_student` |
| -20006 | Enrollment not found | `sp_record_grade`, `sp_drop_enrollment`, `sp_bulk_grade_upload` (logged) |
| -20007 | Enrollment already has a grade | `sp_drop_enrollment` |
| -20008 | Marks outside the 0–100 range | `sp_record_grade` |
| -20009 | Missing or invalid input | `sp_enroll_student`, `sp_bulk_grade_upload` |
| -20010 | Invalid marks value | `fn_marks_to_grade` |
| -20011 | Unrecognised grade | `fn_grade_points` |
| -20012 | Bonus outside the 1–20 range | `sp_apply_bonus_marks` |
| -20013 | No graded enrollments available to update | `sp_apply_bonus_marks` |
| -20014 | One or more rows failed in a bulk update | `sp_apply_bonus_marks`, `sp_update_all_gpas` |
| -20015 | Nothing to report for this class | `sp_class_report` |
| -20016 | Department not found | `sp_department_summary` |
| -20017 | Invalid row count requested | `sp_performance_demo` |
| -20020 | Student has no graded courses | `fn_calculate_gpa` |
| -20040 | Several students share the last name (`TOO_MANY_ROWS`) | `fn_find_student_by_last_name` |
| -20041 | No student has that last name (`NO_DATA_FOUND`) | `fn_find_student_by_last_name` |
| -20099 | Unexpected error (logged first) | All procedures |

---

## 7. Test plan

- `test_success_cases.sql` contains blocks **S1 to S13**, one per feature, all running on the sample data.
- `test_error_cases.sql` contains blocks **E1 to E19**. Each prints the expected error code beside the actual `SQLCODE` and `SQLERRM`. E7 and E12 also display the rows written to `ERROR_LOG`.
- Run the success file first and the error file second. Re-run `install_all.sql` whenever you want to restore the original data.
- Save one screenshot per test as `screenshots/<test_name>_output.png`, for example `S5_bulk_grade_upload_output.png`.

---

## 8. Known limitations and future work

- The sample data covers one semester only, and there are no prerequisites or timetable-clash checks.
- GPA is recalculated when requested rather than maintained by a trigger.
- `BULK COLLECT ... LIMIT` is unnecessary at this data size. For millions of rows, fetch in batches with `LIMIT` to protect memory.
