import pyarrow.parquet as pq
import regex

p = regex.compile(r'\[(..)\]')
schema = pq.ParquetFile(path).schema_arrow
type = schema.field('delivery_duration').type
unit = p.findall(str(type))[0]
