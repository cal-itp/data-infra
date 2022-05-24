"""
Super useful with https://www.convertjson.com/html-table-to-json.htm
"""
import json
import sys

from dbt_artifacts import Column

if __name__ == "__main__":
    model = sys.argv[1]
    fields = json.load(sys.stdin)

    with open(f"{model}.md", "w") as df, open(f"{model}.yml", "w") as pf:
        for field in fields:
            col = Column(
                name=field["Field Name"],
                description=field["Description"],
                meta={"metabase.semantic_type": f"type/{field['Type']}"},
            )
            prefix = f"gtfs_{model}__"
            df.write(col.docblock(prefix=prefix))

            doc_ref = f'{{{{ doc("{prefix}{col.name}") }}}}'

            extras = {
                "description": f"'{doc_ref}'",
            }
            if field["Required"] == "Required":
                extras["tests"] = ["not_null"]
            yml = col.yaml(
                include_description=False,
                extras=extras,
            )
            pf.write(yml)
