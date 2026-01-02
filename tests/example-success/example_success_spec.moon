is_leap_year = require 'example_success'

describe 'leap', ->
  it 'a known leap year', ->
    assert.is_true is_leap_year 1996

  it 'any old year', ->
    assert.is_false is_leap_year 1997

  it 'turn of the 20th century', ->
    assert.is_false is_leap_year 1900

  it 'turn of the 21st century', ->
    assert.is_true is_leap_year 2400

  it 'handles tests with parens in strings', ->
    s = ')'
    assert.is_true true

  it "handles test names with 'apostrophes'", ->
    assert.is_true true

  it 'handles tests with multiple lines in the body', ->
    assert.is_false false

    assert.is_true true
