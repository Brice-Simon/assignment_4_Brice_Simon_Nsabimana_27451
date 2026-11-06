-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- Procedure: sp_log_error
-- Purpose  : Write an unexpected error into ERROR_LOG.
-- Concepts : PRAGMA AUTONOMOUS_TRANSACTION - the log row is committed on its
--            own, so it survives even if the caller rolls back.
-- Note     : If logging itself fails, the problem is printed but NOT raised,
--            so it can never hide the original error the caller re-raises.
-- =====================================================================
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
