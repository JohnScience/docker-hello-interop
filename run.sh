# This script just runs all code examples and appends the corresponding
# output with a "\t(from *)" using `sed` (stream editor).

./from_rust/target/release/from_rust | sed 'a\\t(from Rust)'
./from_c/hello_from_c | sed 'a\\t(from C)'