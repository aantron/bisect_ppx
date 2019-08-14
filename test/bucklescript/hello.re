let () = {
  print_endline("Hello, world!");
  Node.Fs.writeFileSync("foo.out", Bisect.Runtime.get_coverage_data(), `binary);
}
