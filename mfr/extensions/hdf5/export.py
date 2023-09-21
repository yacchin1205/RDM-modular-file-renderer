import json
from urllib import parse

import h5py

from mfr.core import extension
from .render import serialize_dataset


class HDF5Exporter(extension.BaseExporter):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def export(self):
        format, path = self.format.split('.', 1)
        assert format == 'json', (format, path)
        path = parse.unquote(path)
        with h5py.File(self.source_file_path, 'r') as workbook:
            dataset = serialize_dataset(path, workbook[path], data=True)
        with open(self.output_file_path, 'w') as f:
            f.write(json.dumps(dataset))