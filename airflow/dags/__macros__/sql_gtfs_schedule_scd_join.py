def scd_join(
    tbl_a,
    tbl_b,
    join_type=None,
    created_col="calitp_extracted_at",
    deleted_col="calitp_deleted_at",
    using_cols=None,
    sel_left_cols=None,
    sel_right_cols=None,
):

    if join_type is None:
        join_type = "JOIN"

    if using_cols is None:
        raise NotImplementedError(
            "Must specify using_cols in scd_join."
            " E.g. ('calitp_itp_id', 'calitp_url_number', 'route_id')"
        )

    str_using_cols = ", ".join(using_cols)

    if sel_left_cols is None:
        str_sel_left_cols = f"T1.* EXCEPT({created_col}, {deleted_col})"
    else:
        str_sel_left_cols = ", ".join(sel_left_cols)

    if sel_right_cols is None:
        str_sel_right_cols = f"T2.* EXCEPT({created_col}, {deleted_col})"
    else:
        str_sel_right_cols = ", ".join(sel_right_cols)

    return f"""
        -- SLOWLY CHANGING DIMENSION JOIN

        SELECT
            {str_sel_left_cols}
            , {str_sel_right_cols}
            , GREATEST(T1.{created_col}, T2.{created_col}) AS {created_col}
            , LEAST(T1.{deleted_col}, T2.{deleted_col}) AS {deleted_col}
        FROM {tbl_a} T1
        {join_type} {tbl_b} T2
            USING ({str_using_cols})
        WHERE
            T1.{created_col} < T2.{deleted_col}
            AND T2.{created_col} < T1.{deleted_col}
"""
