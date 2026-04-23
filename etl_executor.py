import time
from datetime import datetime

import pyodbc

# =========================
# CONFIGURATION
# =========================
SERVER = r"localhost\SQLEXPRESS"
DATABASE = "AviationSafetyDWH"
DRIVER = "ODBC Driver 17 for SQL Server"

# Optional: use SQL auth instead of Trusted Connection
USERNAME = None
PASSWORD = None

PIPELINE_NAME = "Aviation ETL Pipeline"


# =========================
# CONNECTION
# =========================
def get_connection():
    """Create and return a SQL Server connection."""
    if USERNAME and PASSWORD:
        conn_str = (
            f"DRIVER={{{DRIVER}}};"
            f"SERVER={SERVER};"
            f"DATABASE={DATABASE};"
            f"UID={USERNAME};"
            f"PWD={PASSWORD};"
            "TrustServerCertificate=yes;"
        )
    else:
        conn_str = (
            f"DRIVER={{{DRIVER}}};"
            f"SERVER={SERVER};"
            f"DATABASE={DATABASE};"
            "Trusted_Connection=yes;"
            "TrustServerCertificate=yes;"
        )

    # Use explicit transactions for predictable procedure execution
    return pyodbc.connect(conn_str, autocommit=False)


# =========================
# UTILITY HELPERS
# =========================
def drain_results(cursor):
    """
    Consume all pending result sets/messages from a stored procedure execution.
    This is important when procedures emit rowcount messages or PRINT output.
    """
    try:
        while cursor.nextset():
            pass
    except pyodbc.Error:
        # Some executions may not expose additional sets cleanly; ignore safely
        pass


def print_banner(title):
    print("\n" + "=" * 60)
    print(title)
    print("=" * 60)


def get_table_count(cursor, table_name):
    """Return row count for a table."""
    cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
    return cursor.fetchone()[0]


def print_count(cursor, label, table_name):
    """Print row count for a table."""
    count = get_table_count(cursor, table_name)
    print(f"{label}: {count}")
    return count


def print_sample(cursor, table_name, top_n=3):
    """Optional helper to show a quick sample from a table."""
    cursor.execute(f"SELECT TOP ({top_n}) * FROM {table_name};")
    rows = cursor.fetchall()

    if not rows:
        print(f"{table_name}: no sample rows returned")
        return

    print(f"{table_name}: sample rows returned = {len(rows)}")


def safe_truncate_error(message, max_len=4000):
    """
    Truncate long error messages before sending to SQL logging procedures.
    Keeps logging safe if a procedure parameter has practical size limits.
    """
    if message is None:
        return None
    message = str(message)
    return message[:max_len]


# =========================
# ETL LOGGING HELPERS
# =========================
def start_run(cursor, pipeline_name):
    """Call etl.usp_StartRun and return RunId."""
    run_id = None

    cursor.execute(
        """
        DECLARE @RunId INT;
        EXEC etl.usp_StartRun
            @PipelineName = ?,
            @RunId = @RunId OUTPUT;
        SELECT @RunId AS RunId;
        """,
        pipeline_name,
    )

    row = cursor.fetchone()
    if row:
        run_id = int(row[0])

    drain_results(cursor)

    if run_id is None:
        raise RuntimeError("Failed to retrieve RunId from etl.usp_StartRun.")

    return run_id


def end_run(cursor, run_id, run_status, error_message=None):
    """Call etl.usp_EndRun."""
    cursor.execute(
        """
        EXEC etl.usp_EndRun
            @RunId = ?,
            @RunStatus = ?,
            @ErrorMessage = ?;
        """,
        run_id,
        run_status,
        safe_truncate_error(error_message),
    )
    drain_results(cursor)


def start_step(cursor, run_id, step_name, procedure_name, target_schema=None):
    """Call etl.usp_StartStep and return StepLogId."""
    step_log_id = None

    cursor.execute(
        """
        DECLARE @StepLogId INT;
        EXEC etl.usp_StartStep
            @RunId = ?,
            @StepName = ?,
            @ProcedureName = ?,
            @TargetSchema = ?,
            @StepLogId = @StepLogId OUTPUT;
        SELECT @StepLogId AS StepLogId;
        """,
        run_id,
        step_name,
        procedure_name,
        target_schema,
    )

    row = cursor.fetchone()
    if row:
        step_log_id = int(row[0])

    drain_results(cursor)

    if step_log_id is None:
        raise RuntimeError("Failed to retrieve StepLogId from etl.usp_StartStep.")

    return step_log_id


def end_step(
    cursor,
    step_log_id,
    step_status,
    rows_inserted=None,
    rows_updated=None,
    rows_deleted=None,
    error_message=None,
):
    """Call etl.usp_EndStep."""
    cursor.execute(
        """
        EXEC etl.usp_EndStep
            @StepLogId = ?,
            @StepStatus = ?,
            @RowsInserted = ?,
            @RowsUpdated = ?,
            @RowsDeleted = ?,
            @ErrorMessage = ?;
        """,
        step_log_id,
        step_status,
        rows_inserted,
        rows_updated,
        rows_deleted,
        safe_truncate_error(error_message),
    )
    drain_results(cursor)


def log_table_count(cursor, step_log_id, table_name, row_count_value):
    """Call etl.usp_LogTableCount."""
    cursor.execute(
        """
        EXEC etl.usp_LogTableCount
            @StepLogId = ?,
            @TableName = ?,
            @RowCountValue = ?;
        """,
        step_log_id,
        table_name,
        row_count_value,
    )
    drain_results(cursor)


# =========================
# EXECUTE STORED PROCEDURE
# =========================
def run_procedure(cursor, proc_name):
    """Execute a stored procedure and fully consume its results."""
    print_banner(f"Running: {proc_name}")
    print(f"Start Time: {datetime.now()}")

    start = time.time()

    try:
        cursor.execute(f"EXEC {proc_name};")

        # Important: consume all pending result sets/messages
        drain_results(cursor)

        duration = round(time.time() - start, 2)
        print(f"Completed: {proc_name}")
        print(f"Duration: {duration} seconds")
        return duration

    except Exception as exc:
        print(f"ERROR running {proc_name}")
        print(str(exc))
        raise


# =========================
# PIPELINE STEP
# =========================
def run_step(conn, cursor, run_id, step_name, proc_name, target_schema, count_tables):
    """
    Run one ETL step, commit it, log counts, and update step status.
    Rolls back only the ETL transaction if something fails.

    Important:
    - the step 'Running' log is committed before procedure execution
    - if ETL fails and rollback occurs, we then write the failed log in a new transaction
    """
    step_log_id = None
    proc_start = None

    try:
        # Log step start in its own committed transaction
        step_log_id = start_step(cursor, run_id, step_name, proc_name, target_schema)
        conn.commit()

        proc_start = time.time()

        # Run ETL procedure
        run_procedure(cursor, proc_name)

        # Commit ETL changes first
        conn.commit()

        # Log validation counts after successful ETL commit
        for label, table_name in count_tables:
            count = print_count(cursor, label, table_name)
            log_table_count(cursor, step_log_id, table_name, count)

        # Mark step success
        duration = round(time.time() - proc_start, 2)
        end_step(
            cursor,
            step_log_id,
            "Succeeded",
            rows_inserted=None,
            rows_updated=None,
            rows_deleted=None,
            error_message=None,
        )
        conn.commit()

        print(f"Step '{step_name}' logged as Succeeded.")

    except Exception as exc:
        error_text = str(exc)
        duration = round(time.time() - proc_start, 2) if proc_start else None

        # Roll back ETL work from current transaction
        try:
            conn.rollback()
        except Exception:
            pass

        # Log failure in a fresh transaction so the log survives rollback
        try:
            if step_log_id is not None:
                end_step(
                    cursor,
                    step_log_id,
                    "Failed",
                    rows_inserted=None,
                    rows_updated=None,
                    rows_deleted=None,
                    error_message=error_text,
                )
                conn.commit()
                print(f"Step '{step_name}' logged as Failed.")
        except Exception as log_exc:
            try:
                conn.rollback()
            except Exception:
                pass
            print(f"WARNING: Failed to write step failure log for {step_name}: {log_exc}")

        raise


# =========================
# MAIN PIPELINE
# =========================
def main():
    print_banner("Starting Aviation ETL Pipeline")

    conn = None
    cursor = None
    run_id = None

    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT @@SERVERNAME, DB_NAME(), SUSER_SNAME();")
        row = cursor.fetchone()

        print("Connected to server:", row[0])
        print("Connected to database:", row[1])
        print("Login:", row[2])

        # Start pipeline run log and commit it immediately
        run_id = start_run(cursor, PIPELINE_NAME)
        conn.commit()

        print(f"RunId: {run_id}")

        pipeline_start = time.time()

        # Bronze
        run_step(
            conn=conn,
            cursor=cursor,
            run_id=run_id,
            step_name="Bronze",
            proc_name="bronze.LoadBronze",
            target_schema="bronze",
            count_tables=[
                ("bronze.ref_operator", "bronze.ref_operator"),
                ("bronze.ref_airport", "bronze.ref_airport"),
                ("bronze.ref_aircraft", "bronze.ref_aircraft"),
                ("bronze.incident_reports", "bronze.incident_reports"),
            ],
        )

        # Silver
        run_step(
            conn=conn,
            cursor=cursor,
            run_id=run_id,
            step_name="Silver",
            proc_name="silver.LoadSilver",
            target_schema="silver",
            count_tables=[
                ("silver.RefOperator", "silver.RefOperator"),
                ("silver.RefAirport", "silver.RefAirport"),
                ("silver.RefAircraft", "silver.RefAircraft"),
                ("silver.IncidentReports", "silver.IncidentReports"),
            ],
        )

        # Platinum
        run_step(
            conn=conn,
            cursor=cursor,
            run_id=run_id,
            step_name="Platinum",
            proc_name="platinum.LoadPlatinum",
            target_schema="platinum",
            count_tables=[
                ("platinum.FactIncidents", "platinum.FactIncidents"),
                ("platinum.DimInvestigationStatus", "platinum.DimInvestigationStatus"),
                ("platinum.DimReportedBy", "platinum.DimReportedBy"),
                ("platinum.DimWeatherCondition", "platinum.DimWeatherCondition"),
                ("platinum.DimAircraftDamageLevel", "platinum.DimAircraftDamageLevel"),
                ("platinum.DimPhaseOfFlight", "platinum.DimPhaseOfFlight"),
                ("platinum.DimSeverity", "platinum.DimSeverity"),
                ("platinum.DimEventType", "platinum.DimEventType"),
                ("platinum.DimAircraft", "platinum.DimAircraft"),
                ("platinum.DimOperator", "platinum.DimOperator"),
                ("platinum.DimAirport", "platinum.DimAirport"),
                ("platinum.DimDate", "platinum.DimDate"),
            ],
        )

        total_time = round(time.time() - pipeline_start, 2)

        # Mark run success
        end_run(cursor, run_id, "Succeeded", None)
        conn.commit()

        print("\n" + "=" * 60)
        print("ETL PIPELINE COMPLETED SUCCESSFULLY")
        print(f"RunId: {run_id}")
        print(f"Total Duration: {total_time} seconds")
        print("=" * 60)

    except Exception as exc:
        error_text = str(exc)

        # Attempt to log pipeline failure in a fresh transaction
        if conn is not None and cursor is not None and run_id is not None:
            try:
                conn.rollback()
            except Exception:
                pass

            try:
                end_run(cursor, run_id, "Failed", error_text)
                conn.commit()
            except Exception as log_exc:
                try:
                    conn.rollback()
                except Exception:
                    pass
                print(f"WARNING: Failed to write run failure log: {log_exc}")

        print("\n" + "=" * 60)
        print("ETL PIPELINE FAILED")
        if run_id is not None:
            print(f"RunId: {run_id}")
        print(error_text)
        print("=" * 60)

    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


# =========================
# ENTRY POINT
# =========================
if __name__ == "__main__":
    main()