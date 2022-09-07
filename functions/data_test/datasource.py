import numpy as np
import pandas as pd
import os
import boto3
import awswrangler as wr
import re


def concat_source_list(engine, source, source_engine):
    final_source_files = []
    if engine == 's3':
        for sc in source:
            final_source_files.append('s3://' + source_engine + '/' + sc)
        return final_source_files
    elif engine == 'athena':
        return 2
    elif engine == 'redshift':
        return 3
    elif engine == 'hudi':
        return 4
    elif engine == 'postgresql':
        return 5
    elif engine == 'snowflake':
        return 6
    else:
        for sc in source:
            final_source_files.append('s3://' + source_engine + '/' + sc)
        return final_source_files


def get_file_extension(source):
    return source.split(".")[-1]


def read_source(source, engine, extension):
    if engine == 's3':
        if extension == 'csv':
            return wr.s3.read_csv(path=source)
        elif extension == 'parquet':
            return wr.s3.read_parquet(path=source)
    elif engine == 'athena':
        return 2
    elif engine == 'redshift':
        return 3
    elif engine == 'hudi':
        return 4
    elif engine == 'postgresql':
        return 5
    elif engine == 'snowflake':
        return 6
    else:
        return wr.s3.read_parquet(path=source)


def get_source_name(source, engine,extension):
    if engine == 's3':
        if extension == 'csv':
            return re.search('.*/(.+?)(\_(\d.*)|).csv', source).group(1)
        elif extension == 'parquet':
            return re.search('.*/(.+?)(\_(\d.*)|).parquet', source).group(1)
    elif engine == 'athena':
        return 2
    elif engine == 'redshift':
        return 3
    elif engine == 'hudi':
        return 4
    elif engine == 'postgresql':
        return 5
    elif engine == 'snowflake':
        return 6
    else:
        return re.search('.*/(.+?)(\_(\d.*)|).parquet', source).group(1)


def prepare_final_ds(source, engine, source_engine, source_name):
    source = concat_source_list(engine, source, source_engine)
    source_extension = get_file_extension(source[0])
    if source_name == '':
        source_name = get_source_name(source[0], engine, source_extension)
    df = read_source(source, engine, source_extension)

    return df, source_name
