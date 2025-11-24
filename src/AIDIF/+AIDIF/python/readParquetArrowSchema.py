#   Author: Jan Wrede
#   Date: 2025-10-29
#   
#   This file is part of the larger AIDIF-toolbox project and is licensed 
#       under the MIT license. A copy of the MIT License can be found in 
#       the project's root directory.
#
#   Copyright (c) 2025, AIDIF
#   All rights reserved

import pyarrow.parquet as pq
import regex

p = regex.compile(r'\[(..)\]');
schema = pq.ParquetFile(path).schema_arrow;
