Bad attributes generate an error message.

  $ bash ../test.sh <<'EOF'
  > [@@@coverage invalid]
  > EOF
  File "test.ml", line 1, characters 0-21:
  1 | [@@@coverage invalid]
      ^^^^^^^^^^^^^^^^^^^^^
  Error: Bad payload in coverage attribute.
