is_leap_year = require 'example_empty_file'

describe 'leap', ->
  it 'a known leap year', ->
    assert.is_true is_leap_year 1996

  it 'any old year', ->
    assert.is_false is_leap_year 1997

  it 'turn of the 20th century', ->
    assert.is_false is_leap_year 1900

  it 'turn of the 21st century', ->
    assert.is_true is_leap_year 2400
