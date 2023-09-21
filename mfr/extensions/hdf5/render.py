import json
import os

import h5py
import furl
from mako.lookup import TemplateLookup

from mfr.core import extension
from mfr.extensions.utils import escape_url_for_template

def serialize_dataset(key, entity, data=False):
    e = {
        'key': key,
        'type': 'Dataset' if isinstance(entity, h5py.Dataset) else ('Group' if isinstance(entity, h5py.Group) else None),
        'attributes': dict(list(entity.attrs.items())),
    }
    if isinstance(entity, h5py.Dataset):
        v = {
            'shape': list(entity.value.shape),
        }
        if data:
            v['data'] = _to_json_serializable_list(entity.value, len(entity.value.shape))
        e['value'] = v
    return e

def _to_json_serializable_list(values, nested):
    if nested == 1:
        return [_to_json_serializable_value(e) for e in values]
    return [_to_json_serializable_list(e, nested - 1) for e in values]

def _to_json_serializable_value(value):
    if isinstance(value, str):
        return value
    if isinstance(value, bytes):
        return value.decode('utf8')
    return float(value)

def _enumerate_datasets(entity):
    r = []
    for k, v in entity.items():
        e = serialize_dataset(k, v)
        if isinstance(v, h5py.Group):
            e['children'] = _enumerate_datasets(v)
        r.append(e)
    return r

class HDF5Renderer(extension.BaseRenderer):

    TEMPLATE = TemplateLookup(
        directories=[
            os.path.join(os.path.dirname(__file__), 'templates')
        ]).get_template('viewer.mako')

    def render(self):
        self.metrics.add('needs_export', True)
        exported_url = furl.furl(self.export_url)
        exported_url.args['format'] = 'json'

        with h5py.File(self.file_path, 'r') as workbook:
            datasets = _enumerate_datasets(workbook)

        safe_url = escape_url_for_template(exported_url.url)
        return self.TEMPLATE.render(
            base=self.assets_url,
            exported_url=safe_url,
            datasets=json.dumps(datasets),
        )

    @property
    def file_required(self):
        return True

    @property
    def cache_result(self):
        return True
