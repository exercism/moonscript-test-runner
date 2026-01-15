is_leap_year = require 'example_all_fail'

describe 'leap', ->
  it 'a known leap year', ->
    assert.is_true is_leap_year 1996

  it 'any old year', ->
    assert.is_false is_leap_year 1997
