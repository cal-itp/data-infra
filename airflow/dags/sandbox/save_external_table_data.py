# ---
# ---

from calitp import save_to_gcfs

import pandas as pd

df = pd.DataFrame({"g": ["a", "b"], "x": [1, 2]})

save_to_gcfs(
    df.to_csv(index=False).encode(), "sandbox/external_table.csv", use_pipe=True
)
