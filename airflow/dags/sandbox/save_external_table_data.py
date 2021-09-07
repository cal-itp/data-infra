# ---
# ---

from calitp import save_to_gcfs

import pandas as pd

df1 = pd.DataFrame(
    {
        "calitp_itp_id": [1, 1],
        "calitp_url_number": [0, 0],
        "x": [1, 2],
        "calitp_extracted_at": "2021-01-01",
    }
)

# second entry removed
df2 = pd.DataFrame(
    {
        "calitp_itp_id": [1],
        "calitp_url_number": [0],
        "x": [1],
        "calitp_extracted_at": "2021-01-02",
    }
)


# new first entry, second entry returns
df3 = pd.DataFrame(
    {
        "calitp_itp_id": [1, 1],
        "calitp_url_number": [0, 0],
        "x": [99, 2],
        "calitp_extracted_at": "2021-01-03",
    }
)

for ii, df in enumerate([df1, df2, df3]):
    save_to_gcfs(
        df.to_csv(index=False).encode(),
        f"sandbox/external_table_{ii + 1}.csv",
        use_pipe=True,
    )
