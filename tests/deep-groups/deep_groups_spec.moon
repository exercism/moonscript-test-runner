-- no requires

describe 'root:', ->
  describe 'first child:', ->
    it 'test1', ->
      true
  it 'root-level test', ->
    true
  describe 'second child:', ->
    describe 'grandchild 1:', ->
      it 'first granchild test', ->
        true
    it 'second child test', ->
      true
    describe 'grandchild 2:', ->
      it 'second grandchild test', ->
  it 'another root-level test', ->
    true
