import test_func from require 'duplicated_test_names'

describe 'top level:', ->

  describe 'section 1:', ->
    it 'test name', ->
      assert.are.equal 1, test_func 1

  describe 'section 2:', ->
    it 'test name', ->
      assert.are.equal 2, test_func 2

    describe 'subsection 1:', ->
      it 'test name', ->
        assert.are.equal 21, test_func 21

  describe 'section 3:', ->
    it 'test name', ->
      assert.are.equal 3, test_func 33
