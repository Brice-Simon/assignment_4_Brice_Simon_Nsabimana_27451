
CREATE OR REPLACE PROCEDURE sp_log_error (
  p_source  IN VARCHAR2,
  p_code    IN NUMBER,
  p_message IN VARCHAR2
)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO error_log (log_id, source_name, error_code, error_message)
  VALUES (seq_error_log.NEXTVAL, SUBSTR(p_source, 1, 60), p_code, SUBSTR(p_message, 1, 4000));
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('sp_log_error could not write to ERROR_LOG: ' || SQLERRM);
END sp_log_error;
/
SHOW ERRORS
