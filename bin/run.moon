#! /usr/bin/env moon

-- Implements test-runner interface version 2

require 'moonscript'
lfs = require 'lfs'
json = (require 'dkjson').use_lpeg!
getopt = require 'alt_getopt'
local verbose

-- import p from require 'moon'


-- -----------------------------------------------------------
show_help = (args) ->
  print "Usage: #{args[0]} [-h] [-v]  slug  solution-dir  output-dir"
  print "Where: -h   show this help"
  print "       -v   verbose: show the output JSON"
  os.exit!


-- -----------------------------------------------------------
file_exists = (path) ->
  attrs = lfs.attributes path
  not not attrs

is_directory = (path) ->
  attrs = lfs.attributes path
  attrs and attrs.mode == 'directory'

realpath = (path) ->
  fh = io.popen "realpath #{path}"
  dir = fh\read!
  fh\close!
  dir

validate = (args) ->
  show_help args unless #args == 3
  {slug, src_dir, dest_dir} = args
  assert slug != '', 'First arg, the slug, cannot be empty'
  assert is_directory(src_dir), 'Second arg, the solution directory, must be a directory'
  assert is_directory(dest_dir), 'Third arg, the output directory, must be a directory'

  slug, realpath(src_dir), realpath(dest_dir)


-- -----------------------------------------------------------
run_tests = (slug, dir) ->
  ok, err = lfs.chdir dir
  assert ok, "run_tests: cannot change to directory #{dir}: #{err}"

  -- unskip tests
  cmd = "perl -i.bak -pe 's{^\\s*\\Kpending\\b}{it}' *_spec.moon"
  ok, result_type, status = os.execute cmd
  assert ok, "run_tests: failed to unskip tests with command #{cmd}: #{result_type} #{status}"

  -- launch `busted`
  fh = io.popen 'busted -o json', 'r'
  json_output = fh\read 'a'
  ok, exit_type, exit_status = fh\close!

  if exit_type == 'signal'
    return {
      status: 'error',
      message: json_output
    }

  data = json.decode json_output
  -- p data

  if not data
    output = json_output

    if output\match "^Failed to encode test results to json"
      -- This is a syntax error: moon can't compile it.
      -- Busted cannot output JSON results.
      -- Grab the output from vanilla busted.
      fh = io.popen 'busted', 'r'
      output = fh\read 'a'
      fh\close!
      -- trim off some non-determinant output
      output = output\gsub " : [%d.]+ seconds", ""
      output = output\gsub "(%s)/[%w./-]-/(base.lua)", "%1%2"

    return {
      status: 'error',
      message: output
    }


  if exit_status != 0 and #data.successes == 0 and #data.failures == 0 and #data.errors > 0
    return {
      status: 'error',
      message: data.errors[1].message
    }

  results = {}

  for test in *data.successes
    results[test.name] = {
      status: 'pass',
      name: test.name,
    }

  for test in *data.failures
    results[test.name] = {
      status: 'fail',
      name: test.name,
      message: test.trace.message,
    }

  for test in *data.errors
    results[test.name] = {
      status: 'error',
      name: test.name,
      message: test.trace.message,
    }
  
  -- p results
  results


-- -----------------------------------------------------------
get_test_bodies = (slug, dir) ->
  ok, err = lfs.chdir dir
  assert ok, "get_test_bodies: cannot change to directory #{dir}: #{err}"

  order = {}
  bodies = {}

  test_file = "#{slug\gsub('-', '_')}_spec.moon"
  return unless file_exists test_file -- let `busted` handle the error messaging

  fh = io.open test_file, 'r'

  pattern = (word) -> '^(%s+)' .. word .. '%s+[\'"](.+)[\'"],%s+->'
  patterns = it: pattern('it'), pending: pattern('pending')

  local test_name
  test_body = {}
  in_test = false
  sections = {}

  for line in fh\lines!
    -- do not look for any tests after this line, they won't run in test environment
    break if line\match '-- The next tests are optional.'

    indent, section_name = line\match '^(%s*)describe%s+[\'"](.+)[\'"],%s+->'
    if section_name
      if test_name
        bodies[test_name] = table.concat test_body, '\n'
        test_body = {}
        test_name = nil

      group_indent_level = #indent // 2 + 1
      sections = {table.unpack sections, 1, group_indent_level}  -- discard any deeper indents
      sections[group_indent_level] = section_name
      in_test = false

    indent, name = line\match(patterns.it)
    if not indent
      indent, name = line\match(patterns.pending)
    -- p {:line, :indent, :name}
    if not name
      if in_test
        table.insert test_body, line
    else
      if in_test
        bodies[test_name] = table.concat test_body, '\n'
        test_body = {}

      group_indent_level = #indent // 2 -- note this is one less than the "describe" group level
      -- p {:group_indent_level, :name, :sections}
      sections = {table.unpack sections, 1, group_indent_level}  -- discard any deeper indents
      test_name = table.concat(sections, ' ') .. ' ' .. name
      table.insert order, test_name
      in_test = true

  fh\close!
  if test_name
    bodies[test_name] = table.concat test_body, '\n'
  -- p {:order, :bodies}
  order, bodies


-- -----------------------------------------------------------
write_results = (slug, test_results, names, bodies, dir) ->
  ok, err = lfs.chdir dir
  assert ok, "write_results: cannot change to directory #{dir}: #{err}"
  
  results = version: 2, status: nil, tests: {}

  if test_results.status
    -- this was an error result
    results.status = test_results.status
    results.message = test_results.message

  else
    status = 'pass'
    for name in *names
      test = test_results[name]
      if not test
        status = 'error'
        results.message = "missing test result for «#{name}»"
        break

      status = 'fail' if test.status != 'pass'
      test.test_code = bodies[name]
      table.insert results.tests, test
    results.status = status

  fh = io.open 'results.json', 'w'
  fh\write (json.encode results) .. '\n'
  fh\close!

  os.execute "jq . results.json" if verbose


-- -----------------------------------------------------------
main = (args) ->
  opts, optind = getopt.get_opts args, 'hv', {}

  show_help args if opts.h
  verbose = not not opts.v
  table.remove args, 1 for _ = 1, optind - 1

  slug, src_dir, dest_dir = validate args

  print "#{slug}: testing ..."

  test_names_ordered, test_code = get_test_bodies slug, src_dir

  test_results = run_tests slug, src_dir

  write_results slug, test_results, test_names_ordered, test_code, dest_dir

  print "#{slug}: ... done"

main arg
