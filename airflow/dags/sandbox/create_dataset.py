from calitp import get_engine

engine = get_engine()

engine.execute("""CREATE SCHEMA IF NOT EXISTS sandbox""")
