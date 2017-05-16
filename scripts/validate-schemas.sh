#!/usr/bin/env python2
# -*- coding: utf-8 -*-

# Validate JSON schemas using python2's jsonschema tool

from __future__ import print_function
import json
import jsonschema
import os
import sys
from jsonschema.validators import validator_for


class MissingKeyError(Exception):
    """One of these keys is missing from the JSON: 'default', 'type'"""
def is_root(keys):
    return '$schema' in keys and '_id' in keys
def is_a_special_key(key):
    return key in ['default_caller_id_number']

def check_defaults(json_file, current_key, JSON):
    keys = JSON.keys()
    if 'description' in keys \
       and ('default' not in keys or 'type' not in keys) \
       and not is_root(keys) \
       and not is_a_special_key(current_key):
        print(json_file)
        print(MissingKeyError.__doc__)
        print('at:', current_key)
        for key in keys:
            print('\t', key, ':', JSON[key])
        # raise MissingKeyError
    for key in keys:
        value = JSON[key]
        if isinstance(value, dict):
            check_defaults(json_file, key, value)

def validate(json_file):
    with open(json_file) as fd:
        JSON = json.load(fd)
    check_defaults(json_file, '', JSON)
    try:
        validator = validator_for(JSON)
        validator.check_schema(JSON)
    except jsonschema.exceptions.SchemaError as e:
        print('Bad schema:', json_file)
        with open(json_file, 'r') as fd:
            print(fd.read())
        print(e)
        print()
        print('Run again with:')
        print(sys.argv[0], json_file)
        sys.exit(2)

for arg in sys.argv[1:]:
    if os.path.isdir(arg):
        for filename in os.listdir(arg):
            json_file = os.path.join(arg, filename)
            validate(json_file)
    elif os.path.exists(arg):
        validate(arg)
    else:
        print('Skipping', arg)
